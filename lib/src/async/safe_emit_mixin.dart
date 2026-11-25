import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show protected, visibleForTesting;
import 'package:meta/meta.dart' show useResult;

/// Adds guarded emit helpers that no-op after a cubit has been closed.
///
/// It applies to Cubits only. In a `Bloc`, use the handler's `emit`, which
/// also calls `onTransition` and does nothing in a handler that a transformer
/// such as `restartable()` has cancelled. Check `isClosed` first in the
/// handler and again after every `await`: the handler's `emit` still delivers
/// for a while after `close()` is called, also in a handler that starts
/// afterwards for an event queued before it. With `emit.onEach`, check it in
/// `onData` and `onError` too. `emit.forEach` emits every state its callbacks
/// return, so a check there cannot stop the emit: where a value must not
/// arrive after `close()`, use `emit.onEach`.
mixin SafeEmitMixin<S> on Cubit<S> {
  /// Emits [state] only when the cubit is still open.
  ///
  /// Like `emit`, it is meant to be called from inside the cubit, and from
  /// tests.
  @protected
  @visibleForTesting
  void safeEmit(S state) {
    if (isClosed) return;
    emit(state);
  }

  /// Runs [operation] and returns its result only if the cubit is still open
  /// after completion.
  ///
  /// Like `emit`, it is meant to be called from inside the cubit, and from
  /// tests.
  ///
  /// [operation] does not start on a closed cubit. A failure of [operation]
  /// is rethrown while the cubit is open and dropped like its result once the
  /// cubit is closed, so the call then completes with `null`. A synchronous
  /// throw counts as arriving after the current turn, so a `close()` in the
  /// same turn drops it.
  /// Handle `null` first, with an early return: an `else` or a `default`
  /// branch would take a closed cubit for a failed result. The analyzer
  /// reports a result that is awaited and dropped (`@useResult`), because the
  /// code after it would run on a closed cubit as well.
  ///
  /// `T` cannot be `void` or nullable (`T extends Object`), because `null`
  /// would be ambiguous. Await such work plainly and emit with [safeEmit], or
  /// check `isClosed` before anything else:
  ///
  /// ```dart
  /// final item = await find(query); // may be null: not found
  /// safeEmit(state.copyWith(item: item));
  /// ```
  ///
  /// Wrap the result in a record only to keep what `guarded` adds: the
  /// operation does not start on a closed cubit, and its failure after close
  /// is dropped:
  ///
  /// ```dart
  /// final result = await guarded(() async => (item: await find(query)));
  /// if (result == null) return; // closed
  /// emit(state.copyWith(item: result.item)); // may be null: not found
  /// ```
  @protected
  @visibleForTesting
  @useResult
  Future<T?> guarded<T extends Object>(Future<T> Function() operation) async {
    if (isClosed) return null;
    try {
      // A synchronous throw then reaches the catch after this turn, like the
      // failure of an async operation, so a close() in the same turn drops it.
      final result = await Future.sync(operation);
      return isClosed ? null : result;
    } catch (_) {
      if (isClosed) return null;
      rethrow;
    }
  }
}
