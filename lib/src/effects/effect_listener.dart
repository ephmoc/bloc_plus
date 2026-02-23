import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'has_effects.dart';

class EffectListener<B extends BlocBase<S>, S, E> extends StatefulWidget {
  const EffectListener({
    required this.onEffect,
    super.key,
    this.bloc,
    this.child,
  });

  final B? bloc;
  final void Function(BuildContext context, E effect) onEffect;
  final Widget? child;

  @override
  State<EffectListener<B, S, E>> createState() =>
      _EffectListenerState<B, S, E>();
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
    final oldBloc = oldWidget.bloc ?? context.read<B>();
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
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
      widget.onEffect(context, effect);
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
}
