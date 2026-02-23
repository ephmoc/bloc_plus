import 'package:bloc_plus/bloc_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const ExampleApp());
}

class CounterCubit extends Cubit<int> with HasEffects<int, String> {
  CounterCubit() : super(0);

  void increment() {
    final next = state + 1;
    emit(next);
    if (next == 5) {
      emitEffect('Reached $next');
    }
  }
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => CounterCubit(),
        child: const CounterPage(),
      ),
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rebuildPolicy = distinct<int>();

    return Scaffold(
      appBar: AppBar(title: const Text('bloc_plus example')),
      body: EffectListener<CounterCubit, int, String>(
        onEffect: (context, effect) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(effect)),
          );
        },
        child: Center(
          child: BlocBuilderWithBloc<CounterCubit, int>(
            buildWhen: rebuildPolicy.shouldRebuild,
            builder: (context, bloc, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Count: $state', style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: bloc.increment,
                    child: const Text('Increment'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
