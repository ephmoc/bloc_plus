import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
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
    final listened = <String>[];
    String name(_CounterCubit bloc) =>
        identical(bloc, provided) ? 'provided' : 'explicit';
    Widget consumer({required _CounterCubit? bloc}) => BlocProvider.value(
          value: provided,
          child: BlocConsumerWithBloc<_CounterCubit, int>(
            bloc: bloc,
            listener: (context, bloc, state) =>
                listened.add('${name(bloc)}:$state'),
            builder: (context, bloc, state) =>
                Text('${name(bloc)}:$state', textDirection: TextDirection.ltr),
          ),
        );
    await tester.pumpWidget(consumer(bloc: explicit));

    // When
    await tester.pumpWidget(consumer(bloc: null));
    explicit.increment();
    provided.increment();
    await tester.pumpAndSettle();

    // Then
    expect(listened, ['provided:3']);
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
    final listened = <String>[];
    String name(_CounterCubit bloc) =>
        identical(bloc, second) ? 'second' : 'first';
    final consumer = BlocConsumerWithBloc<_CounterCubit, int>(
      listener: (context, bloc, state) => listened.add('${name(bloc)}:$state'),
      builder: (context, bloc, state) =>
          Text('${name(bloc)}:$state', textDirection: TextDirection.ltr),
    );
    await tester.pumpWidget(BlocProvider.value(value: first, child: consumer));

    // When
    await tester.pumpWidget(BlocProvider.value(value: second, child: consumer));
    first.increment();
    second.increment();
    await tester.pumpAndSettle();

    // Then
    expect(listened, ['second:3']);
    expect(find.text('second:3'), findsOneWidget);
  });

  testWidgets('does not rebuild for a state that buildWhen rejects', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    var builds = 0;
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: BlocConsumerWithBloc<_CounterCubit, int>(
          buildWhen: (previous, current) => false,
          listener: (context, bloc, state) {},
          builder: (context, bloc, state) {
            builds++;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // When
    cubit.increment();
    await tester.pumpAndSettle();

    // Then
    expect(builds, 1);
  });

  testWidgets('builds and listens with bloc instance', (tester) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    final listened = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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
    await tester.pumpAndSettle();

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
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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
    final widget = Directionality(
      textDirection: TextDirection.ltr,
      child: BlocConsumerWithBloc<_CounterCubit, int>(
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
