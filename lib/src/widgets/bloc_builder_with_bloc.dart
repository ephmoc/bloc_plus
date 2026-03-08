import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Signature for building a widget with both the resolved bloc and current
/// state.
typedef BlocWidgetBuilderWithBloc<B extends BlocBase<S>, S> = Widget Function(
    BuildContext context, B bloc, S state);

/// A [BlocBuilderBase] variant that also passes the resolved bloc instance to
/// [builder].
class BlocBuilderWithBloc<B extends BlocBase<S>, S>
    extends BlocBuilderBase<B, S> {
  /// Creates a builder widget that exposes both bloc and state.
  const BlocBuilderWithBloc({
    required this.builder,
    super.key,
    super.bloc,
    super.buildWhen,
  });

  /// Builds a widget in response to state changes using the resolved bloc.
  final BlocWidgetBuilderWithBloc<B, S> builder;

  @override
  Widget build(BuildContext context, S state) {
    final resolvedBloc = bloc ?? context.read<B>();
    return builder(context, resolvedBloc, state);
  }
}
