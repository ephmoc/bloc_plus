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

  /// Closes the bloc, then waits until every effect subscriber has received
  /// the effects emitted before [close] and the done event.
  ///
  /// The bloc is closed right away even if an effect subscriber is paused;
  /// only the returned future waits for that subscriber to resume.
  @override
  Future<void> close() async {
    final effectsDone = _effectsController.close();
    await super.close();
    await effectsDone;
  }
}
