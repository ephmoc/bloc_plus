# Task Spec - context_extensions (BuildContext Extensions)

## Preconditions
- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- If missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope
- Implement `readOrNull<B>()`
- Implement `watchOrNull<B>()`
- Implement `selectOrNull<B, S, T>(selector)`
- Implement `withBloc<B, R>(fn)`

## Out Of Scope
- Any lifecycle behavior requiring disposed-context support
- Widget rewrites outside extension usage examples

## Public Contract
- Missing provider returns `null`, no provider-not-found throw
- Methods must be used with live `BuildContext` only
- `watchOrNull` subscribes and rebuilds when state changes (when bloc exists)
- `selectOrNull` rebuilds only when selected value changes
- `withBloc` executes callback only when bloc exists

## Target Files
- `lib/src/extensions/build_context_extensions.dart`
- `lib/src/extensions/extensions.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)
- `test/extensions/build_context_extensions_test.dart`
- `test/widgets/build_context_extensions_widget_test.dart`

Required cases:
- each extension returns `null` when provider missing
- no throw for missing provider
- `watchOrNull` updates when state changes
- `selectOrNull` updates only on selected value change
- `withBloc` returns callback result when bloc exists, otherwise `null`

## Example App Updates
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
