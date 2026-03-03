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
