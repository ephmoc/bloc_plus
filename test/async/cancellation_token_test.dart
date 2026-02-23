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
}
