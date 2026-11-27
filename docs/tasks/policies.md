# Task Spec - policies

> Status: delivered. `BlocCondition<S>` and `whenChanged<S, T>(selector,
> {equals})` from `lib/src/policies/conditions.dart` since 0.3.0, passed
> directly as `buildWhen`, `listenWhen` or `selectorShouldRebuild`.
> Historical: 0.1.0 shipped `RebuildPolicy` and `ListenPolicy` with their
> factories; 0.3.0 deprecated them and 1.0.0 removed them.

## Preconditions

- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- If missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope

- `typedef BlocCondition<S> = bool Function(S previous, S current)`, the same
  function type as `BlocBuilderCondition<S>` and `BlocListenerCondition<S>`
- `whenChanged<S, T>(selector, {equals})`, which returns a `BlocCondition<S>`
- Compatibility with `ui_with_bloc` widgets and the upstream `BlocBuilder`,
  `BlocListener` and `BlocConsumer`

## Out Of Scope

- New widget types
- Async safety/effects internals
- Policy classes or named factories: a plain predicate covers `always`,
  `never` and `distinct`

## Public Contract

- Conditions are stateless and reusable
- `whenChanged(selector)`: true when the selected values differ by `==`
- `whenChanged(selector, equals: eq)`: true when `eq(previous, current)` is
  false; `equals` receives the selected values in `(previous, current)` order
- A record of scalars is compared field by field; a collection is compared by
  identity unless `equals` is given (for example `listEquals`)
- With the widget's type arguments given, `whenChanged` infers `S` from the
  widget parameter; otherwise type the selector's parameter

## Target Files

- `lib/src/policies/conditions.dart`
- `lib/src/policies/policies.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)

- `test/policies/conditions_test.dart`

Required cases:

- holds on a selected change, not on a change of other fields
- record of scalars, `equals` instead of `==` and its argument order
- a selector that builds a new collection always holds
- inference from the parameters of upstream and `*WithBloc` widgets, with a
  provided and an explicit bloc

## Example App Updates

- Show `whenChanged` with custom equality as `buildWhen`

## Acceptance Criteria (DoD)

- `BlocCondition` and `whenChanged` implemented and exported
- Unit tests cover `whenChanged` with and without `equals`
- Works with `ui_with_bloc` `buildWhen` / `listenWhen` / `selectorShouldRebuild`
- Dartdoc complete for API and examples

## Validation Commands

- `dart format .`
- `flutter analyze`
- `flutter test test/policies`
- `flutter test test/widgets`

## Agent Constraints

- Keep conditions pure and side-effect free
- No runtime reflection/dynamic hacks
- No additional dependencies
