import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc_builder_with_bloc.dart';
import 'bloc_listener_with_bloc.dart';

/// A [BlocConsumer] variant that passes the resolved bloc instance to both
/// [listener] and [builder].
class BlocConsumerWithBloc<B extends BlocBase<S>, S> extends StatelessWidget {
  /// Creates a widget that rebuilds and listens with access to the bloc.
  const BlocConsumerWithBloc({
    required this.listener,
    required this.builder,
    super.key,
    this.bloc,
    this.buildWhen,
    this.listenWhen,
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

  /// Called in response to state changes with the resolved bloc instance.
  final BlocWidgetListenerWithBloc<B, S> listener;

  /// Builds the widget tree with the resolved bloc instance and current state.
  final BlocWidgetBuilderWithBloc<B, S> builder;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<B, S>(
      bloc: bloc,
      buildWhen: buildWhen,
      listenWhen: listenWhen,
      listener: (context, state) {
        final resolvedBloc = bloc ?? context.read<B>();
        listener(context, resolvedBloc, state);
      },
      builder: (context, state) {
        final resolvedBloc = bloc ?? context.read<B>();
        return builder(context, resolvedBloc, state);
      },
    );
  }
}
