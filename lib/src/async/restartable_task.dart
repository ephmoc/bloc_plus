import 'cancellation_token.dart';
import 'task_outcome.dart';

/// Runs async work where starting a new task cancels the previous result.
///
/// Cancellation is cooperative: a superseded run releases its caller at once,
/// but its task keeps running. Use [runOutcome] to get the run's
/// [CancellationToken] and check it before any side effect.
class RestartableTask<T> {
  /// Creates a task runner that keeps only the latest task result.
  RestartableTask();

  CancellationToken? _activeToken;
  int _generation = 0;
  bool _isDisposed = false;
  bool _isRunning = false;

  /// Whether the latest scheduled task is still running.
  bool get isRunning => _isRunning;

  /// Starts [task], cancelling any previous task result tracked by this
  /// instance.
  ///
  /// Completes with `null` as soon as a newer run, [cancel] or [dispose]
  /// supersedes this run, without waiting for [task], whose later success or
  /// failure is dropped. The failure of the latest run is rethrown.
  ///
  /// When `T` is nullable or `void`, `null` is ambiguous: use [runOutcome].
  Future<T?> run(Future<T> Function() task) async {
    final outcome = await runOutcome((_) => task());
    return outcome.isCompleted ? outcome.value : null;
  }

  /// Starts [task] with a token that is cancelled when a newer run, [cancel]
  /// or [dispose] supersedes this run, and tells a discarded run apart from a
  /// `null` value.
  ///
  /// Completes with [TaskOutcome.completed] for the latest run, and with
  /// [TaskOutcome.cancelled] as soon as the run is superseded, without waiting
  /// for [task]. [task] does not start after [dispose]. The failure of the
  /// latest run is rethrown; a failure of a superseded run is dropped.
  ///
  /// The abandoned task keeps running: check `token.isCancelled` before any
  /// side effect, or pass `token.whenCancelled` to the I/O so it can abort.
  /// Because a superseded caller resumes at once, while the newer run is still
  /// in flight, a `finally` block that resets state shared with the newer run
  /// must check the outcome first.
  Future<TaskOutcome<T>> runOutcome(
    Future<T> Function(CancellationToken token) task,
  ) async {
    if (_isDisposed) return TaskOutcome<T>.cancelled();

    _activeToken?.cancel();

    final token = CancellationToken();
    _activeToken = token;
    final generation = ++_generation;
    _isRunning = true;

    try {
      final outcome = await runUntilCancelled(token, () => task(token));
      return token.isCancelled ? TaskOutcome<T>.cancelled() : outcome;
    } finally {
      if (generation == _generation) {
        _isRunning = false;
      }
    }
  }

  /// Cancels the currently tracked task result, if any, and releases its
  /// caller.
  void cancel() {
    _activeToken?.cancel();
    _generation++;
    _isRunning = false;
  }

  /// Cancels any in-flight task result and releases its caller. Later runs do
  /// not start their task and complete with `null` or
  /// [TaskOutcome.cancelled].
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _activeToken?.cancel();
    _generation++;
    _isRunning = false;
  }
}
