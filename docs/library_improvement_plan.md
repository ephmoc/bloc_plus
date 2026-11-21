# Library Improvement Plan

Delivery notes for the expansion items shipped in `0.2.0`, the planned next
steps, and the guardrails for future work. API names and signatures are
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

## Next

Planned, in this order. Items marked *proposed* still need a decision.

- `0.2.2` (patch, in progress): one gated CI workflow that also covers the
  lowest dependency versions and the declared minimum SDK, and contract tests
  for lifecycle, explicit-bloc and `buildWhen` paths (both on `develop`);
  fixes for errors of superseded async work, `HasEffects.close()` ordering,
  `BlocSelectorWithBloc` selection updates, the `*OrNull` lookups and
  `runLatest` cleanup; `bloc >=9.2.1`.
- `0.3.0` (minor, *proposed*): function-typed rebuild/listen conditions with
  deprecation of the policy classes, which also resolves the `whenListen` name
  clash with `bloc_test`; a typed effect listener with two type parameters;
  cancellation hooks for the async helpers and an explicit outcome instead of
  `null`.
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
