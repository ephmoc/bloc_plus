import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'has_effects.dart';

/// Signature for deciding whether an [effect] should trigger [EffectListener].
typedef EffectCondition<E> = bool Function(E effect);

/// Contract for effect listener widgets that can wrap a child subtree.
abstract interface class SingleChildEffectListener {
  /// Returns a copy of this listener that wraps [child].
  Widget withChild(Widget child);
}

/// Listens to one-off effects emitted by blocs implementing [EffectsSource].
class EffectListener<B extends BlocBase<S>, S, E> extends StatefulWidget
    implements SingleChildEffectListener {
  /// Creates an effect listener for the given bloc type.
  const EffectListener({
    required this.onEffect,
    super.key,
    this.bloc,
    this.effectWhen,
    this.child,
  });

  /// The bloc to listen to.
  ///
  /// When omitted, the widget reads the bloc from the nearest provider.
  final B? bloc;

  /// Called whenever the bloc emits a new effect.
  final void Function(BuildContext context, E effect) onEffect;

  /// Optional predicate that decides whether [onEffect] should run.
  final EffectCondition<E>? effectWhen;

  /// Optional subtree rendered by this listener.
  final Widget? child;

  @override
  State<EffectListener<B, S, E>> createState() =>
      _EffectListenerState<B, S, E>();

  @override
  Widget withChild(Widget child) {
    return EffectListener<B, S, E>(
      key: key,
      bloc: bloc,
      effectWhen: effectWhen,
      onEffect: onEffect,
      child: child,
    );
  }
}

class _EffectListenerState<B extends BlocBase<S>, S, E>
    extends State<EffectListener<B, S, E>> {
  StreamSubscription<E>? _subscription;
  late B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant EffectListener<B, S, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentBloc = widget.bloc ?? context.read<B>();
    if (_bloc != currentBloc) {
      _unsubscribe();
      _bloc = currentBloc;
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<B>();
    if (_bloc != bloc) {
      _unsubscribe();
      _bloc = bloc;
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bloc == null) {
      context.select<B, bool>((bloc) => identical(_bloc, bloc));
    }
    return widget.child ?? const SizedBox.shrink();
  }

  void _subscribe() {
    final effectsOwner = _bloc;
    if (effectsOwner is! EffectsSource<E>) {
      throw StateError(
        'EffectListener requires bloc to implement EffectsSource<$E>.',
      );
    }
    final effectsSource = effectsOwner as EffectsSource<E>;
    _subscription = effectsSource.effects.listen((effect) {
      if (!mounted) return;
      final shouldHandleEffect = widget.effectWhen;
      if (shouldHandleEffect != null && !shouldHandleEffect(effect)) {
        return;
      }
      widget.onEffect(context, effect);
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
}
