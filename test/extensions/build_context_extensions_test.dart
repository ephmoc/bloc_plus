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

/// A [StateStreamable] that is not a bloc.
class _Store implements StateStreamable<int> {
  const _Store(this.state);

  @override
  final int state;

  @override
  Stream<int> get stream => const Stream.empty();
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

  testWidgets('selectOrNull selects from a provided store that is not a bloc',
      (tester) async {
    // Given
    final selected = <bool?>[];

    // When
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: const _Store(3),
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

    // Then
    expect(selected, [true]);
  });
}
