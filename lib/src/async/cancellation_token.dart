class CancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  Future<T?> run<T>(Future<T> Function() task) async {
    if (_isCancelled) return null;
    final result = await task();
    if (_isCancelled) return null;
    return result;
  }
}
