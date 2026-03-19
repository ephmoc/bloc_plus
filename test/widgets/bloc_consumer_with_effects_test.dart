import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _EffectCounterCubit extends Cubit<int> with HasEffects<int, String> {
  _EffectCounterCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  testWidgets('builds, listens, and handles effects with bloc instance', (
    tester,
  ) async {
    // Given
    final cubit = _EffectCounterCubit();
    addTearDown(cubit.close);
    final listened = <int>[];
    final effects = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocConsumerWithEffects<_EffectCounterCubit, int, String>(
            listener: (context, bloc, state) {
              expect(bloc, same(cubit));
              listened.add(state);
            },
            onEffect: (context, bloc, effect) {
              expect(bloc, same(cubit));
              effects.add(effect);
            },
            builder: (context, bloc, state) {
              expect(bloc, same(cubit));
              return Text('$state', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );

    // When
    cubit.increment();
    cubit.emitEffect('toast');
    await tester.pumpAndSettle();

    // Then
    expect(find.text('1'), findsOneWidget);
    expect(listened, [1]);
    expect(effects, ['toast']);
  });

  testWidgets('state and effect predicates are evaluated independently', (
    tester,
  ) async {
    // Given
    final cubit = _EffectCounterCubit();
    addTearDown(cubit.close);
    final listened = <int>[];
    final effects = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocConsumerWithEffects<_EffectCounterCubit, int, String>(
            buildWhen: (previous, current) => current.isEven,
            listenWhen: (previous, current) => current.isOdd,
            effectWhen: (effect) => effect.startsWith('allow'),
            listener: (context, bloc, state) => listened.add(state),
            onEffect: (context, bloc, effect) => effects.add(effect),
            builder: (context, bloc, state) =>
                Text('$state', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );

    // When
    cubit.increment();
    await tester.pumpAndSettle();
    cubit.increment();
    cubit.emitEffect('skip');
    cubit.emitEffect('allow');
    await tester.pumpAndSettle();

    // Then
    expect(listened, [1]);
    expect(effects, ['allow']);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('explicit bloc overrides provider lookup', (tester) async {
    // Given
    final providerCubit = _EffectCounterCubit();
    final explicitCubit = _EffectCounterCubit();
    addTearDown(providerCubit.close);
    addTearDown(explicitCubit.close);
    final listened = <int>[];
    final effects = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: providerCubit,
          child: BlocConsumerWithEffects<_EffectCounterCubit, int, String>(
            bloc: explicitCubit,
            listener: (context, bloc, state) {
              expect(bloc, same(explicitCubit));
              listened.add(state);
            },
            onEffect: (context, bloc, effect) {
              expect(bloc, same(explicitCubit));
              effects.add(effect);
            },
            builder: (context, bloc, state) {
              expect(bloc, same(explicitCubit));
              return Text('$state', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );

    // When
    providerCubit.increment();
    explicitCubit.increment();
    explicitCubit.emitEffect('explicit');
    await tester.pumpAndSettle();

    // Then
    expect(find.text('1'), findsOneWidget);
    expect(listened, [1]);
    expect(effects, ['explicit']);
  });

  testWidgets('throws when bloc is missing', (tester) async {
    // Given
    final widget = MaterialApp(
      home: BlocConsumerWithEffects<_EffectCounterCubit, int, String>(
        listener: (context, bloc, state) {},
        onEffect: (context, bloc, effect) {},
        builder: (context, bloc, state) => const SizedBox.shrink(),
      ),
    );

    // When
    await tester.pumpWidget(widget);

    // Then
    final exception = tester.takeException();
    expect(exception, isA<ProviderNotFoundException>());
  });

  testWidgets('unsubscribes the effect listener path on dispose',
      (tester) async {
    // Given
    final cubit = _EffectCounterCubit();
    addTearDown(cubit.close);
    final effects = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocConsumerWithEffects<_EffectCounterCubit, int, String>(
            listener: (context, bloc, state) {},
            onEffect: (context, bloc, effect) => effects.add(effect),
            builder: (context, bloc, state) => const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // When
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    cubit.emitEffect('late');
    await tester.pumpAndSettle();

    // Then
    expect(effects, isEmpty);
  });
}
