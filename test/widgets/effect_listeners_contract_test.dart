// Exercises the deprecated effect widgets until their removal in 1.0.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _EffectCubit extends Cubit<int> with HasEffects<int, String> {
  _EffectCubit() : super(0);
}

/// A hand-written [EffectsSource] so the test can observe the subscription.
class _ProbeCubit extends Cubit<int> implements EffectsSource<String> {
  _ProbeCubit() : super(0);

  final controller = StreamController<String>.broadcast();

  @override
  Stream<String> get effects => controller.stream;

  @override
  Future<void> close() async {
    await controller.close();
    return super.close();
  }
}

void main() {
  group('EffectListener', () {
    testWidgets('cancels its subscription when disposed', (tester) async {
      // Given
      final cubit = _ProbeCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        EffectListener<_ProbeCubit, int, String>(
          bloc: cubit,
          onEffect: (context, effect) {},
          child: const SizedBox.shrink(),
        ),
      );
      final listeningWhileMounted = cubit.controller.hasListener;

      // When
      await tester.pumpWidget(const SizedBox.shrink());

      // Then
      expect(listeningWhileMounted, isTrue);
      expect(cubit.controller.hasListener, isFalse);
    });

    testWidgets('follows the provider when the provided instance changes',
        (tester) async {
      // Given
      final firstCubit = _EffectCubit();
      final secondCubit = _EffectCubit();
      addTearDown(firstCubit.close);
      addTearDown(secondCubit.close);
      final events = <String>[];
      // One cached widget instance: only the provider above it changes.
      final listener = EffectListener<_EffectCubit, int, String>(
        onEffect: (context, effect) => events.add(effect),
        child: const SizedBox.shrink(),
      );
      await tester.pumpWidget(
        BlocProvider.value(value: firstCubit, child: listener),
      );

      // When
      await tester.pumpWidget(
        BlocProvider.value(value: secondCubit, child: listener),
      );
      firstCubit.emitEffect('from-first');
      secondCubit.emitEffect('from-second');
      await tester.pump();

      // Then
      expect(events, ['from-second']);
    });

    testWidgets('uses the latest onEffect and effectWhen after a rebuild',
        (tester) async {
      // Given
      final cubit = _EffectCubit();
      addTearDown(cubit.close);
      final events = <String>[];
      Widget build(String tag, {required String blocked}) {
        return BlocProvider.value(
          value: cubit,
          child: EffectListener<_EffectCubit, int, String>(
            effectWhen: (effect) => effect != blocked,
            onEffect: (context, effect) => events.add('$tag:$effect'),
            child: const SizedBox.shrink(),
          ),
        );
      }

      await tester.pumpWidget(build('v1', blocked: 'a'));

      // When
      await tester.pumpWidget(build('v2', blocked: 'b'));
      cubit.emitEffect('a');
      cubit.emitEffect('b');
      await tester.pump();

      // Then
      expect(events, ['v2:a']);
    });

    testWidgets('survives the bloc being closed while mounted', (tester) async {
      // Given
      final cubit = _EffectCubit();
      final events = <String>[];
      await tester.pumpWidget(
        EffectListener<_EffectCubit, int, String>(
          bloc: cubit,
          onEffect: (context, effect) => events.add(effect),
          child: const SizedBox.shrink(),
        ),
      );

      // When
      await tester.runAsync(cubit.close);
      cubit.emitEffect('late');
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());

      // Then
      expect(events, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('MultiEffectListener', () {
    testWidgets('renders its child', (tester) async {
      // Given
      final cubit = _EffectCubit();
      addTearDown(cubit.close);

      // When
      await tester.pumpWidget(
        MultiEffectListener(
          listeners: [
            EffectListener<_EffectCubit, int, String>(
              bloc: cubit,
              onEffect: (context, effect) {},
            ),
          ],
          child: const Text('content', textDirection: TextDirection.ltr),
        ),
      );

      // Then
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('keeps effectWhen and key of every listener', (tester) async {
      // Given
      final cubit = _EffectCubit();
      addTearDown(cubit.close);
      final events = <String>[];
      await tester.pumpWidget(
        MultiEffectListener(
          listeners: [
            EffectListener<_EffectCubit, int, String>(
              key: const ValueKey('snack-listener'),
              bloc: cubit,
              effectWhen: (effect) => effect.startsWith('snack:'),
              onEffect: (context, effect) => events.add('snack<$effect'),
            ),
            EffectListener<_EffectCubit, int, String>(
              bloc: cubit,
              effectWhen: (effect) => effect.startsWith('dialog:'),
              onEffect: (context, effect) => events.add('dialog<$effect'),
            ),
          ],
          child: const SizedBox.shrink(),
        ),
      );

      // When
      cubit.emitEffect('snack:saved');
      cubit.emitEffect('dialog:confirm');
      await tester.pump();

      // Then
      expect(events, ['snack<snack:saved', 'dialog<dialog:confirm']);
      expect(find.byKey(const ValueKey('snack-listener')), findsOneWidget);
    });
  });
}
