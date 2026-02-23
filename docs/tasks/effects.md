# Task Spec - effects

## Preconditions
- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- If missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope
- Implement `HasEffects<E>` contract for one-shot effects
- Implement `EffectListener<B, E>` widget
- Define and enforce lifecycle behavior for effect stream ownership/closing

## Out Of Scope
- Replacing state with effects
- Cross-isolate/event-bus integrations

## Public Contract
- Effects are emitted on separate stream from state
- Effects do not trigger rebuild by themselves
- `EffectListener` subscribes once and invokes callback once per effect event
- Listener unsubscribes on dispose
- Missing provider follows provider-not-found semantics (same as widget family)
- Late emits after bloc close must not crash consumer code (well-defined no-op or handled close path)

## Target Files
- `lib/src/effects/has_effects.dart`
- `lib/src/effects/effect_listener.dart`
- `lib/src/effects/effects.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)
- `test/effects/has_effects_test.dart`
- `test/widgets/effect_listener_test.dart`

Required cases:
- `emitEffect` emits event to stream
- stream supports multiple listeners when expected by contract
- listener callback called exactly once per emission
- listener unsubscribes on widget dispose
- bloc disposal/close path does not leak subscriptions
- missing provider throws as expected

## Example App Updates
- Auth/navigation example using effect types and `EffectListener`
- Multiple listeners example for different effect categories

## Acceptance Criteria (DoD)
- Effect APIs compile and are exported
- Widget + unit tests cover lifecycle and disposal edge cases
- No stream controller leaks in repeated mount/unmount tests
- Documentation clearly separates state vs effect responsibilities

## Validation Commands
- `dart format .`
- `flutter analyze`
- `flutter test test/effects`
- `flutter test test/widgets`

## Agent Constraints
- Keep effect stream contract explicit (broadcast vs single-subscription) and test it
- Do not couple effects with state equality/rebuild logic
- No extra dependencies
