/// Encapsulates rebuild decisions for pairs of previous and current state.
abstract class RebuildPolicy<S> {
  /// Creates a rebuild policy.
  const RebuildPolicy();

  /// Returns `true` when a widget should rebuild for the given state change.
  bool shouldRebuild(S previous, S current);
}

class _DistinctRebuildPolicy<S> extends RebuildPolicy<S> {
  const _DistinctRebuildPolicy();

  @override
  bool shouldRebuild(S previous, S current) => previous != current;
}

class _OnChangeRebuildPolicy<S, T> extends RebuildPolicy<S> {
  const _OnChangeRebuildPolicy(this._selector);

  final T Function(S state) _selector;

  @override
  bool shouldRebuild(S previous, S current) =>
      _selector(previous) != _selector(current);
}

class _AlwaysRebuildPolicy<S> extends RebuildPolicy<S> {
  const _AlwaysRebuildPolicy();

  @override
  bool shouldRebuild(S previous, S current) => true;
}

class _NeverRebuildPolicy<S> extends RebuildPolicy<S> {
  const _NeverRebuildPolicy();

  @override
  bool shouldRebuild(S previous, S current) => false;
}

/// Rebuilds only when the full state value changes.
RebuildPolicy<S> distinct<S>() => _DistinctRebuildPolicy<S>();

/// Rebuilds only when the selected value changes.
RebuildPolicy<S> onChange<S, T>(T Function(S state) selector) =>
    _OnChangeRebuildPolicy<S, T>(selector);

/// Rebuilds for every state change.
RebuildPolicy<S> always<S>() => _AlwaysRebuildPolicy<S>();

/// Never rebuilds for state changes.
RebuildPolicy<S> never<S>() => _NeverRebuildPolicy<S>();
