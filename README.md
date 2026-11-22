# bloc_plus

[![CI](https://github.com/ephmoc/bloc_plus/actions/workflows/ci.yml/badge.svg?event=push)](https://github.com/ephmoc/bloc_plus/actions/workflows/ci.yml)
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

Delivery notes, next steps and guardrails are tracked in
[`docs/library_improvement_plan.md`](docs/library_improvement_plan.md).

## Getting started

Add dependency:

```yaml
dependencies:
  bloc_plus: ^0.2.2
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

`readOrNull`, `watchOrNull` and `selectOrNull` return `null` only when there
is no provider. An error thrown while the provider creates the bloc is
rethrown.

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

`whenChanged` returns a `BlocCondition<S>`, a plain
`bool Function(previous, current)`. It goes straight into `buildWhen`,
`listenWhen` and `selectorShouldRebuild`, in this package's widgets and in
`BlocBuilder`, `BlocListener` and `BlocConsumer`, without type arguments: the
state type comes from the widget, so a typo in the selector is a compile error.

```dart
BlocBuilder<CounterCubit, CounterState>(
  buildWhen: whenChanged((state) => state.count),
  builder: (context, state) => Text('${state.count}'),
)

// Several fields: select a record of scalars.
buildWhen: whenChanged((state) => (state.count, state.label)),

// Collections: pass equals.
listenWhen: whenChanged((state) => state.items, equals: listEquals),

// Anything else: a plain predicate.
buildWhen: (previous, current) =>
    previous.count != current.count && current.count.isEven,
```

Select scalars or records of scalars. A list, also inside a record, is
compared by identity, so pass `equals:` (for example `listEquals` from
`package:flutter/foundation.dart`). Never build a new list in the selector,
such as `(state) => [state.a]`: it is then always "changed".

`RebuildPolicy`, `ListenPolicy` and their factories are deprecated and will
be removed in 1.0:

| Deprecated | Replacement |
| --- | --- |
| `onChange(sel).shouldRebuild`, `onChangeListen(sel).shouldListen` | `whenChanged(sel)` |
| `onChangeBy(sel, equals: eq)`, `onChangeListenBy(sel, equals: eq)` | `whenChanged(sel, equals: eq)` |
| `whenRebuild(p).shouldRebuild`, `whenListen(p).shouldListen` | `p` |
| `always()`, `alwaysListen()` | omit `buildWhen` / `listenWhen` |
| `never()`, `neverListen()` | `(previous, current) => false` |
| `distinct()`, `distinctListen()` | `(previous, current) => previous != current`, or omit the parameter for a `Bloc` or `Cubit` (`emit` already skips equal states) |
| `a.and(b)`, `a.or(b)`, `a.not()` | `(p, c) => a(p, c) && b(p, c)`, `\|\|`, `!` |

Until 1.0, `whenListen` clashes with `whenListen` from `bloc_test`. In tests
that import both, hide this package's one:

```dart
import 'package:bloc_plus/bloc_plus.dart' hide whenListen;
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

`runLatest`, `RestartableTask.run`, `CancellationToken.run` and `guarded`
complete with `null` when the work was superseded, cancelled or outlived the
bloc. That also holds when such work fails, so only the latest run can throw.

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
