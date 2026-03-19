# Task Spec - multi_effect_listener

## Preconditions
- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- Baseline `effects` module is already implemented and exported
- Effect filtering task may be implemented first, but it is not required
- If scaffold is missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope
- Implement `MultiEffectListener`
- Provide a public API for combining multiple effect listeners without manual
  nesting
- Preserve the semantics of each individual `EffectListener`

## Out Of Scope
- Effect stream aggregation across blocs
- Reordering effect delivery across listener entries
- Provider/private-framework internals that are not part of the public API

## Public Contract
- `MultiEffectListener` is a composition convenience, not a new delivery model
- Each configured listener behaves as if it were nested manually
- Listener invocation order is deterministic and matches the configured order
- Disposal unsubscribes every underlying effect listener
- Errors from missing providers surface with the same semantics as individual
  listeners

## Target Files
- `lib/src/effects/multi_effect_listener.dart`
- `lib/src/effects/effects.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)
- `test/widgets/multi_effect_listener_test.dart`

Required cases:
- multiple listeners for different blocs are invoked correctly
- listener invocation order matches declaration order
- multiple listeners can target the same bloc type when configured explicitly
- widget dispose unsubscribes all listeners
- missing provider for one configured listener throws as expected
- manual nesting and `MultiEffectListener` behave equivalently

## Example App Updates
- Add one example screen section that replaces nested effect listeners with
  `MultiEffectListener`

## Acceptance Criteria (DoD)
- New widget compiles, is exported, and is documented
- Widget semantics match equivalent manual nesting
- Tests cover lifecycle and ordering behavior
- Implementation uses only public APIs and does not require new dependencies

## Validation Commands
- `dart format .`
- `flutter analyze`
- `flutter test test/widgets/multi_effect_listener_test.dart`
- `flutter test test/widgets`

## Agent Constraints
- Prefer explicit composition over clever generic machinery
- Keep the public API readable in typical app code
- Do not depend on private provider or framework internals
