import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Signature for building a widget with both the resolved bloc and current
/// state.
typedef BlocWidgetBuilderWithBloc<B extends StateStreamable<S>, S> = Widget
    Function(BuildContext context, B bloc, S state);

/// A `BlocBuilder` whose [builder] also receives the resolved bloc.
///
/// The bloc is resolved once per build, so the state and the bloc that
/// [builder] receives come from one instance. The widget follows the provided
/// bloc right after [bloc] changes from an instance to `null`, and when a
/// different instance is provided.
class BlocBuilderWithBloc<B extends StateStreamable<S>, S>
    extends StatelessWidget {
  /// Creates a builder widget that exposes both bloc and state.
  const BlocBuilderWithBloc({
    required this.builder,
    super.key,
    this.bloc,
    this.buildWhen,
  });

  /// The bloc to build from.
  ///
  /// When omitted, the widget reads the bloc from the nearest provider and
  /// throws a `ProviderNotFoundException` if there is none.
  final B? bloc;

  /// Optional predicate that controls whether [builder] runs for a state
  /// change.
  final BlocBuilderCondition<S>? buildWhen;

  /// Builds a widget in response to state changes using the resolved bloc.
  final BlocWidgetBuilderWithBloc<B, S> builder;

  @override
  Widget build(BuildContext context) {
    // Rebuilds only when a different instance is provided.
    final resolvedBloc = bloc ?? context.select<B, B>((bloc) => bloc);
    return BlocBuilder<B, S>(
      bloc: resolvedBloc,
      buildWhen: buildWhen,
      builder: (context, state) => builder(context, resolvedBloc, state),
    );
  }
}
