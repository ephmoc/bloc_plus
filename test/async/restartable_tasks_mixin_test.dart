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

class _SlowCloseCubit extends Cubit<int> {
  _SlowCloseCubit() : super(0);

  final release = Completer<void>();

  @override
  Future<void> close() async {
    await release.future;
    return super.close();
  }
}

class _SlowTrackedCubit extends _SlowCloseCubit
    with RestartableTasksMixin<int> {}

class _ReentrantCloseObserver extends BlocObserver {
  Future<void>? reentrantClose;

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    reentrantClose ??= bloc.close();
  }
}

// Every key has the same hash code, so a map that still holds one of them
// has to compare it with any other key that is looked up.
class _CollidingKey {
  static int comparisons = 0;

  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) {
    comparisons++;
    return identical(this, other);
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

  test('runLatest completes with null when a superseded run fails', () async {
    // Given
    final cubit = _TrackedCubit();
    addTearDown(cubit.close);
    final stale = Completer<String>();
    final fresh = Completer<String>();
    final staleRun = cubit.runLatest('search', () => stale.future);
    final freshRun = cubit.runLatest('search', () => fresh.future);

    // When
    fresh.complete('fresh');
    stale.completeError(TimeoutException('old request'));

    // Then
    expect(await freshRun, 'fresh');
    expect(await staleRun, isNull);
  });

  test('runLatest rethrows the failure of the latest run', () async {
    // Given
    final cubit = _TrackedCubit();
    addTearDown(cubit.close);

    // When
    final run = cubit.runLatest<String>(
      'search',
      () async => throw StateError('boom'),
    );

    // Then
    await expectLater(run, throwsStateError);
    expect(cubit.isTaskRunning('search'), isFalse);
  });

  test('runLatest rethrows a failure with the stack trace of the task',
      () async {
    // Given
    final cubit = _TrackedCubit();
    addTearDown(cubit.close);
    final thrown = StackTrace.fromString('thrown by the task');

    // When
    final caught = await cubit
        .runLatest<int>(
          'search',
          () => Future<int>.error(Exception('boom'), thrown),
        )
        .then<StackTrace?>((_) => null, onError: (Object _, StackTrace s) => s);

    // Then
    expect('$caught', contains('thrown by the task'));
  });

  test('a run that has ended leaves no key to compare later keys with',
      () async {
    // Given
    final cubit = _TrackedCubit();
    addTearDown(cubit.close);
    final value = await cubit.runLatest(_CollidingKey(), () async => 1);
    final failure = cubit.runLatest<int>(
      _CollidingKey(),
      () async => throw StateError('boom'),
    );
    await expectLater(failure, throwsStateError);
    _CollidingKey.comparisons = 0;

    // When
    final running = cubit.isTaskRunning(_CollidingKey());

    // Then
    expect(value, 1);
    expect(running, isFalse);
    expect(_CollidingKey.comparisons, 0);
  });

  test('a run made while close is in progress does not start its task',
      () async {
    // Given
    final cubit = _SlowTrackedCubit();
    final closing = cubit.close();
    final closedBeforeRun = cubit.isClosed;
    var started = false;

    // When
    final outcome = await cubit.runLatestOutcome('search', (_) async {
      started = true;
      return 1;
    });
    cubit.release.complete();
    await closing;

    // Then
    expect(closedBeforeRun, isFalse);
    expect(started, isFalse);
    expect(outcome.isCompleted, isFalse);
  });

  test('a second close waits until the first one has finished', () async {
    // Given
    final cubit = _SlowTrackedCubit();
    final first = cubit.close();
    var secondDone = false;

    // When
    final second = cubit.close().then((_) => secondDone = true);
    await Future<void>.delayed(Duration.zero);
    final doneBeforeRelease = secondDone;
    cubit.release.complete();
    await Future.wait([first, second]);

    // Then
    expect(doneBeforeRelease, isFalse);
    expect(secondDone, isTrue);
  });

  test('a close() made from BlocObserver.onClose shares the first close',
      () async {
    // Given
    final previousObserver = Bloc.observer;
    final observer = _ReentrantCloseObserver();
    Bloc.observer = observer;
    addTearDown(() => Bloc.observer = previousObserver);
    final cubit = _TrackedCubit();

    // When
    final first = cubit.close();
    await first;

    // Then
    expect(observer.reentrantClose, same(first));
  });
}
