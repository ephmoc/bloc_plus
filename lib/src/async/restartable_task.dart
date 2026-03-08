import 'cancellation_token.dart';

/// Runs async work where starting a new task cancels the previous result.
class RestartableTask<T> {
  CancellationToken? _activeToken;
  int _generation = 0;
  bool _isDisposed = false;
  bool _isRunning = false;

  /// Whether the latest scheduled task is still running.
  bool get isRunning => _isRunning;

  /// Starts [task], cancelling any previous task result tracked by this
  /// instance.
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

  /// Cancels any in-flight task result and prevents future runs from
  /// completing.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _activeToken?.cancel();
    _generation++;
    _isRunning = false;
  }
}
