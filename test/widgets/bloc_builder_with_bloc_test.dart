import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  testWidgets('rebuilds on state changes and provides bloc instance', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    var buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocBuilderWithBloc<_CounterCubit, int>(
            builder: (context, bloc, state) {
              buildCount++;
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
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(buildCount, 2);
  });

  testWidgets('explicit bloc overrides context bloc', (tester) async {
    // Given
    final explicitCubit = _CounterCubit();
    final contextCubit = _CounterCubit()..increment();
    addTearDown(explicitCubit.close);
    addTearDown(contextCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: contextCubit,
          child: BlocBuilderWithBloc<_CounterCubit, int>(
            bloc: explicitCubit,
            builder: (context, bloc, state) {
              expect(bloc, same(explicitCubit));
              return Text('$state', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );

    // When
    await tester.pump();

    // Then
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('throws when bloc is missing', (tester) async {
    // Given
    final widget = MaterialApp(
      home: BlocBuilderWithBloc<_CounterCubit, int>(
        builder: (context, bloc, state) {
          return const SizedBox.shrink();
        },
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
