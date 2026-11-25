import 'dart:async';

import 'package:bloc/bloc.dart';
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

class _TrackedCubit extends Cubit<int> with RestartableTasksMixin<int> {
  _TrackedCubit() : super(0);
}

class _SearchState {
  const _SearchState({this.isLoading = false, this.item});

  final bool isLoading;
  final String? item;
}

class _SearchCubit extends Cubit<_SearchState>
    with RestartableTasksMixin<_SearchState> {
  _SearchCubit(this.find) : super(const _SearchState());

  final Future<String?> Function(String query) find;

  Future<void> search(String query) async {
    emit(_SearchState(isLoading: true, item: state.item));
    final outcome = await runLatestOutcome('search', (_) => find(query));
    // A superseded call resumes while the newer search is still loading, so
    // it must not clear the loading flag.
    if (outcome.isCompleted) emit(_SearchState(item: outcome.value));
  }
}

abstract class _Event {}

class _Load extends _Event {
  _Load(this.gate);

  final Future<void> gate;
}

class _Cancel extends _Event {}

class _EmitInTaskBloc extends Bloc<_Event, String>
    with RestartableTasksMixin<String> {
  _EmitInTaskBloc() : super('initial') {
    on<_Load>((event, emit) async {
      await runLatest('load', () async {
        await event.gate;
        emitDoneWhenTaskResumed = emit.isDone;
        // The documented guard: bloc rejects a late emit only with an assert,
        // so without it a release build would emit the stale state.
        if (!emit.isDone) emit('stale');
        return 1;
      });
      handlerDone = true;
    });
    on<_Cancel>((event, emit) => cancelLatest('load'));
  }

  bool handlerDone = false;
  bool? emitDoneWhenTaskResumed;
}

void main() {
  group('CancellationToken', () {
    test('whenCancelled completes only once cancel is called', () async {
      // Given
      final token = CancellationToken();
      final completedBeforeCancel = await _isReleased(token.whenCancelled);

      // When
      token.cancel();
      token.cancel();

      // Then
      expect(completedBeforeCancel, isFalse);
      expect(await _isReleased(token.whenCancelled), isTrue);
    });

    test('run releases its caller on cancel without waiting for the task',
        () async {
      // Given
      final token = CancellationToken();
      final run = token.run(() => Completer<int>().future);

      // When
      token.cancel();

      // Then
      expect(await _isReleased(run), isTrue);
      expect(await run, isNull);
    });

    test('run drops a failure of the task that ends after cancel', () async {
      // Given
      final token = CancellationToken();
      final work = Completer<int>();
      final run = token.run(() => work.future);
      token.cancel();
      await run;

      // When
      work.completeError(StateError('late'));
      await pumpEventQueue();

      // Then
      expect(await run, isNull);
    });

    test('run drops a value when cancel lands before the caller resumes',
        () async {
      // Given
      final token = CancellationToken();
      // Delivers the value at once, so the cancel below lands after it has
      // arrived but before the caller resumes.
      final work = Completer<int>.sync();
      final run = token.run(() => work.future);

      // When
      work.complete(7);
      token.cancel();

      // Then
      expect(await run, isNull);
    });
  });

  group('RestartableTask.runOutcome', () {
    test('completes with a completed outcome carrying a null value', () async {
      // Given
      final task = RestartableTask<String?>();

      // When
      final outcome = await task.runOutcome((_) async => null);

      // Then
      expect(outcome, const TaskOutcome<String?>.completed(null));
    });

    test('a newer run cancels the token and releases a never-ending run',
        () async {
      // Given
      final task = RestartableTask<int>();
      late CancellationToken firstToken;
      final first = task.runOutcome((token) {
        firstToken = token;
        return Completer<int>().future;
      });

      // When
      final second = task.runOutcome((_) async => 2);

      // Then
      expect(await _isReleased(first), isTrue);
      expect(await first, const TaskOutcome<int>.cancelled());
      expect(firstToken.isCancelled, isTrue);
      expect(await second, const TaskOutcome<int>.completed(2));
    });

    test('cancel releases a never-ending run', () async {
      // Given
      final task = RestartableTask<int>();
      final run = task.runOutcome((_) => Completer<int>().future);

      // When
      task.cancel();

      // Then
      expect(await _isReleased(run), isTrue);
      expect(await run, const TaskOutcome<int>.cancelled());
      expect(task.isRunning, isFalse);
    });

    test('cancel between the value and the caller resuming cancels the run',
        () async {
      // Given
      final task = RestartableTask<int>();
      // Delivers the value at once, so the cancel below lands after it has
      // arrived but before the caller resumes.
      final work = Completer<int>.sync();
      final run = task.runOutcome((_) => work.future);

      // When
      work.complete(7);
      task.cancel();

      // Then
      expect(await run, const TaskOutcome<int>.cancelled());
    });

    test('does not cancel the token of a finished run', () async {
      // Given
      final task = RestartableTask<int>();
      late CancellationToken succeeded;
      late CancellationToken failed;
      await task.runOutcome((token) async {
        succeeded = token;
        return 1;
      });
      await expectLater(
        task.runOutcome((token) async {
          failed = token;
          throw StateError('boom');
        }),
        throwsStateError,
      );

      // When
      await task.runOutcome((_) async => 2);
      task.cancel();
      await task.dispose();

      // Then
      expect(succeeded.isCancelled, isFalse);
      expect(failed.isCancelled, isFalse);
    });

    test('dispose releases a never-ending run', () async {
      // Given
      final task = RestartableTask<int>();
      late CancellationToken token;
      final run = task.runOutcome((t) {
        token = t;
        return Completer<int>().future;
      });

      // When
      await task.dispose();

      // Then
      expect(await _isReleased(run), isTrue);
      expect(await run, const TaskOutcome<int>.cancelled());
      expect(token.isCancelled, isTrue);
    });

    test('does not start the task after dispose', () async {
      // Given
      final task = RestartableTask<int>();
      await task.dispose();
      var started = false;

      // When
      final outcome = await task.runOutcome((_) async {
        started = true;
        return 1;
      });

      // Then
      expect(outcome, const TaskOutcome<int>.cancelled());
      expect(started, isFalse);
    });

    test('drops a failure of a superseded run without an unhandled error',
        () async {
      // Given
      final task = RestartableTask<int>();
      final stale = Completer<int>();
      final first = task.runOutcome((_) => stale.future);
      await task.runOutcome((_) async => 2);

      // When
      stale.completeError(StateError('stale'));
      await pumpEventQueue();

      // Then
      expect(await first, const TaskOutcome<int>.cancelled());
    });

    test('rethrows the failure of the latest run', () async {
      // Given
      final task = RestartableTask<int>();

      // When
      final run = task.runOutcome((_) async => throw StateError('boom'));

      // Then
      await expectLater(run, throwsStateError);
      expect(task.isRunning, isFalse);
    });
  });

  group('RestartableTasksMixin.runLatestOutcome', () {
    test('a not-found result clears the loading flag', () async {
      // Given
      final cubit = _SearchCubit((_) async => null);
      addTearDown(cubit.close);

      // When
      await cubit.search('missing');

      // Then
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.item, isNull);
    });

    test('a newer run cancels the token and releases a never-ending run',
        () async {
      // Given
      final cubit = _TrackedCubit();
      addTearDown(cubit.close);
      late CancellationToken firstToken;
      final first = cubit.runLatestOutcome<int>('k', (token) {
        firstToken = token;
        return Completer<int>().future;
      });

      // When
      final second = cubit.runLatestOutcome<int>('k', (_) async => 2);

      // Then
      expect(await _isReleased(first), isTrue);
      expect(await first, const TaskOutcome<int>.cancelled());
      expect(firstToken.isCancelled, isTrue);
      expect(await second, const TaskOutcome<int>.completed(2));
    });

    test('cancelLatest releases a never-ending run and its finally runs',
        () async {
      // Given
      final cubit = _TrackedCubit();
      addTearDown(cubit.close);
      late CancellationToken token;
      var finallyRan = false;
      final run = () async {
        try {
          return await cubit.runLatestOutcome<int>('k', (t) {
            token = t;
            return Completer<int>().future;
          });
        } finally {
          finallyRan = true;
        }
      }();

      // When
      cubit.cancelLatest('k');

      // Then
      expect(await _isReleased(run), isTrue);
      expect(await run, const TaskOutcome<int>.cancelled());
      expect(finallyRan, isTrue);
      expect(token.isCancelled, isTrue);
    });

    test('cancelAllLatest releases never-ending runs of every key', () async {
      // Given
      final cubit = _TrackedCubit();
      addTearDown(cubit.close);
      final search = cubit.runLatestOutcome('search', (_) {
        return Completer<int>().future;
      });
      final profile = cubit.runLatestOutcome('profile', (_) {
        return Completer<String>().future;
      });

      // When
      cubit.cancelAllLatest();

      // Then
      expect(await _isReleased(Future.wait([search, profile])), isTrue);
      expect(await search, const TaskOutcome<int>.cancelled());
      expect(await profile, const TaskOutcome<String>.cancelled());
    });

    test('close cancels the token and releases a never-ending run', () async {
      // Given
      final cubit = _TrackedCubit();
      late CancellationToken token;
      final run = cubit.runLatestOutcome<int>('k', (t) {
        token = t;
        return Completer<int>().future;
      });

      // When
      await cubit.close();

      // Then
      expect(await _isReleased(run), isTrue);
      expect(await run, const TaskOutcome<int>.cancelled());
      expect(token.isCancelled, isTrue);
    });

    test('close between the value and the caller resuming cancels the run',
        () async {
      // Given
      final cubit = _TrackedCubit();
      // Delivers the value at once, so the close below lands after it has
      // arrived but before the caller resumes.
      final work = Completer<int>.sync();
      final run = cubit.runLatestOutcome<int>('k', (_) => work.future);

      // When
      work.complete(7);
      await cubit.close();

      // Then
      expect(await run, const TaskOutcome<int>.cancelled());
    });

    test('does not start the task on a closed cubit', () async {
      // Given
      final cubit = _TrackedCubit();
      await cubit.close();
      var started = false;

      // When
      final outcome = await cubit.runLatestOutcome<int>('k', (_) async {
        started = true;
        return 1;
      });

      // Then
      expect(outcome, const TaskOutcome<int>.cancelled());
      expect(started, isFalse);
    });

    test('a void task completes with a completed outcome', () async {
      // Given
      final cubit = _TrackedCubit();
      addTearDown(cubit.close);

      // When
      final outcome = await cubit.runLatestOutcome<void>('save', (_) async {});

      // Then
      expect(outcome.isCompleted, isTrue);
    });

    test('drops a failure of a superseded run without an unhandled error',
        () async {
      // Given
      final cubit = _TrackedCubit();
      addTearDown(cubit.close);
      final stale = Completer<int>();
      final first = cubit.runLatestOutcome<int>('k', (_) => stale.future);
      await cubit.runLatestOutcome<int>('k', (_) async => 2);

      // When
      stale.completeError(StateError('stale'));
      await pumpEventQueue();

      // Then
      expect(await first, const TaskOutcome<int>.cancelled());
    });

    test('rethrows the failure of the latest run and drops the key', () async {
      // Given
      final cubit = _TrackedCubit();
      addTearDown(cubit.close);

      // When
      final run = cubit.runLatestOutcome<int>(
        'k',
        (_) async => throw StateError('boom'),
      );

      // Then
      await expectLater(run, throwsStateError);
      expect(cubit.isTaskRunning('k'), isFalse);
    });

    test('a reentrant run with the same key supersedes the outer run',
        () async {
      // Given
      final cubit = _TrackedCubit();
      addTearDown(cubit.close);
      final inner = Completer<int>();
      Future<TaskOutcome<int>>? innerRun;

      // When
      final outerOutcome = await cubit.runLatestOutcome<int>('k', (_) async {
        innerRun = cubit.runLatestOutcome<int>('k', (_) => inner.future);
        return 1;
      });
      final runningAfterOuter = cubit.isTaskRunning('k');
      inner.complete(2);
      final innerOutcome = await innerRun!;

      // Then
      expect(outerOutcome, const TaskOutcome<int>.cancelled());
      expect(runningAfterOuter, isTrue);
      expect(innerOutcome, const TaskOutcome<int>.completed(2));
      expect(cubit.isTaskRunning('k'), isFalse);
    });

    test('runLatest still completes with null on cancelLatest', () async {
      // Given
      final cubit = _TrackedCubit();
      addTearDown(cubit.close);
      final run = cubit.runLatest<int>('k', () => Completer<int>().future);

      // When
      cubit.cancelLatest('k');

      // Then
      expect(await _isReleased(run), isTrue);
      expect(await run, isNull);
    });
  });

  group('release on supersede', () {
    test('a superseded caller resumes while the newer run is in flight',
        () async {
      // Given
      final slow = Completer<String?>();
      final cubit = _SearchCubit(
        (query) => query == 'a' ? slow.future : Completer<String?>().future,
      );
      addTearDown(cubit.close);
      final first = cubit.search('a');

      // When
      unawaited(cubit.search('ab'));

      // Then
      expect(await _isReleased(first), isTrue);
      expect(cubit.isTaskRunning('search'), isTrue);
      expect(cubit.state.isLoading, isTrue);
    });

    test('a superseded search keeps the result of the latest one', () async {
      // Given
      final slow = Completer<String?>();
      final cubit = _SearchCubit(
        (query) => query == 'a' ? slow.future : Future.value(query),
      );
      addTearDown(cubit.close);
      final first = cubit.search('a');

      // When
      await cubit.search('ab');
      slow.complete('a');
      await first;
      await pumpEventQueue();

      // Then
      expect(cubit.state.item, 'ab');
      expect(cubit.state.isLoading, isFalse);
    });

    test(
        'the abandoned task keeps running, so a token check guards its '
        'side effect', () async {
      // Given
      final cubit = _TrackedCubit();
      addTearDown(cubit.close);
      var cache = '';
      var staleTaskFinished = false;
      final staleGate = Completer<void>();
      Future<TaskOutcome<String>> search(String query, Future<void> gate) {
        return cubit.runLatestOutcome('search', (token) async {
          await gate;
          if (!token.isCancelled) cache = query;
          if (query == 'a') staleTaskFinished = true;
          return query;
        });
      }

      final stale = search('a', staleGate.future);
      await search('b', Future<void>.value());
      await stale;

      // When
      staleGate.complete();
      await pumpEventQueue();

      // Then
      expect(staleTaskFinished, isTrue);
      expect(cache, 'b');
    });

    test(
        'a cancelled Bloc handler completes at once and emit.isDone guards '
        'the abandoned task', () async {
      // Given
      final bloc = _EmitInTaskBloc();
      final states = <String>[];
      final subscription = bloc.stream.listen(states.add);
      addTearDown(subscription.cancel);
      addTearDown(bloc.close);
      final gate = Completer<void>();
      bloc.add(_Load(gate.future));
      await pumpEventQueue();

      // When
      bloc.add(_Cancel());
      await pumpEventQueue();
      final handlerDoneBeforeGate = bloc.handlerDone;
      gate.complete();
      await pumpEventQueue();

      // Then
      expect(handlerDoneBeforeGate, isTrue);
      expect(bloc.emitDoneWhenTaskResumed, isTrue);
      expect(states, isEmpty);
      expect(bloc.state, 'initial');
    });
  });
}
