import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _PrimaryCubit extends Cubit<int> with HasEffects<int, String> {
  _PrimaryCubit() : super(0);
}

class _SecondaryCubit extends Cubit<int> with HasEffects<int, String> {
  _SecondaryCubit() : super(0);
}

void main() {
  testWidgets('invokes listeners for different blocs', (tester) async {
    // Given
    final primaryCubit = _PrimaryCubit();
    final secondaryCubit = _SecondaryCubit();
    addTearDown(primaryCubit.close);
    addTearDown(secondaryCubit.close);
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<_PrimaryCubit>.value(value: primaryCubit),
            BlocProvider<_SecondaryCubit>.value(value: secondaryCubit),
          ],
          child: MultiEffectListener(
            listeners: [
              EffectListener<_PrimaryCubit, int, String>(
                onEffect: (context, effect) => events.add('primary:$effect'),
              ),
              EffectListener<_SecondaryCubit, int, String>(
                onEffect: (context, effect) => events.add('secondary:$effect'),
              ),
            ],
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // When
    primaryCubit.emitEffect('one');
    secondaryCubit.emitEffect('two');
    await tester.pumpAndSettle();

    // Then
    expect(events, ['primary:one', 'secondary:two']);
  });

  testWidgets('invokes listeners in declaration order', (tester) async {
    // Given
    final cubit = _PrimaryCubit();
    addTearDown(cubit.close);
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: MultiEffectListener(
            listeners: [
              EffectListener<_PrimaryCubit, int, String>(
                onEffect: (context, effect) => events.add('first:$effect'),
              ),
              EffectListener<_PrimaryCubit, int, String>(
                onEffect: (context, effect) => events.add('second:$effect'),
              ),
            ],
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // When
    cubit.emitEffect('ordered');
    await tester.pumpAndSettle();

    // Then
    expect(events, ['first:ordered', 'second:ordered']);
  });

  testWidgets('supports multiple listeners for the same bloc via explicit bloc',
      (
    tester,
  ) async {
    // Given
    final firstCubit = _PrimaryCubit();
    final secondCubit = _PrimaryCubit();
    addTearDown(firstCubit.close);
    addTearDown(secondCubit.close);
    final events = <String>[];

    await tester.pumpWidget(
      const MaterialApp(home: SizedBox.shrink()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiEffectListener(
          listeners: [
            EffectListener<_PrimaryCubit, int, String>(
              bloc: firstCubit,
              onEffect: (context, effect) => events.add('first:$effect'),
            ),
            EffectListener<_PrimaryCubit, int, String>(
              bloc: secondCubit,
              onEffect: (context, effect) => events.add('second:$effect'),
            ),
          ],
          child: const SizedBox.shrink(),
        ),
      ),
    );

    // When
    firstCubit.emitEffect('one');
    secondCubit.emitEffect('two');
    await tester.pumpAndSettle();

    // Then
    expect(events, ['first:one', 'second:two']);
  });

  testWidgets('throws when one of the listeners is missing its provider', (
    tester,
  ) async {
    // Given
    final primaryCubit = _PrimaryCubit();
    addTearDown(primaryCubit.close);

    final widget = MaterialApp(
      home: BlocProvider.value(
        value: primaryCubit,
        child: MultiEffectListener(
          listeners: [
            EffectListener<_PrimaryCubit, int, String>(
              onEffect: (context, effect) {},
            ),
            EffectListener<_SecondaryCubit, int, String>(
              onEffect: (context, effect) {},
            ),
          ],
          child: const SizedBox.shrink(),
        ),
      ),
    );

    // When
    await tester.pumpWidget(widget);

    // Then
    final exception = tester.takeException();
    expect(exception, isA<ProviderNotFoundException>());
  });

  testWidgets('unsubscribes all listeners on dispose', (tester) async {
    // Given
    final cubit = _PrimaryCubit();
    addTearDown(cubit.close);
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: MultiEffectListener(
            listeners: [
              EffectListener<_PrimaryCubit, int, String>(
                onEffect: (context, effect) => events.add('first:$effect'),
              ),
              EffectListener<_PrimaryCubit, int, String>(
                onEffect: (context, effect) => events.add('second:$effect'),
              ),
            ],
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // When
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    cubit.emitEffect('late');
    await tester.pumpAndSettle();

    // Then
    expect(events, isEmpty);
  });
}
