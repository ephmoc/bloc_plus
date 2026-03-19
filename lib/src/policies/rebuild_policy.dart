/// Encapsulates rebuild decisions for pairs of previous and current state.
abstract class RebuildPolicy<S> {
  /// Creates a rebuild policy.
  const RebuildPolicy();

  /// Returns `true` when a widget should rebuild for the given state change.
  bool shouldRebuild(S previous, S current);

  /// Returns a policy that rebuilds only when this policy and [other] return
  /// `true`.
  RebuildPolicy<S> and(RebuildPolicy<S> other) =>
      _AndRebuildPolicy<S>(this, other);

  /// Returns a policy that rebuilds when either this policy or [other] returns
  /// `true`.
  RebuildPolicy<S> or(RebuildPolicy<S> other) =>
      _OrRebuildPolicy<S>(this, other);

  /// Returns a policy that negates this policy result.
  RebuildPolicy<S> not() => _NotRebuildPolicy<S>(this);
}

class _DistinctRebuildPolicy<S> extends RebuildPolicy<S> {
  const _DistinctRebuildPolicy();

  @override
  bool shouldRebuild(S previous, S current) => previous != current;
}

class _OnChangeRebuildPolicy<S, T> extends RebuildPolicy<S> {
  const _OnChangeRebuildPolicy(this._selector, this._equals);

  final T Function(S state) _selector;
  final bool Function(T previous, T current) _equals;

  @override
  bool shouldRebuild(S previous, S current) =>
      !_equals(_selector(previous), _selector(current));
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

class _PredicateRebuildPolicy<S> extends RebuildPolicy<S> {
  const _PredicateRebuildPolicy(this._predicate);

  final bool Function(S previous, S current) _predicate;

  @override
  bool shouldRebuild(S previous, S current) => _predicate(previous, current);
}

class _AndRebuildPolicy<S> extends RebuildPolicy<S> {
  const _AndRebuildPolicy(this._left, this._right);

  final RebuildPolicy<S> _left;
  final RebuildPolicy<S> _right;

  @override
  bool shouldRebuild(S previous, S current) =>
      _left.shouldRebuild(previous, current) &&
      _right.shouldRebuild(previous, current);
}

class _OrRebuildPolicy<S> extends RebuildPolicy<S> {
  const _OrRebuildPolicy(this._left, this._right);

  final RebuildPolicy<S> _left;
  final RebuildPolicy<S> _right;

  @override
  bool shouldRebuild(S previous, S current) =>
      _left.shouldRebuild(previous, current) ||
      _right.shouldRebuild(previous, current);
}

class _NotRebuildPolicy<S> extends RebuildPolicy<S> {
  const _NotRebuildPolicy(this._policy);

  final RebuildPolicy<S> _policy;

  @override
  bool shouldRebuild(S previous, S current) =>
      !_policy.shouldRebuild(previous, current);
}

/// Rebuilds only when the full state value changes.
RebuildPolicy<S> distinct<S>() => _DistinctRebuildPolicy<S>();

/// Rebuilds only when the selected value changes.
RebuildPolicy<S> onChange<S, T>(T Function(S state) selector) =>
    onChangeBy<S, T>(selector,
        equals: (previous, current) => previous == current);

/// Rebuilds only when the selected value changes according to [equals].
RebuildPolicy<S> onChangeBy<S, T>(
  T Function(S state) selector, {
  required bool Function(T previous, T current) equals,
}) =>
    _OnChangeRebuildPolicy<S, T>(selector, equals);

/// Rebuilds for every state change.
RebuildPolicy<S> always<S>() => _AlwaysRebuildPolicy<S>();

/// Never rebuilds for state changes.
RebuildPolicy<S> never<S>() => _NeverRebuildPolicy<S>();

/// Wraps [predicate] as a reusable rebuild policy.
RebuildPolicy<S> whenRebuild<S>(
  bool Function(S previous, S current) predicate,
) =>
    _PredicateRebuildPolicy<S>(predicate);
