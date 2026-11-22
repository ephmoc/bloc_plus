import 'dart:async';

import 'package:bloc/bloc.dart';

import 'restartable_task.dart';

/// Tracks keyed restartable tasks for "latest request wins" workflows.
///
/// Cancellation is cooperative: starting a new run or closing the owner
/// suppresses stale results but does not interrupt underlying `Future` work.
mixin RestartableTasksMixin<S> on BlocBase<S> {
  final Map<Object, RestartableTask<Object?>> _tasks = {};
  Future<void>? _closing;

  /// Returns `true` when the latest task for [key] is still running.
  bool isTaskRunning(Object key) => _tasks[key]?.isRunning ?? false;

  /// Runs [task] as the latest task for [key], invalidating older results for
  /// the same key.
  ///
  /// Completes with `null` when a newer run for [key], [cancelLatest],
  /// [cancelAllLatest] or [close] supersedes this run, whether [task] succeeds
  /// or fails. The failure of the latest run is rethrown.
  ///
  /// Keys are compared with `==`: a new `List` key never matches an earlier
  /// one, while a string or a record with the same content does.
  Future<T?> runLatest<T>(Object key, Future<T> Function() task) async {
    if (_closing != null || isClosed) return null;

    final restartableTask =
        _tasks.putIfAbsent(key, () => RestartableTask<Object?>());
    try {
      final result = await restartableTask.run(() async => await task());
      if (_closing != null || isClosed) return null;
      return result as T?;
    } finally {
      // Also runs when the task throws, so failed keys do not pile up.
      if (identical(_tasks[key], restartableTask) &&
          !restartableTask.isRunning) {
        _tasks.remove(key);
      }
    }
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

  /// Cancels all tracked tasks and closes the bloc.
  ///
  /// A repeated call returns the future of the first call, so every caller
  /// waits for the same close.
  @override
  Future<void> close() {
    final pending = _closing;
    if (pending != null) return pending;
    if (isClosed) return Future<void>.value();
    // Assigned before super.close(), which calls BlocObserver.onClose
    // synchronously, so a close() from there also gets this future.
    final closing = Completer<void>();
    _closing = closing.future;
    cancelAllLatest();
    closing.complete(super.close());
    return closing.future;
  }
}
