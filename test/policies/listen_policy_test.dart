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

  test('whenListen wraps a custom predicate', () {
    // Given
    final policy = whenListen<int>((previous, current) => current.isEven);

    // When
    final oddResult = policy.shouldListen(0, 1);
    final evenResult = policy.shouldListen(1, 2);

    // Then
    expect(oddResult, isFalse);
    expect(evenResult, isTrue);
  });

  test('and returns true only when both listen policies return true', () {
    // Given
    final policy =
        distinctListen<int>().and(whenListen<int>((_, current) => current > 1));

    // When
    final sameResult = policy.shouldListen(1, 1);
    final blockedResult = policy.shouldListen(1, 0);
    final passingResult = policy.shouldListen(1, 2);

    // Then
    expect(sameResult, isFalse);
    expect(blockedResult, isFalse);
    expect(passingResult, isTrue);
  });

  test('or returns true when any listen policy returns true', () {
    // Given
    final policy =
        neverListen<int>().or(whenListen<int>((_, current) => current > 1));

    // When
    final blockedResult = policy.shouldListen(1, 1);
    final passingResult = policy.shouldListen(1, 2);

    // Then
    expect(blockedResult, isFalse);
    expect(passingResult, isTrue);
  });

  test('not negates the wrapped listen policy', () {
    // Given
    final policy = distinctListen<int>().not();

    // When
    final sameResult = policy.shouldListen(1, 1);
    final changedResult = policy.shouldListen(1, 2);

    // Then
    expect(sameResult, isTrue);
    expect(changedResult, isFalse);
  });

  test('onChangeListenBy uses custom equality for selected values', () {
    // Given
    final policy = onChangeListenBy<_CollectionState, List<int>>(
      (state) => state.items,
      equals: _listEquals,
    );
    const previous = _CollectionState([1, 2]);
    const sameSelected = _CollectionState([1, 2]);
    const changedSelected = _CollectionState([1, 3]);

    // When
    final sameResult = policy.shouldListen(previous, sameSelected);
    final changedResult = policy.shouldListen(previous, changedSelected);

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
