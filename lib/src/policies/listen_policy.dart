abstract class ListenPolicy<S> {
  const ListenPolicy();

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

ListenPolicy<S> distinctListen<S>() => _DistinctListenPolicy<S>();

ListenPolicy<S> onChangeListen<S, T>(T Function(S state) selector) =>
    _OnChangeListenPolicy<S, T>(selector);

ListenPolicy<S> alwaysListen<S>() => _AlwaysListenPolicy<S>();

ListenPolicy<S> neverListen<S>() => _NeverListenPolicy<S>();
