// Implements the deprecated SingleChildEffectListener so MultiEffectListener
// users can migrate one listener at a time, and reads the deprecated
// effectWhen; drop both in 1.0.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';

import 'effect_listener.dart';
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
/// Always write both type arguments. Without them [E] is not inferred, at
/// any language version: the `effect` of [onEffect] is `Object?` and the
/// `switch` loses its exhaustiveness check.
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
    extends SingleChildStatefulWidget implements SingleChildEffectListener {
  /// Creates an effect listener for the bloc type [B].
  const BlocEffectListener({
    required this.onEffect,
    super.key,
    this.bloc,
    @Deprecated(
      'Use an if or an if-case at the top of onEffect, which also promotes '
      'the effect type. Will be removed in 1.0.',
    )
    this.effectWhen,
    this.child,
  }) : super(child: child);

  /// The bloc to listen to.
  ///
  /// When omitted, the widget reads the bloc from the nearest provider and
  /// throws a `ProviderNotFoundException` if there is none.
  final B? bloc;

  /// Called for every effect, unless the deprecated [effectWhen] rejects it.
  ///
  /// `effect` has the type [E] only when the widget has both type arguments;
  /// without them it is `Object?`.
  final void Function(BuildContext context, E effect) onEffect;

  /// Optional predicate that decides whether [onEffect] should run.
  @Deprecated(
    'Use an if or an if-case at the top of onEffect, which also promotes '
    'the effect type. Will be removed in 1.0.',
  )
  final EffectCondition<E>? effectWhen;

  /// Optional subtree rendered by this listener.
  final Widget? child;

  @override
  SingleChildState<BlocEffectListener<B, E>> createState() =>
      _BlocEffectListenerState<B, E>();

  @Deprecated(
    'Pass child: to the constructor, or list the listener in '
    'MultiBlocListener, which supplies the child. Will be removed in 1.0.',
  )
  @override
  Widget withChild(Widget child) => BlocEffectListener<B, E>(
        key: key,
        bloc: bloc,
        effectWhen: effectWhen,
        onEffect: onEffect,
        child: child,
      );
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
      if (widget.effectWhen?.call(effect) ?? true) {
        widget.onEffect(context, effect);
      }
    });
  }
}
