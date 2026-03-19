import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const ExampleApp());
}

class CounterState {
  const CounterState({
    this.count = 0,
    this.evenHistory = const <int>[],
  });

  final int count;
  final List<int> evenHistory;

  CounterState copyWith({
    int? count,
    List<int>? evenHistory,
  }) {
    return CounterState(
      count: count ?? this.count,
      evenHistory: evenHistory ?? this.evenHistory,
    );
  }
}

class SearchState {
  const SearchState({
    this.isLoading = false,
    this.result = 'No result yet',
  });

  final bool isLoading;
  final String result;

  SearchState copyWith({
    bool? isLoading,
    String? result,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
    );
  }
}

class CounterCubit extends Cubit<CounterState>
    with HasEffects<CounterState, String> {
  CounterCubit() : super(const CounterState());

  void increment() {
    final nextCount = state.count + 1;
    final nextHistory = nextCount.isEven
        ? [...state.evenHistory, nextCount]
        : state.evenHistory;

    emit(
      state.copyWith(
        count: nextCount,
        evenHistory: nextHistory,
      ),
    );
    emitEffect('snack:Count moved to $nextCount');
  }

  void cloneHistory() {
    emit(
      state.copyWith(
        evenHistory: List<int>.of(state.evenHistory),
      ),
    );
    emitEffect('snack:Cloned the history list');
  }

  void showDialogEffect() {
    emitEffect(
      'dialog:Current even history length is ${state.evenHistory.length}',
    );
  }
}

class SearchCubit extends Cubit<SearchState>
    with
        SafeEmitMixin<SearchState>,
        RestartableTasksMixin<SearchState>,
        HasEffects<SearchState, String> {
  SearchCubit() : super(const SearchState());

  Future<void> loadPreview(String label, Duration delay) async {
    safeEmit(
      state.copyWith(
        isLoading: true,
        result: 'Loading $label...',
      ),
    );

    final result = await runLatest<String>('preview', () async {
      await Future<void>.delayed(delay);
      return label;
    });

    if (result == null) return;

    safeEmit(
      state.copyWith(
        isLoading: false,
        result: 'Latest result: $result',
      ),
    );
    emitEffect('info:Loaded $result');
  }

  void cancelPreview() {
    cancelLatest('preview');
    safeEmit(
      state.copyWith(
        isLoading: false,
        result: 'Cancelled latest preview',
      ),
    );
    emitEffect('info:Cancelled preview');
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
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        home: const ExamplePage(),
      ),
    );
  }
}

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiEffectListener(
      listeners: [
        EffectListener<CounterCubit, CounterState, String>(
          effectWhen: (effect) => effect.startsWith('dialog:'),
          onEffect: (context, effect) {
            showDialog<void>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text('Counter effect'),
                  content: Text(_stripEffectPrefix(effect)),
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
        EffectListener<SearchCubit, SearchState, String>(
          effectWhen: (effect) => effect.startsWith('info:'),
          onEffect: (context, effect) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_stripEffectPrefix(effect))),
            );
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('bloc_plus example')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Text(
              'This example shows the new policy helpers, effect filtering, '
              'multi-effect composition, restartable async helpers, and the '
              'combined state-and-effect consumer.',
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
    final evenOnlyPolicy = distinct<CounterState>().and(
      whenRebuild<CounterState>((previous, current) => current.count.isEven),
    );
    final historyPolicy = onChangeBy<CounterState, List<int>>(
      (state) => state.evenHistory,
      equals: _listEquals,
    );

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
              'MultiEffectListener for dialog effects, and policy helpers for '
              'targeted rebuilds.',
            ),
            const SizedBox(height: 16),
            BlocConsumerWithEffects<CounterCubit, CounterState, String>(
              effectWhen: (effect) => effect.startsWith('snack:'),
              listener: (context, bloc, state) {},
              onEffect: (context, bloc, effect) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_stripEffectPrefix(effect))),
                );
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
              buildWhen: evenOnlyPolicy.shouldRebuild,
              builder: (context, bloc, state) {
                return Text(
                  'Even-only preview (and + whenRebuild): ${state.count}',
                );
              },
            ),
            const SizedBox(height: 8),
            BlocBuilderWithBloc<CounterCubit, CounterState>(
              buildWhen: historyPolicy.shouldRebuild,
              builder: (context, bloc, state) {
                final history = state.evenHistory.isEmpty
                    ? 'none yet'
                    : state.evenHistory.join(', ');
                return Text(
                  'Even history (onChangeBy + custom equality): $history',
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
                  'Uses RestartableTasksMixin so the latest preview request '
                  'wins without forcing cancellation of the underlying work.',
                ),
                const SizedBox(height: 16),
                Text(state.result),
                const SizedBox(height: 4),
                Text(
                  bloc.isTaskRunning('preview')
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
                      onPressed: bloc.isTaskRunning('preview')
                          ? bloc.cancelPreview
                          : null,
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

String _stripEffectPrefix(String effect) {
  final separatorIndex = effect.indexOf(':');
  if (separatorIndex == -1) return effect;
  return effect.substring(separatorIndex + 1).trimLeft();
}

bool _listEquals(List<int> previous, List<int> current) {
  if (previous.length != current.length) return false;

  for (var index = 0; index < previous.length; index++) {
    if (previous[index] != current[index]) return false;
  }

  return true;
}
