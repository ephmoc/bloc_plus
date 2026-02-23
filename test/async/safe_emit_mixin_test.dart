import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class _SafeEmitCubit extends Cubit<int> with SafeEmitMixin<int> {
  _SafeEmitCubit() : super(0);
}

void main() {
  test('safeEmit does not throw after cubit is closed', () async {
    // Given
    final cubit = _SafeEmitCubit();
    await cubit.close();

    // When
    void action() => cubit.safeEmit(1);

    // Then
    expect(action, returnsNormally);
  });

  test('guarded returns result when cubit is open', () async {
    // Given
    final cubit = _SafeEmitCubit();
    addTearDown(cubit.close);

    // When
    final result = await cubit.guarded(() async => 42);

    // Then
    expect(result, 42);
  });

  test('guarded returns null when cubit closes before completion', () async {
    // Given
    final cubit = _SafeEmitCubit();
    addTearDown(() async {
      if (!cubit.isClosed) await cubit.close();
    });
    final completer = Completer<int>();

    // When
    final guardedFuture = cubit.guarded(() => completer.future);
    await cubit.close();
    completer.complete(7);
    final result = await guardedFuture;

    // Then
    expect(result, isNull);
  });
}
