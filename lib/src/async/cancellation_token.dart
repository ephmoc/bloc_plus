/// Tracks cancellation for async work that may become stale.
class CancellationToken {
  bool _isCancelled = false;

  /// Whether this token has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Marks this token as cancelled.
  void cancel() {
    _isCancelled = true;
  }

  /// Runs [task] and returns its result unless the token is cancelled before or
  /// after completion.
  Future<T?> run<T>(Future<T> Function() task) async {
    if (_isCancelled) return null;
    final result = await task();
    if (_isCancelled) return null;
    return result;
  }
}
