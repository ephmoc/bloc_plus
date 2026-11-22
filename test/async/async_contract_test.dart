import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class _SafeEmitCubit extends Cubit<int> with SafeEmitMixin<int> {
  _SafeEmitCubit() : super(0);
}

class _TrackedCubit extends Cubit<int> with RestartableTasksMixin<int> {
  _TrackedCubit() : super(0);
}

class _CountingCubit extends Cubit<int> {
  _CountingCubit() : super(0);

  int baseCloseCalls = 0;

  @override
  Future<void> close() {
    baseCloseCalls++;
    return super.close();
  }
}

class _CountingTrackedCubit extends _CountingCubit
    with RestartableTasksMixin<int> {}

class _EffectsAndTasksCubit extends Cubit<int>
    with HasEffects<int, String>, RestartableTasksMixin<int> {
  _EffectsAndTasksCubit() : super(0);
}

void main() {
  group('SafeEmitMixin', () {
    test('safeEmit emits the state while the cubit is open', () {
      // Given
      final cubit = _SafeEmitCubit();
      addTearDown(cubit.close);

      // When
      cubit.safeEmit(1);

      // Then
      expect(cubit.state, 1);
    });

    test('safeEmit leaves the state untouched after close', () async {
      // Given
      final cubit = _SafeEmitCubit();
      await cubit.close();

      // When
      cubit.safeEmit(1);

      // Then
      expect(cubit.state, 0);
    });
  });

  group('CancellationToken', () {
    test('run does not start the task on an already cancelled token', () async {
      // Given
      final token = CancellationToken()..cancel();
      var started = false;

      // When
      final result = await token.run(() async {
        started = true;
        return 1;
      });

      // Then
      expect(result, isNull);
      expect(started, isFalse);
    });
  });

  group('RestartableTask', () {
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
  });

  group('RestartableTasksMixin', () {
    test('runLatest does not start the task after close', () async {
      // Given
      final cubit = _TrackedCubit();
      await cubit.close();
      var started = false;

      // When
      final result = await cubit.runLatest('search', () async {
        started = true;
        return 1;
      });

      // Then
      expect(result, isNull);
      expect(started, isFalse);
    });

    test('a stale run finishing keeps the latest run tracked and cancellable',
        () async {
      // Given
      final cubit = _TrackedCubit();
      addTearDown(cubit.close);
      final firstCompleter = Completer<int>();
      final secondCompleter = Completer<int>();
      final first = cubit.runLatest('search', () => firstCompleter.future);
      final second = cubit.runLatest('search', () => secondCompleter.future);

      // When
      firstCompleter.complete(1);
      await first;
      final runningAfterStaleCompletion = cubit.isTaskRunning('search');
      cubit.cancelLatest('search');
      secondCompleter.complete(2);

      // Then
      expect(runningAfterStaleCompletion, isTrue);
      expect(await second, isNull);
    });

    test('a cancelled run finishing does not untrack a newer run', () async {
      // Given
      final cubit = _TrackedCubit();
      addTearDown(cubit.close);
      final firstCompleter = Completer<int>();
      final secondCompleter = Completer<int>();
      final first = cubit.runLatest('search', () => firstCompleter.future);
      cubit.cancelLatest('search');
      final second = cubit.runLatest('search', () => secondCompleter.future);

      // When
      firstCompleter.complete(1);
      await first;
      final runningAfterCancelledCompletion = cubit.isTaskRunning('search');
      cubit.cancelLatest('search');
      secondCompleter.complete(2);

      // Then
      expect(runningAfterCancelledCompletion, isTrue);
      expect(await second, isNull);
    });

    test('close closes the cubit and stops reporting running tasks', () async {
      // Given
      final cubit = _TrackedCubit();
      final completer = Completer<int>();
      final pending = cubit.runLatest('search', () => completer.future);

      // When
      await cubit.close();

      // Then
      expect(cubit.isClosed, isTrue);
      expect(cubit.isTaskRunning('search'), isFalse);
      completer.complete(1);
      expect(await pending, isNull);
    });

    test('close is idempotent', () async {
      // Given
      final cubit = _CountingTrackedCubit();

      // When
      await Future.wait([cubit.close(), cubit.close()]);
      await cubit.close();

      // Then
      expect(cubit.baseCloseCalls, 1);
    });

    test('runLatest is rejected while close is still in progress', () async {
      // Given
      final cubit = _EffectsAndTasksCubit();
      final subscription = cubit.effects.listen((_) {});
      addTearDown(subscription.cancel);
      var started = false;

      // When
      final closing = cubit.close();
      final result = await cubit.runLatest('search', () async {
        started = true;
        return 1;
      });
      await closing;

      // Then
      expect(result, isNull);
      expect(started, isFalse);
    });
  });

  group('HasEffects', () {
    test('close also closes the cubit itself', () async {
      // Given
      final cubit = _EffectsAndTasksCubit();

      // When
      await cubit.close();

      // Then
      expect(cubit.isClosed, isTrue);
    });

    test('effects are delivered asynchronously, never inside emitEffect',
        () async {
      // Given
      final cubit = _EffectsAndTasksCubit();
      addTearDown(cubit.close);
      final received = <String>[];
      final subscription = cubit.effects.listen(received.add);
      addTearDown(subscription.cancel);

      // When
      cubit.emitEffect('toast');
      final receivedSynchronously = List<String>.of(received);
      await Future<void>.delayed(Duration.zero);

      // Then
      expect(receivedSynchronously, isEmpty);
      expect(received, ['toast']);
    });
  });
}
