import 'package:bloc/bloc.dart';

import 'restartable_task.dart';

/// Tracks keyed restartable tasks for "latest request wins" workflows.
///
/// Cancellation is cooperative: starting a new run or closing the owner
/// suppresses stale results but does not interrupt underlying `Future` work.
mixin RestartableTasksMixin<S> on BlocBase<S> {
  final Map<Object, RestartableTask<Object?>> _tasks = {};
  bool _isClosing = false;

  /// Returns `true` when the latest task for [key] is still running.
  bool isTaskRunning(Object key) => _tasks[key]?.isRunning ?? false;

  /// Runs [task] as the latest task for [key], invalidating older results for
  /// the same key.
  Future<T?> runLatest<T>(Object key, Future<T> Function() task) async {
    if (_isClosing || isClosed) return null;

    final restartableTask =
        _tasks.putIfAbsent(key, () => RestartableTask<Object?>());
    final result = await restartableTask.run(() async => await task());

    if (identical(_tasks[key], restartableTask) && !restartableTask.isRunning) {
      _tasks.remove(key);
    }

    if (_isClosing || isClosed) return null;
    return result as T?;
  }

  /// Cancels the latest tracked result for [key], if any.
  void cancelLatest(Object key) {
    final task = _tasks.remove(key);
    task?.cancel();
  }

  /// Cancels and clears all tracked task results.
  void cancelAllLatest() {
    for (final task in _tasks.values) {
      task.cancel();
    }
    _tasks.clear();
  }

  @override
  Future<void> close() async {
    if (_isClosing || isClosed) return;
    _isClosing = true;
    cancelAllLatest();
    await super.close();
  }
}
