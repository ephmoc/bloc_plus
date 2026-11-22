import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [StateStreamable] that is not a bloc, like a store from another library.
class _Store implements StateStreamable<int> {
  final _controller = StreamController<int>.broadcast();
  int _state = 0;

  @override
  int get state => _state;

  @override
  Stream<int> get stream => _controller.stream;

  void increment() => _controller.add(++_state);

  Future<void> close() => _controller.close();
}

void main() {
  testWidgets('BlocBuilderWithBloc builds from a store that is not a bloc',
      (tester) async {
    // Given
    final store = _Store();
    addTearDown(store.close);
    await tester.pumpWidget(
      BlocBuilderWithBloc<_Store, int>(
        bloc: store,
        builder: (context, bloc, state) => Text(
          '${identical(bloc, store)}:$state',
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    // When
    store.increment();
    await tester.pumpAndSettle();

    // Then
    expect(find.text('true:1'), findsOneWidget);
  });

  testWidgets('BlocListenerWithBloc listens to a store that is not a bloc',
      (tester) async {
    // Given
    final store = _Store();
    addTearDown(store.close);
    final listened = <String>[];
    await tester.pumpWidget(
      BlocListenerWithBloc<_Store, int>(
        bloc: store,
        listener: (context, bloc, state) =>
            listened.add('${identical(bloc, store)}:$state'),
        child: const SizedBox.shrink(),
      ),
    );

    // When
    store.increment();
    await tester.pump();

    // Then
    expect(listened, ['true:1']);
  });

  testWidgets(
      'BlocConsumerWithBloc consumes a provided store that is not a '
      'bloc', (tester) async {
    // Given
    final store = _Store();
    addTearDown(store.close);
    final listened = <String>[];
    await tester.pumpWidget(
      RepositoryProvider<_Store>.value(
        value: store,
        child: BlocConsumerWithBloc<_Store, int>(
          listener: (context, bloc, state) =>
              listened.add('${identical(bloc, store)}:$state'),
          builder: (context, bloc, state) =>
              Text('$state', textDirection: TextDirection.ltr),
        ),
      ),
    );

    // When
    store.increment();
    await tester.pumpAndSettle();

    // Then
    expect(listened, ['true:1']);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('BlocSelectorWithBloc selects from a store that is not a bloc',
      (tester) async {
    // Given
    final store = _Store();
    addTearDown(store.close);
    await tester.pumpWidget(
      BlocSelectorWithBloc<_Store, int, bool>(
        bloc: store,
        selector: (state) => state.isOdd,
        builder: (context, bloc, isOdd) => Text(
          '${identical(bloc, store)}:$isOdd',
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    // When
    store.increment();
    await tester.pumpAndSettle();

    // Then
    expect(find.text('true:true'), findsOneWidget);
  });
}
