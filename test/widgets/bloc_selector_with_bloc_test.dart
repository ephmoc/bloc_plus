import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _SelectorState {
  const _SelectorState({required this.count, required this.flag});

  final int count;
  final bool flag;
}

class _SelectorCubit extends Cubit<_SelectorState> {
  _SelectorCubit() : super(const _SelectorState(count: 0, flag: false));

  void increment() =>
      emit(_SelectorState(count: state.count + 1, flag: state.flag));

  void toggle() => emit(_SelectorState(count: state.count, flag: !state.flag));
}

void main() {
  testWidgets('rebuilds only when selected value changes by default', (
    tester,
  ) async {
    // Given
    final cubit = _SelectorCubit();
    addTearDown(cubit.close);
    final renderedValues = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocSelectorWithBloc<_SelectorCubit, _SelectorState, int>(
            selector: (state) => state.count,
            builder: (context, bloc, selected) {
              expect(bloc, same(cubit));
              renderedValues.add(selected);
              return Text('$selected', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );

    // When
    cubit.toggle(); // selected value unchanged
    await tester.pumpAndSettle();
    cubit.increment(); // selected value changed
    await tester.pumpAndSettle();

    // Then
    expect(renderedValues, [0, 1]);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('uses custom selectorShouldRebuild comparator', (tester) async {
    // Given
    final cubit = _SelectorCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocSelectorWithBloc<_SelectorCubit, _SelectorState, int>(
            selector: (state) => state.count,
            selectorShouldRebuild: (previous, current) => false,
            builder: (context, bloc, selected) =>
                Text('$selected', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );

    // When
    cubit.increment();
    await tester.pumpAndSettle();

    // Then
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('throws when bloc is missing', (tester) async {
    // Given
    final widget = MaterialApp(
      home: BlocSelectorWithBloc<_SelectorCubit, _SelectorState, int>(
        selector: (state) => state.count,
        builder: (context, bloc, selected) => const SizedBox.shrink(),
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
