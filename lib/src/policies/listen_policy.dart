/// Encapsulates listener decisions for pairs of previous and current state.
abstract class ListenPolicy<S> {
  /// Creates a listen policy.
  const ListenPolicy();

  /// Returns `true` when a listener should run for the given state change.
  bool shouldListen(S previous, S current);
}

class _DistinctListenPolicy<S> extends ListenPolicy<S> {
  const _DistinctListenPolicy();

  @override
  bool shouldListen(S previous, S current) => previous != current;
}

class _OnChangeListenPolicy<S, T> extends ListenPolicy<S> {
  const _OnChangeListenPolicy(this._selector);

  final T Function(S state) _selector;

  @override
  bool shouldListen(S previous, S current) =>
      _selector(previous) != _selector(current);
}

class _AlwaysListenPolicy<S> extends ListenPolicy<S> {
  const _AlwaysListenPolicy();

  @override
  bool shouldListen(S previous, S current) => true;
}

class _NeverListenPolicy<S> extends ListenPolicy<S> {
  const _NeverListenPolicy();

  @override
  bool shouldListen(S previous, S current) => false;
}

/// Listens only when the full state value changes.
ListenPolicy<S> distinctListen<S>() => _DistinctListenPolicy<S>();

/// Listens only when the selected value changes.
ListenPolicy<S> onChangeListen<S, T>(T Function(S state) selector) =>
    _OnChangeListenPolicy<S, T>(selector);

/// Listens for every state change.
ListenPolicy<S> alwaysListen<S>() => _AlwaysListenPolicy<S>();

/// Never listens for state changes.
ListenPolicy<S> neverListen<S>() => _NeverListenPolicy<S>();
