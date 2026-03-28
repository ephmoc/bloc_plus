# bloc_plus

[![CI](https://github.com/ephmoc/bloc_plus/actions/workflows/ci.yml/badge.svg)](https://github.com/ephmoc/bloc_plus/actions/workflows/ci.yml)
[![PR Checks](https://github.com/ephmoc/bloc_plus/actions/workflows/pr.yml/badge.svg)](https://github.com/ephmoc/bloc_plus/actions/workflows/pr.yml)
[![pub package](https://img.shields.io/pub/v/bloc_plus)](https://pub.dev/packages/bloc_plus)
[![license](https://img.shields.io/github/license/ephmoc/bloc_plus)](https://github.com/ephmoc/bloc_plus/blob/main/LICENSE)
[![style: flutter_lints](https://img.shields.io/badge/style-flutter__lints-40c4ff)](https://pub.dev/packages/flutter_lints)
[![codecov](https://codecov.io/gh/ephmoc/bloc_plus/branch/main/graph/badge.svg)](https://codecov.io/gh/ephmoc/bloc_plus)

`bloc_plus` extends `flutter_bloc` with ergonomic widgets, reusable policies,
cooperative async helpers, and explicit effect handling primitives.

## Features

- `BlocBuilderWithBloc`, `BlocListenerWithBloc`, `BlocConsumerWithBloc`,
  `BlocSelectorWithBloc`, `BlocConsumerWithEffects`
- BuildContext extensions:
  - `readOrNull<B>()`
  - `watchOrNull<B>()`
  - `selectOrNull<B, S, T>(selector)`
  - `withBloc<B, R>(fn)`
- Reusable policies:
  - Rebuild: `distinct`, `onChange`, `onChangeBy`, `whenRebuild`, `always`,
    `never`
  - Listen: `distinctListen`, `onChangeListen`, `onChangeListenBy`,
    `whenListen`, `alwaysListen`, `neverListen`
  - Composition: `and`, `or`, `not`
- Async safety:
  - `SafeEmitMixin`
  - `CancellationToken`
  - `RestartableTask`
  - `RestartableTasksMixin`
- Effects:
  - `HasEffects`
  - `EffectListener`
  - `MultiEffectListener`
  - `effectWhen` filtering

Recent delivery notes are tracked in
[`docs/library_improvement_plan.md`](docs/library_improvement_plan.md).

## Getting started

Add dependency:

```yaml
dependencies:
  bloc_plus: ^0.2.1
```

Run the example app:

```bash
cd example
flutter pub get
flutter run
```

## Usage

### UI widgets with bloc in callback

```dart
class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilderWithBloc<CounterCubit, int>(
      builder: (context, bloc, state) {
        return Text('$state');
      },
    );
  }
}
```

### Null-safe context access

```dart
void tryIncrement(BuildContext context) {
  final counterCubit = context.readOrNull<CounterCubit>();
  counterCubit?.increment();
}
```

### Combined state and effects

```dart
class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumerWithEffects<CounterCubit, CounterState, String>(
      effectWhen: (effect) => effect.startsWith('snack:'),
      listener: (context, bloc, state) {},
      onEffect: (context, bloc, effect) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(effect)),
        );
      },
      builder: (context, bloc, state) {
        return Text('${state.count}');
      },
    );
  }
}
```

### Policies

```dart
final evenOnlyPolicy = distinct<MyState>().and(
  whenRebuild<MyState>((previous, current) => current.count.isEven),
);

final listPolicy = onChangeBy<MyState, List<int>>(
  (state) => state.items,
  equals: _listEquals,
);
```

### Async safety

```dart
class SearchCubit extends Cubit<SearchState>
    with SafeEmitMixin<SearchState>, RestartableTasksMixin<SearchState> {
  SearchCubit() : super(const SearchState());

  Future<void> loadPreview(String query) async {
    safeEmit(state.copyWith(isLoading: true));

    final result = await runLatest<String>('preview', () async {
      return repository.fetchPreview(query);
    });

    if (result == null) return;
    safeEmit(state.copyWith(isLoading: false, result: result));
  }
}
```

### Effects

```dart
MultiEffectListener(
  listeners: [
    EffectListener<AuthCubit, AuthState, String>(
      effectWhen: (effect) => effect.startsWith('snack:'),
      onEffect: (context, effect) {},
    ),
    EffectListener<AuthCubit, AuthState, String>(
      effectWhen: (effect) => effect.startsWith('dialog:'),
      onEffect: (context, effect) {},
    ),
  ],
  child: const AuthView(),
)
```
