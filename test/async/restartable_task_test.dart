// Exercises the deprecated RestartableTask.run until its removal in 1.0.
// The contracts of RestartableTask are tested with runOutcome in
// run_outcome_test.dart and async_contract_test.dart.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether [future] has completed once all pending microtasks and timers ran.
Future<bool> _isReleased(Future<Object?> future) async {
  var released = false;
  unawaited(
    future.then((_) => released = true, onError: (_) => released = true),
  );
  await pumpEventQueue();
  return released;
}

void main() {
  test('run invalidates stale result from previous task', () async {
    // Given
    final task = RestartableTask<int>();
    final firstCompleter = Completer<int>();
    final secondCompleter = Completer<int>();

    // When
    final first = task.run(() => firstCompleter.future);
    final second = task.run(() => secondCompleter.future);
    firstCompleter.complete(1);
    secondCompleter.complete(2);
    final firstResult = await first;
    final secondResult = await second;

    // Then
    expect(firstResult, isNull);
    expect(secondResult, 2);
  });

  test('dispose prevents new runs', () async {
    // Given
    final task = RestartableTask<int>();

    // When
    await task.dispose();
    final result = await task.run(() async => 123);

    // Then
    expect(result, isNull);
  });

  test('cancel marks task as not running', () async {
    // Given
    final task = RestartableTask<int>();
    final completer = Completer<int>();
    final runningFuture = task.run(() => completer.future);

    // When
    task.cancel();
    completer.complete(1);
    final result = await runningFuture;

    // Then
    expect(result, isNull);
    expect(task.isRunning, isFalse);
  });

  test('run does not start the task after dispose', () async {
    // Given
    final task = RestartableTask<int>();
    await task.dispose();
    var started = false;

    // When
    final result = await task.run(() async {
      started = true;
      return 1;
    });

    // Then
    expect(result, isNull);
    expect(started, isFalse);
  });

  test('a stale run finishing does not clear isRunning of the latest run',
      () async {
    // Given
    final task = RestartableTask<int>();
    final firstCompleter = Completer<int>();
    final secondCompleter = Completer<int>();
    final first = task.run(() => firstCompleter.future);
    final second = task.run(() => secondCompleter.future);

    // When
    firstCompleter.complete(1);
    await first;

    // Then
    expect(task.isRunning, isTrue);
    secondCompleter.complete(2);
    expect(await second, 2);
    expect(task.isRunning, isFalse);
  });

  test('dispose during an in-flight run drops the result and isRunning',
      () async {
    // Given
    final task = RestartableTask<int>();
    final completer = Completer<int>();
    final running = task.run(() => completer.future);

    // When
    await task.dispose();
    completer.complete(1);
    final result = await running;

    // Then
    expect(result, isNull);
    expect(task.isRunning, isFalse);
  });

  test('run still completes with null when cancelled', () async {
    // Given
    final task = RestartableTask<int>();
    final run = task.run(() => Completer<int>().future);

    // When
    task.cancel();

    // Then
    expect(await _isReleased(run), isTrue);
    expect(await run, isNull);
  });
}
