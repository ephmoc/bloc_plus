import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../effects/effect_listener.dart';
import 'bloc_builder_with_bloc.dart';
import 'bloc_consumer_with_bloc.dart';
import 'bloc_listener_with_bloc.dart';

/// Signature for handling one-off effects with access to the resolved bloc.
typedef BlocEffectListenerWithBloc<B extends BlocBase<S>, S, E> = void Function(
  BuildContext context,
  B bloc,
  E effect,
);

/// Combines state building/listening with one-off effect handling.
class BlocConsumerWithEffects<B extends BlocBase<S>, S, E>
    extends StatelessWidget {
  /// Creates a widget that consumes state and effects from the same bloc.
  const BlocConsumerWithEffects({
    required this.listener,
    required this.onEffect,
    required this.builder,
    super.key,
    this.bloc,
    this.buildWhen,
    this.listenWhen,
    this.effectWhen,
  });

  /// The bloc to consume.
  ///
  /// When omitted, the widget reads the bloc from the nearest provider.
  final B? bloc;

  /// Optional predicate that controls whether [builder] runs for a state
  /// change.
  final BlocBuilderCondition<S>? buildWhen;

  /// Optional predicate that controls whether [listener] runs for a state
  /// change.
  final BlocListenerCondition<S>? listenWhen;

  /// Optional predicate that controls whether [onEffect] runs for an effect.
  final EffectCondition<E>? effectWhen;

  /// Called in response to state changes with the resolved bloc instance.
  final BlocWidgetListenerWithBloc<B, S> listener;

  /// Called in response to one-off effects with the resolved bloc instance.
  final BlocEffectListenerWithBloc<B, S, E> onEffect;

  /// Builds the widget tree with the resolved bloc instance and current state.
  final BlocWidgetBuilderWithBloc<B, S> builder;

  @override
  Widget build(BuildContext context) {
    return EffectListener<B, S, E>(
      bloc: bloc,
      effectWhen: effectWhen,
      onEffect: (context, effect) {
        final resolvedBloc = bloc ?? context.read<B>();
        onEffect(context, resolvedBloc, effect);
      },
      child: BlocConsumerWithBloc<B, S>(
        bloc: bloc,
        buildWhen: buildWhen,
        listenWhen: listenWhen,
        listener: listener,
        builder: builder,
      ),
    );
  }
}
