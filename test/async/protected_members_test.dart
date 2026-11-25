// @protected and @visibleForTesting have no runtime behaviour to test: they
// promise that a call from outside the bloc and outside tests is reported. So
// these tests ask the analyzer of the SDK under test about a fixture, which is
// neither part of the bloc nor a test.

import 'package:flutter_test/flutter_test.dart';

import '../support/analyzer.dart';

const _codes = [
  'invalid_use_of_protected_member',
  'invalid_use_of_visible_for_testing_member',
];

// Every line marked `// rejected` has to give both warnings; nothing else may
// give an error or a warning. Without the annotations, the whole fixture would
// be clean.
const _fixture = '''
import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchCubit extends Cubit<int>
    with SafeEmitMixin<int>, RestartableTasksMixin<int> {
  SearchCubit() : super(0);

  Future<void> search() async {
    if (isTaskRunning('search')) return;
    if (await runLatest('search', () async => 1) == null) return;
    final outcome = await runLatestOutcome('search', (_) async => 1);
    if (!outcome.isCompleted) return;
    if (await guarded(() async => 1) == null) return;
    cancelLatest('search');
    cancelAllLatest();
  }
}

class SubCubit extends SearchCubit {
  bool get busy => isTaskRunning('search');
  Future<int?> load() => guarded(() async => 1);
}

mixin Busy on SafeEmitMixin<int>, RestartableTasksMixin<int> {
  bool get busy => isTaskRunning('search');
  Future<int?> load() => guarded(() async => 1);
}

class SearchBloc extends Bloc<String, int> with RestartableTasksMixin<int> {
  SearchBloc() : super(0) {
    on<String>((query, emit) async {
      if (isTaskRunning(query)) cancelLatest(query);
    });
  }
}

Widget status(SearchCubit cubit) {
  final running = cubit.isTaskRunning('search'); // rejected
  unawaited(cubit.runLatest('search', () async => 1)); // rejected
  unawaited(cubit.runLatestOutcome('search', (_) async => 1)); // rejected
  cubit.cancelLatest('search'); // rejected
  cubit.cancelAllLatest(); // rejected
  unawaited(cubit.guarded(() async => 1)); // rejected
  return Text('\$running');
}

extension Status on SearchCubit {
  bool get running => isTaskRunning('search'); // rejected
}
''';

void main() {
  group('The protected members of RestartableTasksMixin and guarded', () {
    late List<String> diagnostics;
    late List<String> expected;

    setUpAll(() async {
      diagnostics = await analyzerErrorsAndWarnings(_fixture);
      expected = [
        for (final line in rejectedLines(_fixture))
          for (final code in _codes) '$code:$line',
      ];
    });

    test('are reported when called from a widget or an extension', () {
      // Given
      // The fixture's status() and Status call each member from outside.

      // When
      final reported = [
        for (final diagnostic in diagnostics)
          if (expected.contains(diagnostic)) diagnostic,
      ];

      // Then
      expect(reported, unorderedEquals(expected));
    });

    test('can be called from the bloc, a subclass and a mixin on it', () {
      // Given
      // The fixture's SearchCubit, SubCubit, Busy and the handler of
      // SearchBloc call them from inside.

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
