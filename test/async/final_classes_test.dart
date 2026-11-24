// A final class has no runtime behaviour to test: it promises that code
// outside its library cannot extend or implement it. So these tests ask the
// analyzer of the SDK under test about a fixture, which is another library.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

/// The Dart SDK of the Flutter SDK under test. `flutter test` sets
/// FLUTTER_ROOT to it; `dart` on PATH may belong to another SDK.
String _dart() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return 'dart';
  return '$root/bin/cache/dart-sdk/bin/${Platform.isWindows ? 'dart.exe' : 'dart'}';
}

/// The errors in the JSON output of `dart analyze`, as `code:line`. Warnings
/// and lints are left out: they depend on the lint set, not on the modifiers.
List<String> _errors(ProcessResult result) {
  final stdout = '${result.stdout}';
  // Older SDKs print an "Analyzing ..." line before the JSON.
  final start = stdout.indexOf('{');
  if (start < 0) {
    fail('dart analyze printed no JSON.\n$stdout\n${result.stderr}');
  }
  final json = jsonDecode(stdout.substring(start)) as Map<String, Object?>;
  final diagnostics =
      (json['diagnostics']! as List<Object?>).cast<Map<String, Object?>>();
  return [
    for (final diagnostic in diagnostics)
      if (diagnostic['severity'] == 'ERROR')
        '${diagnostic['code']}:${_line(diagnostic)}',
  ];
}

int _line(Map<String, Object?> diagnostic) {
  final location = diagnostic['location']! as Map<String, Object?>;
  final range = location['range']! as Map<String, Object?>;
  final start = range['start']! as Map<String, Object?>;
  return start['line']! as int;
}

void main() {
  group('CancellationToken, RestartableTask and TaskOutcome', () {
    late List<String> errors;

    setUpAll(() async {
      final dir = Directory('.dart_tool').createTempSync('final_classes_');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/fixture.dart').writeAsStringSync(_fixture);
      final result = await Process.run(
        _dart(),
        ['analyze', '--format=json', dir.path],
      );
      errors = _errors(result);
    });

    test('cannot be extended or implemented outside their library', () {
      // Given
      final rejectedLines = [
        for (final (index, line) in _fixture.split('\n').indexed)
          if (line.endsWith('// rejected')) index + 1,
      ];

      // When
      final rejected = [
        for (final error in errors)
          if (error.startsWith('$_rejected:')) error,
      ];

      // Then
      expect(rejected, [for (final line in rejectedLines) '$_rejected:$line']);
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
