import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, protected, visibleForTesting;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether [HasEffects.emitEffect] prints a warning in debug builds for an
/// effect that nothing listens to.
///
/// Effects are not replayed, so such an effect is lost: for example one
/// emitted from the bloc's constructor, or before the widget that listens to
/// it is mounted. Off by default, because tests of a bloc often emit effects
/// that they do not listen to. Turn it on while debugging, for example at the
/// start of `main()`. Release builds never print it.
bool debugPrintUnheardEffects = false;

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
  ///
  /// An effect that nothing listens to is lost; set
  /// [debugPrintUnheardEffects] to get a warning about it in debug builds.
  ///
  /// Like `emit`, call it only from inside the bloc (or from a
  /// `mixin X on HasEffects<S, E>` that shares helpers between blocs).
  /// Calls from elsewhere, including extensions on the bloc and other
  /// libraries, get analyzer warnings; tests may call it.
  @protected
  @visibleForTesting
  void emitEffect(E effect) {
    if (_effectsController.isClosed) return;
    assert(() {
      if (debugPrintUnheardEffects && !_effectsController.hasListener) {
        debugPrint(
          '$runtimeType emitted the effect $effect, but nothing listens to '
          'its effects, so the effect is lost: effects are not replayed.',
        );
      }
      return true;
    }());
    _effectsController.add(effect);
  }

  /// Closes the bloc, then waits until every effect subscriber has received
  /// the effects emitted before [close] and the done event.
  ///
  /// Like the bloc's own last states, effects emitted right before [close]
  /// reach subscribers after the bloc is closed. A cubit method that a
  /// subscriber calls in response should emit with `SafeEmitMixin.safeEmit`,
  /// and a subscriber that adds an event to a `Bloc` should check `isClosed`
  /// first, because `add` throws after [close]. The bloc is closed right away
  /// even if an effect subscriber is paused; only the returned future waits
  /// for that subscriber to resume.
  @override
  Future<void> close() async {
    final effectsDone = _effectsController.close();
    await super.close();
    await effectsDone;
  }
}
