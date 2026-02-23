import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  testWidgets('readOrNull returns null when provider is missing', (
    tester,
  ) async {
    // Given
    final values = <_CounterCubit?>[];

    // When
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
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
      MaterialApp(
        home: Builder(
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
      MaterialApp(
        home: BlocProvider.value(
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
}
