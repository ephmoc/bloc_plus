import 'cancellation_token.dart';

class RestartableTask<T> {
  CancellationToken? _activeToken;
  int _generation = 0;
  bool _isDisposed = false;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

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

  void cancel() {
    _activeToken?.cancel();
    _generation++;
    _isRunning = false;
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _activeToken?.cancel();
    _generation++;
    _isRunning = false;
  }
}
