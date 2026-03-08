import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Exposes a stream of one-off effects emitted outside the main bloc state.
abstract interface class EffectsSource<E> {
  /// Stream of transient effects.
  Stream<E> get effects;
}

/// Adds a broadcast effect stream to a bloc and closes it with the bloc.
mixin HasEffects<S, E> on BlocBase<S> implements EffectsSource<E> {
  final StreamController<E> _effectsController =
      StreamController<E>.broadcast();

  @override

  /// Stream of emitted effects.
  Stream<E> get effects => _effectsController.stream;

  /// Emits a one-off [effect] to current listeners.
  void emitEffect(E effect) {
    if (_effectsController.isClosed) return;
    _effectsController.add(effect);
  }

  @override
  Future<void> close() async {
    await _effectsController.close();
    return super.close();
  }
}
