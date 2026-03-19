import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class _TrackedCubit extends Cubit<int> with RestartableTasksMixin<int> {
  _TrackedCubit() : super(0);
}

class _SafeTrackedCubit extends Cubit<int>
    with SafeEmitMixin<int>, RestartableTasksMixin<int> {
  _SafeTrackedCubit() : super(0);

  Future<void> load(Completer<int> completer) async {
    final value = await runLatest('load', () => completer.future);
    if (value != null) safeEmit(value);
  }
}

void main() {
  test('runLatest invalidates stale result for the same key', () async {
    // Given
    final cubit = _TrackedCubit();
    addTearDown(cubit.close);
    final firstCompleter = Completer<int>();
    final secondCompleter = Completer<int>();

    // When
    final first = cubit.runLatest('search', () => firstCompleter.future);
    final second = cubit.runLatest('search', () => secondCompleter.future);
    firstCompleter.complete(1);
    secondCompleter.complete(2);
    final firstResult = await first;
    final secondResult = await second;

    // Then
    expect(firstResult, isNull);
    expect(secondResult, 2);
  });

  test('runLatest keeps different keys independent', () async {
    // Given
    final cubit = _TrackedCubit();
    addTearDown(cubit.close);
    final searchCompleter = Completer<int>();
    final profileCompleter = Completer<int>();

    // When
    final search = cubit.runLatest('search', () => searchCompleter.future);
    final profile = cubit.runLatest('profile', () => profileCompleter.future);
    searchCompleter.complete(1);
    profileCompleter.complete(2);

    // Then
    expect(await search, 1);
    expect(await profile, 2);
  });

  test('cancelLatest only affects the matching key', () async {
    // Given
    final cubit = _TrackedCubit();
    addTearDown(cubit.close);
    final searchCompleter = Completer<int>();
    final profileCompleter = Completer<int>();

    // When
    final search = cubit.runLatest('search', () => searchCompleter.future);
    final profile = cubit.runLatest('profile', () => profileCompleter.future);
    cubit.cancelLatest('search');
    searchCompleter.complete(1);
    profileCompleter.complete(2);

    // Then
    expect(await search, isNull);
    expect(await profile, 2);
  });

  test('cancelAllLatest invalidates every tracked key', () async {
    // Given
    final cubit = _TrackedCubit();
    addTearDown(cubit.close);
    final searchCompleter = Completer<int>();
    final profileCompleter = Completer<int>();

    // When
    final search = cubit.runLatest('search', () => searchCompleter.future);
    final profile = cubit.runLatest('profile', () => profileCompleter.future);
    cubit.cancelAllLatest();
    searchCompleter.complete(1);
    profileCompleter.complete(2);

    // Then
    expect(await search, isNull);
    expect(await profile, isNull);
    expect(cubit.isTaskRunning('search'), isFalse);
    expect(cubit.isTaskRunning('profile'), isFalse);
  });

  test('close invalidates all tracked task results', () async {
    // Given
    final cubit = _TrackedCubit();
    final firstCompleter = Completer<int>();
    final secondCompleter = Completer<int>();

    // When
    final first = cubit.runLatest('search', () => firstCompleter.future);
    final second = cubit.runLatest('profile', () => secondCompleter.future);
    await cubit.close();
    firstCompleter.complete(1);
    secondCompleter.complete(2);

    // Then
    expect(await first, isNull);
    expect(await second, isNull);
  });

  test('runLatest ignores new runs after the cubit is closed', () async {
    // Given
    final cubit = _TrackedCubit();

    // When
    await cubit.close();
    final result = await cubit.runLatest('search', () async => 42);

    // Then
    expect(result, isNull);
  });

  test('isTaskRunning reflects the latest run for each key', () async {
    // Given
    final cubit = _TrackedCubit();
    addTearDown(cubit.close);
    final completer = Completer<int>();

    // When
    final future = cubit.runLatest('search', () => completer.future);

    // Then
    expect(cubit.isTaskRunning('search'), isTrue);

    // When
    completer.complete(1);
    await future;

    // Then
    expect(cubit.isTaskRunning('search'), isFalse);
  });

  test('runLatest works with SafeEmitMixin after close', () async {
    // Given
    final cubit = _SafeTrackedCubit();
    final completer = Completer<int>();

    // When
    final future = cubit.load(completer);
    await cubit.close();
    completer.complete(7);
    await future;

    // Then
    expect(cubit.state, 0);
  });
}
