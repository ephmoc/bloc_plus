/// The outcome of a run of `RestartableTask.runOutcome` or
/// `RestartableTasksMixin.runLatestOutcome`: either the run completed with a
/// value, or it was cancelled (superseded, cancelled explicitly, disposed or
/// closed) and its result was discarded.
///
/// Unlike a `null` result, the outcome tells a cancelled run apart from a run
/// that completed with `null` or with a `void` value:
///
/// ```dart
/// if (outcome.isCompleted) use(outcome.value);
/// // or
/// if (outcome case TaskOutcome(isCompleted: true, :final value)) use(value);
/// ```
///
/// A failure is not an outcome: the failure of the latest run is rethrown by
/// the call that started it, so handle it with `try`/`catch`. A failure of a
/// cancelled run is dropped.
final class TaskOutcome<T> {
  /// The outcome of a run that completed with [value].
  const TaskOutcome.completed(T value)
      : _value = value,
        isCompleted = true;

  /// The outcome of a run that was cancelled before it completed.
  const TaskOutcome.cancelled()
      : _value = null,
        isCompleted = false;

  final T? _value;

  /// Whether the run completed; `false` when it was cancelled.
  final bool isCompleted;

  /// The value the run completed with.
  ///
  /// Throws a [StateError] when the run was cancelled; check [isCompleted]
  /// first. An object pattern reads its fields in order, so write
  /// `isCompleted: true` before `:final value` there.
  T get value {
    if (!isCompleted) {
      throw StateError('A cancelled TaskOutcome has no value.');
    }
    return _value as T;
  }

  /// Two outcomes are equal when both are cancelled, or both completed with
  /// equal values. The type argument is not compared.
  @override
  bool operator ==(Object other) =>
      other is TaskOutcome &&
      other.isCompleted == isCompleted &&
      other._value == _value;

  @override
  int get hashCode => Object.hash(isCompleted, _value);

  @override
  String toString() => isCompleted
      ? 'TaskOutcome.completed($_value)'
      : 'TaskOutcome.cancelled()';
}
