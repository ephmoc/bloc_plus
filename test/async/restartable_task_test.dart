import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
