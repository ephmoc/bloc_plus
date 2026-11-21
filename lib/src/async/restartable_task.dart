import 'cancellation_token.dart';

/// Runs async work where starting a new task cancels the previous result.
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
  /// Completes with `null` when a newer [run], [cancel] or [dispose] supersedes
  /// this run, whether [task] succeeds or fails. The failure of the latest run
  /// is rethrown.
  Future<T?> run(Future<T> Function() task) async {
    if (_isDisposed) return null;

    _activeToken?.cancel();

    final token = CancellationToken();
    _activeToken = token;
    final generation = ++_generation;
    _isRunning = true;

    try {
      final result = await token.run(task);
      if (_isDisposed) return null;
      if (generation != _generation) return null;
      return result;
    } finally {
      if (generation == _generation) {
        _isRunning = false;
      }
    }
  }

  /// Cancels the currently tracked task result, if any.
  void cancel() {
    _activeToken?.cancel();
    _generation++;
    _isRunning = false;
  }

  /// Cancels any in-flight task result. Later [run] calls do not start their
  /// task and complete with `null`.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _activeToken?.cancel();
    _generation++;
    _isRunning = false;
  }
}
