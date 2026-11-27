// Exercises the deprecated BuildContext helpers until their removal in 1.0.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterState {
  const _CounterState({required this.count, required this.flag});

  final int count;
  final bool flag;
}

class _CounterCubit extends Cubit<_CounterState> {
  _CounterCubit() : super(const _CounterState(count: 0, flag: false));

  void increment() =>
      emit(_CounterState(count: state.count + 1, flag: state.flag));

  void toggle() => emit(_CounterState(count: state.count, flag: !state.flag));
}

class _Repo {}

class _RepoCubit extends Cubit<int> {
  _RepoCubit(this.repo) : super(0);

  final _Repo repo;
}

class _IntCubit extends Cubit<int> {
  _IntCubit() : super(5);

  void increment() => emit(state + 1);
}

void main() {
  testWidgets(
      'readOrNull surfaces a missing dependency of a lazily created bloc', (
    tester,
  ) async {
    // Given
    final results = <_RepoCubit?>[];
    final widget = BlocProvider<_RepoCubit>(
      create: (context) => _RepoCubit(context.read<_Repo>()),
      child: Builder(
        builder: (context) {
          results.add(context.readOrNull<_RepoCubit>());
          return const SizedBox.shrink();
        },
      ),
    );

    // When
    await tester.pumpWidget(widget);
    final buildError = tester.takeException();
    // provider throws a cast error when disposing a provider whose create
    // callback failed; consume it so only the build error is asserted.
    await tester.pumpWidget(const SizedBox.shrink());
    tester.takeException();

    // Then
    expect(buildError, isA<ProviderNotFoundException>());
    expect(results, isEmpty);
  });

  testWidgets(
      'watchOrNull picks up a provider that appears above a relocated widget',
      (tester) async {
    // Given
    final cubit = _IntCubit();
    addTearDown(cubit.close);
    final watched = <int?>[];
    final child = Builder(
      key: GlobalKey(),
      builder: (context) {
        watched.add(context.watchOrNull<_IntCubit>()?.state);
        return const SizedBox.shrink();
      },
    );
    await tester.pumpWidget(child);

    // When
    await tester.pumpWidget(BlocProvider.value(value: cubit, child: child));
    cubit.increment();
    await tester.pumpAndSettle();

    // Then
    expect(watched, [null, 5, 6]);
  });

  testWidgets(
      'selectOrNull picks up a provider that appears above a relocated widget',
      (tester) async {
    // Given
    final cubit = _IntCubit();
    addTearDown(cubit.close);
    final selected = <int?>[];
    final child = Builder(
      key: GlobalKey(),
      builder: (context) {
        selected.add(context.selectOrNull<_IntCubit, int, int>((s) => s));
        return const SizedBox.shrink();
      },
    );
    await tester.pumpWidget(child);

    // When
    await tester.pumpWidget(BlocProvider.value(value: cubit, child: child));
    cubit.increment();
    await tester.pumpAndSettle();

    // Then
    expect(selected, [null, 5, 6]);
  });

  testWidgets('watchOrNull updates widget when bloc state changes', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              final bloc = context.watchOrNull<_CounterCubit>();
              final count = bloc?.state.count ?? -1;
              return Text('$count', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );

    // When
    cubit.increment();
    await tester.pumpAndSettle();

    // Then
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('selectOrNull rebuilds only when selected value changes', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    final renderedCounts = <int?>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              final selected =
                  context.selectOrNull<_CounterCubit, _CounterState, int>(
                      (state) => state.count);
              renderedCounts.add(selected);
              return Text('${selected ?? -1}',
                  textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );

    // When
    cubit.toggle(); // no selected value change
    await tester.pumpAndSettle();
    cubit.increment(); // selected value change
    await tester.pumpAndSettle();

    // Then
    expect(renderedCounts, [0, 1]);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('selectOrNull returns null when provider is missing', (
    tester,
  ) async {
    // Given
    final values = <int?>[];

    // When
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            values.add(
              context.selectOrNull<_CounterCubit, _CounterState, int>(
                (state) => state.count,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // Then
    expect(values, [null]);
  });
}
