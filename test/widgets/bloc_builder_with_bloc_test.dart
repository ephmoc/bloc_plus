import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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
    await tester.pumpAndSettle();

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
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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
    final widget = Directionality(
      textDirection: TextDirection.ltr,
      child: BlocBuilderWithBloc<_CounterCubit, int>(
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

  testWidgets('follows the provided bloc right after bloc changes to null', (
    tester,
  ) async {
    // Given
    final explicit = _CounterCubit();
    final provided = _CounterCubit()
      ..increment()
      ..increment();
    addTearDown(explicit.close);
    addTearDown(provided.close);
    String name(_CounterCubit bloc) =>
        identical(bloc, provided) ? 'provided' : 'explicit';
    Widget builder({required _CounterCubit? bloc}) => BlocProvider.value(
          value: provided,
          child: BlocBuilderWithBloc<_CounterCubit, int>(
            bloc: bloc,
            builder: (context, bloc, state) =>
                Text('${name(bloc)}:$state', textDirection: TextDirection.ltr),
          ),
        );
    await tester.pumpWidget(builder(bloc: explicit));

    // When
    await tester.pumpWidget(builder(bloc: null));
    // The old bloc emits last, so a leftover subscription would show.
    provided.increment();
    explicit.increment();
    await tester.pumpAndSettle();

    // Then
    expect(find.text('provided:3'), findsOneWidget);
  });

  testWidgets('follows a new provided bloc', (tester) async {
    // Given
    final first = _CounterCubit();
    final second = _CounterCubit()
      ..increment()
      ..increment();
    addTearDown(first.close);
    addTearDown(second.close);
    String name(_CounterCubit bloc) =>
        identical(bloc, second) ? 'second' : 'first';
    final builder = BlocBuilderWithBloc<_CounterCubit, int>(
      builder: (context, bloc, state) =>
          Text('${name(bloc)}:$state', textDirection: TextDirection.ltr),
    );
    await tester.pumpWidget(BlocProvider.value(value: first, child: builder));

    // When
    await tester.pumpWidget(BlocProvider.value(value: second, child: builder));
    // The old bloc emits last, so a leftover subscription would show.
    second.increment();
    first.increment();
    await tester.pumpAndSettle();

    // Then
    expect(find.text('second:3'), findsOneWidget);
  });

  testWidgets('buildWhen gets the previous state from the new bloc', (
    tester,
  ) async {
    // Given
    final explicit = _CounterCubit();
    for (var i = 0; i < 5; i++) {
      explicit.increment();
    }
    final provided = _CounterCubit()
      ..increment()
      ..increment();
    addTearDown(explicit.close);
    addTearDown(provided.close);
    final calls = <(int, int)>[];
    Widget builder({required _CounterCubit? bloc}) => BlocProvider.value(
          value: provided,
          child: BlocBuilderWithBloc<_CounterCubit, int>(
            bloc: bloc,
            buildWhen: (previous, current) {
              calls.add((previous, current));
              return true;
            },
            builder: (context, bloc, state) =>
                Text('$state', textDirection: TextDirection.ltr),
          ),
        );
    await tester.pumpWidget(builder(bloc: explicit));

    // When
    await tester.pumpWidget(builder(bloc: null));
    provided.increment();
    await tester.pumpAndSettle();

    // Then
    expect(calls, [(2, 3)]);
  });

  testWidgets('does not create a lazily provided bloc while bloc is explicit', (
    tester,
  ) async {
    // Given
    final explicit = _CounterCubit();
    addTearDown(explicit.close);
    var created = false;

    // When
    await tester.pumpWidget(
      BlocProvider<_CounterCubit>(
        create: (_) {
          created = true;
          return _CounterCubit();
        },
        child: BlocBuilderWithBloc<_CounterCubit, int>(
          bloc: explicit,
          builder: (context, bloc, state) =>
              Text('$state', textDirection: TextDirection.ltr),
        ),
      ),
    );

    // Then
    expect(created, isFalse);
    expect(find.text('0'), findsOneWidget);
  });
}
