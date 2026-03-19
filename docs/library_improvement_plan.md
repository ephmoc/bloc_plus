# Library Improvement Plan

This document captures the expansion items delivered after the initial `v0.x`
baseline.

The goal is to extend the package in ways that stay aligned with the existing
design principles:

- zero magic,
- compatibility with public `flutter_bloc` APIs,
- small and explicit abstractions,
- high-value ergonomics for day-to-day app code.

## Delivered areas

### 1. Composable policies and custom equality

Previous gap:

- `RebuildPolicy` and `ListenPolicy` cover only `distinct`, `onChange`,
  `always`, and `never`.
- `onChange` relies on `!=`, which is often too limited for lists, maps, DTOs,
  and computed view models.

Delivered additions:

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

- higher-level helpers for common "latest request wins" flows
- APIs designed for direct use inside Cubits/Blocs

Why this matters:

- lowers adoption cost of the async safety module
- helps standardize safe async flows in library consumers

### 5. Combined state-and-effect consumer ergonomics

Previous gap:

- state rendering and effect handling are currently composed from separate
  widgets

Delivered additions:

- `BlocConsumerWithEffects`

Why this matters:

- could simplify common screen wiring
- should only be added if it stays explicit and does not blur state/effect
  responsibilities

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

## Guardrails

The following remain out of scope unless product direction changes:

- replacing `flutter_bloc`
- event bus patterns
- framework-specific code generation
- APIs that depend on non-public `flutter_bloc` internals
- abstractions that hide provider lookup or effect delivery semantics

## Release notes

- Policy composition and effect filtering shipped as additive APIs.
- `MultiEffectListener` shipped as a composition convenience.
- Higher-level async helpers shipped with lifecycle and cancellation coverage.
- The combined state-and-effect consumer shipped as a thin composition of
  existing primitives rather than a new runtime model.
