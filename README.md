# bloc_plus

[![CI](https://github.com/ephmoc/bloc_plus/actions/workflows/ci.yml/badge.svg?event=push)](https://github.com/ephmoc/bloc_plus/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/bloc_plus)](https://pub.dev/packages/bloc_plus)
[![license](https://img.shields.io/github/license/ephmoc/bloc_plus)](https://github.com/ephmoc/bloc_plus/blob/main/LICENSE)
[![style: flutter_lints](https://img.shields.io/badge/style-flutter__lints-40c4ff)](https://pub.dev/packages/flutter_lints)
[![codecov](https://codecov.io/gh/ephmoc/bloc_plus/branch/main/graph/badge.svg)](https://codecov.io/gh/ephmoc/bloc_plus)

`bloc_plus` adds two things to `flutter_bloc`: async helpers for Cubits, with
"latest wins" runs and emits that stop at `close()`, and one-off effects such
as navigation or a snack bar, kept out of the state. It also has rebuild and
listen conditions, and widgets that hand the bloc to their callbacks.

## Features

- Async helpers for Cubits:
  - `RestartableTasksMixin` (`runLatestOutcome`, `runLatest`, `cancelLatest`,
    `isTaskRunning`): "latest wins" runs by key, cancelled at `close()`
  - `SafeEmitMixin` (Cubits only): `safeEmit` and `guarded`
  - `TaskOutcome`, `CancellationToken` (with `whenCancelled`) and
    `RestartableTask` (`runOutcome`) for "latest wins" outside a bloc
- Effects, one-off events kept out of the state:
  - `HasEffects` (`emitEffect`)
  - `BlocEffectListener`, which composes inside `MultiBlocListener`
  - `BlocConsumerWithEffects`: the state and the effects of one bloc in one
    widget
  - `debugPrintUnheardEffects`, an opt-in debug warning for effects that
    nothing listens to
- Conditions for `buildWhen`, `listenWhen` and `selectorShouldRebuild`:
  `BlocCondition`, `whenChanged`
- Widgets that hand the bloc to their callbacks: `BlocBuilderWithBloc`,
  `BlocListenerWithBloc`, `BlocConsumerWithBloc`, `BlocSelectorWithBloc`

Delivery notes, next steps and guardrails are tracked in
[`docs/library_improvement_plan.md`](docs/library_improvement_plan.md).

## Getting started

Add dependency:

```yaml
dependencies:
  bloc_plus: ^1.0.0
```

Run the example app:

```bash
cd example
flutter pub get
flutter run
```

## Usage

### Async helpers for Cubits

| You want | Use |
| --- | --- |
| an emit after an `await` that does nothing once the cubit is closed | `safeEmit` from `SafeEmitMixin` |
| the result of work that may outlive the cubit, used afterwards | `guarded` from `SafeEmitMixin`, for a non-null result |
| "latest wins": a new call supersedes the one that is still running | `runLatestOutcome` from `RestartableTasksMixin`, or `runLatest` when the result is non-null |
| "latest wins" outside a bloc | `RestartableTask` |
| no further logic, not only no emit, once the cubit is closed | a plain `if (isClosed) return;`, which this package does not replace |

"Latest wins" needs `RestartableTasksMixin` only:

```dart
class SearchCubit extends Cubit<SearchState>
    with RestartableTasksMixin<SearchState> {
  SearchCubit(this.repository) : super(const SearchState());

  final SearchRepository repository;

  Future<void> search(String query) async {
    // Before the first await the cubit may be closed already; safeEmit from
    // SafeEmitMixin does this check for you.
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, failed: false));

    final TaskOutcome<Item?> outcome;
    try {
      outcome = await runLatestOutcome('search', (token) {
        return repository.find(query, abortTrigger: token.whenCancelled);
      });
    } catch (_) {
      // Only the failure of the latest run arrives here.
      emit(state.copyWith(isLoading: false, failed: true));
      return;
    }

    // A superseded call resumes at once while the newer search is still
    // loading, and close() cancels the run: only a completed outcome clears
    // the flag.
    if (!outcome.isCompleted) return;
    emit(SearchState(item: outcome.value)); // item is null when not found
  }
}
```

`safeEmit` matters for an emit that can run on a closed cubit, such as the
one before the first `await` when `search` is called after `close()`. After
`runLatestOutcome`, a closed cubit gives a cancelled outcome, also when the
run failed just before `close()`, so the check of `outcome.isCompleted` covers
it and the `catch` never runs on a closed cubit.

`runLatestOutcome` and `RestartableTask.runOutcome` complete with a
`TaskOutcome`: `TaskOutcome.completed(value)` for the latest run, or
`TaskOutcome.cancelled()` as soon as the run is superseded, cancelled
(`cancelLatest`, `cancelAllLatest`, `RestartableTask.cancel`), disposed or the
bloc closes. `outcome.value` throws on a cancelled outcome, so check
`outcome.isCompleted` first, or match it with
`if (outcome case TaskOutcome(isCompleted: true, :final value))`, with
`isCompleted: true` before `value`, because a pattern reads its fields in
order. Both methods are `@useResult`: the analyzer reports an outcome that is
awaited and dropped, because the code after it would run for a cancelled run
as well. Outcomes compare by value, so
`expect(outcome, const TaskOutcome<int>.completed(2))` works in tests.

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
  so use `try`/`catch`. A failure of a cancelled run is dropped, also one that
  arrived just before the cancel, while the caller had not resumed yet.
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
  run clears that flag itself: the example above clears it only when the run
  completes or fails.

`runLatest`, `CancellationToken.run` and `guarded` complete with `null` when
the work was superseded, cancelled or outlived the bloc, also when that work
fails, so only the latest run can throw. Handle `null` first, with an early
return: an `else` or a `default` branch would take discarded work for a failed
result. Like the outcome methods, they are `@useResult`: the analyzer reports
a result that is awaited and dropped. The task of `runLatest` gets no token:
a task that checks `token.isCancelled` or passes `token.whenCancelled` to its
I/O uses `runLatestOutcome`.

For `void` work or a nullable result, `null` would be ambiguous, so
`runLatest`, `CancellationToken.run` and `guarded` do not accept it
(`T extends Object`). Instead of `runLatest`, use `runLatestOutcome` as above,
or `RestartableTask.runOutcome` outside a bloc, and check the outcome before
anything else. Instead of `guarded` or `CancellationToken.run`, await such
work plainly and then check what the method checked, before anything else:
`isClosed` for `guarded`, which `safeEmit` checks for you, and
`token.isCancelled` for `CancellationToken.run`, which `safeEmit` does not
check:

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

#### A flow with several awaits

Run the whole flow inside one `runLatestOutcome`, check `token.isCancelled`
after every `await` and emit inside the task. A `catch` inside the task needs
the same check first: the abandoned flow keeps running and can fail after the
newer flow has emitted, and without the check its stale failure replaces the
newer state. The method returns the future of `runLatestOutcome` and is not
`async`: awaiting the future as a statement would drop the outcome, which the
analyzer reports. In a method that does more, such as one with a `try` around
the call, keep `await` and check the outcome instead: a returned future
escapes the `catch` and the `finally`.

```dart
Future<void> open(String orderId) {
  return runLatestOutcome('open', (token) async {
    try {
      final order = await repository.order(orderId);
      if (token.isCancelled) return;
      // A new order starts without an invoice.
      emit(OrderState(order: order));

      final invoice = await repository.invoice(order);
      if (token.isCancelled) return;
      emit(state.copyWith(invoice: invoice));
    } catch (_) {
      // A superseded flow can fail after the newer one has emitted.
      if (token.isCancelled) return;
      emit(state.copyWith(failed: true));
    }
  });
}
```

A key names a whole flow, not a step. With one run per step under the same
key, a superseded flow that has any other `await` between its steps resumes
and starts its next step: that step cancels the newer flow when the newer
flow is inside a run, and emits its stale state otherwise. `close()` cancels
the token as well, so the same checks stop the flow on a closed cubit.

#### Ignore while running

To ignore a call while the previous one still runs, check `isTaskRunning`
before the first `await`:

```dart
Future<void> refresh() async {
  if (isTaskRunning('refresh')) return;
  final outcome = await runLatestOutcome('refresh', (_) => repository.load());
  if (!outcome.isCompleted) return;
  emit(state.copyWith(items: outcome.value));
}
```

`isTaskRunning` is not reactive, so read it inside the cubit, not in `build`.
For the handlers of a `Bloc`, use `droppable()` from `bloc_concurrency`.

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

- Write both type arguments. Without them the `effect` parameter of
  `onEffect` is `Object?` at every language version, so the `switch` is not
  checked for exhaustiveness.
- To react to one subtype, listen to the supertype and use an if-case
  pattern at the top of `onEffect`, which also promotes the effect type:
  `if (effect case ShowError(:final message)) ...`.
- `MultiBlocListener` asserts that `listeners` is not empty, and ignores a
  `child` passed to a listener inside it.
- `emitEffect` is `@protected` and `@visibleForTesting`, like `emit`. Calls
  from outside the bloc, including extensions on the bloc and other
  libraries, get analyzer warnings. Share helpers between blocs with a
  `mixin AuthEffects on HasEffects<AuthState, AuthEffect>`.
- In a `Bloc` handler that a transformer such as `restartable()` has
  cancelled, `emitEffect` still delivers its effect: check `emit.isDone`
  first.

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

The bloc must mix in `HasEffects<S, E>`, while `BlocEffectListener` accepts
any `EffectsSource<E>`. The consumer hands the bloc to `builder`, `listener`
and `onEffect`, and its `buildWhen` and `listenWhen` get the previous and the
current state; `BlocEffectListener.onEffect` gets only `(context, effect)`.
`listener` is optional; pass it, with an optional `listenWhen`, to react to
state changes as well. `listenWhen` without `listener` fails an assert.

Write all three type arguments: `S` and `E` are inferred from `bloc:` only in
code at language version 3.7 or later, which is the language version of your
app, not of this package.

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

A widget test that mocks the cubit, with `MockCubit` from `bloc_test` or a
mocktail `Mock`, has to stub `effects` as well: unstubbed, it returns `null`,
and the listener fails with a `TypeError`. Stub it with a stream that the test
controls:

```dart
class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

testWidgets('AuthPage shows the error of a mocked cubit', (tester) async {
  // Given
  final cubit = MockAuthCubit();
  final effects = StreamController<AuthEffect>.broadcast();
  addTearDown(effects.close);
  when(() => cubit.state).thenReturn(const AuthState());
  when(() => cubit.effects).thenAnswer((_) => effects.stream);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AuthCubit>.value(value: cubit, child: const AuthPage()),
    ),
  );

  // When
  effects.add(ShowError('Wrong password'));
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

### Conditions

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
import 'package:flutter_bloc/flutter_bloc.dart'; // exports read, watch, select

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
non-null forms do. To read a member of a bloc that may not be provided, write
`context.read<CounterCubit?>()?.state.count`. When the selector is not a
member chain, write `cubit == null ? null : ...`; for more than one member
access, use a local variable and a null check. `bloc_plus` does not export
these lookups: a file that uses them needs the `flutter_bloc` import.

## Compared with

Measured against the versions that were current in November 2026.

- **`bloc_presentation`** (1.1.2+3) adds one-off events to a bloc in the same
  way: a broadcast stream in a mixin, and a listener that composes inside
  `MultiBlocListener`. Here `emitEffect` after `close()` does nothing, where
  `emitPresentation` throws a `StateError`; `BlocEffectListener` follows the
  provided bloc after `bloc:` changes from an instance to `null`, where
  `BlocPresentationListener` keeps the old instance; `debugPrintUnheardEffects`
  warns about an effect that nothing listens to; and `BlocConsumerWithEffects`
  builds, listens and handles effects for one bloc. For tests,
  `bloc_presentation_test` is a separate package; here the README has
  recipes.
- **`CancelableOperation`** from `package:async` (2.13.1) gives nearly the
  same result as `RestartableTask` when it is written with
  `valueOrCancellation()` and `onCancel`: the superseded caller is released at
  once, its result and its later failure are dropped, and the failure of the
  latest run is rethrown. Only a value or a failure that arrived just before
  the cancel, while the caller had not resumed yet, is still delivered there,
  where `RestartableTask` drops it. Awaiting its `value` instead never
  releases a superseded caller.
  In a Cubit it takes a field, a cancel, a wrap and a `close()` override per
  task, where `RestartableTasksMixin` takes a key and cancels every run at
  `close()`.
- **`bloc_concurrency`** (0.3.1) has event transformers for the handlers of a
  `Bloc`: `restartable()`, `droppable()`, `sequential()` and `concurrent()`.
  It has nothing for a Cubit, which has no events. Inside a `Bloc`, prefer it
  to `RestartableTasksMixin`.

## Versioning

These rules apply from 1.0.0:

- The public API is everything exported from
  `package:bloc_plus/bloc_plus.dart`.
- A major version is needed to remove or rename an export, to change a
  signature incompatibly, to change the superclass of a widget, to change
  documented behaviour, or to add an annotation that makes the analyzer
  report code that was clean before, such as `@protected`. `@Deprecated` is
  the exception (next item).
- A minor version may add exports, members and optional parameters, support a
  new major of a dependency when no signature here changes, raise the minimum
  Dart or Flutter SDK or the minimum version of a dependency (a new major
  included), and deprecate an API, which is then removed no earlier than the
  next major.
- Not covered: classes that `implement` this package's classes or mixins by
  hand (`EffectsSource` is the exception, and gets no new member without a
  major), subclasses of its classes and widgets, and overriding members of
  its widgets. Applying the mixins with `with`, or building on them with
  `mixin X on ...`, is covered. Where a widget is documented as a
  `flutter_bloc` widget with something added, the rest of its behaviour is
  that of the `flutter_bloc` version the app resolves; a change there is not
  a change of this package.
- A member added in a minor may clash with a member of the same name in a
  class that applies a mixin or extends a class of this package, and an
  optional parameter added to a method of a mixin breaks an override of that
  method. Neither is treated as a breaking change.

## Upgrading from 0.x

1.0.0 removes the APIs that 0.3.0 and 0.4.0 deprecated and changes nothing
else. A constraint such as `^0.2.0` or `^0.3.1` does not admit 0.4.0, so a
project on it never saw all of the deprecation warnings. This section gathers
every replacement; the version in parentheses is the one that deprecated the
API.

1. Upgrade to `^0.4.0` first and clear every deprecation warning that
   `flutter analyze` reports.
2. Move to `^1.0.0`, search the code for the removed names below and compile
   the app or run `flutter test`. Clean 0.4.0 code can still name them:
   - A removed name in the `hide` list of an import becomes an
     `undefined_hidden_name` warning; the code still compiles. The usual case
     is `hide whenListen` next to the `bloc_test` import: delete it.
   - The analyzer does not report a deprecated use inside the app's own
     `@Deprecated` declarations, under an ignore comment, where
     `analysis_options.yaml` turns `deprecated_member_use` off, or in files
     excluded from analysis. With 1.0.0 such a use no longer compiles. A use
     through a `dynamic` receiver fails only at run time.

Conditions:

| Removed | Replacement |
| --- | --- |
| `onChange(sel).shouldRebuild`, `onChangeListen(sel).shouldListen` (0.3.0) | `whenChanged(sel)` |
| `onChangeBy(sel, equals: eq)`, `onChangeListenBy(sel, equals: eq)` (0.3.0) | `whenChanged(sel, equals: eq)` |
| `whenRebuild(p).shouldRebuild`, `whenListen(p).shouldListen` (0.3.0) | `p` |
| `always()`, `alwaysListen()` (0.3.0) | omit `buildWhen` / `listenWhen` |
| `never()`, `neverListen()` (0.3.0) | `(previous, current) => false` |
| `distinct()`, `distinctListen()` (0.3.0) | `(previous, current) => previous != current` (omitting the parameter differs only for a first emitted state equal to the initial one, which `emit` does not skip) |
| `a.and(b)`, `a.or(b)`, `a.not()` on `RebuildPolicy` and `ListenPolicy` (0.3.0) | `(p, c) => a(p, c) && b(p, c)`, `\|\|`, `!` |
| `BlocSelectedCondition<T>` (0.4.0) | `BlocCondition<T>`, the same function type |

Where the widget has no type arguments, keep them on the condition:
`onChange<S, T>(sel).shouldRebuild` becomes `whenChanged<S, T>(sel)`.

Effects:

| Removed | Replacement |
| --- | --- |
| `EffectListener<B, S, E>` (0.3.0) | `BlocEffectListener<B, E>` |
| `EffectListener` on a subtype of the declared effect type (0.3.0) | `BlocEffectListener` on the supertype with an if-case pattern |
| `MultiEffectListener` (0.3.0) | `MultiBlocListener`, which asserts that `listeners` is not empty |
| `SingleChildEffectListener` (0.3.0) | `BlocEffectListener`, a `SingleChildWidget`, inside `MultiBlocListener` |
| `effectWhen: (effect) => effect is ShowError` and the typedef `EffectCondition` (0.4.0) | `if (effect case ShowError(...))` or `if (effect is! ShowError) return;` at the top of `onEffect`; the if-case also promotes the effect type |
| `listener.withChild(child)` (0.4.0) | `child:` in the constructor, or the listener in `MultiBlocListener` |
| `BlocEffectListenerWithBloc<B, S, E>` (0.4.0) | no replacement: `void Function(BuildContext context, B bloc, E effect)` |

`BlocEffectListener` no longer implements `SingleChildEffectListener`.

Lookups, the extension `BlocContextExtension` (0.4.0):

| Removed | Replacement |
| --- | --- |
| `context.readOrNull<B>()` | `context.read<B?>()` |
| `context.watchOrNull<B>()` | `context.watch<B?>()` |
| `context.selectOrNull<B, S, T>((state) => state.x)` | `context.select<B?, T?>((bloc) => bloc?.state.x)` |
| `context.withBloc((B bloc) => bloc.x)` | `context.read<B?>()?.x` |

These lookups of `provider` return the same values, with the same rebuilds
(see "Optional lookups"). `package:flutter_bloc/flutter_bloc.dart` exports
them and `bloc_plus` does not: a file without that import needs it, and drops
the `bloc_plus` import when it used `bloc_plus` only for the helpers.

Async helpers:

| Removed | Replacement |
| --- | --- |
| `RestartableTask.run(task)` (0.4.0) | `runOutcome((_) => task())`, and `if (!outcome.isCompleted) return;` before `outcome.value` |
