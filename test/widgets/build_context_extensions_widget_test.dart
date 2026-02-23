import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/material.dart';
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

void main() {
  testWidgets('watchOrNull updates widget when bloc state changes', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
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
      MaterialApp(
        home: BlocProvider.value(
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
      MaterialApp(
        home: Builder(
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
