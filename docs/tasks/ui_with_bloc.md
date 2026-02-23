# Task Spec - ui_with_bloc (UI Layer Enhancements)

## Preconditions
- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- If missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope
- Implement `BlocBuilderWithBloc`
- Implement `BlocListenerWithBloc`
- Implement `BlocConsumerWithBloc`
- Implement `BlocSelectorWithBloc`
- Keep behavior parity with corresponding `flutter_bloc` widgets plus bloc instance in callbacks

## Out Of Scope
- `policies` module
- `async_safety` utilities
- `effects` module

## Public Contract
- `bloc` is optional; when omitted, resolve from `BuildContext`
- Missing bloc in context must throw provider-not-found error (same semantics as `flutter_bloc`)
- `buildWhen` / `listenWhen` semantics must match `flutter_bloc`
- `BlocSelectorWithBloc` rebuilds only on selected value change by default (`!=`)
- `BlocSelectorWithBloc` accepts custom `selectorShouldRebuild(previous, current)`

## Target Files
- `lib/src/widgets/bloc_builder_with_bloc.dart`
- `lib/src/widgets/bloc_listener_with_bloc.dart`
- `lib/src/widgets/bloc_consumer_with_bloc.dart`
- `lib/src/widgets/bloc_selector_with_bloc.dart`
- `lib/src/widgets/widgets.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)
- `test/widgets/bloc_builder_with_bloc_test.dart`
- `test/widgets/bloc_listener_with_bloc_test.dart`
- `test/widgets/bloc_consumer_with_bloc_test.dart`
- `test/widgets/bloc_selector_with_bloc_test.dart`

Required cases:
- builder/listener receive bloc instance used by widget
- explicit `bloc:` overrides context lookup
- missing provider throws
- `buildWhen` and `listenWhen` are respected
- selector default compare prevents unnecessary rebuilds
- custom `selectorShouldRebuild` controls rebuild behavior

## Example App Updates
- Add a page/section showing all four widgets with one shared bloc
- Show mixed usage with standard `flutter_bloc` widgets in the same tree

## Acceptance Criteria (DoD)
- All public APIs compile and are exported
- Widget tests pass for all required cases
- `flutter analyze` has no new warnings/errors from this module
- Example app demonstrates each widget
- Dartdoc added for all public classes/params

## Validation Commands
- `dart format .`
- `flutter analyze`
- `flutter test test/widgets`

## Agent Constraints
- Do not change public API outside PRD contract
- Prefer composition over fragile inheritance internals
- Do not introduce extra dependencies
