# Task Spec - async_safety

> Status: delivered in 0.1.0. 0.2.2 drops the failure of cancelled work like
> its result. 0.3.0 adds `CancellationToken.whenCancelled`,
> `RestartableTask.runOutcome` and `TaskOutcome<T>`, makes `safeEmit`
> `@protected` and `@visibleForTesting`, and releases a cancelled or
> superseded caller at once instead of waiting for the abandoned work, which
> keeps running. 0.4.0 makes `CancellationToken` and `RestartableTask`
> `final` classes, and `guarded` and `CancellationToken.run` take a non-null
> `T` only (`T extends Object`).

## Preconditions
- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- If missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope
- Implement `SafeEmitMixin<S>` on `BlocBase<S>`
  - `safeEmit(S state)` (`@protected`, `@visibleForTesting` since 0.3.0)
  - `guarded<T extends Object>(Future<T> Function() operation)` (bound since
    0.4.0)
- Implement `CancellationToken`, a `final class` since 0.4.0: `isCancelled`,
  `whenCancelled` (0.3.0), `cancel()`,
  `run<T extends Object>(Future<T> Function() task)` (bound since 0.4.0)
- Implement `RestartableTask<T>`, a `final class` since 0.4.0: `isRunning`,
  `run(Future<T> Function() task)`,
  `runOutcome(Future<T> Function(CancellationToken token) task)` returning
  `Future<TaskOutcome<T>>` (0.3.0), `cancel()`, `dispose()`
- `TaskOutcome<T>` (0.3.0): `completed(value)` / `cancelled()`, `isCompleted`,
  `value` (throws `StateError` when cancelled)

## Out Of Scope
- Hard cancellation of arbitrary `Future` work
- External task schedulers or isolates

## Public Contract
- `safeEmit` performs no-op when bloc is closed
- `guarded` returns `null` when bloc is closed before completion; it does not
  start on a closed bloc, and a failure after close is dropped (0.2.2)
- `CancellationToken.cancel()` is one-way and idempotent
- `CancellationToken.run` is cooperative: it does not interrupt running task, only suppresses result;
  since 0.3.0 it completes with `null` as soon as the token is cancelled
- `guarded` and `CancellationToken.run` reject a `void`, nullable or
  `dynamic` result at compile time (0.4.0), so `null` only means discarded
- `RestartableTask.run` invalidates previous in-flight result and releases its
  caller at once; only the latest run's failure is rethrown
- `RestartableTask.dispose` prevents future runs and cancels current token/result flow

## Target Files
- `lib/src/async/safe_emit_mixin.dart`
- `lib/src/async/cancellation_token.dart`
- `lib/src/async/restartable_task.dart`
- `lib/src/async/task_outcome.dart` (0.3.0)
- `lib/src/async/async.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)
- `test/async/safe_emit_mixin_test.dart`
- `test/async/cancellation_token_test.dart`
- `test/async/restartable_task_test.dart`
- `test/async/run_outcome_test.dart`, `test/async/task_outcome_test.dart` (0.3.0)
- `test/async/final_classes_test.dart`, `test/async/object_bound_test.dart`
  (0.4.0: compile-time contracts, checked with the analyzer)

Required cases:
- safe emit after close does not throw
- guarded returns value when open, `null` when closed
- token cancel state transitions
- token run returns `null` when cancelled before completion
- restartable task drops stale result from previous run
- dispose blocks new runs and cleans active flow

## Example App Updates
- Historical: the example app at 0.3.0 has no direct `RestartableTask`,
  debounce or close/lifecycle example; it uses
  `RestartableTasksMixin.runLatestOutcome` with `safeEmit` (see async_helpers).
- Add search/debounce-style example using `RestartableTask`
- Add bloc close/lifecycle example for `safeEmit` and token usage

## Acceptance Criteria (DoD)
- All APIs exported and documented with cooperative cancellation note
- Unit tests include race-like scenarios with delayed futures
- No memory leaks in repeated run/cancel/dispose cycle tests
- Analyzer and tests pass

## Validation Commands
- `dart format .`
- `flutter analyze`
- `flutter test test/async`

## Agent Constraints
- Explicitly document non-goal: no hard cancellation guarantee
- Avoid zone/global state tricks
- Keep implementation lightweight and dependency-free
