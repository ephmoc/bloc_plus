import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../effects/bloc_effect_listener.dart';
import '../effects/effect_listener.dart';
import '../effects/has_effects.dart';
import 'bloc_builder_with_bloc.dart';
import 'bloc_consumer_with_bloc.dart';
import 'bloc_listener_with_bloc.dart';

/// Signature for handling one-off effects with access to the resolved bloc.
typedef BlocEffectListenerWithBloc<B extends StateStreamable<S>, S, E> = void
    Function(BuildContext context, B bloc, E effect);

/// Combines state building, optional state listening and one-off effect
/// handling for a bloc that mixes in [HasEffects].
///
/// The bloc is resolved once per build, so states, effects and every callback
/// come from one instance, also right after [bloc] changes from an instance to
/// `null`.
///
/// Write all three type arguments, for example
/// `BlocConsumerWithEffects<UiCubit, UiState, UiEffect>`: below language
/// version 3.7 they are not inferred from [bloc].
class BlocConsumerWithEffects<B extends HasEffects<S, E>, S, E>
    extends StatelessWidget {
  /// Creates a widget that consumes state and effects from the same bloc.
  const BlocConsumerWithEffects({
    required this.onEffect,
    required this.builder,
    super.key,
    this.listener,
    this.bloc,
    this.buildWhen,
    this.listenWhen,
    this.effectWhen,
  }) : assert(
          listener != null || listenWhen == null,
          'listenWhen has no effect without a listener; '
          'pass a listener or remove listenWhen.',
        );

  /// The bloc to consume.
  ///
  /// When omitted, the widget reads the bloc from the nearest provider and
  /// throws a `ProviderNotFoundException` if there is none.
  final B? bloc;

  /// Optional predicate that controls whether [builder] runs for a state
  /// change.
  final BlocBuilderCondition<S>? buildWhen;

  /// Optional predicate that controls whether [listener] runs for a state
  /// change. Requires [listener].
  final BlocListenerCondition<S>? listenWhen;

  /// Optional predicate that controls whether [onEffect] runs for an effect.
  final EffectCondition<E>? effectWhen;

  /// Optional callback for state changes with the resolved bloc instance.
  ///
  /// When omitted, only [builder] and [onEffect] run.
  final BlocWidgetListenerWithBloc<B, S>? listener;

  /// Called in response to one-off effects with the resolved bloc instance.
  final BlocEffectListenerWithBloc<B, S, E> onEffect;

  /// Builds the widget tree with the resolved bloc instance and current state.
  final BlocWidgetBuilderWithBloc<B, S> builder;

  @override
  Widget build(BuildContext context) {
    // Rebuilds only when a different instance is provided.
    final resolvedBloc = bloc ?? context.select<B, B>((bloc) => bloc);
    return BlocEffectListener<B, E>(
      bloc: resolvedBloc,
      effectWhen: effectWhen,
      onEffect: (context, effect) => onEffect(context, resolvedBloc, effect),
      // One child type with or without a listener, so toggling [listener]
      // between null and a callback keeps the builder's subtree and state.
      child: BlocConsumerWithBloc<B, S>(
        bloc: resolvedBloc,
        buildWhen: buildWhen,
        listenWhen: listenWhen,
        listener: listener ?? _ignore,
        builder: builder,
      ),
    );
  }
}

void _ignore(BuildContext context, Object? bloc, Object? state) {}
