import 'package:bloc/bloc.dart';

mixin SafeEmitMixin<S> on BlocBase<S> {
  void safeEmit(S state) {
    if (isClosed) return;
    emit(state);
  }

  Future<T?> guarded<T>(Future<T> Function() operation) async {
    final result = await operation();
    if (isClosed) return null;
    return result;
  }
}
