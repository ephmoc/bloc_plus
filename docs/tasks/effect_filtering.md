# Task Spec - effect_filtering

## Preconditions
- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- Baseline `effects` module is already implemented and exported
- If scaffold is missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope
- Extend `EffectListener` with optional effect filtering
- Add an explicit predicate API for deciding whether an emitted effect should
  invoke `onEffect`
- Preserve existing subscription, provider lookup, and disposal semantics

## Out Of Scope
- Replacing state with effects
- Effect replay, buffering, or persistence
- Runtime type reflection beyond normal Dart generic checks

## Public Contract
- `EffectListener` remains compatible with existing usage
- New filtering is optional; when omitted, current behavior is preserved
- Filtered-out effects must not invoke `onEffect`
- The effect stream subscription stays active even when individual effects are
  filtered out
- Missing provider behavior remains aligned with widget family semantics
- Late emits after bloc close remain a no-op from the consumer perspective

## Target Files
- `lib/src/effects/effect_listener.dart`
- `lib/src/effects/effects.dart` (barrel, if API surface changes)
- `lib/bloc_plus.dart` (exports, if required)

## Tests (Contract)
- `test/widgets/effect_listener_test.dart`

Required cases:
- listener still receives all effects when no filter is provided
- predicate allows matching effects through
- predicate blocks non-matching effects
- filtering does not create duplicate subscriptions
- explicit `bloc:` still overrides context lookup
- missing provider still throws as expected
- widget dispose still cancels the subscription

## Example App Updates
- Add one example using effect filtering for navigation vs snackbar effects

## Acceptance Criteria (DoD)
- Existing `EffectListener` usage remains source-compatible
- Filtering behavior is explicit and documented
- Widget tests cover positive and negative filter paths
- No extra rebuild behavior is introduced by filtering support

## Validation Commands
- `dart format .`
- `flutter analyze`
- `flutter test test/widgets/effect_listener_test.dart`

## Agent Constraints
- Keep filtering API explicit; avoid hidden type-based dispatch unless it is a
  separately documented API
- Do not change the broadcast effect stream contract
- Do not add dependencies
