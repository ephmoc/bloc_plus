/// Tracks cancellation for async work that may become stale.
class CancellationToken {
  /// Creates a token that can invalidate stale async work.
  CancellationToken();

  bool _isCancelled = false;

  /// Whether this token has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Marks this token as cancelled.
  void cancel() {
    _isCancelled = true;
  }

  /// Runs [task] and returns its result unless the token is cancelled before or
  /// after completion.
  ///
  /// [task] does not start on a cancelled token. A failure of [task] after the
  /// token was cancelled is dropped like its result, so the call completes
  /// with `null`; a failure of a task that was not cancelled is rethrown.
  Future<T?> run<T>(Future<T> Function() task) async {
    if (_isCancelled) return null;
    try {
      final result = await task();
      return _isCancelled ? null : result;
    } catch (_) {
      if (_isCancelled) return null;
      rethrow;
    }
  }
}
