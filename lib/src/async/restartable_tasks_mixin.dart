import 'dart:async';

import 'package:bloc/bloc.dart';

import 'cancellation_token.dart';
import 'restartable_task.dart';
import 'task_outcome.dart';

/// Tracks keyed restartable tasks for "latest request wins" workflows.
///
/// Cancellation is cooperative: starting a new run or closing the owner
/// releases the superseded caller at once and suppresses the stale result,
/// but does not interrupt the underlying `Future` work.
///
/// Inside `Bloc` event handlers, prefer the handler's `emit` with an event
/// transformer from `bloc_concurrency` such as `restartable()`; use this mixin
/// for Cubits and for work that is not tied to one event.
mixin RestartableTasksMixin<S> on BlocBase<S> {
  final Map<Object, RestartableTask<Object?>> _tasks = {};
  Future<void>? _closing;

  /// Returns `true` when the latest task for [key] is still running.
  bool isTaskRunning(Object key) => _tasks[key]?.isRunning ?? false;

  /// Runs [task] as the latest task for [key], invalidating older results for
  /// the same key.
  ///
  /// Completes with `null` as soon as a newer run for [key], [cancelLatest],
  /// [cancelAllLatest] or [close] supersedes this run, without waiting for
  /// [task], whose later success or failure is dropped. The failure of the
  /// latest run is rethrown.
  ///
  /// When `T` is nullable or `void`, `null` is ambiguous: use
  /// [runLatestOutcome].
  ///
  /// Keys are compared with `==`: a new `List` key never matches an earlier
  /// one, while a string or a record with the same content does.
  Future<T?> runLatest<T>(Object key, Future<T> Function() task) async {
    final outcome = await runLatestOutcome<T>(key, (_) => task());
    return outcome.isCompleted ? outcome.value : null;
  }

  /// Runs [task] as the latest task for [key] with a token that is cancelled
  /// when this run is superseded, and tells a discarded run apart from a
  /// `null` value.
  ///
  /// Completes with [TaskOutcome.completed] for the latest run, and with
  /// [TaskOutcome.cancelled] as soon as a newer run for [key], [cancelLatest],
  /// [cancelAllLatest] or [close] supersedes this run, without waiting for
  /// [task]. [task] does not start once [close] was called. The failure of the
  /// latest run is rethrown; a failure of a superseded run is dropped.
  ///
  /// The abandoned task keeps running: check `token.isCancelled` before any
  /// side effect, or pass `token.whenCancelled` to the I/O so it can abort.
  /// Because a superseded caller resumes at once, while the newer run is still
  /// in flight, a `finally` block that resets state shared with the newer run
  /// must check the outcome first.
  ///
  /// ```dart
  /// final outcome = await runLatestOutcome('search', (token) {
  ///   return repository.find(query, abortTrigger: token.whenCancelled);
  /// });
  /// if (outcome.isCompleted) {
  ///   emit(state.copyWith(isLoading: false, item: outcome.value));
  /// }
  /// ```
  ///
  /// Keys are compared as in [runLatest].
  Future<TaskOutcome<T>> runLatestOutcome<T>(
    Object key,
    Future<T> Function(CancellationToken token) task,
  ) async {
    if (_closing != null || isClosed) return TaskOutcome<T>.cancelled();

    final restartableTask =
        _tasks.putIfAbsent(key, () => RestartableTask<Object?>());
    try {
      final outcome = await restartableTask.runOutcome(task);
      if (!outcome.isCompleted || _closing != null || isClosed) {
        return TaskOutcome<T>.cancelled();
      }
      return TaskOutcome<T>.completed(outcome.value as T);
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
