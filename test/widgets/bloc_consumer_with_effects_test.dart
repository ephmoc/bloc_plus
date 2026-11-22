import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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

  testWidgets('uses the latest onEffect and effectWhen after a rebuild',
      (tester) async {
    // Given
    final cubit = _EffectCounterCubit();
    addTearDown(cubit.close);
    final effects = <String>[];
    Widget consumer(String tag, {required String blocked}) =>
        BlocConsumerWithEffects<_EffectCounterCubit, int, String>(
          bloc: cubit,
          effectWhen: (effect) => effect != blocked,
          onEffect: (context, bloc, effect) => effects.add('$tag:$effect'),
          builder: (context, bloc, state) => const SizedBox.shrink(),
        );
    await tester.pumpWidget(consumer('v1', blocked: 'a'));

    // When
    await tester.pumpWidget(consumer('v2', blocked: 'b'));
    cubit
      ..emitEffect('a')
      ..emitEffect('b');
    await tester.pump();

    // Then
    expect(effects, ['v2:a']);
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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

  testWidgets('builds and handles effects without a state listener', (
    tester,
  ) async {
    // Given
    final cubit = _EffectCounterCubit();
    addTearDown(cubit.close);
    final effects = <String>[];
    await tester.pumpWidget(
      BlocConsumerWithEffects<_EffectCounterCubit, int, String>(
        bloc: cubit,
        onEffect: (context, bloc, effect) => effects.add(effect),
        builder: (context, bloc, state) =>
            Text('$state', textDirection: TextDirection.ltr),
      ),
    );

    // When
    cubit.increment();
    cubit.emitEffect('toast');
    await tester.pumpAndSettle();

    // Then
    expect(find.text('1'), findsOneWidget);
    expect(effects, ['toast']);
  });

  test('asserts when listenWhen is given without a listener', () {
    // Given
    bool listenWhen(int previous, int current) => true;

    // When
    BlocConsumerWithEffects<_EffectCounterCubit, int, String> construct() =>
        BlocConsumerWithEffects<_EffectCounterCubit, int, String>(
          listenWhen: listenWhen,
          onEffect: (context, bloc, effect) {},
          builder: (context, bloc, state) => const SizedBox.shrink(),
        );

    // Then
    expect(construct, throwsAssertionError);
  });

  testWidgets('throws when bloc is missing', (tester) async {
    // Given
    final widget = Directionality(
      textDirection: TextDirection.ltr,
      child: BlocConsumerWithEffects<_EffectCounterCubit, int, String>(
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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
    await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr, child: SizedBox.shrink()));
    cubit.emitEffect('late');
    await tester.pumpAndSettle();

    // Then
    expect(effects, isEmpty);
  });

  testWidgets('keeps the builder state when listener toggles to non-null',
      (tester) async {
    // Given
    final cubit = _EffectCounterCubit();
    addTearDown(cubit.close);
    Widget consumer({required bool withListener}) => Directionality(
          textDirection: TextDirection.ltr,
          child: BlocConsumerWithEffects<_EffectCounterCubit, int, String>(
            bloc: cubit,
            listener: withListener ? (context, bloc, state) {} : null,
            onEffect: (context, bloc, effect) {},
            builder: (context, bloc, state) => const _TapCounter(),
          ),
        );
    await tester.pumpWidget(consumer(withListener: false));
    await tester.tap(find.byType(_TapCounter));
    await tester.pump();

    // When
    await tester.pumpWidget(consumer(withListener: true));

    // Then
    expect(find.text('taps: 1'), findsOneWidget);
  });
}

class _TapCounter extends StatefulWidget {
  const _TapCounter();

  @override
  State<_TapCounter> createState() => _TapCounterState();
}

class _TapCounterState extends State<_TapCounter> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => setState(() => _taps++),
        child: Text('taps: $_taps'),
      );
}
