import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cancel is idempotent and updates isCancelled', () {
    // Given
    final token = CancellationToken();

    // When
    token.cancel();
    token.cancel();

    // Then
    expect(token.isCancelled, isTrue);
  });

  test('run returns null when cancelled before completion', () async {
    // Given
    final token = CancellationToken();
    final completer = Completer<int>();

    // When
    final future = token.run(() => completer.future);
    token.cancel();
    completer.complete(10);
    final result = await future;

    // Then
    expect(result, isNull);
  });

  test('run returns task value when not cancelled', () async {
    // Given
    final token = CancellationToken();

    // When
    final result = await token.run(() async => 5);

    // Then
    expect(result, 5);
  });

  test('run completes with null when the task fails after cancel', () async {
    // Given
    final token = CancellationToken();
    final work = Completer<int>();
    final run = token.run(() => work.future);

    // When
    token.cancel();
    work.completeError(StateError('boom'));

    // Then
    expect(await run, isNull);
  });

  test('run rethrows the failure of a task that was not cancelled', () async {
    // Given
    final token = CancellationToken();

    // When
    final run = token.run<int>(() async => throw StateError('boom'));

    // Then
    await expectLater(run, throwsStateError);
  });

  test('run rethrows a failure with the stack trace of the task', () async {
    // Given
    final token = CancellationToken();
    final thrown = StackTrace.fromString('thrown by the task');

    // When
    final caught = await token
        .run<int>(() => Future<int>.error(Exception('boom'), thrown))
        .then<StackTrace?>((_) => null, onError: (Object _, StackTrace s) => s);

    // Then
    expect('$caught', contains('thrown by the task'));
  });
}
