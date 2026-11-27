import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _EffectCubit extends Cubit<int> with HasEffects<int, String> {
  _EffectCubit() : super(0);
}

void main() {
  test('emitEffect emits events to listeners', () async {
    // Given
    final cubit = _EffectCubit();
    addTearDown(cubit.close);
    final received = <String>[];
    final sub = cubit.effects.listen(received.add);
    addTearDown(sub.cancel);

    // When
    cubit.emitEffect('hello');
    await Future<void>.delayed(Duration.zero);

    // Then
    expect(received, ['hello']);
  });

  test('effects stream supports multiple listeners', () async {
    // Given
    final cubit = _EffectCubit();
    addTearDown(cubit.close);
    final first = <String>[];
    final second = <String>[];
    final sub1 = cubit.effects.listen(first.add);
    final sub2 = cubit.effects.listen(second.add);
    addTearDown(sub1.cancel);
    addTearDown(sub2.cancel);

    // When
    cubit.emitEffect('event');
    await Future<void>.delayed(Duration.zero);

    // Then
    expect(first, ['event']);
    expect(second, ['event']);
  });

  test('effects stream closes when cubit closes', () async {
    // Given
    final cubit = _EffectCubit();
    var completed = false;
    final sub = cubit.effects.listen((_) {}, onDone: () => completed = true);
    addTearDown(sub.cancel);

    // When
    await cubit.close();
    await Future<void>.delayed(Duration.zero);

    // Then
    expect(completed, isTrue);
  });

  test('emitEffect after close does not throw', () async {
    // Given
    final cubit = _EffectCubit();
    await cubit.close();

    // When
    void action() => cubit.emitEffect('late');

    // Then
    expect(action, returnsNormally);
  });

  test('close closes the cubit even while an effect subscriber is paused',
      () async {
    // Given
    final cubit = _EffectCubit();
    final subscription = cubit.effects.listen((_) {})..pause();

    // When
    final closing = cubit.close();
    final closedRightAway = cubit.isClosed;
    subscription.resume();
    await closing;

    // Then
    expect(closedRightAway, isTrue);
  });

  test('close completes after the effects emitted before it are delivered',
      () async {
    // Given
    final cubit = _EffectCubit();
    final received = <String>[];
    final subscription = cubit.effects.listen(received.add);
    addTearDown(subscription.cancel);
    cubit
      ..emitEffect('a')
      ..emitEffect('b')
      ..emitEffect('c');

    // When
    await cubit.close();

    // Then
    expect(received, ['a', 'b', 'c']);
  });

  test('drops an effect emitted after close was called', () async {
    // Given
    final cubit = _EffectCubit();
    final received = <String>[];
    final subscription = cubit.effects.listen(received.add);
    addTearDown(subscription.cancel);
    cubit.emitEffect('before');

    // When
    final closing = cubit.close();
    cubit.emitEffect('after');
    await closing;

    // Then
    expect(received, ['before']);
  });
}
