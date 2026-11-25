// Runs the README recipe "A flow with several awaits": one runLatestOutcome
// around the whole flow, a check of token.isCancelled after every await, and
// the emits inside the task. OrderCubit.open is the README sample; keep them
// in sync.

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository {
  final orders = <String, Completer<String>>{};
  final invoices = <String, Completer<String>>{};

  Future<String> order(String id) => (orders[id] = Completer<String>()).future;

  Future<String> invoice(String order) =>
      (invoices[order] = Completer<String>()).future;
}

class _OrderState {
  const _OrderState({this.order, this.invoice});

  final String? order;
  final String? invoice;

  _OrderState copyWith({String? order, String? invoice}) => _OrderState(
        order: order ?? this.order,
        invoice: invoice ?? this.invoice,
      );

  @override
  String toString() => '$order, $invoice';
}

class _OrderCubit extends Cubit<_OrderState>
    with RestartableTasksMixin<_OrderState> {
  _OrderCubit(this.repository) : super(const _OrderState());

  final _Repository repository;

  // An emit after close() throws, and the run drops that failure, so the
  // tests read it here, where bloc reports it first.
  final errors = <Object>[];

  @override
  void onError(Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(error, stackTrace);
  }

  Future<void> open(String orderId) async {
    await runLatestOutcome('open', (token) async {
      final order = await repository.order(orderId);
      if (token.isCancelled) return;
      emit(state.copyWith(order: order));

      final invoice = await repository.invoice(order);
      if (token.isCancelled) return;
      emit(state.copyWith(invoice: invoice));
    });
  }
}

void main() {
  late _Repository repository;
  late _OrderCubit cubit;
  late List<String> states;

  setUp(() {
    repository = _Repository();
    cubit = _OrderCubit(repository);
    states = <String>[];
    final subscription = cubit.stream.listen((state) => states.add('$state'));
    addTearDown(subscription.cancel);
    addTearDown(cubit.close);
  });

  test('a flow superseded in its first step neither emits nor goes on',
      () async {
    // Given
    final superseded = cubit.open('a');
    final latest = cubit.open('b');

    // When
    repository.orders['a']!.complete('order a');
    await pumpEventQueue();
    repository.orders['b']!.complete('order b');
    await pumpEventQueue();
    repository.invoices['order b']!.complete('invoice b');
    await Future.wait([superseded, latest]);
    await pumpEventQueue();

    // Then
    expect(states, ['order b, null', 'order b, invoice b']);
    expect(repository.invoices.keys, ['order b']);
  });

  test('a flow superseded in its second step does not emit its stale result',
      () async {
    // Given
    final superseded = cubit.open('a');
    repository.orders['a']!.complete('order a');
    await pumpEventQueue();
    final latest = cubit.open('b');

    // When
    repository.invoices['order a']!.complete('invoice a');
    await pumpEventQueue();
    repository.orders['b']!.complete('order b');
    await pumpEventQueue();
    repository.invoices['order b']!.complete('invoice b');
    await Future.wait([superseded, latest]);
    await pumpEventQueue();

    // Then
    expect(states, ['order a, null', 'order b, null', 'order b, invoice b']);
  });

  test('close stops the flow at its next check', () async {
    // Given
    final flow = cubit.open('a');

    // When
    await cubit.close();
    repository.orders['a']!.complete('order a');
    await flow;
    await pumpEventQueue();

    // Then
    expect(cubit.errors, isEmpty);
    expect(states, isEmpty);
  });
}
