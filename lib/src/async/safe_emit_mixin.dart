import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show protected, visibleForTesting;

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
  /// after the cubit was closed is dropped like its result, so the call
  /// completes with `null`; a failure while the cubit is open is rethrown.
  /// Handle `null` first, with an early return: an `else` or a `default`
  /// branch would take a closed cubit for a failed result.
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
  Future<T?> guarded<T extends Object>(Future<T> Function() operation) async {
    if (isClosed) return null;
    try {
      final result = await operation();
      return isClosed ? null : result;
    } catch (_) {
      if (isClosed) return null;
      rethrow;
    }
  }
}
