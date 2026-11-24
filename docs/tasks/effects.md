# Task Spec - effects

> Status: delivered in 0.1.0 as `EffectsSource<E>`, `HasEffects<S, E>` and
> `EffectListener<B extends BlocBase<S>, S, E>`. In 0.3.0 `EffectListener`
> is deprecated, removed in 1.0. Replacement:
> `BlocEffectListener<B extends EffectsSource<E>, E>`, which checks the effect
> type at compile time and composes inside `MultiBlocListener`. 0.3.0 also
> makes `emitEffect` `@protected` and `@visibleForTesting`. 0.3.1 adds the
> opt-in `debugPrintUnheardEffects` debug warning for effects that nothing
> listens to.

## Preconditions

- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- If missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope

- Implement the `EffectsSource<E>` interface (`Stream<E> get effects`) and
  `mixin HasEffects<S, E> on BlocBase<S> implements EffectsSource<E>` with
  `emitEffect(E effect)` for one-shot effects
- Implement an effect listener widget: shipped as `EffectListener<B, S, E>`
  (deprecated in 0.3.0); use `BlocEffectListener<B, E>` with
  `onEffect(context, effect)`, `bloc`, `child` (`effectWhen` is deprecated
  since 0.4.0)
- Define and enforce lifecycle behavior for effect stream ownership/closing:
  the stream is broadcast, and `close()` closes the bloc, then waits until
  subscribers got the effects emitted before it

## Out Of Scope

- Replacing state with effects
- Cross-isolate/event-bus integrations

## Public Contract

- Effects are emitted on separate stream from state
- Effects do not trigger rebuild by themselves
- Effects are not replayed: a listener gets only effects emitted while it is
  subscribed
- The listener (`BlocEffectListener`, formerly `EffectListener`) subscribes once and invokes callback once per effect event
- Listener unsubscribes on dispose
- Missing provider follows provider-not-found semantics (same as widget family)
- Late emits after bloc close must not crash consumer code (well-defined no-op or handled close path)

## Target Files

- `lib/src/effects/has_effects.dart`
- `lib/src/effects/effect_listener.dart` (deprecated widget)
- `lib/src/effects/bloc_effect_listener.dart` (0.3.0)
- `lib/src/effects/effects.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)

- `test/effects/has_effects_test.dart`
- `test/widgets/effect_listener_test.dart`
- `test/widgets/bloc_effect_listener_test.dart` (0.3.0)

Required cases:

- `emitEffect` emits event to stream
- stream supports multiple listeners when expected by contract
- listener callback called exactly once per emission
- listener unsubscribes on widget dispose
- bloc disposal/close path does not leak subscriptions
- missing provider throws as expected

## Example App Updates

- Historical: the example app at 0.3.0 uses `String` effects with prefixes
  (snack/dialog/info) and two `BlocEffectListener` entries in a
  `MultiBlocListener`; it has no auth/navigation example or effect types.
- Auth/navigation example using effect types and `BlocEffectListener`
  (originally `EffectListener`)
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
