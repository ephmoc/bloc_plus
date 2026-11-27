// The bound `T extends Object` has no runtime behaviour to test: it promises
// that a call with a `void`, nullable or `dynamic` result does not compile.
// So these tests ask the analyzer of the SDK under test about a fixture.

import 'package:flutter_test/flutter_test.dart';

import '../support/analyzer.dart';

const _rejected = 'could_not_infer';

// Every line marked `// rejected` has to be an error; nothing else may be.
// Without the bound, the whole fixture would compile.
const _fixture = '''
import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SaveCubit extends Cubit<int>
    with SafeEmitMixin<int>, RestartableTasksMixin<int> {
  SaveCubit() : super(0);

  Future<void> save() async {}
  Future<int?> find() async => null;
  Future<dynamic> fetch() async => 1;

  Future<void> voidNullableOrDynamic(CancellationToken token) async {
    await runLatest('save', save); // rejected
    await runLatest('find', find); // rejected
    await runLatest('fetch', fetch); // rejected
    await guarded(save); // rejected
    await guarded(find); // rejected
    await guarded(fetch); // rejected
    await token.run(save); // rejected
    await token.run(find); // rejected
    await token.run(fetch); // rejected
  }

  Future<List<Object?>> nonNull(CancellationToken token) async => [
        await runLatest('count', () async => 1),
        await guarded(() async => (item: await find())),
        await token.run(() async => (item: await find())),
        await load(() async => 1),
        await runLatestOutcome('save', (_) => save()),
        await runLatestOutcome('find', (_) => find()),
      ];

  Future<T?> load<T extends Object>(Future<T> Function() task) =>
      guarded(task);
}
''';

void main() {
  group('runLatest, guarded and CancellationToken.run', () {
    late List<String> errors;

    setUpAll(() async {
      errors = await analyzerErrors(_fixture);
    });

    test('reject a void, nullable or dynamic result', () {
      // Given
      final lines = rejectedLines(_fixture);

      // When
      final rejected = [
        for (final error in errors)
          if (error.startsWith('$_rejected:')) error,
      ];

      // Then
      expect(rejected, [for (final line in lines) '$_rejected:$line']);
    });

    test('accept a non-null result', () {
      // Given
      // The fixture's nonNull() also forwards a task through a helper with
      // the same bound, and runs void and nullable work through
      // runLatestOutcome, which takes any result.

      // When
      final others = [
        for (final error in errors)
          if (!error.startsWith('$_rejected:')) error,
      ];

      // Then
      expect(others, isEmpty);
    });
  });
}
