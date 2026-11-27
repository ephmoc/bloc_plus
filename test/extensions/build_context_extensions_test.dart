// Exercises the deprecated BuildContext helpers until their removal in 1.0.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

class _Repo {
  const _Repo(this.name);

  final String name;
}

/// A [StateStreamableSource] that is not a bloc, so `BlocProvider` accepts it.
class _Store implements StateStreamableSource<int> {
  final _controller = StreamController<int>.broadcast();
  int _state = 0;

  @override
  int get state => _state;

  @override
  Stream<int> get stream => _controller.stream;

  @override
  bool get isClosed => _controller.isClosed;

  @override
  Future<void> close() => _controller.close();

  void increment() => _controller.add(++_state);
}

void main() {
  testWidgets('readOrNull returns null when provider is missing', (
    tester,
  ) async {
    // Given
    final values = <_CounterCubit?>[];

    // When
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            values.add(context.readOrNull<_CounterCubit>());
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // Then
    expect(values, [null]);
  });

  testWidgets('withBloc returns null when provider is missing', (tester) async {
    // Given
    final values = <String?>[];

    // When
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            values.add(context.withBloc<_CounterCubit, String>(
              (bloc) => bloc.state.toString(),
            ));
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // Then
    expect(values, [null]);
  });

  testWidgets('withBloc returns computed value when provider exists', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit()..increment();
    addTearDown(cubit.close);
    final values = <String?>[];

    // When
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              values.add(context.withBloc<_CounterCubit, String>(
                (bloc) => bloc.state.toString(),
              ));
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    // Then
    expect(values, ['1']);
  });

  testWidgets('readOrNull and watchOrNull return a provided repository', (
    tester,
  ) async {
    // Given
    const repo = _Repo('auth');
    final values = <_Repo?>[];

    // When
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: repo,
        child: Builder(
          builder: (context) {
            values
              ..add(context.readOrNull<_Repo>())
              ..add(context.watchOrNull<_Repo>());
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // Then
    expect(values, [same(repo), same(repo)]);
  });

  testWidgets('withBloc infers a repository from the callback', (
    tester,
  ) async {
    // Given
    final names = <String?>[];

    // When
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: const _Repo('auth'),
        child: Builder(
          builder: (context) {
            names.add(context.withBloc((_Repo repo) => repo.name));
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // Then
    expect(names, ['auth']);
  });

  testWidgets('withBloc returns null when the repository is missing', (
    tester,
  ) async {
    // Given
    final names = <String?>[];

    // When
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          names.add(context.withBloc((_Repo repo) => repo.name));
          return const SizedBox.shrink();
        },
      ),
    );

    // Then
    expect(names, [null]);
  });

  testWidgets('selectOrNull follows a store that is not a bloc', (
    tester,
  ) async {
    // Given
    final store = _Store();
    addTearDown(store.close);
    final selected = <bool?>[];
    await tester.pumpWidget(
      BlocProvider.value(
        value: store,
        child: Builder(
          builder: (context) {
            selected.add(
              context.selectOrNull<_Store, int, bool>((state) => state.isOdd),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // When
    store.increment();
    await tester.pumpAndSettle();
    store.increment();
    await tester.pumpAndSettle();

    // Then
    expect(selected, [false, true, false]);
  });
}
