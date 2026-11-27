import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';

import 'has_effects.dart';

/// Listens to the one-off effects of a bloc that implements [EffectsSource]
/// of [E], usually through [HasEffects].
///
/// The bound `B extends EffectsSource<E>` makes a wrong effect type, or a bloc
/// without effects, a compile-time error. The recommended pattern is a
/// `sealed` effect hierarchy handled with an exhaustive `switch`:
///
/// ```dart
/// BlocEffectListener<UiCubit, UiEffect>(
///   onEffect: (context, effect) {
///     switch (effect) {
///       case ShowToast(:final message):
///         showToast(context, message);
///       case GoHome():
///         goHome(context);
///     }
///   },
///   child: const UiView(),
/// )
/// ```
///
/// Always write both type arguments: without them the `effect` parameter of
/// [onEffect] is `Object?` at every language version, so a `switch` over it
/// is not checked for exhaustiveness.
///
/// To react to a single subtype, listen to the supertype and match it with an
/// if-case pattern at the top of [onEffect], which promotes the effect type:
///
/// ```dart
/// BlocEffectListener<UiCubit, UiEffect>(
///   onEffect: (context, effect) {
///     if (effect case ShowToast(:final message)) showToast(context, message);
///   },
/// )
/// ```
///
/// Composes inside `MultiBlocListener` together with `BlocListener` and
/// `BlocListenerWithBloc`. `MultiBlocListener` asserts a non-empty list and
/// ignores a [child] passed to a listener inside it.
class BlocEffectListener<B extends EffectsSource<E>, E>
    extends SingleChildStatefulWidget {
  /// Creates an effect listener for the bloc type [B].
  const BlocEffectListener({
    required this.onEffect,
    super.key,
    this.bloc,
    this.child,
  }) : super(child: child);

  /// The bloc to listen to.
  ///
  /// When omitted, the widget reads the bloc from the nearest provider and
  /// throws a `ProviderNotFoundException` if there is none.
  final B? bloc;

  /// Called for every effect.
  ///
  /// `effect` has the type [E] only when the widget has both type arguments;
  /// without them it is `Object?`.
  final void Function(BuildContext context, E effect) onEffect;

  /// Optional subtree rendered by this listener.
  ///
  /// Without one, and outside a multi widget such as `MultiBlocListener`,
  /// the listener renders `SizedBox.shrink()`.
  final Widget? child;

  @override
  SingleChildState<BlocEffectListener<B, E>> createState() =>
      _BlocEffectListenerState<B, E>();
}

class _BlocEffectListenerState<B extends EffectsSource<E>, E>
    extends SingleChildState<BlocEffectListener<B, E>> {
  StreamSubscription<E>? _subscription;
  late B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant BlocEffectListener<B, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resubscribeIfChanged();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resubscribeIfChanged();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    // Rebuilds, and so resubscribes, when a different instance is provided.
    if (widget.bloc == null) {
      context.select<B, bool>((bloc) => identical(_bloc, bloc));
    }
    return child ?? const SizedBox.shrink();
  }

  void _resubscribeIfChanged() {
    final bloc = widget.bloc ?? context.read<B>();
    if (identical(_bloc, bloc)) return;
    _subscription?.cancel();
    _bloc = bloc;
    _subscribe();
  }

  void _subscribe() {
    _subscription = _bloc.effects.listen((effect) {
      if (!mounted) return;
      widget.onEffect(context, effect);
    });
  }
}
