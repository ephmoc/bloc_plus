import 'dart:async';

import 'task_outcome.dart';

/// Tracks cancellation for async work that may become stale.
///
/// Cancellation is cooperative: [cancel] releases the callers waiting in [run]
/// but does not stop the work itself. The work keeps running, so check
/// [isCancelled] before any side effect, or pass [whenCancelled] to the I/O so
/// it can abort.
///
/// The `cancellation_token` package also exports a `CancellationToken`; when
/// both are imported, add `hide CancellationToken` to one of the imports or
/// use a prefix.
class CancellationToken {
  /// Creates a token that can invalidate stale async work.
  CancellationToken();

  final Completer<void> _cancelled = Completer<void>();

  // Releases the callers of runs that are still waiting. Each run removes its
  // own entry when it ends, so a long-lived token does not accumulate them.
  final Set<void Function()> _onCancel = <void Function()>{};

  /// Whether this token has been cancelled.
  bool get isCancelled => _cancelled.isCompleted;

  /// Completes when [cancel] is first called; never completes otherwise.
  ///
  /// Pass it to the underlying work to abort it, for example as the
  /// `abortTrigger` of a `package:http` request, or call `cancel` on a dio
  /// `CancelToken` from it.
  Future<void> get whenCancelled => _cancelled.future;

  /// Marks this token as cancelled. Calls after the first one do nothing.
  void cancel() {
    if (_cancelled.isCompleted) return;
    _cancelled.complete();
    final callbacks = List<void Function()>.of(_onCancel);
    _onCancel.clear();
    for (final callback in callbacks) {
      callback();
    }
  }

  /// Runs [task] and returns its result unless the token is cancelled before or
  /// after completion.
  ///
  /// [task] does not start on a cancelled token. The call completes with
  /// `null` as soon as the token is cancelled, without waiting for [task],
  /// which keeps running; a later failure of [task] is dropped. A failure of a
  /// task that was not cancelled is rethrown.
  ///
  /// When `T` is nullable or `void`, `null` is ambiguous: check [isCancelled]
  /// after the call, or wrap the result in a record so that `null` only means
  /// cancelled:
  ///
  /// ```dart
  /// final result = await token.run(() async => (item: await find(query)));
  /// if (result == null) return; // cancelled
  /// show(result.item); // may be null: not found
  /// ```
  Future<T?> run<T>(Future<T> Function() task) async {
    final outcome = await runUntilCancelled(this, task);
    return outcome.isCompleted && !isCancelled ? outcome.value : null;
  }
}

/// Runs [task] and completes with [TaskOutcome.cancelled] as soon as [token]
/// is cancelled, without waiting for [task]. Not exported.
///
/// [task] does not start on a cancelled token. A failure of [task] after the
/// token was cancelled is dropped; a failure of a task that was not cancelled
/// is rethrown.
Future<TaskOutcome<T>> runUntilCancelled<T>(
  CancellationToken token,
  Future<T> Function() task,
) {
  if (token.isCancelled) return Future.value(TaskOutcome<T>.cancelled());

  final outcome = Completer<TaskOutcome<T>>();
  void release() {
    if (!outcome.isCompleted) outcome.complete(TaskOutcome<T>.cancelled());
  }

  token._onCancel.add(release);
  Future<T>.sync(task).then(
    (value) {
      token._onCancel.remove(release);
      if (token.isCancelled) {
        release();
      } else if (!outcome.isCompleted) {
        outcome.complete(TaskOutcome<T>.completed(value));
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      token._onCancel.remove(release);
      if (token.isCancelled) {
        release();
      } else if (!outcome.isCompleted) {
        outcome.completeError(error, stackTrace);
      }
    },
  );
  return outcome.future;
}
