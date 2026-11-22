## 0.3.1

- Added:
  - `debugPrintUnheardEffects`: set it to `true` and `emitEffect` prints a
    warning in debug builds for an effect that nothing listens to. Effects
    are not replayed, so such an effect is lost, for example one emitted from
    the bloc's constructor or before the listening widget is mounted. Off by
    default; release builds never print it.
  - README: a recipe for testing effects in unit and widget tests.

Migration impact:

- None.

Release type rationale:

- `patch`: one additive, opt-in debug flag (a new public top-level variable)
  and docs; nothing changes unless the flag is set. Under the 0.x convention
  `^0.3.0` already allows it; code that uses the flag needs `^0.3.1`.

## 0.3.0

- Added:
  - `BlocCondition<S>` and `whenChanged(selector, {equals})`. The result goes
    straight into `buildWhen`, `listenWhen` and `selectorShouldRebuild`, also
    on `BlocBuilder`, `BlocListener` and `BlocConsumer`, without type
    arguments when the widget has its own. Select a record for several
    fields; pass `equals:` for collections.
  - `BlocEffectListener<B extends EffectsSource<E>, E>`: a wrong effect type
    or a bloc without effects no longer compiles, and the listener composes
    inside `MultiBlocListener`.
  - `RestartableTask.runOutcome` and `RestartableTasksMixin.runLatestOutcome`:
    the task gets a `CancellationToken`, and the `TaskOutcome<T>` result tells
    a cancelled run apart from one that completed with `null`.
    `CancellationToken.whenCancelled` can abort the underlying I/O.
  - `BlocConsumerWithEffects.listener` is optional.
  - A `const` constructor for `BlocListenerWithBloc`.
- Changed:
  - A cancelled, superseded or closed run releases its caller at once (`null`
    or `TaskOutcome.cancelled()`) instead of waiting for the abandoned work,
    which keeps running. This fixes callers that hung on work that never
    completes.
  - `BlocConsumerWithEffects` requires `B extends HasEffects<S, E>`.
  - The `*WithBloc` widgets and their callback typedefs accept
    `B extends StateStreamable<S>`, like flutter_bloc's widgets.
    `readOrNull`, `watchOrNull` and `withBloc` accept any provided type, such
    as a repository: `withBloc((Repo repo) => ...)` now finds the repository
    instead of inferring `Never` and returning `null`. `selectOrNull` accepts
    any `StateStreamableSource<S>`, the type `BlocProvider` provides and
    keeps up to date.
  - `BlocConsumerWithBloc` and `BlocConsumerWithEffects` resolve the bloc once
    per build, so states, effects and every callback come from one instance,
    also right after `bloc:` changes from an instance to `null`.
  - `emitEffect` and `safeEmit` are `@protected` and `@visibleForTesting`,
    like `emit`.
  - New direct dependency: `provider` `>=6.0.0 <7.0.0`, the range
    `flutter_bloc` already requires.
- Deprecated, removed in 1.0: `RebuildPolicy`, `ListenPolicy` and their 12
  factories (including `whenListen`, which clashes with `bloc_test`),
  `EffectListener`, `MultiEffectListener` and `SingleChildEffectListener`.

Migration impact:

- Deprecated APIs keep working; each use is a `deprecated_member_use` info,
  which fails `flutter analyze` until migrated:
  - `onChange(sel)` / `onChangeListen(sel)` -> `whenChanged(sel)`, keeping
    `<S, T>` when the widget has no type arguments; the `...By`
    forms -> `whenChanged(sel, equals: eq)`; `whenRebuild(p)` /
    `whenListen(p)` -> `p`; `always()` -> omit the parameter; `never()` ->
    `(previous, current) => false`; `distinct()` ->
    `(previous, current) => previous != current` (omitting the parameter
    differs only for a first emitted state equal to the initial one);
    `a.and(b)` -> a plain predicate or a record selector.
  - `EffectListener<B, S, E>` -> `BlocEffectListener<B, E>`;
    `MultiEffectListener` -> `MultiBlocListener`, which needs a non-empty
    list; a listener for one effect subtype -> the supertype with
    `if (effect case Sub(...))` in `onEffect`.
  - With `bloc_test`, import `bloc_plus` with `hide whenListen` until 1.0.
- `BlocConsumerWithEffects` no longer compiles with a bloc that implements
  `EffectsSource` by hand: mix in `HasEffects<S, E>`.
- `emitEffect` and `safeEmit` called from outside the bloc, extension methods
  on it included, now warn (tests are exempt): move the call into the bloc or
  into a `mixin X on HasEffects<S, E>`.
- Code after the `await` of a superseded run, a `finally` included, now runs
  while the newer run is in flight: check the outcome before resetting a
  shared loading flag.
- In a `Bloc` handler, a task that calls the handler's `emit` still needs an
  `emit.isDone` (or `token.isCancelled`) check: the handler now completes
  first, and bloc rejects the late `emit` only with an assert, so release
  builds emit the stale state.
- Write both type arguments of `BlocEffectListener`: below language version
  3.7, `E` is not inferred from `bloc:`.
- After `bloc:` of `BlocConsumerWithBloc` or `BlocConsumerWithEffects` changes
  from an instance to `null`, the widget follows the provided bloc at once
  instead of the previous instance. `BlocBuilderWithBloc` and
  `BlocListenerWithBloc` keep the previous instance, like `BlocBuilder` and
  `BlocListener`, while their callback gets the provided one: give them a new
  `key` when you switch.

Release type rationale:

- `minor`: new APIs, wider type bounds and deprecations; the narrower consumer
  bound, the new analyzer warnings, the earlier release of superseded callers
  and the consumers following the provided bloc are behaviour changes that a
  0.x minor allows.

## 0.2.2

- Fixes:
  - `CancellationToken.run`, `RestartableTask.run`, `runLatest` and `guarded`
    drop the failure of superseded or cancelled work like its result; only
    the latest run can throw. `guarded` no longer starts on a closed bloc.
  - `HasEffects.close()` no longer waits for a paused effect subscriber
    before closing the bloc.
  - `BlocSelectorWithBloc` behaves like `BlocSelector`: no stale value after
    the selector changes, one selector call per state change, and
    `selectorShouldRebuild` gets the last built value as `previous`.
  - `readOrNull`, `watchOrNull` and `selectOrNull` return `null` only when no
    provider exists.
  - `runLatest` drops the keys of failed tasks; a repeated `close()` waits for
    the first one.
  - `bloc` lower bound raised to `9.2.1`, so `safeEmit` and `guarded` also
    stop on a closing `Bloc`.
- Tooling: Flutter 3.50 support (`flutter_lints` `^6.0.0`, contributors need
  Dart 3.8; example app on `material_ui`, Flutter >=3.47), one gated CI
  workflow that also checks the lowest dependency versions and Flutter
  3.10.6, contract tests and clearer API docs. Package minimums stay at
  Dart 3.0 and Flutter 3.10.

Migration impact:

- No API changes; if you pin `bloc` below `9.2.1`, upgrade within `9.x`.
- Superseded or cancelled runs, and `guarded` calls that fail after close,
  return `null` instead of throwing.
- Effects emitted right before `close()` reach subscribers after the bloc is
  closed, like its last states; a subscriber that emits into the bloc in
  response should use `safeEmit`.
- `selectorShouldRebuild` gets the last built value as `previous`;
  `BlocSelectorWithBloc` is now a `StatefulWidget`.
- A missing provider read inside a bloc's `create` now throws from
  `readOrNull` / `watchOrNull` / `selectOrNull` instead of returning `null`.

Release type rationale:

- `patch`: bug fixes without API changes.

## 0.2.1

- Compatibility metadata update:
  - lowered the developer tooling floor from `Dart 3.8` to `Dart 3.0` by
    constraining `flutter_lints` to the latest line that still supports Dart 3.0
  - kept the package minimum SDKs unchanged at `Dart >=3.0.0` and
    `Flutter >=3.10.0`

Migration impact:

- No API changes. No migration required.

Release type rationale:

- `patch` change for compatibility metadata and tooling support only.

## 0.2.0

- Added policy composition and custom equality helpers:
  - `whenRebuild`
  - `whenListen`
  - `RebuildPolicy.and`, `RebuildPolicy.or`, `RebuildPolicy.not`
  - `ListenPolicy.and`, `ListenPolicy.or`, `ListenPolicy.not`
  - `onChangeBy`
  - `onChangeListenBy`
- Expanded effect ergonomics:
  - added `effectWhen` to `EffectListener`
  - added `MultiEffectListener`
- Added higher-level async helpers:
  - `RestartableTasksMixin`
  - keyed `runLatest`, `cancelLatest`, `cancelAllLatest`, `isTaskRunning`
- Added `BlocConsumerWithEffects` for combined state and effect composition.
- Updated README, PRD, task specs, and example app to document the new APIs.

Migration impact:

- No breaking API changes. Existing code continues to work.
- Consumers can adopt the new APIs incrementally.

Release type rationale:

- `minor` bump for new public API surface additions.

## 0.1.3

- Documentation improvements:
  - Added dartdoc comments for the public API to improve generated package
    docs and pub.dev documentation coverage.

Migration impact:

- No API changes. No migration required.

Release type rationale:

- `patch` bump for user-visible documentation improvements with no behavior
  changes.

## 0.1.2

- Documentation cleanup:
  - Removed the two trailing README sections: `Status` and
    `Release process (without verified publisher)`.
- Change category:
  - `chore`

Migration impact:

- No API changes. No migration required.

Release type rationale:

- `patch` bump for documentation-only cleanup.

## 0.1.1

- CI improvements:
  - Added dedicated coverage workflow with Codecov upload.
  - Coverage upload now supports `CODECOV_TOKEN` via GitHub Actions secret.
- Release process improvements:
  - Added PR quality and release automation workflows.
  - Added manual publish workflow for non-verified publisher setup.
- Documentation improvements:
  - Added status badges to README.
  - Clarified release flow and publish steps.

Migration impact:

- No API changes. No migration required.

Release type rationale:

- `patch` bump for CI, release automation, and documentation improvements.

## 0.1.0

- Added `ui_with_bloc` module:
  - `BlocBuilderWithBloc`
  - `BlocListenerWithBloc`
  - `BlocConsumerWithBloc`
  - `BlocSelectorWithBloc`
- Added `context_extensions` module:
  - `readOrNull`
  - `watchOrNull`
  - `selectOrNull`
  - `withBloc`
- Added `policies` module:
  - Rebuild policies: `distinct`, `onChange`, `always`, `never`
  - Listen policies: `distinctListen`, `onChangeListen`, `alwaysListen`, `neverListen`
- Added `async_safety` module:
  - `SafeEmitMixin`
  - `CancellationToken`
  - `RestartableTask`
- Added `effects` module:
  - `HasEffects`
  - `EffectListener`

Migration impact:

- First feature release, no migration required.

Release type rationale:

- `minor` bump due to new public API surface additions.
