import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../policies/conditions.dart';

/// Signature for building a widget from a selected value and the resolved bloc.
typedef BlocSelectorBuilderWithBloc<B extends StateStreamable<S>, S, T> = Widget
    Function(BuildContext context, B bloc, T selected);

/// Signature for deciding whether a newly selected value should trigger a
/// rebuild.
@Deprecated(
  'Use BlocCondition<T>, the same function type. Will be removed in 1.0.',
)
typedef BlocSelectedCondition<T> = bool Function(T previous, T current);

/// A selector widget that exposes both the resolved bloc instance and selected
/// value to [builder].
///
/// Like `BlocSelector`, it keeps the last built selection: the selection is
/// recomputed when [selector] or the bloc changes, and [selector] runs once
/// per state change.
class BlocSelectorWithBloc<B extends StateStreamable<S>, S, T>
    extends StatefulWidget {
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
  /// When omitted, the widget reads the bloc from the nearest provider and
  /// throws a `ProviderNotFoundException` if there is none.
  final B? bloc;

  /// Selects the value that should be passed to [builder].
  final T Function(S state) selector;

  /// Custom comparison used to decide whether the selected value should rebuild.
  ///
  /// Receives the last built selection as `previous` and the selection of the
  /// new state as `current`. Defaults to `previous != current`.
  final BlocCondition<T>? selectorShouldRebuild;

  /// Builds a widget with the selected value and resolved bloc instance.
  final BlocSelectorBuilderWithBloc<B, S, T> builder;

  @override
  State<BlocSelectorWithBloc<B, S, T>> createState() =>
      _BlocSelectorWithBlocState<B, S, T>();
}

// Mirrors flutter_bloc's _BlocSelectorState: caches the last built selection.
class _BlocSelectorWithBlocState<B extends StateStreamable<S>, S, T>
    extends State<BlocSelectorWithBloc<B, S, T>> {
  late B _bloc;
  late T _selected;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _selected = widget.selector(_bloc.state);
  }

  @override
  void didUpdateWidget(BlocSelectorWithBloc<B, S, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bloc = widget.bloc ?? context.read<B>();
    if (oldWidget.selector != widget.selector) {
      _bloc = bloc;
      _selected = widget.selector(_bloc.state);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when a different instance is provided. The switch is here
    // because provider does not notify an element that is already dirty.
    final bloc = widget.bloc ?? context.select<B, B>((bloc) => bloc);
    if (!identical(_bloc, bloc)) {
      _bloc = bloc;
      _selected = widget.selector(_bloc.state);
    }
    return BlocListener<B, S>(
      bloc: _bloc,
      listener: (context, state) {
        final selected = widget.selector(state);
        final changed =
            widget.selectorShouldRebuild?.call(_selected, selected) ??
                _selected != selected;
        if (changed) setState(() => _selected = selected);
      },
      child: widget.builder(context, _bloc, _selected),
    );
  }
}
