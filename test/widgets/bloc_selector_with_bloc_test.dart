import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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
    final widget = Directionality(
      textDirection: TextDirection.ltr,
      child: BlocSelectorWithBloc<_SelectorCubit, _SelectorState, int>(
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

  testWidgets('renders the current selection after the selector changes', (
    tester,
  ) async {
    // Given
    final cubit = _MapCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(_mapSelector(cubit, 'a'));
    cubit.set(const {'a': 1, 'b': 2});
    await tester.pumpAndSettle();

    // When
    await tester.pumpWidget(_mapSelector(cubit, 'b'));

    // Then
    expect(find.text('b=2'), findsOneWidget);
  });

  testWidgets('runs the selector once per state change', (tester) async {
    // Given
    final cubit = _MapCubit();
    addTearDown(cubit.close);
    var calls = 0;
    await tester.pumpWidget(
      _mapSelector(cubit, 'a', onSelect: () => calls++),
    );
    calls = 0;

    // When
    cubit.set(const {'a': 2, 'b': 1});
    await tester.pumpAndSettle();
    cubit.set(const {'a': 2, 'b': 7});
    await tester.pumpAndSettle();

    // Then
    expect(find.text('a=2'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('selectorShouldRebuild compares with the last built selection', (
    tester,
  ) async {
    // Given
    final cubit = _SelectorCubit();
    addTearDown(cubit.close);
    final built = <int>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocSelectorWithBloc<_SelectorCubit, _SelectorState, int>(
          bloc: cubit,
          selector: (state) => state.count,
          selectorShouldRebuild: (previous, current) =>
              (current - previous).abs() >= 3,
          builder: (context, bloc, count) {
            built.add(count);
            return Text('$count');
          },
        ),
      ),
    );

    // When
    for (var i = 0; i < 6; i++) {
      cubit.increment();
      await tester.pumpAndSettle();
    }

    // Then
    expect(built, [0, 3, 6]);
  });

  testWidgets('switches to a new explicit bloc', (tester) async {
    // Given
    final first = _SelectorCubit();
    final second = _SelectorCubit()
      ..increment()
      ..increment();
    addTearDown(first.close);
    addTearDown(second.close);
    final builtWith = <_SelectorCubit>[];
    Widget host(_SelectorCubit cubit) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: BlocSelectorWithBloc<_SelectorCubit, _SelectorState, int>(
          bloc: cubit,
          selector: (state) => state.count,
          builder: (context, bloc, count) {
            builtWith.add(bloc);
            return Text('$count');
          },
        ),
      );
    }

    await tester.pumpWidget(host(first));

    // When
    await tester.pumpWidget(host(second));
    first.increment();
    second.increment();
    await tester.pumpAndSettle();

    // Then
    expect(find.text('3'), findsOneWidget);
    expect(builtWith.last, same(second));
  });

  testWidgets('switches to a new provided bloc', (tester) async {
    // Given
    final first = _SelectorCubit();
    final second = _SelectorCubit()
      ..increment()
      ..increment();
    addTearDown(first.close);
    addTearDown(second.close);
    // The same instance in both pumps, so only the provider change can
    // rebuild it.
    final selectorWidget =
        BlocSelectorWithBloc<_SelectorCubit, _SelectorState, int>(
      selector: (state) => state.count,
      builder: (context, bloc, count) => Text('$count'),
    );
    Widget host(_SelectorCubit cubit) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider<_SelectorCubit>.value(
          value: cubit,
          child: selectorWidget,
        ),
      );
    }

    await tester.pumpWidget(host(first));

    // When
    await tester.pumpWidget(host(second));
    second.increment();
    await tester.pumpAndSettle();

    // Then
    expect(find.text('3'), findsOneWidget);
  });
}

class _MapCubit extends Cubit<Map<String, int>> {
  _MapCubit() : super(const {'a': 1, 'b': 1});

  void set(Map<String, int> value) => emit(value);
}

Widget _mapSelector(
  _MapCubit cubit,
  String key, {
  void Function()? onSelect,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: BlocSelectorWithBloc<_MapCubit, Map<String, int>, int>(
      bloc: cubit,
      selector: (state) {
        onSelect?.call();
        return state[key]!;
      },
      builder: (context, bloc, selected) => Text('$key=$selected'),
    ),
  );
}
