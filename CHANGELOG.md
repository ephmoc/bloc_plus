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
