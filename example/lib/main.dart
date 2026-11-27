import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // Debug builds only: warns about effects that nothing listens to.
  debugPrintUnheardEffects = true;
  runApp(const ExampleApp());
}

class CounterState {
  const CounterState({this.count = 0, this.evenHistory = const <int>[]});

  final int count;
  final List<int> evenHistory;

  CounterState copyWith({int? count, List<int>? evenHistory}) {
    return CounterState(
      count: count ?? this.count,
      evenHistory: evenHistory ?? this.evenHistory,
    );
  }
}

class SearchState {
  const SearchState({this.isLoading = false, this.result = 'No result yet'});

  final bool isLoading;
  final String result;

  SearchState copyWith({bool? isLoading, String? result}) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
    );
  }
}

// Effects are sealed classes, so a switch over them is checked for
// exhaustiveness.
sealed class CounterEffect {}

final class CounterMessage extends CounterEffect {
  CounterMessage(this.text);
  final String text;
}

final class EvenHistoryDialog extends CounterEffect {
  EvenHistoryDialog(this.length);
  final int length;
}

sealed class SearchEffect {}

final class PreviewLoaded extends SearchEffect {
  PreviewLoaded(this.result);
  final String result;
}

final class PreviewCancelled extends SearchEffect {}

class CounterCubit extends Cubit<CounterState>
    with HasEffects<CounterState, CounterEffect> {
  CounterCubit() : super(const CounterState());

  void increment() {
    final nextCount = state.count + 1;
    final nextHistory = nextCount.isEven
        ? [...state.evenHistory, nextCount]
        : state.evenHistory;

    emit(state.copyWith(count: nextCount, evenHistory: nextHistory));
    emitEffect(CounterMessage('Count moved to $nextCount'));
  }

  void cloneHistory() {
    emit(state.copyWith(evenHistory: List<int>.of(state.evenHistory)));
    emitEffect(CounterMessage('Cloned the history list'));
  }

  void showDialogEffect() {
    emitEffect(EvenHistoryDialog(state.evenHistory.length));
  }
}

class SearchCubit extends Cubit<SearchState>
    with
        SafeEmitMixin<SearchState>,
        RestartableTasksMixin<SearchState>,
        HasEffects<SearchState, SearchEffect> {
  SearchCubit() : super(const SearchState());

  Future<void> loadPreview(String label, Duration delay) async {
    // Before the first await the cubit may be closed already.
    safeEmit(state.copyWith(isLoading: true, result: 'Loading $label...'));

    final outcome = await runLatestOutcome('preview', (_) async {
      await Future<void>.delayed(delay);
      return label;
    });

    // A superseded or cancelled request resumes at once, and close() cancels
    // the run: only the latest completed one updates the state.
    if (!outcome.isCompleted) return;
    final result = outcome.value;

    emit(state.copyWith(isLoading: false, result: 'Latest result: $result'));
    emitEffect(PreviewLoaded(result));
  }

  void cancelPreview() {
    cancelLatest('preview');
    safeEmit(
      state.copyWith(isLoading: false, result: 'Cancelled latest preview'),
    );
    emitEffect(PreviewCancelled());
  }
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CounterCubit()),
        BlocProvider(create: (_) => SearchCubit()),
      ],
      child: MaterialApp(
        title: 'bloc_plus example',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const ExamplePage(),
      ),
    );
  }
}

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocEffectListener<CounterCubit, CounterEffect>(
          onEffect: (context, effect) {
            // One subtype only: the consumer below shows the messages.
            if (effect is! EvenHistoryDialog) return;
            showDialog<void>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text('Counter effect'),
                  content: Text(
                    'Current even history length is ${effect.length}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        BlocEffectListener<SearchCubit, SearchEffect>(
          onEffect: (context, effect) {
            // Every subtype: the switch fails to compile when one is missing.
            final message = switch (effect) {
              PreviewLoaded(:final result) => 'Loaded $result',
              PreviewCancelled() => 'Cancelled preview',
            };
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('bloc_plus example')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Text(
              'This example shows sealed effects handled with a switch or an '
              'if-case, effect listeners in a MultiBlocListener, restartable '
              'async helpers with TaskOutcome, whenChanged conditions, and '
              'the combined state-and-effect consumer.',
            ),
            SizedBox(height: 16),
            CounterSection(),
            SizedBox(height: 16),
            SearchSection(),
          ],
        ),
      ),
    );
  }
}

class CounterSection extends StatelessWidget {
  const CounterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Counter section',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Uses BlocConsumerWithEffects for snack effects, '
              'BlocEffectListener in a MultiBlocListener for dialog effects, '
              'and whenChanged conditions for targeted rebuilds.',
            ),
            const SizedBox(height: 16),
            BlocConsumerWithEffects<CounterCubit, CounterState, CounterEffect>(
              onEffect: (context, bloc, effect) {
                // One subtype only: the listener above the page shows the
                // dialog.
                if (effect case CounterMessage(:final text)) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(text)));
                }
              },
              builder: (context, bloc, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current count: ${state.count}'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: bloc.increment,
                          child: const Text('Increment'),
                        ),
                        OutlinedButton(
                          onPressed: bloc.cloneHistory,
                          child: const Text('Clone history'),
                        ),
                        OutlinedButton(
                          onPressed: bloc.showDialogEffect,
                          child: const Text('Show dialog effect'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            BlocBuilderWithBloc<CounterCubit, CounterState>(
              buildWhen: (previous, current) =>
                  previous.count != current.count && current.count.isEven,
              builder: (context, bloc, state) {
                return Text(
                  'Even-only preview (plain predicate): ${state.count}',
                );
              },
            ),
            const SizedBox(height: 8),
            BlocBuilderWithBloc<CounterCubit, CounterState>(
              buildWhen: whenChanged(
                (state) => state.evenHistory,
                equals: _listEquals,
              ),
              builder: (context, bloc, state) {
                final history = state.evenHistory.isEmpty
                    ? 'none yet'
                    : state.evenHistory.join(', ');
                return Text(
                  'Even history (whenChanged + custom equality): $history',
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'The "Clone history" action emits a new list instance with the '
              'same contents, so the history preview stays stable thanks to '
              'custom list equality.',
            ),
          ],
        ),
      ),
    );
  }
}

class SearchSection extends StatelessWidget {
  const SearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilderWithBloc<SearchCubit, SearchState>(
          builder: (context, bloc, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Async section',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Uses RestartableTasksMixin.runLatestOutcome so the latest '
                  'preview request wins: a superseded or cancelled request '
                  'resumes at once, while its underlying work keeps running.',
                ),
                const SizedBox(height: 16),
                Text(state.result),
                const SizedBox(height: 4),
                Text(
                  state.isLoading
                      ? 'Task status: running'
                      : 'Task status: idle',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              bloc.loadPreview(
                                'slow',
                                const Duration(milliseconds: 900),
                              );
                              await Future<void>.delayed(
                                const Duration(milliseconds: 120),
                              );
                              bloc.loadPreview(
                                'fast',
                                const Duration(milliseconds: 250),
                              );
                            },
                      child: const Text('Run slow then fast'),
                    ),
                    OutlinedButton(
                      onPressed: state.isLoading ? bloc.cancelPreview : null,
                      child: const Text('Cancel latest'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

bool _listEquals(List<int> previous, List<int> current) {
  if (previous.length != current.length) return false;

  for (var index = 0; index < previous.length; index++) {
    if (previous[index] != current[index]) return false;
  }

  return true;
}
