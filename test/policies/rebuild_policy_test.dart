import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class _State {
  const _State(this.count, this.tag);

  final int count;
  final String tag;
}

class _CollectionState {
  const _CollectionState(this.items);

  final List<int> items;
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

  test('when wraps a custom predicate', () {
    // Given
    final policy = whenRebuild<int>((previous, current) => current.isEven);

    // When
    final oddResult = policy.shouldRebuild(0, 1);
    final evenResult = policy.shouldRebuild(1, 2);

    // Then
    expect(oddResult, isFalse);
    expect(evenResult, isTrue);
  });

  test('and returns true only when both policies return true', () {
    // Given
    final policy =
        distinct<int>().and(whenRebuild<int>((_, current) => current > 1));

    // When
    final sameResult = policy.shouldRebuild(1, 1);
    final blockedResult = policy.shouldRebuild(1, 0);
    final passingResult = policy.shouldRebuild(1, 2);

    // Then
    expect(sameResult, isFalse);
    expect(blockedResult, isFalse);
    expect(passingResult, isTrue);
  });

  test('or returns true when any policy returns true', () {
    // Given
    final policy =
        never<int>().or(whenRebuild<int>((_, current) => current > 1));

    // When
    final blockedResult = policy.shouldRebuild(1, 1);
    final passingResult = policy.shouldRebuild(1, 2);

    // Then
    expect(blockedResult, isFalse);
    expect(passingResult, isTrue);
  });

  test('not negates the wrapped policy', () {
    // Given
    final policy = distinct<int>().not();

    // When
    final sameResult = policy.shouldRebuild(1, 1);
    final changedResult = policy.shouldRebuild(1, 2);

    // Then
    expect(sameResult, isTrue);
    expect(changedResult, isFalse);
  });

  test('onChangeBy uses custom equality for selected values', () {
    // Given
    final policy = onChangeBy<_CollectionState, List<int>>(
      (state) => state.items,
      equals: _listEquals,
    );
    const previous = _CollectionState([1, 2]);
    const sameSelected = _CollectionState([1, 2]);
    const changedSelected = _CollectionState([1, 3]);

    // When
    final sameResult = policy.shouldRebuild(previous, sameSelected);
    final changedResult = policy.shouldRebuild(previous, changedSelected);

    // Then
    expect(sameResult, isFalse);
    expect(changedResult, isTrue);
  });
}

bool _listEquals(List<int> previous, List<int> current) {
  if (previous.length != current.length) return false;
  for (var index = 0; index < previous.length; index++) {
    if (previous[index] != current[index]) return false;
  }
  return true;
}
