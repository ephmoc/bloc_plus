import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);

  final listened = <int>[];

  void increment() => emit(state + 1);
}

// A top-level function, so the listener below can be const.
void _recordOnBloc(BuildContext context, _CounterCubit bloc, int state) =>
    bloc.listened.add(state);

void main() {
  testWidgets('a const listener passes the provided bloc', (tester) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const BlocListenerWithBloc<_CounterCubit, int>(
          listener: _recordOnBloc,
          child: SizedBox.shrink(),
        ),
      ),
    );

    // When
    cubit.increment();
    await tester.pump();

    // Then
    expect(cubit.listened, [1]);
  });

  testWidgets('calls listener on state changes and provides bloc', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    final listenedStates = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider.value(
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
    final widget = Directionality(
      textDirection: TextDirection.ltr,
      child: BlocListenerWithBloc<_CounterCubit, int>(
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
    Widget listener({required _CounterCubit? bloc}) => BlocProvider.value(
          value: provided,
          child: BlocListenerWithBloc<_CounterCubit, int>(
            bloc: bloc,
            listener: (context, bloc, state) =>
                listened.add('${name(bloc)}:$state'),
            child: const SizedBox.shrink(),
          ),
        );
    await tester.pumpWidget(listener(bloc: explicit));

    // When
    await tester.pumpWidget(listener(bloc: null));
    explicit.increment();
    provided.increment();
    await tester.pumpAndSettle();

    // Then
    expect(listened, ['provided:3']);
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
    final listener = BlocListenerWithBloc<_CounterCubit, int>(
      listener: (context, bloc, state) => listened.add('${name(bloc)}:$state'),
      child: const SizedBox.shrink(),
    );
    await tester.pumpWidget(BlocProvider.value(value: first, child: listener));

    // When
    await tester.pumpWidget(BlocProvider.value(value: second, child: listener));
    first.increment();
    second.increment();
    await tester.pumpAndSettle();

    // Then
    expect(listened, ['second:3']);
  });

  testWidgets('listenWhen gets the previous state from the new bloc', (
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
    Widget listener({required _CounterCubit? bloc}) => BlocProvider.value(
          value: provided,
          child: BlocListenerWithBloc<_CounterCubit, int>(
            bloc: bloc,
            listenWhen: (previous, current) {
              calls.add((previous, current));
              return true;
            },
            listener: (context, bloc, state) {},
            child: const SizedBox.shrink(),
          ),
        );
    await tester.pumpWidget(listener(bloc: explicit));

    // When
    await tester.pumpWidget(listener(bloc: null));
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
        child: BlocListenerWithBloc<_CounterCubit, int>(
          bloc: explicit,
          listener: (context, bloc, state) {},
          child: const SizedBox.shrink(),
        ),
      ),
    );

    // Then
    expect(created, isFalse);
  });

  testWidgets('listens and renders nothing when it has no child', (
    tester,
  ) async {
    // Given
    final cubit = _CounterCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      Center(
        child: BlocListenerWithBloc<_CounterCubit, int>(
          bloc: cubit,
          listener: _recordOnBloc,
        ),
      ),
    );

    // When
    cubit.increment();
    await tester.pump();

    // Then
    expect(cubit.listened, [1]);
    expect(
      tester.getSize(find.byType(BlocListenerWithBloc<_CounterCubit, int>)),
      Size.zero,
    );
  });

  testWidgets('composes inside MultiBlocListener', (tester) async {
    // Given
    final first = _CounterCubit();
    final second = _CounterCubit();
    addTearDown(first.close);
    addTearDown(second.close);
    final listened = <String>[];
    await tester.pumpWidget(
      MultiBlocListener(
        listeners: [
          BlocListenerWithBloc<_CounterCubit, int>(
            bloc: first,
            listener: (context, bloc, state) => listened.add('first:$state'),
          ),
          BlocListenerWithBloc<_CounterCubit, int>(
            bloc: second,
            listener: (context, bloc, state) => listened.add('second:$state'),
          ),
        ],
        child: const SizedBox.shrink(),
      ),
    );

    // When
    first.increment();
    second.increment();
    await tester.pumpAndSettle();

    // Then
    expect(listened, ['first:1', 'second:1']);
  });
}
