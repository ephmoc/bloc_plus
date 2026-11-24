# Task Spec - policy_composition

> Status: delivered in 0.2.0. Deprecated in 0.3.0, removed in 1.0, with the
> rest of `RebuildPolicy` / `ListenPolicy`. Replacements: `whenChanged(sel,
> equals: eq)` for `onChangeBy` / `onChangeListenBy`, the plain predicate `p`
> for `whenRebuild(p)` / `whenListen(p)` (`whenListen` also clashes with
> `bloc_test`), and a plain predicate or a record selector for `and`, `or`,
> `not`. This spec is historical; do not extend it.

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
- Extend `ListenPolicy<S>` with composition helpers:
  - `and`
  - `or`
  - `not`
- Add top-level predicate wrappers:
  - `whenRebuild<S>(predicate)`
  - `whenListen<S>(predicate)`
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
- `whenRebuild` / `whenListen`: wrap an explicit predicate in a policy object
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
- `whenRebuild` / `whenListen` delegate to the provided predicate without
  hidden state
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
- APIs are usable in `buildWhen` / `listenWhen` through `.shouldRebuild` /
  `.shouldListen`
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
