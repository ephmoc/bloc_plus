import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

abstract interface class EffectsSource<E> {
  Stream<E> get effects;
}

mixin HasEffects<S, E> on BlocBase<S> implements EffectsSource<E> {
  final StreamController<E> _effectsController =
      StreamController<E>.broadcast();

  @override
  Stream<E> get effects => _effectsController.stream;

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
