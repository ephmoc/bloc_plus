# Task Spec - policy_composition

## Preconditions
- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- Baseline `policies` module is already implemented and exported
- If scaffold is missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope
- Extend `RebuildPolicy<S>` with composition helpers:
  - `and`
  - `or`
  - `not`
  - `when`
- Extend `ListenPolicy<S>` with composition helpers:
  - `and`
  - `or`
  - `not`
  - `when`
- Add selector policies with explicit equality:
  - `onChangeBy<S, T>(selector, {required equals})`
  - `onChangeListenBy<S, T>(selector, {required equals})`
- Keep compatibility with standard `flutter_bloc` `buildWhen` / `listenWhen`

## Out Of Scope
- New widget types
- Stateful or cached policy behavior
- Reflection or dynamic dispatch tricks

## Public Contract
- Policies remain stateless and reusable
- Composition order is explicit and deterministic
- `and`: returns `true` only when both component policies return `true`
- `or`: returns `true` when any component policy returns `true`
- `not`: negates the wrapped policy result
- `when`: wraps an explicit predicate in a policy object
- `onChangeBy` and `onChangeListenBy` compare selected values with the provided
  `equals` callback instead of relying on `!=`
- Existing public APIs (`distinct`, `onChange`, `always`, `never`,
  `distinctListen`, `onChangeListen`, `alwaysListen`, `neverListen`) remain
  backward compatible

## Target Files
- `lib/src/policies/rebuild_policy.dart`
- `lib/src/policies/listen_policy.dart`
- `lib/src/policies/policies.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)
- `test/policies/rebuild_policy_test.dart`
- `test/policies/listen_policy_test.dart`

Required cases:
- `and` truth table for rebuild and listen policies
- `or` truth table for rebuild and listen policies
- `not` negates wrapped policy result
- `when` delegates to the provided predicate without hidden state
- `onChangeBy` supports custom equality for lists or DTO-like values
- `onChangeListenBy` supports custom equality for lists or DTO-like values
- composed policies can be reused across multiple invocations
- existing built-ins keep previous behavior

## Example App Updates
- Add one example showing policy composition in a widget tree
- Add one example showing custom equality for a derived selected value

## Acceptance Criteria (DoD)
- New policy APIs are exported and documented
- Existing policy behavior remains unchanged
- Unit tests cover composition and custom equality paths
- APIs are directly usable in `buildWhen` / `listenWhen`
- No hidden mutable state is introduced

## Validation Commands
- `dart format .`
- `flutter analyze`
- `flutter test test/policies`
- `flutter test test/widgets`

## Agent Constraints
- Keep policies pure and side-effect free
- Prefer explicit helper constructors/functions over magic operator overloads
- Do not add dependencies
