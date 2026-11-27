// Runs the "Testing effects" recipe from README.md. The first two tests are
// the README samples; keep them in sync. The README's mocked cubit comes from
// bloc_test or mocktail, which are not dependencies here, so the last two tests
// check what it says about such a mock with a mock written by hand.

import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// The effects and the cubit from the README "Effects" section.
sealed class AuthEffect {}

final class ShowError extends AuthEffect {
  ShowError(this.message);
  final String message;
}

final class GoHome extends AuthEffect {}

class AuthState {
  const AuthState();
}

class AuthCubit extends Cubit<AuthState>
    with HasEffects<AuthState, AuthEffect> {
  AuthCubit() : super(const AuthState());

  void signedIn() => emitEffect(GoHome());
}

// Stands in for the app's MaterialApp, so the README sample runs as written:
// the package's tests do not depend on a material library.
class MaterialApp extends StatelessWidget {
  const MaterialApp({required this.home, super.key});

  final Widget home;

  @override
  Widget build(BuildContext context) =>
      Directionality(textDirection: TextDirection.ltr, child: home);
}

// A screen that shows the error from a ShowError effect.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return BlocEffectListener<AuthCubit, AuthEffect>(
      onEffect: (context, effect) {
        if (effect case ShowError(:final message)) {
          setState(() => _error = message);
        }
      },
      child: Text(_error),
    );
  }
}

// Stands in for a MockCubit from bloc_test or a mocktail Mock: as with them,
// every member that is not stubbed returns null.
class _MockAuthCubit implements AuthCubit {
  @override
  AuthState get state => const AuthState();

  @override
  Stream<AuthState> get stream => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockAuthCubitWithEffects extends _MockAuthCubit {
  _MockAuthCubitWithEffects(this.effects);

  @override
  final Stream<AuthEffect> effects;
}

void main() {
  test('signedIn sends GoHome', () async {
    // Given
    final cubit = AuthCubit();
    addTearDown(cubit.close);
    final effects = expectLater(cubit.effects, emits(isA<GoHome>()));

    // When
    cubit.signedIn();

    // Then
    await effects;
  });

  testWidgets('AuthPage shows the error', (tester) async {
    // Given
    final cubit = AuthCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const AuthPage()),
      ),
    );

    // When
    cubit.emitEffect(ShowError('Wrong password'));
    await tester.pumpAndSettle();

    // Then
    expect(find.text('Wrong password'), findsOneWidget);
  });

  testWidgets('a mocked cubit without effects stubbed fails with a TypeError',
      (tester) async {
    // Given
    final cubit = _MockAuthCubit();

    // When
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const AuthPage(),
        ),
      ),
    );

    // Then
    expect(tester.takeException(), isA<TypeError>());
  });

  testWidgets('AuthPage shows the error of a mocked cubit with effects stubbed',
      (tester) async {
    // Given
    final effects = StreamController<AuthEffect>.broadcast();
    addTearDown(effects.close);
    final cubit = _MockAuthCubitWithEffects(effects.stream);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const AuthPage(),
        ),
      ),
    );

    // When
    effects.add(ShowError('Wrong password'));
    await tester.pumpAndSettle();

    // Then
    expect(find.text('Wrong password'), findsOneWidget);
  });
}
