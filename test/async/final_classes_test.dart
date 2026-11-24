// A final class has no runtime behaviour to test: it promises that code
// outside its library cannot extend or implement it. So these tests ask the
// analyzer of the SDK under test about a fixture, which is another library.

import 'package:flutter_test/flutter_test.dart';

import '../support/analyzer.dart';

const _rejected = 'invalid_use_of_type_outside_library';

// Every line marked `// rejected` has to be an error; nothing else may be.
// Without the final modifiers, the whole fixture would compile.
const _fixture = '''
import 'package:bloc_plus/bloc_plus.dart';

class ExtendsToken extends CancellationToken {} // rejected

class ImplementsToken implements CancellationToken { // rejected
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ExtendsTask extends RestartableTask<int> {} // rejected

class ImplementsTask implements RestartableTask<int> { // rejected
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ExtendsOutcome extends TaskOutcome<int> { // rejected
  const ExtendsOutcome() : super.cancelled();
}

class ImplementsOutcome implements TaskOutcome<int> { // rejected
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<bool> useDirectly() async {
  final token = CancellationToken()..cancel();
  final task = RestartableTask<int>();
  final outcome = await task.runOutcome((_) async => 1);
  task.dispose();
  return token.isCancelled && outcome == const TaskOutcome<int>.completed(1);
}
''';

void main() {
  group('CancellationToken, RestartableTask and TaskOutcome', () {
    late List<String> errors;

    setUpAll(() async {
      errors = await analyzerErrors(_fixture);
    });

    test('cannot be extended or implemented outside their library', () {
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

    test('can still be created and used directly', () {
      // Given
      // The fixture's useDirectly() creates and runs all three.

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
