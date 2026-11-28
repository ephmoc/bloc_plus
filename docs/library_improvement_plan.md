# Library Improvement Plan

Delivery notes for `0.2.0`, `0.2.2`, `0.3.0`, `0.3.1` and `0.4.0`, the planned
next steps, and the guardrails for future work. For delivered items, API names
and signatures are defined by the code and its API docs, and per-version
changes by `CHANGELOG.md`; where this file disagrees with them, they win.
"Next" describes changes that are not in the code yet.

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

## Delivered in 0.3.1

Released 2026-11-22 (patch): a recipe for testing effects and the opt-in
`debugPrintUnheardEffects` warning for effects that nothing listens to.
`dart fix` data for the 0.3.0 deprecations was dropped: the policy factories
cannot be described, and renaming `EffectListener<B, S, E>` to
`BlocEffectListener` keeps the extra type argument, so the result does not
compile.

## Delivered in 0.4.0

Released 2026-11-27 (minor). It made every change of shape that 1.0 freezes
and deprecated the rest of what 1.0 removes, so that 1.0 itself only removes
what is deprecated as of 0.4.0. Details and migration notes are in
`CHANGELOG.md`.

- changed: `runLatest`, `guarded` and `CancellationToken.run` take a
  non-null `T` only, and with `runLatestOutcome` and
  `RestartableTask.runOutcome` they are `@useResult` (`meta` became a direct
  dependency); `SafeEmitMixin` is declared `on Cubit<S>`;
  `BlocBuilderWithBloc` and `BlocListenerWithBloc` return the upstream
  widgets and follow the provided bloc after `bloc:` becomes `null`, and the
  listener without a `child`, outside a multi widget, renders
  `SizedBox.shrink()` with every supported `flutter_bloc`;
  `CancellationToken` and `RestartableTask` are `final` classes;
  `isTaskRunning`, `runLatest`, `runLatestOutcome`, `cancelLatest`,
  `cancelAllLatest` and `guarded` are `@protected` and `@visibleForTesting`;
- fixed: a failure that arrives just before a run is cancelled or superseded
  or its bloc is closed, while the caller has not resumed yet, is dropped
  like a value; `guarded` drops a synchronous throw of the operation, and the
  value of a future that calls back synchronously, when `close()` is called
  in the same turn; `BlocSelectorWithBloc` follows a replaced provided bloc
  also when its element was already dirty;
- deprecated, removed in 1.0: `BlocContextExtension` with its four
  `BuildContext` helpers, `effectWhen` with `EffectCondition`,
  `RestartableTask.run`, `BlocEffectListener.withChild` and the typedefs
  `BlocEffectListenerWithBloc` and `BlocSelectedCondition`;
- docs: the README leads with the async helpers for Cubits and the effects,
  and adds a table of which helper to use, recipes, "Compared with" and
  "Versioning"; the example models its effects as `sealed` classes; the PRD
  and the task specs follow the code.

## Next

First planned on 2026-11-23, after two reviews: one of the 1.0 scope, one of
the direction of the changes and of what each API is worth to an app.

The second review found that the async helpers for Cubits and the effects
carry the package, that the `BuildContext` helpers repeat what provider
documents, and that some signatures can only be tightened before a freeze.
So 0.4.0 tightened the API and deprecated more of it for 1.0 to remove, and
1.0 follows no earlier than four weeks after it was published.

### 1.0.0 (major)

Released when both conditions hold:

- at least four weeks have passed since 0.4.0 was published. A 0.4.x release
  that changes code under `lib/` (anything but comments) restarts them, a bug
  fix included, and so does one that changes a constraint under
  `dependencies` or `environment` in `pubspec.yaml`; a release that changes
  only documentation, the example or tests does not, and the other
  `pubspec.yaml` fields, `dev_dependencies` included, count as documentation.
  A change of `lib/` that 1.0.0 would publish for the first time is released
  in a 0.4.x first: `lib/` of 1.0.0 differs from the last published 0.4.x
  only by the removals below;
- no change is open that would need a major under "Versioning from 1.0"
  below: none is planned in this file, and none is asked for in an open issue
  or pull request of the repository.

Such a change is released in 0.5.0 first, and then this section reads 0.5
wherever it says 0.4: the four weeks count from the publication of 0.5.0. A
change that only adds API comes in a 0.4.x patch, which restarts the four
weeks as any change of `lib/` does, or in a 1.x minor.

Before the release, upstream is checked once more for a built-in cancelable
API (bloc issue 3069, open since 2021) and for a new major of a dependency.
Either would change what 1.0 freezes: if one exists, 1.0 waits until this
section says what it changes.

There is no `-dev` prerelease: releases are cut from `main`, so a prerelease
there would close the 0.4.x line for fixes. 1.0.0 closes it for the same
reason: no 0.4.x fix is published after it. The removals wait on their own
branch, open as a draft pull request into `develop` so that CI runs on them
and updated after every 0.4.x release. They are merged into `develop` only
for the release.

- Remove everything deprecated: `RebuildPolicy`, `ListenPolicy` and their 12
  factories; `EffectListener`, `MultiEffectListener` and
  `SingleChildEffectListener`; `BlocEffectListener.withChild`; `effectWhen`
  and `EffectCondition`; the extension `BlocContextExtension` with
  `readOrNull`, `watchOrNull`, `selectOrNull` and `withBloc`;
  `RestartableTask.run`; the typedefs `BlocEffectListenerWithBloc` and
  `BlocSelectedCondition`.
- The `context_extensions` module then has no API: its export, its PRD
  section and its task spec go, and AGENTS.md section 4 drops it from the
  module sequence. `docs/tasks/effect_filtering.md`,
  `docs/tasks/multi_effect_listener.md` and `docs/tasks/policy_composition.md`
  describe only removed API and go as well, with their entries under "Related
  task specs" above. `docs/tasks/policies.md` keeps only `BlocCondition` and
  `whenChanged`: the `policies` module stays.
- Nothing else changes: the bounds, the class modifiers and the widget types
  are those of 0.4.0. The mixins stay plain mixins. The widgets are not marked
  `final`, but subclassing them is outside the versioning policy. The minimum
  SDK stays at Dart 3.0 / Flutter 3.10.
- The dartdoc that still mentions a removed name is corrected in the same
  change, because no CI gate reports it: `effectWhen` in
  `BlocEffectListener.onEffect` and "complete with `null` or" in
  `RestartableTask.dispose`. `dart doc --dry-run` prints no warning. The two
  `ignore_for_file: deprecated_member_use_from_same_package` headers go with
  their comments (`bloc_effect_listener.dart`,
  `bloc_consumer_with_effects.dart`): the analyzer does not report an ignore
  that has become unnecessary.
- Migration notes: "upgrade to 0.4.0 and clear every warning first, then
  search for the removed names and compile", because clean 0.4.0 code can
  still name them. A name that 1.0 removes has to be deleted from the `hide`
  list of an import, where it becomes an `undefined_hidden_name` warning (the
  code still compiles). The usual case is the `hide whenListen` that the
  README asked for next to `bloc_test`. The analyzer also does not report a
  deprecated use inside the app's own `@Deprecated` declarations, under an
  ignore comment, where `analysis_options.yaml` turns `deprecated_member_use`
  off, in files excluded from analysis, or through a `dynamic` receiver,
  which fails only at run time. A short "Upgrading from 0.x" section of the
  README gathers every replacement, because a constraint such as `^0.2.0` or
  `^0.3.1` does not admit 0.4.0: such a project never saw all of the
  deprecation warnings. The replacements stand today in two README tables
  (under "Effects" and "Conditions"), in two README paragraphs
  (`RestartableTask.run` under "Async helpers for Cubits", the lookups under
  "Optional lookups"), in the CHANGELOG of 0.4.0 (`BlocSelectedCondition`
  and `BlocEffectListenerWithBloc`) and, for `SingleChildEffectListener`,
  only in its deprecation message (`BlocEffectListener`, a
  `SingleChildWidget` inside `MultiBlocListener`). The install snippet
  reads `^1.0.0`.
- The API freeze table in the PRD and the task specs are updated. The
  statements that speak of 1.0 as coming are removed or reworded in the
  README (the list of deprecated APIs, the notes "removed in 1.0", the
  `hide whenListen` paragraph, the introduction of "Versioning"), in the PRD
  (the API freeze table with its heading "v0.x scope", the entry
  "v1.0.0 - API Freeze", the version it says it describes) and in the task
  specs that stay.

### Versioning from 1.0

Published in the README:

- the public API is everything exported from
  `package:bloc_plus/bloc_plus.dart`;
- a major version is needed to remove or rename an export, to change a
  signature incompatibly, to change the superclass of a widget, to change
  documented behaviour, or to add an annotation that makes the analyzer
  report code that was clean before, such as `@protected`. `@Deprecated` is
  the exception (next item);
- a minor version may add exports, members and optional parameters, support a
  new major of a dependency when no signature here changes, raise the minimum
  Dart or Flutter SDK or the minimum version of a dependency (a new major
  included), and deprecate an API, which is then removed no earlier than the
  next major;
- not covered: classes that `implement` this package's classes or mixins by
  hand (`EffectsSource` is the exception, and gets no new member without a
  major), subclasses of its classes and widgets, and overriding members of
  its widgets. Applying the mixins with `with`, or building on them with
  `mixin X on ...`, is covered. Where a widget is documented as a
  `flutter_bloc` widget with something added, the rest of its behaviour is
  that of the `flutter_bloc` version the app resolves; a change there is not
  a change of this package;
- a member added in a minor may clash with a member of the same name in a
  class that applies a mixin or extends a class of this package, and an
  optional parameter added to a method of a mixin breaks an override of that
  method. Neither is treated as a breaking change.

### Reviewed and kept

The second review proposed to cut or reshape these as well. Each one stays as
it is, for a reason that a replacement would have to match:

- `guarded` makes the closed check part of the type. Its result is `T?`, so
  where the result is used as a non-null value (an exhaustive `switch` over a
  sealed result, `.match` on an `Either`, a member, a non-nullable parameter)
  a forgotten check is a compile error; an `else`, a `default` branch or `?.`
  still compiles, which the dartdoc warns about. The manual
  `final r = await op(); if (isClosed) return;` compiles without its check
  and then throws or runs on after `close()`. `guarded` also does not start
  the operation on a closed cubit and drops a failure that arrives after
  `close()`. The first has a one-line manual replacement; the second is one
  line in a `catch` that exists and a `try`/`catch` around the `await`
  otherwise. It is for work with a non-null result: void work keeps the
  manual guard.
- `BlocConsumerWithEffects` resolves the bloc once for the builder, the
  listener and the effects. In the composed form a `bloc:` that is forgotten
  on one of the widgets makes that widget look the bloc up: it listens to the
  provided instance without an error, or throws `ProviderNotFoundException`
  when none is provided.
- The `*WithBloc` widgets hand the callback the bloc that the widget listens
  to. With an explicit `bloc:` that is not the provided one,
  `context.read<B>()` in the callback throws or returns another instance.
- `BlocSelectorWithBloc.selectorShouldRebuild` is a custom comparison with
  the value that is shown. `BlocSelector` compares with `!=` only, and
  `buildWhen` compares with the previous state, whether it was built or not.
- `CancellationToken` keeps its constructor, `cancel()` and `run`: tests need
  a real token, and one token can cover several operations that run in
  parallel. `RestartableTask` stays public, as the engine of the mixin and
  for "latest wins" outside a bloc. Its `run` is removed because the bound
  `T extends Object` cannot go on the class; an extension with that bound
  can bring `run` back for a non-null `T` in a 1.x minor, and resolves only
  once the member is gone.
- `TaskOutcome` stays a `final class` with `isCompleted` and `value`. A
  sealed pair of subclasses can be added in a 1.x minor without breaking it.
  It does not make the compiler force the check, because `value` stays on
  the base type: it offers a checked path, a `switch` over the two subtypes.
  Forcing the check needs a major.
- `BlocEffectListener.onEffect` stays `(context, effect)`, although
  `BlocConsumerWithEffects` hands the bloc to its callbacks. A third argument
  would let `E` be inferred from `bloc:` in code at language version 3.7 or
  later, but it would change every existing listener, and the case it helps
  is an explicit `bloc:` without type arguments. A listener that hands over
  the bloc can be added in a 1.x minor.

### Dropped from the plan

- Reshaping `selectOrNull` into a nullable twin of provider's `select`: the
  helpers are deprecated instead.
- Repairing the builder and the listener by overriding `createState()`: about
  126 lines of copied subscription lifecycle, against a composition of the
  upstream widgets that needs none.
- `@sealed` as a step before `final class`.
- A selector-based listener: `listenWhen: whenChanged(...)` covers it.
- More async modes for Cubits: no new API. "Ignore while running" is one
  line with `isTaskRunning` (the README recipe in 0.4.0), and
  `bloc_concurrency` covers a `Bloc`. A queue per key is not planned; if it is
  ever needed, it comes as a separate mixin in a 1.x minor.
- Renaming the `BlocEffectListenerWithBloc` typedef: it is deprecated
  instead, and 1.0 removes it.
- Raising the minimum SDK to Dart 3.7: type inference depends on the language
  version of the app, so the package gains nothing.
- Replaying or buffering an effect for a listener that subscribes later: an
  effect that nothing listens to stays lost, as the README and the dartdoc of
  `emitEffect` say. If replay is ever needed, it comes as a separate mixin in
  a 1.x minor.
- A trial migration of an existing application (planned on 2026-11-23,
  dropped on 2026-11-25): the work stays on the library.

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
