import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _EffectCubit extends Cubit<int> with HasEffects<int, String> {
  _EffectCubit() : super(0);
}

class _NoEffectsCubit extends Cubit<int> {
  _NoEffectsCubit() : super(0);
}

void main() {
  testWidgets('calls onEffect once per emission', (tester) async {
    // Given
    final cubit = _EffectCubit();
    addTearDown(cubit.close);
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: EffectListener<_EffectCubit, int, String>(
            onEffect: (context, effect) => events.add(effect),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // When
    cubit.emitEffect('a');
    await tester.pumpAndSettle();

    // Then
    expect(events, ['a']);
  });

  testWidgets('unsubscribes when widget is disposed', (tester) async {
    // Given
    final cubit = _EffectCubit();
    addTearDown(cubit.close);
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: EffectListener<_EffectCubit, int, String>(
            onEffect: (context, effect) => events.add(effect),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // When
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    cubit.emitEffect('late');
    await tester.pumpAndSettle();

    // Then
    expect(events, isEmpty);
  });

  testWidgets('effectWhen filters out non-matching effects', (tester) async {
    // Given
    final cubit = _EffectCubit();
    addTearDown(cubit.close);
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: EffectListener<_EffectCubit, int, String>(
            effectWhen: (effect) => effect.startsWith('allow'),
            onEffect: (context, effect) => events.add(effect),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // When
    cubit.emitEffect('skip:first');
    cubit.emitEffect('allow:second');
    await tester.pumpAndSettle();

    // Then
    expect(events, ['allow:second']);
  });

  testWidgets('effectWhen does not create duplicate effect deliveries', (
    tester,
  ) async {
    // Given
    final cubit = _EffectCubit();
    addTearDown(cubit.close);
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: EffectListener<_EffectCubit, int, String>(
            effectWhen: (effect) => effect.contains('match'),
            onEffect: (context, effect) => events.add(effect),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // When
    cubit.emitEffect('match');
    await tester.pumpAndSettle();

    // Then
    expect(events, ['match']);
  });

  testWidgets('throws when provider is missing', (tester) async {
    // Given
    final widget = MaterialApp(
      home: EffectListener<_EffectCubit, int, String>(
        onEffect: (context, effect) {},
        child: const SizedBox.shrink(),
      ),
    );

    // When
    await tester.pumpWidget(widget);

    // Then
    final exception = tester.takeException();
    expect(exception, isA<ProviderNotFoundException>());
  });

  testWidgets('throws when bloc does not implement HasEffects', (tester) async {
    // Given
    final cubit = _NoEffectsCubit();
    addTearDown(cubit.close);
    final widget = MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: EffectListener<_NoEffectsCubit, int, String>(
          onEffect: (context, effect) {},
          child: const SizedBox.shrink(),
        ),
      ),
    );

    // When
    await tester.pumpWidget(widget);

    // Then
    final exception = tester.takeException();
    expect(exception, isA<StateError>());
  });

  testWidgets('switches subscription from explicit bloc to provider bloc', (
    tester,
  ) async {
    // Given
    final providerCubit = _EffectCubit();
    final explicitCubit = _EffectCubit();
    addTearDown(providerCubit.close);
    addTearDown(explicitCubit.close);
    final events = <String>[];

    Widget buildApp({required bool useExplicitBloc}) {
      return MaterialApp(
        home: BlocProvider.value(
          value: providerCubit,
          child: EffectListener<_EffectCubit, int, String>(
            bloc: useExplicitBloc ? explicitCubit : null,
            onEffect: (context, effect) => events.add(effect),
            child: const SizedBox.shrink(),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(useExplicitBloc: true));

    // When
    explicitCubit.emitEffect('explicit');
    providerCubit.emitEffect('provider-before-switch');
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildApp(useExplicitBloc: false));
    providerCubit.emitEffect('provider-after-switch');
    explicitCubit.emitEffect('explicit-after-switch');
    await tester.pumpAndSettle();

    // Then
    expect(events, ['explicit', 'provider-after-switch']);
  });
}
