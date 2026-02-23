abstract class RebuildPolicy<S> {
  const RebuildPolicy();

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

RebuildPolicy<S> distinct<S>() => _DistinctRebuildPolicy<S>();

RebuildPolicy<S> onChange<S, T>(T Function(S state) selector) =>
    _OnChangeRebuildPolicy<S, T>(selector);

RebuildPolicy<S> always<S>() => _AlwaysRebuildPolicy<S>();

RebuildPolicy<S> never<S>() => _NeverRebuildPolicy<S>();
