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
  Future<T?> guarded<T>(Future<T> Function() operation) async {
    final result = await operation();
    if (isClosed) return null;
    return result;
  }
}
