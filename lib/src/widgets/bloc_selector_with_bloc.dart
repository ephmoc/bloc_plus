import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Signature for building a widget from a selected value and the resolved bloc.
typedef BlocSelectorBuilderWithBloc<B extends BlocBase<S>, S, T> = Widget
    Function(BuildContext context, B bloc, T selected);

/// Signature for deciding whether a newly selected value should trigger a
/// rebuild.
typedef BlocSelectedCondition<T> = bool Function(T previous, T current);

/// A selector widget that exposes both the resolved bloc instance and selected
/// value to [builder].
class BlocSelectorWithBloc<B extends BlocBase<S>, S, T>
    extends StatelessWidget {
  /// Creates a selector widget with optional custom rebuild logic.
  const BlocSelectorWithBloc({
    required this.selector,
    required this.builder,
    super.key,
    this.bloc,
    this.selectorShouldRebuild,
  });

  /// The bloc to read from.
  ///
  /// When omitted, the widget reads the bloc from the nearest provider.
  final B? bloc;

  /// Selects the value that should be passed to [builder].
  final T Function(S state) selector;

  /// Custom comparison used to decide whether the selected value should rebuild.
  final BlocSelectedCondition<T>? selectorShouldRebuild;

  /// Builds a widget with the selected value and resolved bloc instance.
  final BlocSelectorBuilderWithBloc<B, S, T> builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      bloc: bloc,
      buildWhen: (previous, current) {
        final previousSelected = selector(previous);
        final currentSelected = selector(current);
        final shouldRebuild = selectorShouldRebuild;
        if (shouldRebuild != null) {
          return shouldRebuild(previousSelected, currentSelected);
        }
        return previousSelected != currentSelected;
      },
      builder: (context, state) {
        final resolvedBloc = bloc ?? context.read<B>();
        final selected = selector(state);
        return builder(context, resolvedBloc, selected);
      },
    );
  }
}
