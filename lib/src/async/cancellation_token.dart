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
///
/// It is a `final` class, so it cannot be extended, implemented or mocked. In
/// tests, use a real token and call [cancel].
final class CancellationToken {
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
  ///
  /// Listeners attached to this future stay attached until the token is
  /// cancelled, so give each operation its own token (as `runOutcome` and
  /// `runLatestOutcome` do) rather than passing one long-lived token to many
  /// requests.
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
  /// which keeps running; a later failure of [task] is dropped. A failure is
  /// rethrown unless the token is cancelled before the caller resumes. Handle
  /// `null` first, with an early return: an `else` or a `default` branch would
  /// take a cancelled run for a failed one.
  ///
  /// `T` cannot be `void` or nullable (`T extends Object`), because `null`
  /// would be ambiguous. Await such work plainly and check [isCancelled]
  /// before anything else:
  ///
  /// ```dart
  /// final item = await find(query); // may be null: not found
  /// if (token.isCancelled) return;
  /// show(item);
  /// ```
  ///
  /// Wrap the result in a record only to keep what `run` adds: [task] does
  /// not start on a cancelled token, its later failure is dropped, and the
  /// caller is released at [cancel] instead of when [task] ends:
  ///
  /// ```dart
  /// final result = await token.run(() async => (item: await find(query)));
  /// if (result == null) return; // cancelled
  /// show(result.item); // may be null: not found
  /// ```
  Future<T?> run<T extends Object>(Future<T> Function() task) async {
    final TaskOutcome<T> outcome;
    try {
      outcome = await runUntilCancelled(this, task);
    } catch (_) {
      // A cancel after the failure, before the caller resumes, drops it as it
      // drops a value.
      if (isCancelled) return null;
      rethrow;
    }
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
