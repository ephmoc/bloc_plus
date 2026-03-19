/// Encapsulates listener decisions for pairs of previous and current state.
abstract class ListenPolicy<S> {
  /// Creates a listen policy.
  const ListenPolicy();

  /// Returns `true` when a listener should run for the given state change.
  bool shouldListen(S previous, S current);

  /// Returns a policy that listens only when this policy and [other] return
  /// `true`.
  ListenPolicy<S> and(ListenPolicy<S> other) =>
      _AndListenPolicy<S>(this, other);

  /// Returns a policy that listens when either this policy or [other] returns
  /// `true`.
  ListenPolicy<S> or(ListenPolicy<S> other) => _OrListenPolicy<S>(this, other);

  /// Returns a policy that negates this policy result.
  ListenPolicy<S> not() => _NotListenPolicy<S>(this);
}

class _DistinctListenPolicy<S> extends ListenPolicy<S> {
  const _DistinctListenPolicy();

  @override
  bool shouldListen(S previous, S current) => previous != current;
}

class _OnChangeListenPolicy<S, T> extends ListenPolicy<S> {
  const _OnChangeListenPolicy(this._selector, this._equals);

  final T Function(S state) _selector;
  final bool Function(T previous, T current) _equals;

  @override
  bool shouldListen(S previous, S current) =>
      !_equals(_selector(previous), _selector(current));
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

class _PredicateListenPolicy<S> extends ListenPolicy<S> {
  const _PredicateListenPolicy(this._predicate);

  final bool Function(S previous, S current) _predicate;

  @override
  bool shouldListen(S previous, S current) => _predicate(previous, current);
}

class _AndListenPolicy<S> extends ListenPolicy<S> {
  const _AndListenPolicy(this._left, this._right);

  final ListenPolicy<S> _left;
  final ListenPolicy<S> _right;

  @override
  bool shouldListen(S previous, S current) =>
      _left.shouldListen(previous, current) &&
      _right.shouldListen(previous, current);
}

class _OrListenPolicy<S> extends ListenPolicy<S> {
  const _OrListenPolicy(this._left, this._right);

  final ListenPolicy<S> _left;
  final ListenPolicy<S> _right;

  @override
  bool shouldListen(S previous, S current) =>
      _left.shouldListen(previous, current) ||
      _right.shouldListen(previous, current);
}

class _NotListenPolicy<S> extends ListenPolicy<S> {
  const _NotListenPolicy(this._policy);

  final ListenPolicy<S> _policy;

  @override
  bool shouldListen(S previous, S current) =>
      !_policy.shouldListen(previous, current);
}

/// Listens only when the full state value changes.
ListenPolicy<S> distinctListen<S>() => _DistinctListenPolicy<S>();

/// Listens only when the selected value changes.
ListenPolicy<S> onChangeListen<S, T>(T Function(S state) selector) =>
    onChangeListenBy<S, T>(
      selector,
      equals: (previous, current) => previous == current,
    );

/// Listens only when the selected value changes according to [equals].
ListenPolicy<S> onChangeListenBy<S, T>(
  T Function(S state) selector, {
  required bool Function(T previous, T current) equals,
}) =>
    _OnChangeListenPolicy<S, T>(selector, equals);

/// Listens for every state change.
ListenPolicy<S> alwaysListen<S>() => _AlwaysListenPolicy<S>();

/// Never listens for state changes.
ListenPolicy<S> neverListen<S>() => _NeverListenPolicy<S>();

/// Wraps [predicate] as a reusable listen policy.
ListenPolicy<S> whenListen<S>(
  bool Function(S previous, S current) predicate,
) =>
    _PredicateListenPolicy<S>(predicate);
