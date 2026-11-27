import 'dart:async';

import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class _UiEffect {}

final class _ShowToast extends _UiEffect {
  _ShowToast(this.message);
  final String message;
}

final class _Navigate extends _UiEffect {
  _Navigate(this.route);
  final String route;
}

class _UiCubit extends Cubit<int> with HasEffects<int, _UiEffect> {
  _UiCubit() : super(0);

  void increment() => emit(state + 1);
  void toast(String message) => emitEffect(_ShowToast(message));
  void navigate(String route) => emitEffect(_Navigate(route));
}

class _OtherCubit extends Cubit<int> with HasEffects<int, String> {
  _OtherCubit() : super(0);

  void say(String text) => emitEffect(text);
}

/// A hand-written [EffectsSource] so the test can observe the subscription.
class _ProbeCubit extends Cubit<int> implements EffectsSource<String> {
  _ProbeCubit() : super(0);

  final controller = StreamController<String>.broadcast();

  @override
  Stream<String> get effects => controller.stream;

  @override
  Future<void> close() async {
    await controller.close();
    return super.close();
  }
}

String _describe(_UiEffect effect) {
  switch (effect) {
    case _ShowToast(:final message):
      return 'toast:$message';
    case _Navigate(:final route):
      return 'go:$route';
  }
}

void main() {
  testWidgets('delivers effects of the provided cubit', (tester) async {
    // Given
    final cubit = _UiCubit();
    addTearDown(cubit.close);
    final effects = <String>[];
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: BlocEffectListener<_UiCubit, _UiEffect>(
          onEffect: (context, effect) => effects.add(_describe(effect)),
        ),
      ),
    );

    // When
    cubit.toast('saved');
    await tester.pump();

    // Then
    expect(effects, ['toast:saved']);
  });

  testWidgets('handles a sealed effect hierarchy with an exhaustive switch',
      (tester) async {
    // Given
    final cubit = _UiCubit();
    addTearDown(cubit.close);
    final handled = <String>[];
    await tester.pumpWidget(
      BlocEffectListener<_UiCubit, _UiEffect>(
        bloc: cubit,
        onEffect: (context, effect) {
          switch (effect) {
            case _ShowToast(:final message):
              handled.add('toast:$message');
            case _Navigate(:final route):
              handled.add('go:$route');
          }
        },
      ),
    );

    // When
    cubit
      ..toast('saved')
      ..navigate('/home');
    await tester.pump();

    // Then
    expect(handled, ['toast:saved', 'go:/home']);
  });

  testWidgets('matches a single subtype with an if-case pattern',
      (tester) async {
    // Given
    final cubit = _UiCubit();
    addTearDown(cubit.close);
    final toasts = <String>[];
    await tester.pumpWidget(
      BlocEffectListener<_UiCubit, _UiEffect>(
        bloc: cubit,
        onEffect: (context, effect) {
          if (effect case _ShowToast(:final message)) toasts.add(message);
        },
      ),
    );

    // When
    cubit
      ..navigate('/home')
      ..toast('hi');
    await tester.pump();

    // Then
    expect(toasts, ['hi']);
  });

  testWidgets('uses the latest onEffect after a rebuild', (tester) async {
    // Given
    final cubit = _UiCubit();
    addTearDown(cubit.close);
    final effects = <String>[];
    Widget build(String tag) {
      return BlocProvider.value(
        value: cubit,
        child: BlocEffectListener<_UiCubit, _UiEffect>(
          onEffect: (context, effect) =>
              effects.add('$tag:${_describe(effect)}'),
        ),
      );
    }

    await tester.pumpWidget(build('v1'));

    // When
    await tester.pumpWidget(build('v2'));
    cubit.toast('a');
    await tester.pump();

    // Then
    expect(effects, ['v2:toast:a']);
  });

  testWidgets('explicit bloc wins over the provided one', (tester) async {
    // Given
    final provided = _UiCubit();
    final explicit = _UiCubit();
    addTearDown(provided.close);
    addTearDown(explicit.close);
    final effects = <String>[];
    await tester.pumpWidget(
      BlocProvider.value(
        value: provided,
        child: BlocEffectListener<_UiCubit, _UiEffect>(
          bloc: explicit,
          onEffect: (context, effect) => effects.add(_describe(effect)),
        ),
      ),
    );

    // When
    provided.toast('provided');
    explicit.toast('explicit');
    await tester.pump();

    // Then
    expect(effects, ['toast:explicit']);
  });

  testWidgets('follows the provided bloc after bloc changes to null',
      (tester) async {
    // Given
    final provided = _UiCubit();
    final explicit = _UiCubit();
    addTearDown(provided.close);
    addTearDown(explicit.close);
    final effects = <String>[];
    Widget tree({required _UiCubit? bloc}) => BlocProvider.value(
          value: provided,
          child: BlocEffectListener<_UiCubit, _UiEffect>(
            bloc: bloc,
            onEffect: (context, effect) => effects.add(_describe(effect)),
          ),
        );
    await tester.pumpWidget(tree(bloc: explicit));
    explicit.toast('explicit');
    provided.toast('provided-before');
    await tester.pump();

    // When
    await tester.pumpWidget(tree(bloc: null));
    provided.toast('provided-after');
    explicit.toast('explicit-after');
    await tester.pump();

    // Then
    expect(effects, ['toast:explicit', 'toast:provided-after']);
  });

  testWidgets('switches from the provided bloc to an explicit one',
      (tester) async {
    // Given
    final provided = _UiCubit();
    final explicit = _UiCubit();
    addTearDown(provided.close);
    addTearDown(explicit.close);
    final effects = <String>[];
    Widget tree({required _UiCubit? bloc}) => BlocProvider.value(
          value: provided,
          child: BlocEffectListener<_UiCubit, _UiEffect>(
            bloc: bloc,
            onEffect: (context, effect) => effects.add(_describe(effect)),
          ),
        );
    await tester.pumpWidget(tree(bloc: null));
    provided.toast('provided');
    explicit.toast('explicit-before');
    await tester.pump();

    // When
    await tester.pumpWidget(tree(bloc: explicit));
    explicit.toast('explicit-after');
    provided.toast('provided-after');
    await tester.pump();

    // Then
    expect(effects, ['toast:provided', 'toast:explicit-after']);
  });

  testWidgets('throws ProviderNotFoundException without bloc or provider',
      (tester) async {
    // Given
    final listener = BlocEffectListener<_UiCubit, _UiEffect>(
      onEffect: (context, effect) {},
    );

    // When
    await tester.pumpWidget(listener);

    // Then
    expect(tester.takeException(), isA<ProviderNotFoundException>());
  });

  testWidgets('without a child delivers effects and renders nothing',
      (tester) async {
    // Given
    final cubit = _UiCubit();
    addTearDown(cubit.close);
    final effects = <String>[];
    const key = Key('listener');
    await tester.pumpWidget(
      Center(
        child: BlocEffectListener<_UiCubit, _UiEffect>(
          key: key,
          bloc: cubit,
          onEffect: (context, effect) => effects.add(_describe(effect)),
        ),
      ),
    );

    // When
    cubit.toast('saved');
    await tester.pump();

    // Then
    expect(effects, ['toast:saved']);
    expect(tester.getSize(find.byKey(key)), Size.zero);
  });

  testWidgets('cancels its subscription when disposed', (tester) async {
    // Given
    final cubit = _ProbeCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocEffectListener<_ProbeCubit, String>(
        bloc: cubit,
        onEffect: (context, effect) {},
      ),
    );
    final listeningWhileMounted = cubit.controller.hasListener;

    // When
    await tester.pumpWidget(const SizedBox.shrink());

    // Then
    expect(listeningWhileMounted, isTrue);
    expect(cubit.controller.hasListener, isFalse);
  });

  testWidgets('survives the bloc being closed while mounted', (tester) async {
    // Given
    final cubit = _UiCubit();
    final effects = <String>[];
    await tester.pumpWidget(
      BlocEffectListener<_UiCubit, _UiEffect>(
        bloc: cubit,
        onEffect: (context, effect) => effects.add(_describe(effect)),
      ),
    );

    // When
    await tester.runAsync(cubit.close);
    cubit.toast('late');
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    // Then
    expect(effects, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('composes inside MultiBlocListener with state listeners',
      (tester) async {
    // Given
    final cubit = _UiCubit();
    addTearDown(cubit.close);
    final calls = <String>[];
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MultiBlocListener(
          listeners: [
            BlocListener<_UiCubit, int>(
              listener: (context, state) => calls.add('state:$state'),
            ),
            BlocListenerWithBloc<_UiCubit, int>(
              listener: (context, bloc, state) => calls.add('withBloc:$state'),
            ),
            BlocEffectListener<_UiCubit, _UiEffect>(
              onEffect: (context, effect) => calls.add(_describe(effect)),
            ),
          ],
          child: const SizedBox.shrink(),
        ),
      ),
    );

    // When
    cubit.increment();
    await tester.pump();
    cubit.toast('saved');
    await tester.pump();

    // Then
    expect(calls, ['state:1', 'withBloc:1', 'toast:saved']);
  });

  testWidgets('MultiBlocListener: calls listeners of one bloc in order',
      (tester) async {
    // Given
    final cubit = _UiCubit();
    addTearDown(cubit.close);
    final log = <String>[];
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MultiBlocListener(
          listeners: [
            BlocEffectListener<_UiCubit, _UiEffect>(
              onEffect: (context, effect) =>
                  log.add('first:${_describe(effect)}'),
            ),
            BlocEffectListener<_UiCubit, _UiEffect>(
              onEffect: (context, effect) =>
                  log.add('second:${_describe(effect)}'),
            ),
          ],
          child: const SizedBox.shrink(),
        ),
      ),
    );

    // When
    cubit.toast('ordered');
    await tester.pump();

    // Then
    expect(log, ['first:toast:ordered', 'second:toast:ordered']);
  });

  testWidgets(
      'resubscribes when only the provider above a reused listener '
      'changes', (tester) async {
    // Given
    final first = _UiCubit();
    final second = _UiCubit();
    addTearDown(first.close);
    addTearDown(second.close);
    final log = <String>[];
    // The same instance on every pump: didUpdateWidget does not run, so only
    // the provider dependency can trigger the resubscription.
    final listener = BlocEffectListener<_UiCubit, _UiEffect>(
      onEffect: (context, effect) => log.add(_describe(effect)),
      child: const SizedBox.shrink(),
    );
    await tester.pumpWidget(BlocProvider.value(value: first, child: listener));

    // When
    await tester.pumpWidget(BlocProvider.value(value: second, child: listener));
    first.toast('old');
    second.toast('new');
    await tester.pump();

    // Then
    expect(log, ['toast:new']);
  });

  testWidgets('MultiBlocListener: resubscribes when the provider is swapped',
      (tester) async {
    // Given
    final first = _UiCubit();
    final second = _UiCubit();
    final other = _OtherCubit();
    addTearDown(first.close);
    addTearDown(second.close);
    addTearDown(other.close);
    final log = <String>[];
    Widget tree(_UiCubit ui) => BlocProvider.value(
          value: other,
          child: BlocProvider.value(
            value: ui,
            child: MultiBlocListener(
              listeners: [
                BlocEffectListener<_UiCubit, _UiEffect>(
                  onEffect: (context, effect) => log.add(_describe(effect)),
                ),
                BlocEffectListener<_OtherCubit, String>(
                  onEffect: (context, effect) => log.add('other:$effect'),
                ),
              ],
              child: const SizedBox.shrink(),
            ),
          ),
        );
    await tester.pumpWidget(tree(first));

    // When
    await tester.pumpWidget(tree(second));
    first.toast('old');
    second.toast('new');
    await tester.pump();

    // Then
    expect(log, ['toast:new']);
  });

  testWidgets('MultiBlocListener: resubscribes when the explicit bloc changes',
      (tester) async {
    // Given
    final first = _UiCubit();
    final second = _UiCubit();
    addTearDown(first.close);
    addTearDown(second.close);
    final log = <String>[];
    Widget tree(_UiCubit ui) => MultiBlocListener(
          listeners: [
            BlocEffectListener<_UiCubit, _UiEffect>(
              bloc: ui,
              onEffect: (context, effect) => log.add(_describe(effect)),
            ),
          ],
          child: const SizedBox.shrink(),
        );
    await tester.pumpWidget(tree(first));

    // When
    await tester.pumpWidget(tree(second));
    first.toast('old');
    second.toast('new');
    await tester.pump();

    // Then
    expect(log, ['toast:new']);
  });

  testWidgets('MultiBlocListener: reordered keyed listeners deliver once',
      (tester) async {
    // Given
    final ui = _UiCubit();
    final other = _OtherCubit();
    addTearDown(ui.close);
    addTearDown(other.close);
    final log = <String>[];
    final uiListener = BlocEffectListener<_UiCubit, _UiEffect>(
      key: const ValueKey('ui'),
      onEffect: (context, effect) => log.add(_describe(effect)),
    );
    final otherListener = BlocEffectListener<_OtherCubit, String>(
      key: const ValueKey('other'),
      onEffect: (context, effect) => log.add('other:$effect'),
    );
    Widget tree({required bool swapped}) => BlocProvider.value(
          value: other,
          child: BlocProvider.value(
            value: ui,
            child: MultiBlocListener(
              listeners: swapped
                  ? [otherListener, uiListener]
                  : [uiListener, otherListener],
              child: const SizedBox.shrink(),
            ),
          ),
        );
    await tester.pumpWidget(tree(swapped: false));

    // When
    await tester.pumpWidget(tree(swapped: true));
    ui.navigate('/home');
    other.say('x');
    await tester.pump();

    // Then
    expect(log..sort(), ['go:/home', 'other:x']);
  });

  testWidgets('MultiBlocListener: ignores a child given to a listener',
      (tester) async {
    // Given
    final cubit = _UiCubit();
    addTearDown(cubit.close);

    // When
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MultiBlocListener(
          listeners: [
            BlocEffectListener<_UiCubit, _UiEffect>(
              bloc: cubit,
              onEffect: (context, effect) {},
              child: const Text('lost'),
            ),
          ],
          child: const Text('kept'),
        ),
      ),
    );

    // Then
    expect(find.text('lost'), findsNothing);
    expect(find.text('kept'), findsOneWidget);
  });

  testWidgets('still composes inside the deprecated MultiEffectListener',
      (tester) async {
    // Given
    final cubit = _UiCubit();
    addTearDown(cubit.close);
    final effects = <String>[];
    await tester.pumpWidget(
      // ignore: deprecated_member_use_from_same_package
      MultiEffectListener(
        listeners: [
          BlocEffectListener<_UiCubit, _UiEffect>(
            bloc: cubit,
            onEffect: (context, effect) => effects.add(_describe(effect)),
          ),
        ],
        child: const Text('screen', textDirection: TextDirection.ltr),
      ),
    );

    // When
    cubit.toast('saved');
    await tester.pump();

    // Then
    expect(effects, ['toast:saved']);
    expect(find.text('screen'), findsOneWidget);
  });
}
