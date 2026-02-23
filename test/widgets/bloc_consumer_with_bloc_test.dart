import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  testWidgets('builds and listens with bloc instance', (tester) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    final listened = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocConsumerWithBloc<_CounterCubit, int>(
            listener: (context, bloc, state) {
              expect(bloc, same(cubit));
              listened.add(state);
            },
            builder: (context, bloc, state) {
              expect(bloc, same(cubit));
              return Text('$state', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );

    // When
    cubit.increment();
    await tester.pump();

    // Then
    expect(find.text('1'), findsOneWidget);
    expect(listened, [1]);
  });

  testWidgets('respects buildWhen and listenWhen independently', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    final listened = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocConsumerWithBloc<_CounterCubit, int>(
            buildWhen: (previous, current) => current.isEven,
            listenWhen: (previous, current) => current.isOdd,
            listener: (context, bloc, state) => listened.add(state),
            builder: (context, bloc, state) =>
                Text('$state', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );

    // When
    cubit.increment(); // 1 -> listen only
    await tester.pumpAndSettle();
    cubit.increment(); // 2 -> build only
    await tester.pumpAndSettle();

    // Then
    expect(listened, [1]);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('throws when bloc is missing', (tester) async {
    // Given
    final widget = MaterialApp(
      home: BlocConsumerWithBloc<_CounterCubit, int>(
        listener: (context, bloc, state) {},
        builder: (context, bloc, state) => const SizedBox.shrink(),
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
