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
}
