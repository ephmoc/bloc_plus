import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc_builder_with_bloc.dart';
import 'bloc_listener_with_bloc.dart';

class BlocConsumerWithBloc<B extends BlocBase<S>, S> extends StatelessWidget {
  const BlocConsumerWithBloc({
    required this.listener,
    required this.builder,
    super.key,
    this.bloc,
    this.buildWhen,
    this.listenWhen,
  });

  final B? bloc;
  final BlocBuilderCondition<S>? buildWhen;
  final BlocListenerCondition<S>? listenWhen;
  final BlocWidgetListenerWithBloc<B, S> listener;
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
