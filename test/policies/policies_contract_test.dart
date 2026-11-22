// Tests of the deprecated family until its removal in 1.0.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class _Point {
  // Deliberately not const: equal instances must not be identical.
  _Point(this.x);

  final int x;

  @override
  bool operator ==(Object other) => other is _Point && other.x == x;

  @override
  int get hashCode => x.hashCode;
}

class _State {
  _State(this.point);

  final _Point point;
}

RebuildPolicy<int> _rebuild(bool value) => value ? always<int>() : never<int>();

ListenPolicy<int> _listen(bool value) =>
    value ? alwaysListen<int>() : neverListen<int>();

void main() {
  test('onChange compares selected values with ==, not identity', () {
    // Given
    final policy = onChange<_State, _Point>((state) => state.point);

    // When
    final equalResult =
        policy.shouldRebuild(_State(_Point(1)), _State(_Point(1)));
    final changedResult =
        policy.shouldRebuild(_State(_Point(1)), _State(_Point(2)));

    // Then
    expect(equalResult, isFalse);
    expect(changedResult, isTrue);
  });

  test('onChangeListen compares selected values with ==, not identity', () {
    // Given
    final policy = onChangeListen<_State, _Point>((state) => state.point);

    // When
    final equalResult =
        policy.shouldListen(_State(_Point(1)), _State(_Point(1)));
    final changedResult =
        policy.shouldListen(_State(_Point(1)), _State(_Point(2)));

    // Then
    expect(equalResult, isFalse);
    expect(changedResult, isTrue);
  });

  test('and / or follow the full truth table for rebuild policies', () {
    // Given
    const inputs = [(true, true), (true, false), (false, true), (false, false)];

    // When
    final andResults = [
      for (final (left, right) in inputs)
        _rebuild(left).and(_rebuild(right)).shouldRebuild(0, 1),
    ];
    final orResults = [
      for (final (left, right) in inputs)
        _rebuild(left).or(_rebuild(right)).shouldRebuild(0, 1),
    ];

    // Then
    expect(andResults, [true, false, false, false]);
    expect(orResults, [true, true, true, false]);
  });

  test('and / or follow the full truth table for listen policies', () {
    // Given
    const inputs = [(true, true), (true, false), (false, true), (false, false)];

    // When
    final andResults = [
      for (final (left, right) in inputs)
        _listen(left).and(_listen(right)).shouldListen(0, 1),
    ];
    final orResults = [
      for (final (left, right) in inputs)
        _listen(left).or(_listen(right)).shouldListen(0, 1),
    ];

    // Then
    expect(andResults, [true, false, false, false]);
    expect(orResults, [true, true, true, false]);
  });

  test('onChangeBy hands (previous, current) to equals in that order', () {
    // Given
    final calls = <(int, int)>[];
    final policy = onChangeBy<int, int>(
      (state) => state,
      equals: (previous, current) {
        calls.add((previous, current));
        return true;
      },
    );

    // When
    policy.shouldRebuild(1, 2);

    // Then
    expect(calls, [(1, 2)]);
  });
}
