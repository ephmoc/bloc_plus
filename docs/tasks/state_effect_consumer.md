# Task Spec - state_effect_consumer

> Status: delivered in 0.2.0 as `BlocConsumerWithEffects`. In 0.3.0 it
> requires `B extends HasEffects<S, E>`, `listener` is optional, it resolves
> the bloc once per build, and its effect path is built on
> `BlocEffectListener` instead of the deprecated `EffectListener`.

## Preconditions
- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- Baseline `ui_with_bloc` and `effects` modules are already implemented and
  exported
- `effect_filtering` should be implemented first if the new consumer is expected
  to support effect predicates
- If scaffold is missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope
- Implement a consumer widget that combines:
  - state listening/building from the current `ui_with_bloc` module
  - one-shot effect handling from the `effects` module
- Keep the API explicit about the separation between state changes and effect
  events

## Signature (0.3.0)
- `const BlocConsumerWithEffects<B extends HasEffects<S, E>, S, E>({required onEffect, required builder, listener, bloc, buildWhen, listenWhen, effectWhen})`
- `onEffect(context, bloc, effect)` (`BlocEffectListenerWithBloc<B, S, E>`),
  `builder(context, bloc, state)`, optional `listener(context, bloc, state)`
- `listenWhen` without `listener` fails an assert
- Write all three type arguments: below language version 3.7 they are not
  inferred from `bloc:`

## Out Of Scope
- Merging state and effects into one stream
- Replacing `BlocConsumerWithBloc` or `BlocEffectListener` (originally
  `EffectListener`)
- Hidden buffering or replay of effect events

## Public Contract
- State rendering semantics remain aligned with `BlocConsumer` /
  `BlocConsumerWithBloc`
- Effect handling semantics remain aligned with `BlocEffectListener`
- State callbacks and effect callbacks are independently configurable
- Missing provider behavior remains consistent with the underlying widget family
- The combined widget is a convenience composition, not a new runtime model

## Target Files
- `lib/src/widgets/bloc_consumer_with_effects.dart`
- `lib/src/widgets/widgets.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)
- `test/widgets/bloc_consumer_with_effects_test.dart`

Required cases:
- builder receives state updates as expected
- state listener respects `listenWhen`
- effect callback runs once per emitted effect
- explicit `bloc:` overrides context lookup
- missing provider throws as expected
- widget dispose unsubscribes the effect listener path
- composed behavior matches manual nesting of `BlocEffectListener` and
  `BlocConsumerWithBloc` (not covered by a dedicated test at 0.3.0)

## Example App Updates
- Add one example screen section that uses the combined widget for a common
  "render state + react to effects" flow

## Acceptance Criteria (DoD)
- New widget is exported and documented
- Tests prove equivalence to manual composition (historical: not delivered;
  the widget is a composition of the two, see
  `lib/src/widgets/bloc_consumer_with_effects.dart`)
- API keeps state and effect responsibilities distinct
- Implementation does not introduce hidden coupling between rebuild logic and
  effect delivery

## Validation Commands
- `dart format .`
- `flutter analyze`
- `flutter test test/widgets/bloc_consumer_with_effects_test.dart`
- `flutter test test/widgets`

## Agent Constraints
- Prefer composition of existing primitives over a brand-new internal model
- Keep callback naming unambiguous between state and effect paths
- Do not blur state equality semantics with effect delivery semantics
