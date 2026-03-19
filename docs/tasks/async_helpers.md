# Task Spec - async_helpers

## Preconditions
- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- Baseline `async_safety` module is already implemented and exported
- If scaffold is missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope
- Add higher-level async helpers on top of `RestartableTask`
- Provide a lifecycle-aware API for "latest request wins" flows inside
  Cubits/Blocs
- Ensure helper-managed tasks are cancelled or invalidated when the owner is
  closed or disposed

## Out Of Scope
- Hard cancellation of arbitrary `Future` work
- Background executors, isolates, or schedulers
- Debounce/throttle timing APIs unrelated to cooperative cancellation

## Public Contract
- New helpers are built on cooperative cancellation semantics
- Starting a new run for the same logical task invalidates the previous result
- Distinct logical task keys remain independent
- Owner disposal prevents future task completion from surfacing results
- No helper may imply that the underlying `Future` is forcefully interrupted

## Target Files
- `lib/src/async/restartable_tasks_mixin.dart`
- `lib/src/async/async.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)
- `test/async/restartable_tasks_mixin_test.dart`

Required cases:
- repeated runs for the same key drop stale results
- different keys run independently
- cancellation for one key does not affect other keys
- close/dispose invalidates all tracked task results
- new runs after disposal are ignored
- helper behavior remains compatible with `SafeEmitMixin` usage

## Example App Updates
- Add one search-like example using the higher-level helper instead of managing
  `RestartableTask` manually

## Acceptance Criteria (DoD)
- New helper APIs are exported and documented with cooperative cancellation
  wording
- Tests cover lifecycle, cancellation, and multi-key behavior
- Implementation does not leak task tracking state after close/dispose
- No additional dependencies are introduced

## Validation Commands
- `dart format .`
- `flutter analyze`
- `flutter test test/async/restartable_tasks_mixin_test.dart`
- `flutter test test/async`

## Agent Constraints
- Keep the API explicit and lightweight
- Prefer a small surface area over a general-purpose task framework
- Document clearly that cancellation suppresses results and does not interrupt
  underlying work
