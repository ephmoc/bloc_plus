import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class _State {
  const _State(this.count, this.tag);

  final int count;
  final String tag;
}

void main() {
  test('distinct returns true only for different values', () {
    // Given
    final policy = distinct<int>();

    // When
    final sameResult = policy.shouldRebuild(1, 1);
    final changedResult = policy.shouldRebuild(1, 2);

    // Then
    expect(sameResult, isFalse);
    expect(changedResult, isTrue);
  });

  test('onChange compares selected primitive field', () {
    // Given
    final policy = onChange<_State, int>((state) => state.count);
    const previous = _State(1, 'a');
    const sameSelected = _State(1, 'b');
    const changedSelected = _State(2, 'b');

    // When
    final sameResult = policy.shouldRebuild(previous, sameSelected);
    final changedResult = policy.shouldRebuild(previous, changedSelected);

    // Then
    expect(sameResult, isFalse);
    expect(changedResult, isTrue);
  });

  test('always always returns true', () {
    // Given
    final policy = always<int>();

    // When
    final result = policy.shouldRebuild(1, 1);

    // Then
    expect(result, isTrue);
  });

  test('never always returns false', () {
    // Given
    final policy = never<int>();

    // When
    final result = policy.shouldRebuild(1, 2);

    // Then
    expect(result, isFalse);
  });

  test('policy instance is reusable and stateless', () {
    // Given
    final policy = distinct<int>();

    // When
    final result1 = policy.shouldRebuild(0, 1);
    final result2 = policy.shouldRebuild(1, 1);
    final result3 = policy.shouldRebuild(1, 2);

    // Then
    expect(result1, isTrue);
    expect(result2, isFalse);
    expect(result3, isTrue);
  });
}
