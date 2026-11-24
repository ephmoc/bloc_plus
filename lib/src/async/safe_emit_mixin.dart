import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show protected, visibleForTesting;

/// Adds guarded emit helpers that no-op after a bloc has been closed.
mixin SafeEmitMixin<S> on BlocBase<S> {
  /// Emits [state] only when the bloc is still open.
  ///
  /// Like `emit`, it is meant to be called from inside the bloc, and from
  /// tests.
  @protected
  @visibleForTesting
  void safeEmit(S state) {
    if (isClosed) return;
    emit(state);
  }

  /// Runs [operation] and returns its result only if the bloc is still open
  /// after completion.
  ///
  /// [operation] does not start on a closed bloc. A failure of [operation]
  /// after the bloc was closed is dropped like its result, so the call
  /// completes with `null`; a failure while the bloc is open is rethrown.
  /// Handle `null` first, with an early return: an `else` or a `default`
  /// branch would take a closed bloc for a failed result.
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
  /// operation does not start on a closed bloc, and its failure after close
  /// is dropped:
  ///
  /// ```dart
  /// final result = await guarded(() async => (item: await find(query)));
  /// if (result == null) return; // closed
  /// emit(state.copyWith(item: result.item)); // may be null: not found
  /// ```
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
