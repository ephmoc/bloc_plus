import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class _State {
  const _State(this.count, this.tag);

  final int count;
  final String tag;
}

void main() {
  test('distinctListen returns true only for different values', () {
    // Given
    final policy = distinctListen<int>();

    // When
    final sameResult = policy.shouldListen(1, 1);
    final changedResult = policy.shouldListen(1, 2);

    // Then
    expect(sameResult, isFalse);
    expect(changedResult, isTrue);
  });

  test('onChangeListen compares selected object field', () {
    // Given
    final policy = onChangeListen<_State, String>((state) => state.tag);
    const previous = _State(1, 'a');
    const sameSelected = _State(2, 'a');
    const changedSelected = _State(2, 'b');

    // When
    final sameResult = policy.shouldListen(previous, sameSelected);
    final changedResult = policy.shouldListen(previous, changedSelected);

    // Then
    expect(sameResult, isFalse);
    expect(changedResult, isTrue);
  });

  test('alwaysListen always returns true', () {
    // Given
    final policy = alwaysListen<int>();

    // When
    final result = policy.shouldListen(1, 1);

    // Then
    expect(result, isTrue);
  });

  test('neverListen always returns false', () {
    // Given
    final policy = neverListen<int>();

    // When
    final result = policy.shouldListen(1, 2);

    // Then
    expect(result, isFalse);
  });

  test('policy instance is reusable and stateless', () {
    // Given
    final policy = onChangeListen<_State, int>((state) => state.count);

    // When
    final result1 =
        policy.shouldListen(const _State(0, 'a'), const _State(1, 'a'));
    final result2 =
        policy.shouldListen(const _State(1, 'a'), const _State(1, 'b'));
    final result3 =
        policy.shouldListen(const _State(1, 'b'), const _State(2, 'b'));

    // Then
    expect(result1, isTrue);
    expect(result2, isFalse);
    expect(result3, isTrue);
  });
}
