# Task Spec - context_extensions (BuildContext Extensions)

> Status: delivered in 0.1.0. Since 0.2.2 they return `null` only when no
> provider exists. In 0.3.0 the bounds widened: `readOrNull`, `watchOrNull`
> and `withBloc` accept any provided type, such as a repository, and
> `selectOrNull` any `StateStreamableSource<S>`, the type `BlocProvider`
> provides and keeps up to date. In 0.4.0 the extension
> `BlocContextExtension` and its four members are deprecated, removed in 1.0:
> they return what provider's nullable lookups return, with the same
> rebuilds, so `read<B?>()`, `watch<B?>()`, `select<B?, T?>()` and
> `read<B?>()?.member` replace them. This spec is historical; do not extend
> the extension.

## Preconditions

- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- If missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope

- Implement `readOrNull<B extends Object>()`
- Implement `watchOrNull<B extends Object>()`
- Implement `selectOrNull<B extends StateStreamableSource<S>, S, T>(T Function(S state) selector)`
- Implement `withBloc<B extends Object, R>(R Function(B bloc) fn)`

## Out Of Scope

- Any lifecycle behavior requiring disposed-context support
- Widget rewrites outside extension usage examples

## Public Contract

- Missing provider returns `null`, no provider-not-found throw
- Other errors, such as one thrown while the provider creates the bloc, are
  rethrown
- Methods must be used with live `BuildContext` only
- `watchOrNull` subscribes and rebuilds when state changes (when bloc exists)
- `selectOrNull` rebuilds only when selected value changes
- `withBloc` executes callback only when a `B` is provided

## Target Files

- `lib/src/extensions/build_context_extensions.dart`
- `lib/src/extensions/extensions.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)

- `test/extensions/build_context_extensions_test.dart`
- `test/extensions/build_context_extensions_contract_test.dart`
- `test/widgets/build_context_extensions_widget_test.dart`

Since 0.4.0 these files carry
`// ignore_for_file: deprecated_member_use_from_same_package` and are deleted
with the extension in 1.0.

Required cases:

- each extension returns `null` when provider missing
- no throw for missing provider
- `watchOrNull` updates when state changes
- `selectOrNull` updates only on selected value change
- `withBloc` returns callback result when bloc exists, otherwise `null`
- errors other than a missing provider are rethrown
- a provided repository is found (0.3.0)

## Example App Updates

- Historical: the example app at 0.3.0 does not use these extensions; the
  README shows them.
- Add null-safe usage examples for all four extension methods
- Include one standard `flutter_bloc` widget using these extensions

## Acceptance Criteria (DoD)

- Extensions compile and are exported
- Unit + widget tests cover positive/negative paths
- No API behavior contradicts PRD context-liveness rule
- Documentation includes null-handling examples

## Validation Commands

- `dart format .`
- `flutter analyze`
- `flutter test test/extensions`
- `flutter test test/widgets`

## Agent Constraints

- Do not swallow unrelated runtime exceptions from user callback
- Keep generic bounds type-safe
- No dependency additions
