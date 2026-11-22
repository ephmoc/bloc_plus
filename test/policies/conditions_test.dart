import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _State {
  const _State(this.count, this.label, this.items);

  final int count;
  final String label;
  final List<int> items;

  _State copyWith({int? count, String? label, List<int>? items}) =>
      _State(count ?? this.count, label ?? this.label, items ?? this.items);
}

class _Cubit extends Cubit<_State> {
  _Cubit() : super(_s0);

  void set(_State next) => emit(next);
}

bool _sameLength(List<int> previous, List<int> current) =>
    previous.length == current.length;

Widget _text(Object value) => Text('$value', textDirection: TextDirection.ltr);

const _s0 = _State(0, 'a', <int>[]);

void main() {
  group('whenChanged', () {
    test('holds when the selected value changes', () {
      // Given
      final condition = whenChanged((_State s) => s.count);

      // When
      final result = condition(_s0, _s0.copyWith(count: 1));

      // Then
      expect(result, isTrue);
    });

    test('does not hold when only other fields change', () {
      // Given
      final condition = whenChanged((_State s) => s.count);

      // When
      final result = condition(_s0, _s0.copyWith(label: 'b'));

      // Then
      expect(result, isFalse);
    });

    test('compares a record of scalars field by field', () {
      // Given
      final condition = whenChanged((_State s) => (s.count, s.label));

      // When
      final otherField = condition(_s0, _s0.copyWith(items: <int>[1]));
      final selectedField = condition(_s0, _s0.copyWith(label: 'b'));

      // Then
      expect([otherField, selectedField], [isFalse, isTrue]);
    });

    test('uses equals instead of == when given', () {
      // Given
      final condition = whenChanged((_State s) => s.items, equals: _sameLength);

      // When
      final sameLength =
          condition(_s0.copyWith(items: [1]), _s0.copyWith(items: [2]));
      final otherLength =
          condition(_s0.copyWith(items: [1]), _s0.copyWith(items: [1, 2]));

      // Then
      expect([sameLength, otherLength], [isFalse, isTrue]);
    });

    test('compares equal lists by content only with equals', () {
      // Given
      final byIdentity = whenChanged((_State s) => s.items);
      final byContent = whenChanged((_State s) => s.items, equals: listEquals);
      final previous = _s0.copyWith(items: [1, 2]);
      final current = _s0.copyWith(items: [1, 2]);

      // When
      final identityResult = byIdentity(previous, current);
      final contentResult = byContent(previous, current);

      // Then
      expect([identityResult, contentResult], [isTrue, isFalse]);
    });

    test('a selector that builds a new list always holds', () {
      // Given
      final condition = whenChanged((_State s) => [s.count]);

      // When
      final result = condition(_s0, _s0);

      // Then
      expect(result, isTrue);
    });
  });

  // Every condition below is written without type arguments: these tests
  // compile only while the state type is inferred from the parameter type.
  group('inference from widget parameters', () {
    late _Cubit cubit;
    late List<String> log;

    setUp(() {
      cubit = _Cubit();
      log = <String>[];
    });

    tearDown(() => cubit.close());

    // Emits a label change, then a count change, then an items change.
    Future<void> emitAll(WidgetTester tester) async {
      cubit.set(_s0.copyWith(label: 'b'));
      await tester.pumpAndSettle();
      cubit.set(_s0.copyWith(label: 'b', count: 1));
      await tester.pumpAndSettle();
      cubit.set(_s0.copyWith(label: 'b', count: 1, items: [9]));
      await tester.pumpAndSettle();
    }

    testWidgets('BlocBuilder.buildWhen rebuilds only on a selected change',
        (tester) async {
      // Given
      await tester.pumpWidget(BlocBuilder<_Cubit, _State>(
        bloc: cubit,
        buildWhen: whenChanged((s) => s.count),
        builder: (context, s) => _text(log..add('build ${s.count}')),
      ));

      // When
      await emitAll(tester);

      // Then
      expect(log, ['build 0', 'build 1']);
    });

    testWidgets('BlocListener.listenWhen listens only on a selected change',
        (tester) async {
      // Given
      await tester.pumpWidget(BlocListener<_Cubit, _State>(
        bloc: cubit,
        listenWhen: whenChanged((s) => s.label),
        listener: (context, s) => log.add('listen ${s.label}'),
        child: const SizedBox(),
      ));

      // When
      await emitAll(tester);

      // Then
      expect(log, ['listen b']);
    });

    testWidgets('BlocConsumer takes both conditions, one with equals',
        (tester) async {
      // Given
      await tester.pumpWidget(BlocConsumer<_Cubit, _State>(
        bloc: cubit,
        buildWhen: whenChanged((s) => s.count),
        listenWhen: whenChanged((s) => s.items, equals: listEquals),
        listener: (context, s) => log.add('listen ${s.items}'),
        builder: (context, s) => _text(log..add('build ${s.count}')),
      ));

      // When
      await emitAll(tester);

      // Then
      expect(log, ['build 0', 'build 1', 'listen [9]']);
    });

    testWidgets('BlocBuilderWithBloc and BlocListenerWithBloc', (tester) async {
      // Given
      await tester.pumpWidget(BlocListenerWithBloc<_Cubit, _State>(
        bloc: cubit,
        listenWhen: whenChanged((s) => s.label),
        listener: (context, bloc, s) => log.add('listen ${s.label}'),
        child: BlocBuilderWithBloc<_Cubit, _State>(
          bloc: cubit,
          buildWhen: whenChanged((s) => s.items.length),
          builder: (context, bloc, s) => _text(log..add('build ${s.items}')),
        ),
      ));

      // When
      await emitAll(tester);

      // Then
      expect(log, ['build []', 'listen b', 'build [9]']);
    });

    testWidgets('BlocConsumerWithBloc with a record and a plain predicate',
        (tester) async {
      // Given
      await tester.pumpWidget(BlocConsumerWithBloc<_Cubit, _State>(
        bloc: cubit,
        buildWhen: whenChanged((s) => (s.count, s.items.length)),
        listenWhen: (previous, current) => previous.label != current.label,
        listener: (context, bloc, s) => log.add('listen ${s.label}'),
        builder: (context, bloc, s) => _text(log..add('build ${s.count}')),
      ));

      // When
      await emitAll(tester);

      // Then
      expect(log, ['build 0', 'listen b', 'build 1', 'build 1']);
    });

    testWidgets('BlocSelectorWithBloc.selectorShouldRebuild', (tester) async {
      // Given
      await tester.pumpWidget(BlocSelectorWithBloc<_Cubit, _State, List<int>>(
        bloc: cubit,
        selector: (s) => s.items,
        selectorShouldRebuild: whenChanged((items) => items.length),
        builder: (context, bloc, items) => _text(log..add('build $items')),
      ));

      // When
      await emitAll(tester);

      // Then
      expect(log, ['build []', 'build [9]']);
    });

    testWidgets('a provided bloc works the same as an explicit one',
        (tester) async {
      // Given
      await tester.pumpWidget(BlocProvider<_Cubit>.value(
        value: cubit,
        child: BlocBuilderWithBloc<_Cubit, _State>(
          buildWhen: whenChanged((s) => s.count),
          builder: (context, bloc, s) => _text(log..add('build ${s.count}')),
        ),
      ));

      // When
      await emitAll(tester);

      // Then
      expect(log, ['build 0', 'build 1']);
    });
  });
}
