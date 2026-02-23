import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  testWidgets('calls listener on state changes and provides bloc', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    final listenedStates = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocListenerWithBloc<_CounterCubit, int>(
            listener: (context, bloc, state) {
              expect(bloc, same(cubit));
              listenedStates.add(state);
            },
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // When
    cubit.increment();
    await tester.pump();

    // Then
    expect(listenedStates, isNotEmpty);
    expect(listenedStates, [1]);
  });

  testWidgets('respects listenWhen', (tester) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    final listenedStates = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocListenerWithBloc<_CounterCubit, int>(
            listenWhen: (previous, current) => current.isEven,
            listener: (context, bloc, state) => listenedStates.add(state),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // When
    cubit.increment(); // 1
    await tester.pump();
    cubit.increment(); // 2
    await tester.pump();

    // Then
    expect(listenedStates, [2]);
  });

  testWidgets('throws when bloc is missing', (tester) async {
    // Given
    final widget = MaterialApp(
      home: BlocListenerWithBloc<_CounterCubit, int>(
        listener: (context, bloc, state) {},
        child: const SizedBox.shrink(),
      ),
    );

    // When
    await tester.pumpWidget(
      widget,
    );

    // Then
    final exception = tester.takeException();
    expect(exception, isA<ProviderNotFoundException>());
  });
}
