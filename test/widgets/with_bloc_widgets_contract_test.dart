import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> with HasEffects<int, String> {
  _CounterCubit([super.initial = 0]);

  void increment() => emit(state + 1);
}

Widget _text(Object value) => Text('$value', textDirection: TextDirection.ltr);

void main() {
  group('BlocBuilderWithBloc', () {
    testWidgets('respects buildWhen', (tester) async {
      // Given
      final cubit = _CounterCubit();
      addTearDown(cubit.close);
      final builtStates = <int>[];
      await tester.pumpWidget(
        BlocBuilderWithBloc<_CounterCubit, int>(
          bloc: cubit,
          buildWhen: (previous, current) => current.isEven,
          builder: (context, bloc, state) {
            builtStates.add(state);
            return _text(state);
          },
        ),
      );

      // When
      cubit.increment(); // 1 -> skipped
      await tester.pumpAndSettle();
      cubit.increment(); // 2 -> built
      await tester.pumpAndSettle();

      // Then
      expect(builtStates, [0, 2]);
    });

    testWidgets('a reusable predicate plugs into buildWhen', (tester) async {
      // Given
      final cubit = _CounterCubit();
      addTearDown(cubit.close);
      final builtStates = <int>[];
      bool evenOnly(int previous, int current) => current.isEven;
      await tester.pumpWidget(
        BlocBuilderWithBloc<_CounterCubit, int>(
          bloc: cubit,
          buildWhen: evenOnly,
          builder: (context, bloc, state) {
            builtStates.add(state);
            return _text(state);
          },
        ),
      );

      // When
      cubit.increment();
      await tester.pumpAndSettle();
      cubit.increment();
      await tester.pumpAndSettle();

      // Then
      expect(builtStates, [0, 2]);
    });

    testWidgets('stops listening when disposed', (tester) async {
      // Given
      final cubit = _CounterCubit();
      addTearDown(cubit.close);
      final builtStates = <int>[];
      await tester.pumpWidget(
        BlocBuilderWithBloc<_CounterCubit, int>(
          bloc: cubit,
          builder: (context, bloc, state) {
            builtStates.add(state);
            return _text(state);
          },
        ),
      );

      // When
      await tester.pumpWidget(const SizedBox.shrink());
      cubit.increment();
      await tester.pump();

      // Then
      expect(builtStates, [0]);
      expect(tester.takeException(), isNull);
    });
  });

  group('BlocListenerWithBloc', () {
    testWidgets('explicit bloc overrides the provided bloc', (tester) async {
      // Given
      final providedCubit = _CounterCubit(100);
      final explicitCubit = _CounterCubit();
      addTearDown(providedCubit.close);
      addTearDown(explicitCubit.close);
      final calls = <(_CounterCubit, int)>[];
      await tester.pumpWidget(
        BlocProvider.value(
          value: providedCubit,
          child: BlocListenerWithBloc<_CounterCubit, int>(
            bloc: explicitCubit,
            listener: (context, bloc, state) => calls.add((bloc, state)),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      // When
      providedCubit.increment(); // 101, must be ignored
      explicitCubit.increment(); // 1
      await tester.pump();

      // Then
      expect(calls, [(explicitCubit, 1)]);
    });

    testWidgets('works without any provider when bloc is explicit', (
      tester,
    ) async {
      // Given
      final cubit = _CounterCubit();
      addTearDown(cubit.close);
      final calls = <(_CounterCubit, int)>[];
      await tester.pumpWidget(
        BlocListenerWithBloc<_CounterCubit, int>(
          bloc: cubit,
          listener: (context, bloc, state) => calls.add((bloc, state)),
          child: const SizedBox.shrink(),
        ),
      );

      // When
      cubit.increment();
      await tester.pump();

      // Then
      expect(calls, [(cubit, 1)]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stops listening when disposed', (tester) async {
      // Given
      final cubit = _CounterCubit();
      addTearDown(cubit.close);
      final states = <int>[];
      await tester.pumpWidget(
        BlocListenerWithBloc<_CounterCubit, int>(
          bloc: cubit,
          listener: (context, bloc, state) => states.add(state),
          child: const SizedBox.shrink(),
        ),
      );

      // When
      await tester.pumpWidget(const SizedBox.shrink());
      cubit.increment();
      await tester.pump();

      // Then
      expect(states, isEmpty);
    });
  });

  group('BlocConsumerWithBloc', () {
    testWidgets('explicit bloc drives both builder and listener', (
      tester,
    ) async {
      // Given
      final providedCubit = _CounterCubit(100);
      final explicitCubit = _CounterCubit();
      addTearDown(providedCubit.close);
      addTearDown(explicitCubit.close);
      final listened = <(_CounterCubit, int)>[];
      final built = <(_CounterCubit, int)>[];
      await tester.pumpWidget(
        BlocProvider.value(
          value: providedCubit,
          child: BlocConsumerWithBloc<_CounterCubit, int>(
            bloc: explicitCubit,
            listener: (context, bloc, state) => listened.add((bloc, state)),
            builder: (context, bloc, state) {
              built.add((bloc, state));
              return _text(state);
            },
          ),
        ),
      );

      // When
      providedCubit.increment(); // 101, must be ignored
      explicitCubit.increment(); // 1
      await tester.pumpAndSettle();

      // Then
      expect(listened, [(explicitCubit, 1)]);
      expect(built, [(explicitCubit, 0), (explicitCubit, 1)]);
    });

    testWidgets('buildWhen prevents the skipped state from being built', (
      tester,
    ) async {
      // Given
      final cubit = _CounterCubit();
      addTearDown(cubit.close);
      final builtStates = <int>[];
      await tester.pumpWidget(
        BlocConsumerWithBloc<_CounterCubit, int>(
          bloc: cubit,
          buildWhen: (previous, current) => current.isEven,
          listener: (context, bloc, state) {},
          builder: (context, bloc, state) {
            builtStates.add(state);
            return _text(state);
          },
        ),
      );

      // When
      cubit.increment();
      await tester.pumpAndSettle();
      cubit.increment();
      await tester.pumpAndSettle();

      // Then
      expect(builtStates, [0, 2]);
    });
  });

  group('BlocConsumerWithEffects', () {
    testWidgets('buildWhen prevents the skipped state from being built', (
      tester,
    ) async {
      // Given
      final cubit = _CounterCubit();
      addTearDown(cubit.close);
      final builtStates = <int>[];
      await tester.pumpWidget(
        BlocConsumerWithEffects<_CounterCubit, int, String>(
          bloc: cubit,
          buildWhen: (previous, current) => current.isEven,
          listener: (context, bloc, state) {},
          onEffect: (context, bloc, effect) {},
          builder: (context, bloc, state) {
            builtStates.add(state);
            return _text(state);
          },
        ),
      );

      // When
      cubit.increment();
      await tester.pumpAndSettle();
      cubit.increment();
      await tester.pumpAndSettle();

      // Then
      expect(builtStates, [0, 2]);
    });

    testWidgets('delivers states and effects of one tick in per-stream order',
        (tester) async {
      // Given
      final cubit = _CounterCubit();
      addTearDown(cubit.close);
      final states = <int>[];
      final effects = <String>[];
      await tester.pumpWidget(
        BlocConsumerWithEffects<_CounterCubit, int, String>(
          bloc: cubit,
          listener: (context, bloc, state) => states.add(state),
          onEffect: (context, bloc, effect) => effects.add(effect),
          builder: (context, bloc, state) => _text(state),
        ),
      );

      // When
      cubit.increment();
      cubit.emitEffect('a');
      cubit.increment();
      cubit.emitEffect('b');
      await tester.pumpAndSettle();

      // Then
      // dart:async orders events per stream only, so check each stream alone.
      expect(states, [1, 2]);
      expect(effects, ['a', 'b']);
    });
  });

  group('BlocSelectorWithBloc', () {
    testWidgets('explicit bloc overrides the provided bloc', (tester) async {
      // Given
      final providedCubit = _CounterCubit(100);
      final explicitCubit = _CounterCubit();
      addTearDown(providedCubit.close);
      addTearDown(explicitCubit.close);
      final built = <(_CounterCubit, int)>[];
      await tester.pumpWidget(
        BlocProvider.value(
          value: providedCubit,
          child: BlocSelectorWithBloc<_CounterCubit, int, int>(
            bloc: explicitCubit,
            selector: (state) => state,
            builder: (context, bloc, selected) {
              built.add((bloc, selected));
              return _text(selected);
            },
          ),
        ),
      );

      // When
      providedCubit.increment(); // 101, must be ignored
      explicitCubit.increment(); // 1
      await tester.pumpAndSettle();

      // Then
      expect(built, [(explicitCubit, 0), (explicitCubit, 1)]);
    });

    testWidgets('selectorShouldRebuild receives (previous, current)', (
      tester,
    ) async {
      // Given
      final cubit = _CounterCubit();
      addTearDown(cubit.close);
      final comparisons = <(int, int)>[];
      await tester.pumpWidget(
        BlocSelectorWithBloc<_CounterCubit, int, int>(
          bloc: cubit,
          selector: (state) => state * 10,
          selectorShouldRebuild: (previous, current) {
            comparisons.add((previous, current));
            return true;
          },
          builder: (context, bloc, selected) => _text(selected),
        ),
      );

      // When
      cubit.increment();
      await tester.pumpAndSettle();

      // Then
      expect(comparisons, [(0, 10)]);
      expect(find.text('10'), findsOneWidget);
    });
  });
}
