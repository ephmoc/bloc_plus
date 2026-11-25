// @useResult has no runtime behaviour to test: it promises that a result
// that is awaited and dropped is reported. So these tests ask the analyzer of
// the SDK under test about a fixture, which is another library, as an
// application is.

import 'package:flutter_test/flutter_test.dart';

import '../support/analyzer.dart';

// Every line marked `// rejected` has to give unused_result; nothing else may
// give an error or a warning. Without the annotations, the whole fixture would
// be clean.
const _fixture = '''
import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderCubit extends Cubit<int>
    with SafeEmitMixin<int>, RestartableTasksMixin<int> {
  OrderCubit() : super(0);

  final task = RestartableTask<int>();
  final token = CancellationToken();

  Future<void> dropped() async {
    await runLatestOutcome('save', (_) async {}); // rejected
    await task.runOutcome((_) async => 1); // rejected
    await runLatest('save', () async => 1); // rejected
    await guarded(() async => 1); // rejected
    await token.run(() async => 1); // rejected
    emit(1);
  }

  Future<void> checked() async {
    final outcome = await runLatestOutcome('save', (_) async {});
    if (!outcome.isCompleted) return;
    final loaded = await task.runOutcome((_) async => 1);
    if (!loaded.isCompleted) return;
    final latest = await runLatest('save', () async => 1);
    if (latest == null) return;
    final value = await guarded(() async => 1);
    if (value == null) return;
    final result = await token.run(() async => 1);
    if (result == null) return;
    emit(result);
  }

  Future<void> open() => runLatestOutcome('open', (token) async {
        if (token.isCancelled) return;
        emit(2);
      });

  Future<void> openAsync() async => runLatestOutcome('open', (token) async {
        if (token.isCancelled) return;
        emit(2);
      });

  Future<void> openAfterLoading() {
    emit(0);
    return runLatestOutcome('open', (token) async {
      if (token.isCancelled) return;
      emit(2);
    });
  }

  Future<void> openInTry() async {
    try {
      final outcome = await runLatestOutcome('open', (_) async {});
      if (!outcome.isCompleted) return;
    } catch (_) {
      emit(-1);
    }
  }

  void openInBackground() {
    unawaited(runLatestOutcome('open', (_) async {}));
  }

  Future<int?> load() => guarded(() async => 1);

  Future<void> reload() => task.runOutcome((_) async => 1);
}
''';

void main() {
  group('The helpers whose result says whether the run counted', () {
    late List<String> diagnostics;
    late List<String> expected;

    setUpAll(() async {
      diagnostics = await analyzerErrorsAndWarnings(_fixture);
      expected = [
        for (final line in rejectedLines(_fixture)) 'unused_result:$line',
      ];
    });

    test('report a result that is awaited and dropped', () {
      // Given
      // The fixture's dropped() awaits each of the five as a statement.

      // When
      final reported = [
        for (final diagnostic in diagnostics)
          if (expected.contains(diagnostic)) diagnostic,
      ];

      // Then
      expect(reported, unorderedEquals(expected));
    });

    test('accept a result that is checked, returned or passed on', () {
      // Given
      // The fixture's other methods check the result, return the future,
      // also with async =>, or pass it to unawaited.

      // When
      final others = [
        for (final diagnostic in diagnostics)
          if (!expected.contains(diagnostic)) diagnostic,
      ];

      // Then
      expect(others, isEmpty);
    });
  });
}
