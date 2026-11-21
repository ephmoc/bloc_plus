## 0.2.2

- Flutter 3.50 compatibility and dependency refresh:
  - upgraded `flutter_lints` to `^6.0.0` (dev only); the contributor tooling
    floor is now `Dart 3.8`, which reverses the `0.2.1` cap
  - kept the package minimum SDKs unchanged at `Dart >=3.0.0` and
    `Flutter >=3.10.0`; `lib/` only depends on `package:flutter/widgets.dart`
  - tests no longer import the deprecated `package:flutter/material.dart` and
    use a `Directionality` host instead of `MaterialApp`
  - migrated the example app to `package:material_ui` (example now requires
    `Flutter >=3.47.0`)
  - excluded `build/` from analysis and moved CI actions to their Node 24
    releases
- CI runs as one gated workflow that also checks the lowest allowed dependency
  versions and the newest patch of the minimum SDK (`Flutter 3.10.6` /
  `Dart 3.0.6`).
- Added contract tests for lifecycle, explicit-bloc, `buildWhen` and policy
  composition paths of the existing APIs.
- Raised the `bloc` lower bound to `9.2.1`. On `bloc` 9.0.0-9.2.0 a `Bloc`
  reports `isClosed == false` for a few microtasks after `close()`, so
  `SafeEmitMixin.safeEmit` still emitted and `guarded` still returned results
  while it was closing.
- The async helpers drop the failure of superseded or cancelled work the same
  way they drop its result: `CancellationToken.run`, `RestartableTask.run`,
  `runLatest` and `guarded` complete with `null` instead of throwing. The
  failure of the latest run is still rethrown. `guarded` no longer starts the
  operation on a closed bloc.
- `HasEffects.close()` closes the bloc before it waits for effect subscribers,
  so a paused subscriber no longer keeps the bloc open (`isClosed` stayed
  `false`, `emit` was accepted and `BlocObserver.onClose` was not called). The
  returned future still completes only after every subscriber got the effects
  emitted before `close()`.
- `BlocSelectorWithBloc` keeps the last built selection, like `BlocSelector`.
  It recomputes the selection when the selector or the bloc changes, so a
  parent rebuild with a new selector no longer renders a stale value; it runs
  the selector once per state change instead of two or three times; and
  `selectorShouldRebuild` receives the last built selection as `previous`. The
  widget is now a `StatefulWidget`; its constructor is unchanged.
- `readOrNull`, `watchOrNull` and `selectOrNull` use provider's nullable
  lookups. They still return `null` when no provider exists, but no longer
  turn a missing dependency inside a lazily created bloc into `null`, and a
  widget that moves under a provider later picks it up instead of staying on
  `null`.

Migration impact:

- No API changes.
- Apps that pin `bloc` below `9.2.1` need to upgrade `bloc` within `9.x`.
- Code that caught the failure of a superseded or cancelled run, or of a
  `guarded` call that failed after close, now gets `null` instead.
- A `selectorShouldRebuild` callback now receives the last built selection as
  `previous` instead of the selection of the previous state.
- Code that relied on `readOrNull` / `watchOrNull` / `selectOrNull` returning
  `null` when creating the bloc failed now gets the error.

Release type rationale:

- `patch`: bug fixes with no API changes; the raised `bloc` floor only
  excludes versions with the closing-window bug.

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
