// A Bloc cannot mix in SafeEmitMixin since 0.4.0, and the CHANGELOG tells it
// to check isClosed instead: first in the handler, after every await, in the
// onData and onError of emit.onEach, and first in a catch. That relies on bloc
// 9.2.1 or later, where the isClosed of a Bloc is true from the call of
// close(), which is why the bloc dependency starts at 9.2.1: on bloc 9.2.0 the
// first five tests fail.

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Load {}

/// The handler of the CHANGELOG migration, with `sequential()` as
/// bloc_concurrency defines it, so that close() waits for the handlers.
class _MigratedBloc extends Bloc<_Load, String?> {
  _MigratedBloc(this.load) : super(null) {
    on<_Load>(
      (event, emit) async {
        if (isClosed) return;
        try {
          final item = await load();
          if (isClosed) return;
          emit(item);
        } catch (_) {
          if (isClosed) return;
          rethrow;
        }
      },
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  final Future<String> Function() load;
  final errors = <Object>[];

  @override
  void onError(Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(error, stackTrace);
  }
}

/// A handler that relays a stream with `emit.onEach` and the check in
/// `onData` and `onError`, again with `sequential()`.
class _RelayBloc extends Bloc<_Load, String?> {
  _RelayBloc(this.source) : super(null) {
    on<_Load>(
      (event, emit) => emit.onEach<String>(
        source,
        onData: (value) {
          if (!isClosed) emit(value);
        },
        onError: (error, stackTrace) {
          if (!isClosed) emit('error');
        },
      ),
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  final Stream<String> source;
}

void main() {
  test('a Bloc is closed from the call of close()', () async {
    // Given
    final bloc = _MigratedBloc(() async => 'item');

    // When
    final closing = bloc.close();

    // Then
    expect(bloc.isClosed, isTrue);
    await closing;
  });

  test('the migrated handler emits nothing after close()', () async {
    // Given
    final pending = Completer<String>();
    final bloc = _MigratedBloc(() => pending.future);
    final states = <String?>[];
    final subscription = bloc.stream.listen(states.add);
    bloc.add(_Load());
    await Future<void>.delayed(Duration.zero);

    // When
    final closing = bloc.close();
    pending.complete('late');
    await closing;
    await subscription.cancel();

    // Then
    expect(states, isEmpty);
  });

  test('an event queued before close() does not start its work', () async {
    // Given
    final first = Completer<String>();
    var loads = 0;
    final bloc = _MigratedBloc(() {
      loads++;
      return loads == 1 ? first.future : Future.value('second');
    });
    bloc
      ..add(_Load())
      ..add(_Load());
    await Future<void>.delayed(Duration.zero);

    // When
    final closing = bloc.close();
    first.complete('first');
    await closing;

    // Then
    expect(loads, 1);
  });

  test('a failure after close() is dropped', () async {
    // Given
    final pending = Completer<String>();
    final bloc = _MigratedBloc(() => pending.future);
    bloc.add(_Load());
    await Future<void>.delayed(Duration.zero);

    // When
    final closing = bloc.close();
    pending.completeError(StateError('late failure'));
    await closing;

    // Then
    expect(bloc.errors, isEmpty);
  });

  test('a handler relaying a stream emits nothing after close()', () async {
    // Given
    final source = StreamController<String>();
    final bloc = _RelayBloc(source.stream);
    final states = <String?>[];
    final subscription = bloc.stream.listen(states.add);
    bloc.add(_Load());
    await Future<void>.delayed(Duration.zero);
    source.add('open');
    await Future<void>.delayed(Duration.zero);

    // When
    final closing = bloc.close();
    source
      ..add('late')
      ..addError(StateError('late failure'));
    await source.close();
    await closing;
    await subscription.cancel();

    // Then
    expect(states, ['open']);
  });

  test('the migrated handler emits while the bloc is open', () async {
    // Given
    final bloc = _MigratedBloc(() async => 'item');
    final states = <String?>[];
    final subscription = bloc.stream.listen(states.add);

    // When
    bloc.add(_Load());
    await Future<void>.delayed(Duration.zero);
    await bloc.close();
    await subscription.cancel();

    // Then
    expect(states, ['item']);
  });
}
