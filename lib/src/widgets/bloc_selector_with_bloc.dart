import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef BlocSelectorBuilderWithBloc<B extends BlocBase<S>, S, T> = Widget
    Function(BuildContext context, B bloc, T selected);

typedef BlocSelectedCondition<T> = bool Function(T previous, T current);

class BlocSelectorWithBloc<B extends BlocBase<S>, S, T>
    extends StatelessWidget {
  const BlocSelectorWithBloc({
    required this.selector,
    required this.builder,
    super.key,
    this.bloc,
    this.selectorShouldRebuild,
  });

  final B? bloc;
  final T Function(S state) selector;
  final BlocSelectedCondition<T>? selectorShouldRebuild;
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
