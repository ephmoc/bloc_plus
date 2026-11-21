import 'package:bloc/bloc.dart';

/// Adds guarded emit helpers that no-op after a bloc has been closed.
mixin SafeEmitMixin<S> on BlocBase<S> {
  /// Emits [state] only when the bloc is still open.
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
  Future<T?> guarded<T>(Future<T> Function() operation) async {
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
