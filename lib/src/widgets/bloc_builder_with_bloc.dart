import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef BlocWidgetBuilderWithBloc<B extends BlocBase<S>, S> = Widget Function(
    BuildContext context, B bloc, S state);

class BlocBuilderWithBloc<B extends BlocBase<S>, S>
    extends BlocBuilderBase<B, S> {
  const BlocBuilderWithBloc({
    required this.builder,
    super.key,
    super.bloc,
    super.buildWhen,
  });

  final BlocWidgetBuilderWithBloc<B, S> builder;

  @override
  Widget build(BuildContext context, S state) {
    final resolvedBloc = bloc ?? context.read<B>();
    return builder(context, resolvedBloc, state);
  }
}
