# bloc_plus

[![CI](https://github.com/ephmoc/bloc_plus/actions/workflows/ci.yml/badge.svg?event=push)](https://github.com/ephmoc/bloc_plus/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/bloc_plus)](https://pub.dev/packages/bloc_plus)
[![license](https://img.shields.io/github/license/ephmoc/bloc_plus)](https://github.com/ephmoc/bloc_plus/blob/main/LICENSE)
[![style: flutter_lints](https://img.shields.io/badge/style-flutter__lints-40c4ff)](https://pub.dev/packages/flutter_lints)
[![codecov](https://codecov.io/gh/ephmoc/bloc_plus/branch/main/graph/badge.svg)](https://codecov.io/gh/ephmoc/bloc_plus)

`bloc_plus` extends `flutter_bloc` with ergonomic widgets, rebuild and listen
conditions, cooperative async helpers, and explicit effect handling primitives.

## Features

- `BlocBuilderWithBloc`, `BlocListenerWithBloc`, `BlocConsumerWithBloc`,
  `BlocSelectorWithBloc`, `BlocConsumerWithEffects`
- Conditions for `buildWhen`, `listenWhen` and `selectorShouldRebuild`:
  `BlocCondition`, `whenChanged`
- Async safety:
  - `SafeEmitMixin` (Cubits only)
  - `CancellationToken` (with `whenCancelled`)
  - `RestartableTask` (`runOutcome`)
  - `RestartableTasksMixin` (`runLatest`, `runLatestOutcome`)
  - `TaskOutcome`
- Effects:
  - `HasEffects`
  - `BlocEffectListener`, which composes inside `MultiBlocListener`
  - `debugPrintUnheardEffects`, an opt-in debug warning for effects that
    nothing listens to
- Deprecated, removed in 1.0: `RebuildPolicy`, `ListenPolicy` and their
  factories, `EffectListener`, `MultiEffectListener`,
  `SingleChildEffectListener` (since 0.3.0); the `BuildContext` helpers
  `readOrNull`, `watchOrNull`, `selectOrNull` and `withBloc`, `effectWhen`
  with `EffectCondition`, `RestartableTask.run`, `BlocEffectListener.withChild`,
  and the typedefs `BlocEffectListenerWithBloc` and `BlocSelectedCondition`
  (since 0.4.0)

Delivery notes, next steps and guardrails are tracked in
[`docs/library_improvement_plan.md`](docs/library_improvement_plan.md).

## Getting started

Add dependency:

```yaml
dependencies:
  bloc_plus: ^0.4.0
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

The `*WithBloc` widgets accept any `StateStreamable<S>`, like flutter_bloc's,
and `BlocListenerWithBloc` has a `const` constructor.

`BlocBuilderWithBloc`, `BlocListenerWithBloc`, `BlocConsumerWithBloc` and
`BlocConsumerWithEffects` resolve the bloc once per build, so after `bloc:`
changes from an instance to `null` they follow the provided bloc at once, and
their callbacks get the bloc whose states they receive. `BlocBuilder` and
`BlocListener` keep the previous instance instead.

### Optional lookups

```dart
void tryIncrement(BuildContext context) {
  final counterCubit = context.read<CounterCubit?>();
  counterCubit?.increment();
}
```

With a nullable type argument, the lookups of `provider` handle a bloc that
may not be provided: `context.read<CounterCubit?>()`,
`context.watch<CounterCubit?>()` and
`context.select<CounterCubit?, int?>((cubit) => cubit?.state.count)` return
`null` when there is no provider of `CounterCubit`, rethrow any other error,
such as one thrown while the provider creates the bloc, and rebuild as their
non-null forms do. They replace the deprecated `readOrNull`, `watchOrNull`
and `selectOrNull`, which return the same values, while
`context.withBloc((CounterCubit cubit) => cubit.state.count)` becomes
`context.read<CounterCubit?>()?.state.count`. When the selector is not a
member chain, write `cubit == null ? null : ...`; when the callback of
`withBloc` does more than one member access, use a local variable and a null
check.

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
`BlocBuilder`, `BlocListener` and `BlocConsumer`. When the widget has its type
arguments, `whenChanged` needs none: the state type comes from the widget, so a
typo in the selector is a compile error. When the widget infers them from
`bloc:`, or the condition is stored in a variable, type the selector's
parameter: `whenChanged((CounterState state) => state.count)`.

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
| `distinct()`, `distinctListen()` | `(previous, current) => previous != current` (omitting the parameter differs only for a first emitted state equal to the initial one, which `emit` does not skip) |
| `a.and(b)`, `a.or(b)`, `a.not()` | `(p, c) => a(p, c) && b(p, c)`, `\|\|`, `!` |

Where the widget has no type arguments, keep them on the condition:
`onChange<S, T>(sel).shouldRebuild` becomes `whenChanged<S, T>(sel)`.

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
  call `runLatest`, it now completes as soon as the run is cancelled, but the
  abandoned task can still call the handler's `emit`: bloc rejects that call
  only with an assert, so release builds emit the stale state, and in debug
  the assert's error is dropped along with the abandoned task's other
  failures. Check `emit.isDone` (or `token.isCancelled` with
  `runLatestOutcome`) before calling `emit` inside the task.
- **`SafeEmitMixin` is for Cubits.** A `Bloc` cannot mix it in: the
  handler's `emit` also calls `onTransition` and does nothing in a handler
  that a transformer has cancelled, which `safeEmit` skipped. In a handler,
  check `isClosed` first and again after every `await`, before `emit` and
  before starting work: it is `true` from the call of `close()`, while the
  handler's `emit` still delivers for a while, also in a handler that starts
  after `close()` for an event queued before it. With `emit.onEach`, check it
  in `onData` and `onError` too; `emit.forEach` emits every state its
  callbacks return, so a check there cannot stop the emit: where a value must
  not arrive after `close()`, use `emit.onEach`. The 0.4.0 entry of the
  [CHANGELOG](CHANGELOG.md) has the full migration.
- **Only the bloc calls them.** `isTaskRunning`, `runLatest`,
  `runLatestOutcome`, `cancelLatest`, `cancelAllLatest`, `safeEmit` and
  `guarded` are `@protected` and `@visibleForTesting`, like `emit`: the bloc,
  its subclasses, a `mixin X on RestartableTasksMixin<S>` or
  `on SafeEmitMixin<S>` and tests call them, while a call from a widget, an
  extension on the bloc or a function outside the class gets analyzer
  warnings. Keep what the UI shows, such as a loading flag, in the state
  rather than reading `isTaskRunning` in `build`. A method that cancels the
  run clears that flag itself: the example above clears it only for a
  completed outcome.

`runLatest`, `CancellationToken.run` and `guarded` complete with `null` when
the work was superseded, cancelled or outlived the bloc, also when that work
fails, so only the latest run can throw. Handle `null` first, with an early
return: an `else` or a `default` branch would take discarded work for a failed
result.

For `void` work or a nullable result, `null` would be ambiguous, so
`runLatest`, `CancellationToken.run` and `guarded` do not accept it
(`T extends Object`). `RestartableTask.run` cannot take that bound, because
its `T` belongs to the class, so it is deprecated and will be removed in 1.0.
Instead of `runLatest` or `RestartableTask.run`, use `runLatestOutcome` as
above or `RestartableTask.runOutcome`, and check the outcome before anything
else: an ignored outcome compiles, and the code after it then runs for a
superseded run as well. Instead of `guarded` or
`CancellationToken.run`, await such work plainly and then check what the
method checked, before anything else: `isClosed` for `guarded`, which
`safeEmit` checks for you, and `token.isCancelled` for
`CancellationToken.run`, which `safeEmit` does not check:

```dart
// Instead of guarded:
final item = await repository.find(q); // may be null: not found
safeEmit(state.copyWith(item: item));

// Instead of CancellationToken.run:
final found = await repository.find(q);
if (token.isCancelled) return;
safeEmit(state.copyWith(item: found));
```

Wrap the result in a record only to keep what these two add: the work does
not start on a closed bloc or a cancelled token, its later failure is
dropped, and `CancellationToken.run` releases its caller at `cancel()`
instead of when the work ends:

```dart
final result = await guarded(() async => (item: await repository.find(q)));
if (result == null) return; // the bloc was closed
safeEmit(state.copyWith(item: result.item)); // item may be null: not found
```

The `cancellation_token` package also exports a `CancellationToken`. If you
import both, add `hide CancellationToken` to one import or use a prefix.

`CancellationToken` and `RestartableTask` are `final` classes, so they cannot
be extended, implemented or mocked. In tests, use real instances, for example
`CancellationToken()..cancel()` for a token that is already cancelled.

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
  pattern at the top of `onEffect`, which also promotes the effect type:
  `if (effect case ShowError(:final message)) ...`.
- `MultiBlocListener` asserts that `listeners` is not empty, and ignores a
  `child` passed to a listener inside it.
- `emitEffect` is `@protected` and `@visibleForTesting`, like `emit`. Calls
  from outside the bloc, including extensions on the bloc and other
  libraries, get analyzer warnings. Share helpers between blocs with a
  `mixin AuthEffects on HasEffects<AuthState, AuthEffect>`.

Migrating from the deprecated APIs (removed in 1.0):

| Before | After |
| --- | --- |
| `EffectListener<B, S, E>` | `BlocEffectListener<B, E>` |
| `MultiEffectListener` | `MultiBlocListener` |
| `EffectListener` on a subtype of the declared effect type | `BlocEffectListener` on the supertype with an if-case pattern |
| `effectWhen: (effect) => effect is ShowError` (deprecated in 0.4.0) | `if (effect case ShowError(...))` or `if (effect is! ShowError) return;` at the top of `onEffect` |
| `listener.withChild(child)` (deprecated in 0.4.0) | `child:` in the constructor, or the listener in `MultiBlocListener` |

### Testing effects

Effects are not replayed, so subscribe before you trigger them.
`expectLater` subscribes at once:

```dart
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
```

`blocTest` from `bloc_test` has no parameter for effects: call `expectLater` in
`build:` and await its future in `verify:`.

`emitEffect` is `@visibleForTesting`, so a widget test can send an effect
straight to the screen under test:

```dart
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
```

An effect that nothing listens to is lost, for example one emitted from the
bloc's constructor or before the listening widget is mounted. Set
`debugPrintUnheardEffects = true`, for example at the start of `main()`, to get
a warning about it in debug builds. It is off by default, because tests of a
bloc often emit effects that they do not listen to.
