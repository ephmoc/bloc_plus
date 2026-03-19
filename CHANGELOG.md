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
