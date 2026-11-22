import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

// Non-constant instances, so equality is not mere identity.
TaskOutcome<T> _completed<T>(T value) => TaskOutcome<T>.completed(value);
TaskOutcome<T> _cancelled<T>() => TaskOutcome<T>.cancelled();

void main() {
  test('completed carries its value, including null', () {
    // Given
    const outcome = TaskOutcome<String?>.completed(null);

    // When
    final isCompleted = outcome.isCompleted;
    final value = outcome.value;

    // Then
    expect(isCompleted, isTrue);
    expect(value, isNull);
  });

  test('value throws a StateError when the outcome is cancelled', () {
    // Given
    const outcome = TaskOutcome<int>.cancelled();

    // When
    int readValue() => outcome.value;

    // Then
    expect(outcome.isCompleted, isFalse);
    expect(readValue, throwsStateError);
  });

  test('outcomes with the same case and value are equal', () {
    // Given
    const completed = TaskOutcome<int>.completed(2);
    final sameCompleted = _completed(1 + 1);
    const cancelled = TaskOutcome<int>.cancelled();
    final sameCancelled = _cancelled<int>();

    // When
    final completedEqual = completed == sameCompleted;
    final cancelledEqual = cancelled == sameCancelled;

    // Then
    expect(completedEqual, isTrue);
    expect(completed.hashCode, sameCompleted.hashCode);
    expect(cancelledEqual, isTrue);
    expect(cancelled.hashCode, sameCancelled.hashCode);
  });

  test('outcomes with a different case or value are not equal', () {
    // Given
    const completedNull = TaskOutcome<int?>.completed(null);
    const cancelled = TaskOutcome<int?>.cancelled();
    const completedOne = TaskOutcome<int?>.completed(1);
    const completedTwo = TaskOutcome<int?>.completed(2);

    // When
    final nullEqualsCancelled = completedNull == cancelled;
    final oneEqualsTwo = completedOne == completedTwo;

    // Then
    expect(nullEqualsCancelled, isFalse);
    expect(oneEqualsTwo, isFalse);
  });

  test('toString names the case and the value', () {
    // Given
    const completed = TaskOutcome<int>.completed(3);
    const cancelled = TaskOutcome<int>.cancelled();

    // When
    final texts = [completed.toString(), cancelled.toString()];

    // Then
    expect(texts, ['TaskOutcome.completed(3)', 'TaskOutcome.cancelled()']);
  });

  test('an object pattern matches only a completed outcome', () {
    // Given
    const outcomes = [
      TaskOutcome<String?>.completed(null),
      TaskOutcome<String?>.cancelled(),
      TaskOutcome<String?>.completed('x'),
    ];

    // When
    final matched = <String?>[
      for (final outcome in outcomes)
        if (outcome case TaskOutcome(isCompleted: true, :final value)) value,
    ];

    // Then
    expect(matched, [null, 'x']);
  });
}
