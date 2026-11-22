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
    return BlocConsumerWithEffects<CounterCubit, CounterState, CounterEffect>(
      onEffect: (context, bloc, effect) {
        if (effect case ShowSnack(:final message)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      builder: (context, bloc, state) {
        return Text('${state.count}');
      },
    );
  }
}
```

The bloc must mix in `HasEffects<S, E>`. `listener` is optional; pass it,
with an optional `listenWhen`, to react to state changes as well.
`listenWhen` without `listener` fails an assert.

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

  Future<void> search(String query) async {
    safeEmit(state.copyWith(isLoading: true));

    final outcome = await runLatestOutcome('search', (token) {
      return repository.find(query, abortTrigger: token.whenCancelled);
    });

    // A superseded call resumes at once while the newer search is still
    // loading, so only the latest one clears the flag.
    if (outcome.isCompleted) {
      // outcome.value may be null: not found.
      safeEmit(state.copyWith(isLoading: false, item: outcome.value));
    }
  }
}
```

`runLatestOutcome` and `RestartableTask.runOutcome` complete with a
`TaskOutcome`: `TaskOutcome.completed(value)` for the latest run, or
`TaskOutcome.cancelled()` as soon as the run is superseded, cancelled
(`cancelLatest`, `cancelAllLatest`, `RestartableTask.cancel`), disposed or the
bloc closes. `outcome.value` throws on a cancelled outcome, so check
`outcome.isCompleted` first, or match it with
`if (outcome case TaskOutcome(isCompleted: true, :final value))`. Outcomes
compare by value, so `expect(outcome, const TaskOutcome<int>.completed(2))`
works in tests.

- **The abandoned task keeps running.** Cancellation releases the caller and
  drops the result, but does not stop the work. Check `token.isCancelled`
  before any side effect (a cache write, an analytics call), or pass
  `token.whenCancelled` to the I/O so it can abort: `package:http` accepts it
  as `abortTrigger`, and for dio call `cancel()` on a `CancelToken` from
  `token.whenCancelled.then(...)`.
- **A superseded caller resumes immediately**, while the newer run is still
  in flight. Code after the `await`, including a `finally` block that resets
  state shared with the newer run (such as a loading flag), must check the
  outcome first.
- **Failures are not an outcome.** The failure of the latest run is rethrown,
  so use `try`/`catch`; a failure of a cancelled run is dropped.
- **Inside `Bloc` event handlers**, prefer the handler's `emit` with a
  `bloc_concurrency` transformer such as `restartable()`. If a handler does
  call `runLatest`, the handler now completes as soon as the run is cancelled,
  so a cancelled task can no longer emit a stale state through its `emit`.

`runLatest`, `RestartableTask.run`, `CancellationToken.run` and `guarded`
complete with `null` when the work was superseded, cancelled or outlived the
bloc, also when that work fails, so only the latest run can throw. They suit
non-null results. When `T` is nullable or `void`, use the outcome methods, or
for `CancellationToken.run` and `guarded` wrap the result in a record so that
`null` only means discarded:

```dart
final result = await guarded(() async => (item: await repository.find(q)));
if (result == null) return; // the bloc was closed
safeEmit(state.copyWith(item: result.item)); // item may be null: not found
```

The `cancellation_token` package also exports a `CancellationToken`. If you
import both, add `hide CancellationToken` to one import or use a prefix.

### Effects

Model effects as a `sealed` hierarchy and emit them from inside the bloc:

```dart
sealed class AuthEffect {}

final class ShowError extends AuthEffect {
  ShowError(this.message);
  final String message;
}

final class GoHome extends AuthEffect {}

class AuthCubit extends Cubit<AuthState> with HasEffects<AuthState, AuthEffect> {
  AuthCubit() : super(const AuthState());

  void signedIn() => emitEffect(GoHome());
}
```

Listen with `BlocEffectListener<B, E>` and handle every effect with an
exhaustive `switch`. It composes inside `MultiBlocListener` next to
`BlocListener` and `BlocListenerWithBloc`:

```dart
MultiBlocListener(
  listeners: [
    BlocListener<AuthCubit, AuthState>(listener: (context, state) {}),
    BlocEffectListener<AuthCubit, AuthEffect>(
      onEffect: (context, effect) {
        switch (effect) {
          case ShowError(:final message):
            showError(context, message);
          case GoHome():
            goHome(context);
        }
      },
    ),
  ],
  child: const AuthView(),
)
```

- Write both type arguments. Below language version 3.7, `E` is not inferred
  from `bloc:`: it becomes `Object?` and the `switch` is no longer checked for
  exhaustiveness.
- To react to one subtype, listen to the supertype and use an if-case
  pattern: `if (effect case ShowError(:final message)) ...`. `effectWhen`
  filters effects but does not promote their type.
- `MultiBlocListener` asserts that `listeners` is not empty, and ignores a
  `child` passed to a listener inside it.
- `emitEffect` is `@protected` and `@visibleForTesting`, like `emit`. Calls
  from outside the bloc, including extensions on the bloc and other
  libraries, get analyzer warnings. Share helpers between blocs with a
  `mixin AuthEffects on HasEffects<AuthState, AuthEffect>`.

Migrating from the deprecated widgets (removed in 1.0):

| Before | After |
|---|---|
| `EffectListener<B, S, E>` | `BlocEffectListener<B, E>` |
| `MultiEffectListener` | `MultiBlocListener` |
| `EffectListener` on a subtype of the declared effect type | `BlocEffectListener` on the supertype with an if-case pattern |
