// Exercises the deprecated BuildContext helpers until their removal in 1.0.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  testWidgets('watchOrNull returns null when provider is missing', (
    tester,
  ) async {
    // Given
    final values = <_CounterCubit?>[];

    // When
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          values.add(context.watchOrNull<_CounterCubit>());
          return const SizedBox.shrink();
        },
      ),
    );

    // Then
    expect(values, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('readOrNull returns the bloc without subscribing the widget', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    final values = <_CounterCubit?>[];
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: Builder(
          builder: (context) {
            values.add(context.readOrNull<_CounterCubit>());
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // When
    cubit.increment();
    await tester.pump();
    await tester.pump();

    // Then
    expect(values, [same(cubit)]);
  });

  testWidgets('readOrNull and withBloc work outside build', (tester) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    late BuildContext capturedContext;
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // When
    final bloc = capturedContext.readOrNull<_CounterCubit>();
    final value = capturedContext.withBloc<_CounterCubit, int>(
      (bloc) => bloc.state,
    );

    // Then
    expect(bloc, same(cubit));
    expect(value, 0);
  });

  testWidgets('readOrNull does not swallow errors thrown while creating a bloc',
      (tester) async {
    // Given
    final widget = BlocProvider<_CounterCubit>(
      create: (_) => throw StateError('create failed'),
      child: Builder(
        builder: (context) {
          context.readOrNull<_CounterCubit>();
          return const SizedBox.shrink();
        },
      ),
    );

    // When
    await tester.pumpWidget(widget);
    final buildError = tester.takeException();
    // provider 6.1.5 throws a cast error when disposing a provider whose
    // create callback failed; consume it so only the build error is asserted.
    await tester.pumpWidget(const SizedBox.shrink());
    tester.takeException();

    // Then
    expect(buildError, isA<StateError>());
  });

  testWidgets('selectOrNull does not swallow errors thrown by the selector', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    final widget = BlocProvider.value(
      value: cubit,
      child: Builder(
        builder: (context) {
          context.selectOrNull<_CounterCubit, int, int>(
            (state) => throw StateError('selector failed'),
          );
          return const SizedBox.shrink();
        },
      ),
    );

    // When
    await tester.pumpWidget(widget);

    // Then
    expect(tester.takeException(), isA<StateError>());
  });
}
