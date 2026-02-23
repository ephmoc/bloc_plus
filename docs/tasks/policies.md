# Task Spec - policies

## Scope
- Implement `RebuildPolicy<S>`
- Implement `ListenPolicy<S>`
- Provide built-ins:
  - `distinct()`
  - `onChange<T>(selector)`
  - `always()`
  - `never()`
- Ensure compatibility with `ui_with_bloc` widgets and standard `flutter_bloc` conditions

## Out Of Scope
- New widget types
- Async safety/effects internals

## Public Contract
- Policies are stateless and reusable
- `distinct`: true when `previous != current`
- `onChange`: true when selected values differ
- `always`: always true
- `never`: always false
- Policies expose predicate methods usable directly in `buildWhen` / `listenWhen`

## Target Files
- `lib/src/policies/rebuild_policy.dart`
- `lib/src/policies/listen_policy.dart`
- `lib/src/policies/policies.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)
- `test/policies/rebuild_policy_test.dart`
- `test/policies/listen_policy_test.dart`

Required cases:
- each built-in policy behavior
- `onChange` with primitive and object selector
- policy instance reuse across multiple invocations
- no hidden state between calls

## Example App Updates
- Add one screen/section demonstrating policy reuse in multiple widgets
- Show at least one custom policy implementation

## Acceptance Criteria (DoD)
- Built-ins implemented and exported
- Unit tests cover all built-ins and custom policy example
- Works with `ui_with_bloc` `buildWhen` / `listenWhen`
- Dartdoc complete for API and examples

## Validation Commands
- `dart format .`
- `flutter analyze`
- `flutter test test/policies`
- `flutter test test/widgets`

## Agent Constraints
- Keep policies pure and side-effect free
- No runtime reflection/dynamic hacks
- No additional dependencies
