// That SafeEmitMixin applies to Cubits only has no runtime behaviour to
// test: it promises that a Bloc or a direct BlocBase subclass cannot mix it
// in. So these tests ask the analyzer of the SDK under test about a fixture.

import 'package:flutter_test/flutter_test.dart';

import '../support/analyzer.dart';

const _rejected = 'mixin_application_not_implemented_interface';

// Every line marked `// rejected` has to be an error; nothing else may be.
// With the mixin on BlocBase, the whole fixture would compile.
const _fixture = '''
import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Event {}

class SafeBloc extends Bloc<Event, int> with SafeEmitMixin<int> { // rejected
  SafeBloc() : super(0);
}

class SafeBase extends BlocBase<int> with SafeEmitMixin<int> { // rejected
  SafeBase() : super(0);
}

class SafeCubit extends Cubit<int> with SafeEmitMixin<int> {
  SafeCubit() : super(0);

  void set(int value) => safeEmit(value);
}

class TasksAndEffectsBloc extends Bloc<Event, int>
    with RestartableTasksMixin<int>, HasEffects<int, String> {
  TasksAndEffectsBloc() : super(0);
}
''';

void main() {
  group('SafeEmitMixin', () {
    late List<String> errors;

    setUpAll(() async {
      errors = await analyzerErrors(_fixture);
    });

    test('cannot be mixed into a Bloc or a direct BlocBase subclass', () {
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

    test('still applies to a Cubit', () {
      // Given
      // The fixture's SafeCubit uses safeEmit, and a Bloc still takes
      // RestartableTasksMixin and HasEffects.

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
