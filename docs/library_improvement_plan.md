# Library Improvement Plan

This document captures the next proposed improvements for `bloc_plus` after the
current `v0.x` baseline.

The goal is to extend the package in ways that stay aligned with the existing
design principles:

- zero magic,
- compatibility with public `flutter_bloc` APIs,
- small and explicit abstractions,
- high-value ergonomics for day-to-day app code.

## Priorities

### 1. Composable policies and custom equality

Current gap:

- `RebuildPolicy` and `ListenPolicy` cover only `distinct`, `onChange`,
  `always`, and `never`.
- `onChange` relies on `!=`, which is often too limited for lists, maps, DTOs,
  and computed view models.

Planned additions:

- composition helpers: `and`, `or`, `not`
- custom predicate wrapper: `when`
- selector policies with explicit equality:
  - `onChangeBy(selector, equals: ...)`
  - `onChangeListenBy(selector, equals: ...)`

Why this matters:

- reduces repeated inline lambdas in widgets
- keeps rebuild/listen logic reusable and testable
- improves correctness for non-trivial selected values

### 2. Effect filtering on top of `EffectListener`

Current gap:

- `EffectListener` reacts to every emitted effect
- callers must manually filter with `if`/`switch` inside `onEffect`

Planned additions:

- effect-level predicate support
- optional typed filtering for sealed class effect hierarchies

Why this matters:

- keeps UI callbacks smaller and more focused
- improves ergonomics for apps using multiple effect variants from one bloc

### 3. `MultiEffectListener`

Current gap:

- multiple effect listeners require nested widgets

Planned additions:

- `MultiEffectListener` mirroring the ergonomics of `MultiBlocListener`

Why this matters:

- makes effect-heavy screens easier to read
- keeps package conventions aligned with `flutter_bloc`

### 4. Higher-level async helpers

Current gap:

- `RestartableTask` is useful but still low-level
- users must manually coordinate task ownership, cancellation, and result
  handling

Planned additions:

- higher-level helpers for common "latest request wins" flows
- APIs designed for direct use inside Cubits/Blocs

Why this matters:

- lowers adoption cost of the async safety module
- helps standardize safe async flows in library consumers

### 5. Combined state-and-effect consumer ergonomics

Current gap:

- state rendering and effect handling are currently composed from separate
  widgets

Planned additions:

- evaluate a `state + effect` consumer widget

Why this matters:

- could simplify common screen wiring
- should only be added if it stays explicit and does not blur state/effect
  responsibilities

## Suggested rollout order

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

## Guardrails

The following remain out of scope unless product direction changes:

- replacing `flutter_bloc`
- event bus patterns
- framework-specific code generation
- APIs that depend on non-public `flutter_bloc` internals
- abstractions that hide provider lookup or effect delivery semantics

## Release planning notes

- Policy composition and effect filtering fit a `minor` release because they add
  public API without breaking existing behavior.
- `MultiEffectListener` also fits a `minor` release.
- Higher-level async helpers should be added only with strong lifecycle tests.
- A combined state-and-effect consumer should be treated as optional until the
  API proves simpler than plain composition.
