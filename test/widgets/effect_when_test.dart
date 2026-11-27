// Exercises the deprecated effectWhen until its removal in 1.0.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _EffectCubit extends Cubit<int> with HasEffects<int, String> {
  _EffectCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  group('BlocEffectListener.effectWhen', () {
    testWidgets('skips effects that effectWhen rejects', (tester) async {
      // Given
      final cubit = _EffectCubit();
      addTearDown(cubit.close);
      final effects = <String>[];
      await tester.pumpWidget(
        BlocEffectListener<_EffectCubit, String>(
          bloc: cubit,
          effectWhen: (effect) => effect.startsWith('go:'),
          onEffect: (context, effect) => effects.add(effect),
        ),
      );

      // When
      cubit
        ..emitEffect('toast:ignored')
        ..emitEffect('go:/home');
      await tester.pump();

      // Then
      expect(effects, ['go:/home']);
    });

    testWidgets('uses the latest onEffect and effectWhen after a rebuild',
        (tester) async {
      // Given
      final cubit = _EffectCubit();
      addTearDown(cubit.close);
      final effects = <String>[];
      Widget build(String tag, {required String blocked}) {
        return BlocProvider.value(
          value: cubit,
          child: BlocEffectListener<_EffectCubit, String>(
            effectWhen: (effect) => effect != blocked,
            onEffect: (context, effect) => effects.add('$tag:$effect'),
          ),
        );
      }

      await tester.pumpWidget(build('v1', blocked: 'a'));

      // When
      await tester.pumpWidget(build('v2', blocked: 'b'));
      cubit
        ..emitEffect('a')
        ..emitEffect('b');
      await tester.pump();

      // Then
      expect(effects, ['v2:a']);
    });
  });

  group('BlocConsumerWithEffects.effectWhen', () {
    testWidgets('skips effects that effectWhen rejects, states still flow',
        (tester) async {
      // Given
      final cubit = _EffectCubit();
      addTearDown(cubit.close);
      final listened = <int>[];
      final effects = <String>[];
      await tester.pumpWidget(
        BlocConsumerWithEffects<_EffectCubit, int, String>(
          bloc: cubit,
          effectWhen: (effect) => effect.startsWith('allow'),
          listener: (context, bloc, state) => listened.add(state),
          onEffect: (context, bloc, effect) => effects.add(effect),
          builder: (context, bloc, state) => const SizedBox.shrink(),
        ),
      );

      // When
      cubit
        ..increment()
        ..emitEffect('skip')
        ..emitEffect('allow');
      await tester.pump();

      // Then
      expect(listened, [1]);
      expect(effects, ['allow']);
    });

    testWidgets('uses the latest onEffect and effectWhen after a rebuild',
        (tester) async {
      // Given
      final cubit = _EffectCubit();
      addTearDown(cubit.close);
      final effects = <String>[];
      Widget consumer(String tag, {required String blocked}) =>
          BlocConsumerWithEffects<_EffectCubit, int, String>(
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
  });
}
