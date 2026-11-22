import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _EffectCubit extends Cubit<int> with HasEffects<int, String> {
  _EffectCubit() : super(0);

  void say(String effect) => emitEffect(effect);
}

/// Collects what debugPrint prints during the test and restores both
/// debugPrint and the flag afterwards.
List<String> _capturePrints() {
  final printed = <String>[];
  final previousPrint = debugPrint;
  final previousFlag = debugPrintUnheardEffects;
  debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
  addTearDown(() {
    debugPrint = previousPrint;
    debugPrintUnheardEffects = previousFlag;
  });
  return printed;
}

void main() {
  test('warns about an effect that nothing listens to when enabled', () {
    // Given
    final printed = _capturePrints();
    debugPrintUnheardEffects = true;
    final cubit = _EffectCubit();
    addTearDown(cubit.close);

    // When
    cubit.say('toast');

    // Then
    expect(printed, [
      '_EffectCubit emitted the effect toast, but nothing listens to its '
          'effects, so the effect is lost: effects are not replayed.',
    ]);
  });

  test('stays silent for an effect that has a listener', () async {
    // Given
    final printed = _capturePrints();
    debugPrintUnheardEffects = true;
    final cubit = _EffectCubit();
    addTearDown(cubit.close);
    final received = <String>[];
    final subscription = cubit.effects.listen(received.add);
    addTearDown(subscription.cancel);

    // When
    cubit.say('toast');
    await pumpEventQueue();

    // Then
    expect(printed, isEmpty);
    expect(received, ['toast']);
  });

  test('is off by default', () {
    // Given
    final printed = _capturePrints();
    final cubit = _EffectCubit();
    addTearDown(cubit.close);

    // When
    cubit.say('toast');

    // Then
    expect(debugPrintUnheardEffects, isFalse);
    expect(printed, isEmpty);
  });

  test('stays silent for an effect emitted after close', () async {
    // Given
    final printed = _capturePrints();
    debugPrintUnheardEffects = true;
    final cubit = _EffectCubit();
    await cubit.close();

    // When
    cubit.say('late');

    // Then
    expect(printed, isEmpty);
  });
}
