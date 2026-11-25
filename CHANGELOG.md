# Changelog

## 0.4.0

- Changed:
  - `CancellationToken` and `RestartableTask` are `final` classes: they can
    no longer be extended, implemented or mocked outside the package.
  - `runLatest`, `guarded` and `CancellationToken.run` take a non-null result
    type only (`T extends Object`). Their `null` result means that the run
    was discarded, which a `void`, nullable or `dynamic` result could not
    tell apart: `await runLatest('save', save); emit(saved);` compiled,
    emitted although the run was superseded, and threw after `close()`. Such
    a call is now a compile error: `could_not_infer`, or
    `type_argument_not_matching_bounds` with an explicit type argument.
  - `SafeEmitMixin` is declared `on Cubit<S>`: a `Bloc` and a direct
    subclass of `BlocBase` can no longer mix it in
    (`mixin_application_not_implemented_interface`). In a `Bloc`, the
    handler's `emit` also calls `onTransition` and does nothing in a handler
    that a transformer has cancelled, while `safeEmit` skipped both: under
    `restartable()` a superseded handler emitted its stale state.
    `RestartableTasksMixin` and `HasEffects` still apply to a `Bloc`.
  - `BlocBuilderWithBloc` and `BlocListenerWithBloc` follow the provided
    bloc right after `bloc:` changes from an instance to `null`, like the
    consumers and the selector, and `buildWhen` and `listenWhen` then get
    their previous state from the new bloc. Before, they kept listening to
    the old instance while their callback got the provided one. They are now
    a `StatelessWidget` and a `SingleChildStatelessWidget` that return
    `BlocBuilder` and `BlocListener`; the constructors, `const`, the fields
    and the composition inside `MultiBlocListener` stay.
  - `isTaskRunning`, `runLatest`, `runLatestOutcome`, `cancelLatest` and
    `cancelAllLatest` of `RestartableTasksMixin`, and `guarded` of
    `SafeEmitMixin`, are `@protected` and `@visibleForTesting`, like `emit`,
    `safeEmit` and `emitEffect`.
  - `BlocConsumerWithEffects.onEffect` declares its function type inline,
    and `BlocSelectorWithBloc.selectorShouldRebuild` is a `BlocCondition<T>`.
    Both are the same function types as before.
- Deprecated, removed in 1.0:
  - the extension `BlocContextExtension` and its `readOrNull`, `watchOrNull`,
    `selectOrNull` and `withBloc`. The extension is annotated as well, so
    `show BlocContextExtension` in an import is reported too;
  - `effectWhen` of `BlocEffectListener` and `BlocConsumerWithEffects`, and
    the typedef `EffectCondition`;
  - `RestartableTask.run`: its `T` belongs to the class and cannot take the
    bound `T extends Object`, so its `null` stays ambiguous;
  - `BlocEffectListener.withChild`, which only serves the deprecated
    `MultiEffectListener`;
  - the typedefs `BlocEffectListenerWithBloc`, which has an unused type
    parameter and no replacement, and `BlocSelectedCondition`, the same
    function type as `BlocCondition`.
- Docs:
  - The README leads with the async helpers for Cubits and the effects; the
    "Policies" section is now "Conditions".
  - New in the README: a table of which async helper to use; recipes for a
    flow with several `await`s, for "ignore while running" and for widget
    tests with a mocked cubit, whose `effects` has to be stubbed; "Compared
    with" (`bloc_presentation`, `CancelableOperation`, `bloc_concurrency`);
    and "Versioning", the policy from 1.0.0. The async sample uses
    `RestartableTasksMixin` alone and clears its loading flag when the
    latest run fails.
  - Corrected: without type arguments, `BlocEffectListener` gives `onEffect`
    an `Object?` effect at every language version, not only below 3.7.
    `BlocConsumerWithEffects` infers `S` and `E` from `bloc:` at language
    version 3.7 or later, which is the language version of the app.
  - The dartdoc of `emitEffect` says that a `Bloc` handler cancelled by a
    transformer still delivers its effect unless it checks `emit.isDone`.
  - The example app models its effects as `sealed` classes.
  - pub.dev: the description mentions the effects, and the topic `effects`
    replaces `widgets`.

Migration impact:

- Deprecated APIs keep working; each use is a `deprecated_member_use` info,
  which fails `flutter analyze` until migrated:
  - `context.readOrNull<B>()` -> `context.read<B?>()`;
    `watchOrNull<B>()` -> `watch<B?>()`;
    `selectOrNull<B, S, T>((state) => state.x)` ->
    `select<B?, T?>((bloc) => bloc?.state.x)`, or `bloc == null ? null : ...`
    when the selector is not a member chain;
    `withBloc((B bloc) => bloc.x)` -> `read<B?>()?.x`, or a local variable
    and a null check when the callback is more than one member access. These
    lookups of `provider` return the same values, with the same rebuilds.
    `package:flutter_bloc/flutter_bloc.dart` exports them and `bloc_plus`
    does not: a file without that import needs it, and drops the `bloc_plus`
    import when it used `bloc_plus` only for the helpers.
  - `effectWhen: (effect) => effect is Sub` -> `if (effect is! Sub) return;`
    or `if (effect case Sub(...))` at the top of `onEffect`, which also
    promotes the effect type.
  - `RestartableTask.run(task)` -> `runOutcome((_) => task())`, and
    `if (!outcome.isCompleted) return;` before `outcome.value`.
  - `listener.withChild(child)` -> `child:` in the constructor, or the
    listener in `MultiBlocListener`, which supplies the child.
  - `BlocSelectedCondition<T>` -> `BlocCondition<T>`;
    `BlocEffectListenerWithBloc<B, S, E>` ->
    `void Function(BuildContext context, B bloc, E effect)`.

- A class that extends or implements `CancellationToken` or
  `RestartableTask`, a mock of either written by hand or with mocktail
  (`implements`), and a `mixin X on` either of them no longer compile
  (`invalid_use_of_type_outside_library`). mockito refuses to generate a mock
  of a `final` class. Use real instances: a test creates `CancellationToken()`
  and calls `cancel()`, or runs its work through a real `RestartableTask`.
- Move `void` and nullable work off `runLatest`, `guarded` and
  `CancellationToken.run`:
  - instead of `runLatest`, use `runLatestOutcome` and check the outcome
    before anything else. An ignored outcome compiles, and the code after it
    then runs for a superseded run as well:

    ```dart
    // Before
    await runLatest('save', save);
    emit(saved);

    // After
    final outcome = await runLatestOutcome('save', (_) => save());
    if (!outcome.isCompleted) return; // superseded or closed
    emit(saved);
    ```

  - `guarded` and `CancellationToken.run` have no outcome twin: await the
    work plainly and then check what the method checked, before anything
    else. For `guarded` that is `isClosed`, which `safeEmit` checks for you;
    for `CancellationToken.run` it is `token.isCancelled`, which `safeEmit`
    does not check. Return a non-null value, such as a record, only to keep
    what the two methods add: the work does not start on a closed bloc or a
    cancelled token, its later failure is dropped, and
    `CancellationToken.run` releases its caller at `cancel()` instead of when
    the work ends.
- A generic helper that forwards its own type parameter needs the same bound
  (`Future<T?> load<T extends Object>(...)`), and so do an override of
  `runLatest` or `guarded` and a function type that names the old signature.
- The analyzer does not report a helper that returns the call
  (`=> runLatest(key, task)`, `=> guarded(task)`, `=> token.run(task)`):
  `flutter analyze` stays clean, and the compiler fails with "Inferred type
  argument 'T' doesn't conform to the bound 'Object' of the type variable
  'T'". After upgrading, compile the app or run `flutter test`.
- A `Bloc` drops `SafeEmitMixin` and checks `isClosed`, which is what
  `safeEmit` and `guarded` checked. `isClosed` is `true` from the call of
  `close()`, but `close()` cancels the handlers a few microtasks later, or,
  while any handler of the bloc uses `sequential()`, only after the running
  and the queued handlers have finished. Until then the handler's `emit`
  still delivers. Inside a handler:
  - `safeEmit(state)` becomes `if (!isClosed) emit(state);`, which now also
    calls `onTransition`. In the `onData` and `onError` of `emit.onEach` that
    is the same check. `emit.forEach` emits every state its callbacks return,
    so a check there cannot stop the emit: where a value must not arrive
    after `close()`, use `emit.onEach`;
  - `await guarded(operation)` becomes `if (isClosed) return;` before
    `await operation()` and again after it. The first check keeps the
    operation from starting on a closed bloc, after an earlier `await` or
    in an event that `sequential()` queued before `close()`;
  - `guarded` also dropped a failure that arrives after `close()`: put
    `if (isClosed) return;` first in the `catch`, and `rethrow` otherwise.

    ```dart
    on<Load>((event, emit) async {
      if (isClosed) return;
      try {
        final item = await repository.load(event.id);
        if (isClosed) return;
        emit(state.copyWith(item: item));
      } catch (_) {
        if (isClosed) return;
        rethrow;
      }
    });
    ```

  A public method of the `Bloc`, and a callback that outlives its handler,
  such as a stream subscription, adds an event instead
  (`if (!isClosed) add(event)`) with a handler that emits: the state then
  changes when that handler runs, not during the call. Checking
  `emit.isDone` as well stops a handler that a transformer cancelled, which
  `guarded` never did.
- A direct subclass of `BlocBase` extends `Cubit` instead, or checks
  `isClosed` before `emit` by hand.
- `BlocBuilderWithBloc` and `BlocListenerWithBloc` need no change in
  ordinary use, and a `key` that was added only to switch between an
  explicit and a provided bloc can go. Code that relied on them staying with
  the old instance passes that instance as `bloc:`. Code that typed them as
  `BlocBuilderBase` or `BlocListenerBase`, called `build(context, state)` or
  read `listener` as a `(context, state)` callback adapts: `build` takes only
  the context, and `listener` is the `(context, bloc, state)` callback. The
  callbacks get the context of the inner `BlocBuilder` or `BlocListener`.
- A call of those six methods from outside the bloc class, such as
  `isTaskRunning` read in `build`, `cancelLatest` called from a widget, or a
  call from an extension on the bloc or from a function outside the class,
  gets two analyzer warnings (`invalid_use_of_protected_member` and
  `invalid_use_of_visible_for_testing_member`), so `flutter analyze` fails.
  Move the call into a method of the bloc, and keep what the UI shows, such
  as a loading flag, in the state, as the async example in the README does.
  A method that cancels the run, such as `cancelPreview` in the example app,
  clears that flag itself: the cancelled call completes with a cancelled
  outcome, or `null` from `runLatest`, and leaves the state as it is. The
  bloc, its subclasses, a `mixin X on RestartableTasksMixin<S>` or
  `on SafeEmitMixin<S>`, and files under `test/`, `integration_test/` and
  `test_driver/` may still call them; a test helper under `lib/` may not.

Release type rationale:

- `minor`: breaking changes of the class hierarchy, of three method
  signatures, of the classes that `SafeEmitMixin` applies to, of the
  superclasses of two widgets and of where six methods may be called without
  analyzer warnings, which a 0.x minor allows, and deprecations. A
  constraint such as `^0.3.1` does not resolve to 0.4.0, so nothing changes
  until a project raises it.

## 0.3.1

- Added:
  - `debugPrintUnheardEffects`: set it to `true` and `emitEffect` prints a
    warning in debug builds for an effect that nothing listens to. Effects
    are not replayed, so such an effect is lost, for example one emitted from
    the bloc's constructor or before the listening widget is mounted. Off by
    default; release builds never print it.
  - README: a recipe for testing effects in unit and widget tests.

Migration impact:

- None.

Release type rationale:

- `patch`: one additive, opt-in debug flag (a new public top-level variable)
  and docs; nothing changes unless the flag is set. Under the 0.x convention
  `^0.3.0` already allows it; code that uses the flag needs `^0.3.1`.

## 0.3.0

- Added:
  - `BlocCondition<S>` and `whenChanged(selector, {equals})`. The result goes
    straight into `buildWhen`, `listenWhen` and `selectorShouldRebuild`, also
    on `BlocBuilder`, `BlocListener` and `BlocConsumer`, without type
    arguments when the widget has its own. Select a record for several
    fields; pass `equals:` for collections.
  - `BlocEffectListener<B extends EffectsSource<E>, E>`: a wrong effect type
    or a bloc without effects no longer compiles, and the listener composes
    inside `MultiBlocListener`.
  - `RestartableTask.runOutcome` and `RestartableTasksMixin.runLatestOutcome`:
    the task gets a `CancellationToken`, and the `TaskOutcome<T>` result tells
    a cancelled run apart from one that completed with `null`.
    `CancellationToken.whenCancelled` can abort the underlying I/O.
  - `BlocConsumerWithEffects.listener` is optional.
  - A `const` constructor for `BlocListenerWithBloc`.
- Changed:
  - A cancelled, superseded or closed run releases its caller at once (`null`
    or `TaskOutcome.cancelled()`) instead of waiting for the abandoned work,
    which keeps running. This fixes callers that hung on work that never
    completes.
  - `BlocConsumerWithEffects` requires `B extends HasEffects<S, E>`.
  - The `*WithBloc` widgets and their callback typedefs accept
    `B extends StateStreamable<S>`, like flutter_bloc's widgets.
    `readOrNull`, `watchOrNull` and `withBloc` accept any provided type, such
    as a repository: `withBloc((Repo repo) => ...)` now finds the repository
    instead of inferring `Never` and returning `null`. `selectOrNull` accepts
    any `StateStreamableSource<S>`, the type `BlocProvider` provides and
    keeps up to date.
  - `BlocConsumerWithBloc` and `BlocConsumerWithEffects` resolve the bloc once
    per build, so states, effects and every callback come from one instance,
    also right after `bloc:` changes from an instance to `null`.
  - `emitEffect` and `safeEmit` are `@protected` and `@visibleForTesting`,
    like `emit`.
  - New direct dependency: `provider` `>=6.0.0 <7.0.0`, the range
    `flutter_bloc` already requires.
- Deprecated, removed in 1.0: `RebuildPolicy`, `ListenPolicy` and their 12
  factories (including `whenListen`, which clashes with `bloc_test`),
  `EffectListener`, `MultiEffectListener` and `SingleChildEffectListener`.

Migration impact:

- Deprecated APIs keep working; each use is a `deprecated_member_use` info,
  which fails `flutter analyze` until migrated:
  - `onChange(sel)` / `onChangeListen(sel)` -> `whenChanged(sel)`, keeping
    `<S, T>` when the widget has no type arguments; the `...By`
    forms -> `whenChanged(sel, equals: eq)`; `whenRebuild(p)` /
    `whenListen(p)` -> `p`; `always()` -> omit the parameter; `never()` ->
    `(previous, current) => false`; `distinct()` ->
    `(previous, current) => previous != current` (omitting the parameter
    differs only for a first emitted state equal to the initial one);
    `a.and(b)` -> a plain predicate or a record selector.
  - `EffectListener<B, S, E>` -> `BlocEffectListener<B, E>`;
    `MultiEffectListener` -> `MultiBlocListener`, which needs a non-empty
    list; a listener for one effect subtype -> the supertype with
    `if (effect case Sub(...))` in `onEffect`.
  - With `bloc_test`, import `bloc_plus` with `hide whenListen` until 1.0.
- `BlocConsumerWithEffects` no longer compiles with a bloc that implements
  `EffectsSource` by hand: mix in `HasEffects<S, E>`.
- `emitEffect` and `safeEmit` called from outside the bloc, extension methods
  on it included, now warn (tests are exempt): move the call into the bloc or
  into a `mixin X on HasEffects<S, E>`.
- Code after the `await` of a superseded run, a `finally` included, now runs
  while the newer run is in flight: check the outcome before resetting a
  shared loading flag.
- In a `Bloc` handler, a task that calls the handler's `emit` still needs an
  `emit.isDone` (or `token.isCancelled`) check: the handler now completes
  first, and bloc rejects the late `emit` only with an assert, so release
  builds emit the stale state.
- Write both type arguments of `BlocEffectListener`: below language version
  3.7, `E` is not inferred from `bloc:`.
- After `bloc:` of `BlocConsumerWithBloc` or `BlocConsumerWithEffects` changes
  from an instance to `null`, the widget follows the provided bloc at once
  instead of the previous instance. `BlocBuilderWithBloc` and
  `BlocListenerWithBloc` keep the previous instance, like `BlocBuilder` and
  `BlocListener`, while their callback gets the provided one: give them a new
  `key` when you switch.

Release type rationale:

- `minor`: new APIs, wider type bounds and deprecations; the narrower consumer
  bound, the new analyzer warnings, the earlier release of superseded callers
  and the consumers following the provided bloc are behaviour changes that a
  0.x minor allows.

## 0.2.2

- Fixes:
  - `CancellationToken.run`, `RestartableTask.run`, `runLatest` and `guarded`
    drop the failure of superseded or cancelled work like its result; only
    the latest run can throw. `guarded` no longer starts on a closed bloc.
  - `HasEffects.close()` no longer waits for a paused effect subscriber
    before closing the bloc.
  - `BlocSelectorWithBloc` behaves like `BlocSelector`: no stale value after
    the selector changes, one selector call per state change, and
    `selectorShouldRebuild` gets the last built value as `previous`.
  - `readOrNull`, `watchOrNull` and `selectOrNull` return `null` only when no
    provider exists.
  - `runLatest` drops the keys of failed tasks; a repeated `close()` waits for
    the first one.
  - `bloc` lower bound raised to `9.2.1`, so `safeEmit` and `guarded` also
    stop on a closing `Bloc`.
- Tooling: Flutter 3.50 support (`flutter_lints` `^6.0.0`, contributors need
  Dart 3.8; example app on `material_ui`, Flutter >=3.47), one gated CI
  workflow that also checks the lowest dependency versions and Flutter
  3.10.6, contract tests and clearer API docs. Package minimums stay at
  Dart 3.0 and Flutter 3.10.

Migration impact:

- No API changes; if you pin `bloc` below `9.2.1`, upgrade within `9.x`.
- Superseded or cancelled runs, and `guarded` calls that fail after close,
  return `null` instead of throwing.
- Effects emitted right before `close()` reach subscribers after the bloc is
  closed, like its last states; a subscriber that emits into the bloc in
  response should use `safeEmit`.
- `selectorShouldRebuild` gets the last built value as `previous`;
  `BlocSelectorWithBloc` is now a `StatefulWidget`.
- A missing provider read inside a bloc's `create` now throws from
  `readOrNull` / `watchOrNull` / `selectOrNull` instead of returning `null`.

Release type rationale:

- `patch`: bug fixes without API changes.

## 0.2.1

- Compatibility metadata update:
  - lowered the developer tooling floor from `Dart 3.8` to `Dart 3.0` by
    constraining `flutter_lints` to the latest line that still supports Dart 3.0
  - kept the package minimum SDKs unchanged at `Dart >=3.0.0` and
    `Flutter >=3.10.0`

Migration impact:

- No API changes. No migration required.

Release type rationale:

- `patch` change for compatibility metadata and tooling support only.

## 0.2.0

- Added policy composition and custom equality helpers:
  - `whenRebuild`
  - `whenListen`
  - `RebuildPolicy.and`, `RebuildPolicy.or`, `RebuildPolicy.not`
  - `ListenPolicy.and`, `ListenPolicy.or`, `ListenPolicy.not`
  - `onChangeBy`
  - `onChangeListenBy`
- Expanded effect ergonomics:
  - added `effectWhen` to `EffectListener`
  - added `MultiEffectListener`
- Added higher-level async helpers:
  - `RestartableTasksMixin`
  - keyed `runLatest`, `cancelLatest`, `cancelAllLatest`, `isTaskRunning`
- Added `BlocConsumerWithEffects` for combined state and effect composition.
- Updated README, PRD, task specs, and example app to document the new APIs.

Migration impact:

- No breaking API changes. Existing code continues to work.
- Consumers can adopt the new APIs incrementally.

Release type rationale:

- `minor` bump for new public API surface additions.

## 0.1.3

- Documentation improvements:
  - Added dartdoc comments for the public API to improve generated package
    docs and pub.dev documentation coverage.

Migration impact:

- No API changes. No migration required.

Release type rationale:

- `patch` bump for user-visible documentation improvements with no behavior
  changes.

## 0.1.2

- Documentation cleanup:
  - Removed the two trailing README sections: `Status` and
    `Release process (without verified publisher)`.
- Change category:
  - `chore`

Migration impact:

- No API changes. No migration required.

Release type rationale:

- `patch` bump for documentation-only cleanup.

## 0.1.1

- CI improvements:
  - Added dedicated coverage workflow with Codecov upload.
  - Coverage upload now supports `CODECOV_TOKEN` via GitHub Actions secret.
- Release process improvements:
  - Added PR quality and release automation workflows.
  - Added manual publish workflow for non-verified publisher setup.
- Documentation improvements:
  - Added status badges to README.
  - Clarified release flow and publish steps.

Migration impact:

- No API changes. No migration required.

Release type rationale:

- `patch` bump for CI, release automation, and documentation improvements.

## 0.1.0

- Added `ui_with_bloc` module:
  - `BlocBuilderWithBloc`
  - `BlocListenerWithBloc`
  - `BlocConsumerWithBloc`
  - `BlocSelectorWithBloc`
- Added `context_extensions` module:
  - `readOrNull`
  - `watchOrNull`
  - `selectOrNull`
  - `withBloc`
- Added `policies` module:
  - Rebuild policies: `distinct`, `onChange`, `always`, `never`
  - Listen policies: `distinctListen`, `onChangeListen`, `alwaysListen`, `neverListen`
- Added `async_safety` module:
  - `SafeEmitMixin`
  - `CancellationToken`
  - `RestartableTask`
- Added `effects` module:
  - `HasEffects`
  - `EffectListener`

Migration impact:

- First feature release, no migration required.

Release type rationale:

- `minor` bump due to new public API surface additions.
