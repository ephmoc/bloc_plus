# Library Improvement Plan

Delivery notes for `0.2.0`, `0.2.2` and `0.3.0`, the planned next steps, and
the guardrails for future work. API names and signatures are
defined by the code and its API docs, and per-version changes by
`CHANGELOG.md`; where this file disagrees with them, they win.

The goal is to extend the package in ways that stay aligned with the existing
design principles:

- zero magic,
- compatibility with public `flutter_bloc` APIs,
- small and explicit abstractions,
- high-value ergonomics for day-to-day app code.

## Delivered in 0.2.0

### 1. Composable policies and custom equality

Previous gap:

- `RebuildPolicy` and `ListenPolicy` cover only `distinct`, `onChange`,
  `always`, and `never`.
- `onChange` relies on `!=`, which is often too limited for lists, maps, DTOs,
  and computed view models.

Delivered additions:

- composition helpers: `and`, `or`, `not`
- custom predicate wrappers: `whenRebuild(predicate)` and
  `whenListen(predicate)`
- selector policies with explicit equality:
  - `onChangeBy(selector, equals: ...)`
  - `onChangeListenBy(selector, equals: ...)`

Why this matters:

- reduces repeated inline lambdas in widgets
- keeps rebuild/listen logic reusable and testable
- improves correctness for non-trivial selected values

### 2. Effect filtering on top of `EffectListener`

Previous gap:

- `EffectListener` reacts to every emitted effect
- callers must manually filter with `if`/`switch` inside `onEffect`

Delivered additions:

- effect-level predicate support via `effectWhen`

Why this matters:

- keeps UI callbacks smaller and more focused
- improves ergonomics for apps using multiple effect variants from one bloc

### 3. `MultiEffectListener`

Previous gap:

- multiple effect listeners require nested widgets

Delivered additions:

- `MultiEffectListener` mirroring the ergonomics of `MultiBlocListener`

Why this matters:

- makes effect-heavy screens easier to read
- keeps package conventions aligned with `flutter_bloc`

### 4. Higher-level async helpers

Previous gap:

- `RestartableTask` is useful but still low-level
- users must manually coordinate task ownership, cancellation, and result
  handling

Delivered additions:

- `RestartableTasksMixin` with keyed `runLatest`, `cancelLatest`,
  `cancelAllLatest`, and `isTaskRunning` for "latest request wins" flows
- pending tasks are cancelled when the bloc closes
- designed for direct use inside Cubits; inside Bloc event handlers, prefer the
  handler's `emit` and `bloc_concurrency` transformers

Why this matters:

- lowers adoption cost of the async safety module
- helps standardize safe async flows in library consumers

### 5. Combined state-and-effect consumer ergonomics

Previous gap:

- state rendering and effect handling are composed from separate widgets

Delivered additions:

- `BlocConsumerWithEffects`, a thin composition of `EffectListener` and
  `BlocConsumerWithBloc`

Why this matters:

- simplifies common screen wiring
- stays explicit: state and effects keep separate callbacks and conditions

## Delivered rollout order

1. Composable policies and custom equality
2. Effect filtering
3. `MultiEffectListener`
4. Higher-level async helpers
5. Combined state-and-effect consumer

Related task specs:

- `docs/tasks/policy_composition.md`
- `docs/tasks/effect_filtering.md`
- `docs/tasks/multi_effect_listener.md`
- `docs/tasks/async_helpers.md`
- `docs/tasks/state_effect_consumer.md`

## Delivered in 0.2.2

Fixes for superseded async work, `HasEffects.close()` ordering,
`BlocSelectorWithBloc` selection updates, the `*OrNull` lookups and
`runLatest` cleanup; `bloc >=9.2.1`; one gated CI workflow that also covers the
lowest dependency versions and the minimum SDK; contract tests; releases
published from tags through OIDC. Details are in `CHANGELOG.md`.

## Delivered in 0.3.0

Released 2026-11-22 (minor). Details and migration notes are in
`CHANGELOG.md`.

- conditions: `BlocCondition` and `whenChanged`; `RebuildPolicy`,
  `ListenPolicy` and their 12 factories deprecated, which also retires the
  `whenListen` name that clashes with `bloc_test`. No `and` / `or` / `not` on
  the function type: an untyped lambda as their receiver would compile as
  `dynamic`, so typos would only fail at run time;
- effects: `BlocEffectListener<B extends EffectsSource<E>, E>` as a
  `SingleChildWidget` that composes inside `MultiBlocListener` (direct
  dependency on `provider`, the range `flutter_bloc` requires);
  `EffectListener`, `MultiEffectListener` and `SingleChildEffectListener`
  deprecated; `BlocConsumerWithEffects` bound to `HasEffects<S, E>` with an
  optional `listener`;
- async: `TaskOutcome`, `runOutcome` / `runLatestOutcome` passing a
  `CancellationToken` to the task, `whenCancelled`, and callers released as
  soon as their run is cancelled;
- `@protected` and `@visibleForTesting` on `emitEffect` and `safeEmit`;
- `StateStreamable<S>` bounds on the widgets, `Object` bounds on
  `readOrNull`, `watchOrNull` and `withBloc` (`StateStreamableSource<S>` on
  `selectOrNull`), a `const` `BlocListenerWithBloc` constructor, and one bloc
  instance per `build` in the consumers;
- the PRD and task specs brought in line with the code.

## Next

Planned, in this order. Items marked *proposed* still need a decision.

- `0.3.1` (patch, decided 2026-11-22, on `develop`, not yet released): a
  recipe for testing effects and the opt-in `debugPrintUnheardEffects` warning
  for effects that nothing listens to. `dart fix` data for the 0.3.0
  deprecations was dropped: the policy factories cannot be described, and
  renaming `EffectListener<B, S, E>` to `BlocEffectListener` keeps the extra
  type argument, so the result does not compile.
- Later 0.x (*proposed*): a selector-based listener and more async modes
  (ignore while running, a queue per key); renaming the
  `BlocEffectListenerWithBloc` typedef, which reads like a widget.
- `1.0` (*proposed*): remove deprecated APIs, add class modifiers, freeze the
  public API.

## Guardrails

The following remain out of scope unless product direction changes:

- replacing `flutter_bloc`
- event bus patterns
- framework-specific code generation
- APIs that depend on non-public `flutter_bloc` internals
- abstractions that hide provider lookup or effect delivery semantics
- more `*WithBloc` widget variants or a `MultiBlocBuilder`
- more `BuildContext` lookup helpers (provider already supports nullable
  lookups such as `context.read<T?>()`)
- more policy combinators
- event transformers for `Bloc` (covered by `bloc_concurrency`)
- general-purpose cancellation tokens (timeouts, merging) or structured
  concurrency
- a custom analyzer plugin or a DevTools extension

## Release notes (0.2.0)

- Policy composition and effect filtering shipped as additive APIs.
- `MultiEffectListener` shipped as a composition convenience.
- Higher-level async helpers shipped with lifecycle and cancellation tests.
- The combined state-and-effect consumer shipped as a thin composition of
  existing primitives rather than a new runtime model.
