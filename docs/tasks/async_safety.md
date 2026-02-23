# Task Spec - async_safety

## Scope
- Implement `SafeEmitMixin<S>`
  - `safeEmit(S state)`
  - `guarded<T>(Future<T> Function() operation)`
- Implement `CancellationToken`
- Implement `RestartableTask<T>`

## Out Of Scope
- Hard cancellation of arbitrary `Future` work
- External task schedulers or isolates

## Public Contract
- `safeEmit` performs no-op when bloc is closed
- `guarded` returns `null` when bloc is closed before completion
- `CancellationToken.cancel()` is one-way and idempotent
- `CancellationToken.run` is cooperative: it does not interrupt running task, only suppresses result
- `RestartableTask.run` invalidates previous in-flight result
- `RestartableTask.dispose` prevents future runs and cancels current token/result flow

## Target Files
- `lib/src/async/safe_emit_mixin.dart`
- `lib/src/async/cancellation_token.dart`
- `lib/src/async/restartable_task.dart`
- `lib/src/async/async.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)
- `test/async/safe_emit_mixin_test.dart`
- `test/async/cancellation_token_test.dart`
- `test/async/restartable_task_test.dart`

Required cases:
- safe emit after close does not throw
- guarded returns value when open, `null` when closed
- token cancel state transitions
- token run returns `null` when cancelled before completion
- restartable task drops stale result from previous run
- dispose blocks new runs and cleans active flow

## Example App Updates
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
