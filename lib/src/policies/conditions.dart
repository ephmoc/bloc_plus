/// A predicate over a pair of states, usable directly as `buildWhen`,
/// `listenWhen` or `selectorShouldRebuild`.
///
/// It is the same function type as `BlocBuilderCondition<S>` and
/// `BlocListenerCondition<S>` from `flutter_bloc`, and as this package's
/// `BlocSelectedCondition<T>`.
typedef BlocCondition<S> = bool Function(S previous, S current);

/// Returns a condition that holds when the value picked by [selector] differs
/// between the previous and the current state.
///
/// Values are compared with `==` unless [equals] is given.
///
/// The result works as `buildWhen`, `listenWhen` and `selectorShouldRebuild`,
/// in this package's widgets and in the upstream `BlocBuilder`,
/// `BlocListener` and `BlocConsumer`. When the widget has its type arguments,
/// `whenChanged` needs none: the state type comes from the widget, so a typo
/// in the selector is a compile error. When the widget infers them from
/// `bloc:`, or the condition is stored in a variable, type the selector's
/// parameter: `whenChanged((CounterState state) => state.count)`.
///
/// ```dart
/// BlocBuilder<CounterCubit, CounterState>(
///   buildWhen: whenChanged((state) => state.count),
///   builder: (context, state) => Text('${state.count}'),
/// )
///
/// // Several fields: a record of scalars, compared field by field.
/// buildWhen: whenChanged((state) => (state.count, state.label)),
///
/// // A collection: pass equals.
/// listenWhen: whenChanged((state) => state.items, equals: listEquals),
/// ```
///
/// Select scalars or records of scalars. A collection, also as a record
/// field, is compared by identity, so pass [equals] (for example
/// `listEquals`). Never build a new collection in the selector, such as
/// `(state) => [state.a]`: it is then always "changed".
BlocCondition<S> whenChanged<S, T>(
  T Function(S state) selector, {
  bool Function(T previous, T current)? equals,
}) {
  if (equals == null) {
    return (previous, current) => selector(previous) != selector(current);
  }
  return (previous, current) => !equals(selector(previous), selector(current));
}
