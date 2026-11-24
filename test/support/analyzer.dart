// Some contracts, such as a final class or a type bound, have no runtime
// behaviour to test: they promise that some code outside the package does
// not compile. Tests of such contracts ask the analyzer of the SDK under test
// about a fixture, which is another library, as an application is.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The errors that `dart analyze` reports for [fixture], as `code:line`.
///
/// Warnings and lints are left out: they depend on the lint set, not on the
/// contract.
Future<List<String>> analyzerErrors(String fixture) async {
  final dir = Directory('.dart_tool').createTempSync('fixture_');
  try {
    File('${dir.path}/fixture.dart').writeAsStringSync(fixture);
    final result = await Process.run(
      _dart(),
      ['analyze', '--format=json', dir.path],
    );
    return _errors(result);
  } finally {
    dir.deleteSync(recursive: true);
  }
}

/// The numbers of the lines of [fixture] that end with `// rejected`.
List<int> rejectedLines(String fixture) => [
      for (final (index, line) in fixture.split('\n').indexed)
        if (line.endsWith('// rejected')) index + 1,
    ];

/// The Dart SDK of the Flutter SDK under test. `flutter test` sets
/// FLUTTER_ROOT to it; `dart` on PATH may belong to another SDK.
String _dart() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return 'dart';
  return '$root/bin/cache/dart-sdk/bin/${Platform.isWindows ? 'dart.exe' : 'dart'}';
}

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
