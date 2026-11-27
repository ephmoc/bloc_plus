# Library Improvement Plan

Delivery notes for `0.2.0`, `0.2.2`, `0.3.0` and `0.3.1`, the planned next
steps, and the guardrails for future work. For delivered items, API names
and signatures are defined by the code and its API docs, and per-version
changes by `CHANGELOG.md`; where this file disagrees with them, they win.
"Next" describes changes that are not in the code yet.

The goal is to extend the package in ways that stay aligned with the existing
design principles:

- zero magic,
- compatibility with public `flutter_bloc` APIs,
- small and explicit abstractions,
- high-value ergonomics for day-to-day app code.

## Delivered in 0.2.0

### 1. Composable policies and custom equality

Previous gap:

- `RebuildPolicy` and `ListenPolicy` cover only `distinct`, `onChange`,
  `always`, and `never`.
- `onChange` relies on `!=`, which is often too limited for lists, maps, DTOs,
  and computed view models.

Delivered additions:

- composition helpers: `and`, `or`, `not`
- custom predicate wrappers: `whenRebuild(predicate)` and
  `whenListen(predicate)`
- selector policies with explicit equality:
  - `onChangeBy(selector, equals: ...)`
  - `onChangeListenBy(selector, equals: ...)`

Why this matters:

- reduces repeated inline lambdas in widgets
- keeps rebuild/listen logic reusable and testable
- improves correctness for non-trivial selected values

### 2. Effect filtering on top of `EffectListener`

Previous gap:

- `EffectListener` reacts to every emitted effect
- callers must manually filter with `if`/`switch` inside `onEffect`

Delivered additions:

- effect-level predicate support via `effectWhen`

Why this matters:

- keeps UI callbacks smaller and more focused
- improves ergonomics for apps using multiple effect variants from one bloc

### 3. `MultiEffectListener`

Previous gap:

- multiple effect listeners require nested widgets

Delivered additions:

- `MultiEffectListener` mirroring the ergonomics of `MultiBlocListener`

Why this matters:

- makes effect-heavy screens easier to read
- keeps package conventions aligned with `flutter_bloc`

### 4. Higher-level async helpers

Previous gap:

- `RestartableTask` is useful but still low-level
- users must manually coordinate task ownership, cancellation, and result
  handling

Delivered additions:

- `RestartableTasksMixin` with keyed `runLatest`, `cancelLatest`,
  `cancelAllLatest`, and `isTaskRunning` for "latest request wins" flows
- pending tasks are cancelled when the bloc closes
- designed for direct use inside Cubits; inside Bloc event handlers, prefer the
  handler's `emit` and `bloc_concurrency` transformers

Why this matters:

- lowers adoption cost of the async safety module
- helps standardize safe async flows in library consumers

### 5. Combined state-and-effect consumer ergonomics

Previous gap:

- state rendering and effect handling are composed from separate widgets

Delivered additions:

- `BlocConsumerWithEffects`, a thin composition of `EffectListener` and
  `BlocConsumerWithBloc`

Why this matters:

- simplifies common screen wiring
- stays explicit: state and effects keep separate callbacks and conditions

## Delivered rollout order

1. Composable policies and custom equality
2. Effect filtering
3. `MultiEffectListener`
4. Higher-level async helpers
5. Combined state-and-effect consumer

Related task specs:

- `docs/tasks/policy_composition.md`
- `docs/tasks/effect_filtering.md`
- `docs/tasks/multi_effect_listener.md`
- `docs/tasks/async_helpers.md`
- `docs/tasks/state_effect_consumer.md`

## Delivered in 0.2.2

Fixes for superseded async work, `HasEffects.close()` ordering,
`BlocSelectorWithBloc` selection updates, the `*OrNull` lookups and
`runLatest` cleanup; `bloc >=9.2.1`; one gated CI workflow that also covers the
lowest dependency versions and the minimum SDK; contract tests; releases
published from tags through OIDC. Details are in `CHANGELOG.md`.

## Delivered in 0.3.0

Released 2026-11-22 (minor). Details and migration notes are in
`CHANGELOG.md`.

- conditions: `BlocCondition` and `whenChanged`; `RebuildPolicy`,
  `ListenPolicy` and their 12 factories deprecated, which also retires the
  `whenListen` name that clashes with `bloc_test`. No `and` / `or` / `not` on
  the function type: an untyped lambda as their receiver would compile as
  `dynamic`, so typos would only fail at run time;
- effects: `BlocEffectListener<B extends EffectsSource<E>, E>` as a
  `SingleChildWidget` that composes inside `MultiBlocListener` (direct
  dependency on `provider`, the range `flutter_bloc` requires);
  `EffectListener`, `MultiEffectListener` and `SingleChildEffectListener`
  deprecated; `BlocConsumerWithEffects` bound to `HasEffects<S, E>` with an
  optional `listener`;
- async: `TaskOutcome`, `runOutcome` / `runLatestOutcome` passing a
  `CancellationToken` to the task, `whenCancelled`, and callers released as
  soon as their run is cancelled;
- `@protected` and `@visibleForTesting` on `emitEffect` and `safeEmit`;
- `StateStreamable<S>` bounds on the widgets, `Object` bounds on
  `readOrNull`, `watchOrNull` and `withBloc` (`StateStreamableSource<S>` on
  `selectOrNull`), a `const` `BlocListenerWithBloc` constructor, and one bloc
  instance per `build` in the consumers;
- the PRD and task specs brought in line with the code.

## Delivered in 0.3.1

Released 2026-11-22 (patch): a recipe for testing effects and the opt-in
`debugPrintUnheardEffects` warning for effects that nothing listens to.
`dart fix` data for the 0.3.0 deprecations was dropped: the policy factories
cannot be described, and renaming `EffectListener<B, S, E>` to
`BlocEffectListener` keeps the extra type argument, so the result does not
compile.

## Next

Planned, in this order. Decided on 2026-11-23, after two reviews: one of the
1.0 scope, one of the direction of the changes and of what each API is worth
to an app.

The second review found that the async helpers for Cubits and the effects
carry the package, that the `BuildContext` helpers repeat what provider
documents, and that some signatures can only be tightened before a freeze.
So 0.4.0 tightens and shrinks the API, and 1.0 follows no earlier than four
weeks after it is published.

### 0.4.0, planned as the last 0.x minor

It makes every change of shape that 1.0 will freeze and deprecates everything
that 1.0 removes, so that 1.0 itself only removes what 0.4.0 marked. Code
that compiles on 0.4.0 without deprecation warnings can still name what 1.0
removes: in the `hide` lists of its imports, and where the analyzer does not
report a deprecated use (see below).

It lands on `develop` as separate pull requests: one for each breaking
change, one for the deprecations, one for the new docs and the rest of the
example. Each one passes CI on its own, so it carries its tests, its
CHANGELOG entry, the README, dartdoc, PRD and task-spec edits of its change
(AGENTS.md sections 6, 10 and 12) and the edit of the example that its
warnings force: the deprecations remove `effectWhen` from the example, the
`@protected` change removes its two reads of `isTaskRunning`. The last pull
request holds what belongs to no single change: the recipes, the table,
"Compared with", "Versioning" and the sealed effects in the example.

Before it is published, every helper whose result says whether the run
counted gets `@useResult`, which after 1.0 would need a major (decided on
2026-11-25; the deprecated `RestartableTask.run`, which 1.0 removes, stays
without it): `runLatestOutcome` and `RestartableTask.runOutcome`, and
`runLatest`, `guarded` and `CancellationToken.run`, whose bound catches a
dropped result only for `void` and nullable work. A result that is awaited
and dropped is then reported, so
`await runLatest('save', () => repository.save(item)); emit(saved);` no
longer passes without a warning. A task that emits itself, such as a flow
with several `await`s, returns the future instead:
`Future<void> open() => runLatestOutcome(...)`. The annotation comes from
`meta`, which becomes a direct dependency (`>=1.9.1 <2.0.0`; the Flutter SDK
itself depends on it, and Flutter 3.10 pins 1.9.1). A trial migration of an
existing application, planned here on 2026-11-23, was dropped on
2026-11-25: the work stays on the library.

Before it is published, three findings of a review are fixed as well
(decided on 2026-11-27). `BlocListenerWithBloc` without a `child` renders
`SizedBox.shrink()`, as `BlocEffectListener` does: its assertion copied the
one of `BlocListener`, which `flutter_bloc` 9.1.2 dropped.
`BlocSelectorWithBloc` follows a replaced provided bloc also when its element
was already dirty. `guarded` completes with `null` for a future that
calls back synchronously, such as a `SynchronousFuture`, when `close()` is
called in the same turn.

Breaking changes, allowed inside 0.x, each with its migration in the
CHANGELOG:

- `runLatest`, `guarded` and `CancellationToken.run` get the bound
  `T extends Object`. Their `null` result means "discarded", which is
  ambiguous for a `void`, nullable or `dynamic` task: today
  `await runLatest('save', save); emit(saved);` compiles, emits although the
  run was superseded, and throws after `close()`. With the bound such a call
  is a compile error. Migration: the outcome methods and a check of
  `isCompleted`. `guarded` and `CancellationToken.run` have no outcome twin:
  void or nullable work is awaited plainly and followed by `safeEmit`, or by
  a check of `isClosed` or of `token.isCancelled` before anything else. A
  task that returns a non-null value, such as the record in the README, is
  needed only to keep what the two methods add: the operation is not
  started, a late failure is dropped and, for `CancellationToken.run`, the
  caller is released at `cancel()` instead of when the work ends. A generic
  helper that forwards its own type parameter needs the same bound
  (`Future<T?> load<T extends Object>(...)`), and so does an override of
  `runLatest` or `guarded` and a function type that names the old signature.
  The analyzer does not report a helper that returns the call
  (`=> runLatest(key, task)`, `=> guarded(task)`, `=> token.run(task)`):
  `flutter analyze` stays clean and the build fails with "Inferred type
  argument 'T' doesn't conform to the bound 'Object'". The CHANGELOG says so
  and asks the reader to compile (`flutter test` or a build) after upgrading.
- `SafeEmitMixin` is declared `on Cubit<S>`. In a `Bloc` the handler's `emit`
  is already a no-op once `close()` or a transformer has cancelled the
  handler, while `safeEmit` skips that check and `onTransition`: under
  `restartable()` a superseded handler emits its stale state. Migration for a
  `Bloc`: remove the mixin and check `isClosed`, which is what `safeEmit` and
  `guarded` checked. It is true from the call of `close()`, but `close()`
  cancels the handlers only later: a few microtasks later under the default
  transformer, `concurrent()`, `droppable()` and `restartable()`, and only
  after the running and the queued handlers have finished while any handler
  of the bloc uses `sequential()`. Until then `emit.isDone` is `false` and
  the handler's `emit` still delivers. So:
  - `safeEmit(state)` becomes `if (!isClosed) emit(state);`, which now also
    calls `onTransition`;
  - `await guarded(operation)` becomes `if (isClosed) return;` before
    `await operation()` and again after it. The first check keeps the
    operation from starting on a closed bloc, which happens after an earlier
    `await` and in an event that `sequential()` queued before `close()`;
  - `guarded` also dropped a failure that arrives after `close()` was
    called: wrap the `await` in `try`/`catch` with
    `if (isClosed) return; rethrow;` in the `catch`, or put
    `if (isClosed) return;` first in a `catch` the handler already has.
    Without it the failure reaches that `catch`, whose `emit` may still
    deliver an error state, or else `onError` and the zone;
  - a public method, and a callback that outlives its handler (a stream
    subscription: the handler's `emit` fails an assertion there), adds an
    event instead, `if (!isClosed) add(event)`, with a handler that emits.
    The state then changes when that handler runs, not during the call.

  Checking `emit.isDone` as well stops a handler that a transformer
  cancelled, which `guarded` never did. A direct subclass of `BlocBase`
  loses the mixin as well: it extends `Cubit` instead, or checks `isClosed`
  before `emit` by hand. `RestartableTasksMixin` and `HasEffects` stay
  `on BlocBase<S>`.
- `BlocBuilderWithBloc` and `BlocListenerWithBloc` follow the provided bloc
  after `bloc:` changes from an instance to `null`, like the consumers and
  the selector. This replaces the documented "give it a new `key`"
  limitation. They become a `StatelessWidget` and a
  `SingleChildStatelessWidget` that return the upstream `BlocBuilder` /
  `BlocListener` with `bloc ?? context.select<B, B>((bloc) => bloc)`, as
  `BlocConsumerWithBloc` does, so the package adds no subscription code of
  its own. The constructors with their parameters, `const`, the fields
  `bloc`, `buildWhen`, `listenWhen`, `builder` and `child`, and the
  composition inside `MultiBlocListener` stay. What breaks: the widgets no
  longer extend `BlocBuilderBase` / `BlocListenerBase` (nor `StatefulWidget`),
  `BlocBuilderWithBloc.build` takes only the context,
  `BlocListenerWithBloc.listener` is the `(context, bloc, state)` callback,
  and the callbacks get the context of the inner upstream widget. Migration:
  none for ordinary use. A `key` that was added only for the switch can go.
  Code that relied on the widget staying with the old instance keeps passing
  that instance as `bloc:`. Code that names `BlocBuilderBase` /
  `BlocListenerBase` for these widgets, overrides `build` or reads `listener`
  adapts to the new members.
- `CancellationToken` and `RestartableTask` become `final class`. Extending,
  implementing or mocking them is a compile error, and mockito cannot
  generate a mock of a final class; tests use real instances
  (`CancellationToken()` and `cancel()`). There is no `@sealed` step before
  it: this release breaks compilation in other places anyway, and generated
  mocks would not show the warning.
- `isTaskRunning`, `runLatest`, `runLatestOutcome`, `cancelLatest`,
  `cancelAllLatest` and `guarded` are marked `@protected` and
  `@visibleForTesting`, as `safeEmit` and `emitEffect` already are. A call
  from outside the cubit, such as `isTaskRunning` read in `build` or
  `cancelLatest` called from a widget, becomes two analyzer warnings
  (`invalid_use_of_protected_member` and
  `invalid_use_of_visible_for_testing_member`), so `flutter analyze` fails
  on it. A call from an extension on the cubit is reported as well; a call
  from a mixin declared `on` the package's mixin is not. Files under
  `test/`, `integration_test/` and `test_driver/` may still call them; a
  test helper under `lib/` may not. Migration: a method in the body of the
  cubit class that makes the call, and a field of the state for what the UI
  shows. After 1.0 the same annotation would put new warnings into the CI of
  every user and need a major, so it is done now.

Deprecations, removed in 1.0:

- the extension `BlocContextExtension` and its four `BuildContext` helpers
  `readOrNull`, `watchOrNull`, `selectOrNull` and `withBloc`. The annotation
  goes on the extension and on each member, so that
  `show BlocContextExtension` warns as well as a call. The helpers return
  what provider's nullable lookups return, with the same rebuilds:
  `context.read<B?>()`, `context.watch<B?>()`,
  `context.select<B?, T?>((bloc) => bloc?.state.x)` (or
  `bloc == null ? null : ...` when the selector is not a member chain) and
  `context.read<B?>()?.member` (or a local variable and a null check when the
  callback is more than one member access). The README keeps one paragraph on
  optional lookups with these spellings;
- `effectWhen` on `BlocEffectListener` and `BlocConsumerWithEffects`, with
  the typedef `EffectCondition`: an `if` or an if-case at the top of
  `onEffect` does the same, and the if-case promotes the effect type;
- `RestartableTask.run`, whose `T` belongs to the class and cannot take the
  bound: `runOutcome` replaces it;
- the typedef `BlocEffectListenerWithBloc`. It has an unused type parameter
  and nothing names it, so it gets no replacement:
  `BlocConsumerWithEffects.onEffect` declares its function type inline, as
  `BlocEffectListener.onEffect` does;
- the typedef `BlocSelectedCondition<T>`, the same function type as
  `BlocCondition<T>`, which `BlocSelectorWithBloc.selectorShouldRebuild`
  uses from now on;
- `BlocEffectListener.withChild`, which only serves the deprecated
  `MultiEffectListener`: pass `child:` to the constructor, or list the
  listener in `MultiBlocListener`, which supplies the child.

Tests:

- Contracts of current APIs that have no test of their own get one, before
  1.0 deletes the deprecated tests.
  - Copied from the deprecated twins, which keep theirs until 1.0: the
    `(previous, current)` order of the arguments of `whenChanged`'s `equals`;
    `BlocEffectListener` following the provided bloc after `bloc:` becomes
    `null`; surviving a bloc closed while mounted; several
    `BlocEffectListener`s of one bloc inside `MultiBlocListener` being called
    in declaration order.
  - New: `BlocEffectListener` switching from the provided bloc to an explicit
    one.
  - Split from tests that also use a deprecated member, so that 1.0 deletes
    only the deprecated half: `BlocEffectListener` and
    `BlocConsumerWithEffects` calling the `onEffect` of the latest build
    after a rebuild, and `BlocConsumerWithEffects` applying `listenWhen` to
    its `listener` (both are asserted together with `effectWhen` today); the
    contracts of `RestartableTask` that are tested only through `run` today,
    such as `isRunning` being `false` after `dispose()` during a run, get
    tests with `runOutcome`.
- `BlocBuilderWithBloc` and `BlocListenerWithBloc`: following the provided
  bloc after `bloc:` becomes `null` and after the provider is replaced,
  `previous` in `buildWhen` / `listenWhen` coming from the new bloc after a
  switch, and no creation of a lazily provided bloc while `bloc:` is
  explicit. The old limitation has no test, only its notes in the dartdoc and
  the README, which go.
- The test that applies `SafeEmitMixin` to a `Bloc` goes. Every deprecated
  member keeps its tests until 1.0; their files carry
  `// ignore_for_file: deprecated_member_use_from_same_package`, which the
  analyzer of the minimum SDK reports without being asked. In `lib/`,
  `BlocConsumerWithEffects` forwards `effectWhen` to `BlocEffectListener`
  under the same file-level ignore until 1.0, and `withBloc` calls
  `read<B?>()` instead of the deprecated `readOrNull`.
- A test guards the recipe for a flow with several awaits (see Docs): a
  superseded flow neither emits a stale state nor cancels the newer flow.

Docs:

- the README leads with what the package adds to `flutter_bloc`: the async
  helpers for Cubits and the effects, then the conditions and the `*WithBloc`
  widgets. The "Policies" heading becomes "Conditions". The first sentence,
  the feature list, the library doc comment and the `description` in
  `pubspec.yaml` follow, and mention effects. pub.dev allows at most five
  `topics` and there are five, so `effects` replaces `widgets`;
- the README and the dartdoc follow every change above in the same change set
  (AGENTS.md section 12). In the README: the feature list with its list of
  deprecated APIs, the paragraph on the methods that return `null` (they take
  a non-null `T` only; for void or nullable work it shows the plain form
  first and keeps the record only for what `guarded` and
  `CancellationToken.run` add), the two notes on `effectWhen` and the version
  in the install snippet. In the dartdoc: `SafeEmitMixin` ("after a cubit has
  been closed"), the "When `T` is nullable or `void`" paragraphs of
  `guarded`, `runLatest` and `CancellationToken.run`, which give the same
  order, `HasEffects.close` (which recommends `safeEmit` in "a bloc
  method"), the `effectWhen` sentences of `BlocEffectListener`, and
  `BlocCondition`, which names `BlocSelectedCondition`;
- a "Compared with" section in the README, with differences that were
  measured against the version current at the time: `bloc_presentation` for
  effects (here `emitEffect` after `close()` is a no-op, the listener follows
  the provided bloc after `bloc:` becomes `null`, and there are
  `debugPrintUnheardEffects` and `BlocConsumerWithEffects`; there a test
  package exists, here the README has recipes), `CancelableOperation` from
  `package:async` (outside a bloc it gives the same result as
  `RestartableTask` when it is written with `valueOrCancellation()` and
  `onCancel`, in more lines; awaiting `value` never releases a superseded
  caller), and `bloc_concurrency` (transformers for the event handlers of a
  `Bloc`, nothing for a Cubit);
- the example app shows what the README recommends: effects as a sealed
  hierarchy handled by an exhaustive `switch`, without string prefixes and
  `effectWhen`, and the running flag kept in state instead of
  `isTaskRunning` read in `build`. Until the example drops `effectWhen` and
  its two reads of `isTaskRunning`, `flutter analyze` fails on their
  warnings;
- the README async sample handles the failure path, so that the loading flag
  is cleared when the task throws. It shows "latest wins" with
  `RestartableTasksMixin` alone and says where `safeEmit` still matters in
  such a flow (an emit before the first `await`), instead of applying both
  mixins without a reason;
- a README recipe for a flow with several awaits: one `runLatestOutcome`
  around the whole flow, a check of `token.isCancelled` after every `await`,
  the emits inside the task. A key names a whole flow, not a step: with one
  run per step under the same key, a superseded flow that has any other
  `await` between its steps resumes and starts its next step. That step
  cancels the newer flow when the newer flow is inside a run, and emits its
  stale state otherwise. The dartdoc of `runLatest` and `runLatestOutcome`
  says so in one sentence;
- a short table in the README that says which helper to use: `safeEmit` for
  an emit after an `await`; `guarded` for work whose non-null result is used
  afterwards; `runLatestOutcome` for "latest wins", or `runLatest` when the
  result is non-null; `RestartableTask` outside a bloc. It also says what the
  package does not replace: a plain `if (isClosed) return;` before further
  logic stays;
- the CHANGELOG migration and the dartdoc of `runLatest` show the whole
  replacement for void work, with `if (!outcome.isCompleted) return;`: an
  ignored outcome emits the superseded result, which `@useResult` reports;
- the README states the rule for the effect callbacks:
  `BlocEffectListener.onEffect` gets `(context, effect)`,
  `BlocConsumerWithEffects` hands the bloc to `builder`, `listener` and
  `onEffect` (its conditions get the two states), and it needs the
  `HasEffects` mixin while the listener accepts any `EffectsSource`;
- a README recipe for "ignore while running": `isTaskRunning` checked before
  the first `await`, and a pointer to `bloc_concurrency` for a `Bloc`.
  `isTaskRunning` is not reactive, so it is read inside the cubit and not in
  `build`;
- a testing recipe for widget tests that mock the bloc: `effects` has to be
  stubbed with a stream, or the widget fails with a `TypeError`. The test
  that guards the recipe writes its mock by hand, so that no dev dependency
  is added;
- the dartdoc of `guarded`, `runLatest` and `CancellationToken.run` says to
  handle `null` first, with an early return. An `else` or a `default` branch
  takes a discarded run (a closed cubit, a superseded or a cancelled run)
  for a failed result, and the analyzer's hint for the missing `null` case
  suggests such a branch;
- the dartdoc of `emitEffect` says that a `Bloc` handler cancelled by a
  transformer still delivers its effect unless it checks `emit.isDone` first;
- the note on type inference, in the README, in the class dartdoc of
  `BlocEffectListener`, which holds the current note, and in the dartdoc of
  its `onEffect`. Without type arguments the `effect` parameter of
  `BlocEffectListener.onEffect` is `Object?` at every language version, so a
  `switch` over it is not checked for exhaustiveness. For
  `BlocConsumerWithEffects`, `S` and `E` are inferred from `bloc:` only in
  code at language version 3.7 or later, and that is the version of the app,
  not of this package;
- a "Versioning" section in the README: the policy below, introduced as
  applying from 1.0.0. Until then a 0.x minor may contain breaking changes,
  as 0.4.0 does;
- the PRD and the task specs follow every change of this release in the same
  change set, because AGENTS.md ranks them above this file: the `BuildContext`
  helpers, `effectWhen`, the bound and `RestartableTask.run` (also in the
  samples: one passes a `void` task to `token.run`), `SafeEmitMixin` for
  Cubits only (the PRD says that Bloc and Cubit are both supported, that the
  mixins apply `on BlocBase<S>` and that the `bloc` floor exists for
  `safeEmit` on a closing `Bloc`), `final class`, the builder and the
  listener (their declarations with `BlocBuilderBase` / `BlocListenerBase`,
  `build(context, state)` and the `listener` getter, in the PRD and in
  `docs/tasks/ui_with_bloc.md`, and the notes "matches `BlocBuilder`
  exactly", "parity with `BlocBuilder`", "no overhead" and "give it a new
  `key`"), the two typedefs, the six members that become `@protected` and
  `@visibleForTesting` (the declarations of `RestartableTasksMixin` and of
  `guarded` in the PRD, the rows of its API freeze table, which name the
  annotations only for `safeEmit` and `emitEffect`, and the member lists in
  `docs/tasks/async_helpers.md` and `docs/tasks/async_safety.md`), the
  inference notes, the version that the PRD
  says it describes, and the PRD's own "v1.0.0 - API Freeze" entry, which
  points here instead. The PRD is edited first in that change set, as its
  section 5.6 asks.

### 1.0.0 (major)

Released when both conditions hold:

- at least four weeks have passed since 0.4.0 was published. A 0.4.x release
  that changes code under `lib/` (anything but comments) restarts them, a bug
  fix included, and so does one that changes a constraint under
  `dependencies` or `environment` in `pubspec.yaml`; a release that changes
  only documentation, the example or tests does not, and the other
  `pubspec.yaml` fields, `dev_dependencies` included, count as documentation.
  A change of `lib/` that 1.0.0 would publish for the first time is released
  in a 0.4.x first: `lib/` of 1.0.0 differs from the last published 0.4.x
  only by the removals below;
- no change is open that would need a major under "Versioning from 1.0"
  below: none is planned in this file, and none is asked for in an open issue
  or pull request of the repository.

Such a change is released in 0.5.0 first, and then this section reads 0.5
wherever it says 0.4: the four weeks count from the publication of 0.5.0. A
change that only adds API comes in a 0.4.x patch, which restarts the four
weeks as any change of `lib/` does, or in a 1.x minor.

Before the release, upstream is checked once more for a built-in cancelable
API (bloc issue 3069, open since 2021) and for a new major of a dependency.
Either would change what 1.0 freezes: if one exists, 1.0 waits until this
section says what it changes.

There is no `-dev` prerelease: releases are cut from `main`, so a prerelease
there would close the 0.4.x line for fixes. 1.0.0 closes it for the same
reason: no 0.4.x fix is published after it. The removals wait on their own
branch, open as a draft pull request into `develop` so that CI runs on them
and updated after every 0.4.x release. They are merged into `develop` only
for the release.

- Remove everything deprecated: `RebuildPolicy`, `ListenPolicy` and their 12
  factories; `EffectListener`, `MultiEffectListener` and
  `SingleChildEffectListener`; `BlocEffectListener.withChild`; `effectWhen`
  and `EffectCondition`; the extension `BlocContextExtension` with
  `readOrNull`, `watchOrNull`, `selectOrNull` and `withBloc`;
  `RestartableTask.run`; the typedefs `BlocEffectListenerWithBloc` and
  `BlocSelectedCondition`.
- The `context_extensions` module then has no API: its export, its PRD
  section and its task spec go, and AGENTS.md section 4 drops it from the
  module sequence. `docs/tasks/effect_filtering.md`,
  `docs/tasks/multi_effect_listener.md` and `docs/tasks/policy_composition.md`
  describe only removed API and go as well, with their entries under "Related
  task specs" above. `docs/tasks/policies.md` keeps only `BlocCondition` and
  `whenChanged`: the `policies` module stays.
- Nothing else changes: the bounds, the class modifiers and the widget types
  are those of 0.4.0. The mixins stay plain mixins. The widgets are not marked
  `final`, but subclassing them is outside the versioning policy. The minimum
  SDK stays at Dart 3.0 / Flutter 3.10.
- The dartdoc that still mentions a removed name is corrected in the same
  change, because no CI gate reports it: `effectWhen` in
  `BlocEffectListener.onEffect` and "complete with `null` or" in
  `RestartableTask.dispose`. `dart doc --dry-run` prints no warning. The two
  `ignore_for_file: deprecated_member_use_from_same_package` headers go with
  their comments (`bloc_effect_listener.dart`,
  `bloc_consumer_with_effects.dart`): the analyzer does not report an ignore
  that has become unnecessary.
- Migration notes: "upgrade to 0.4.0 and clear every warning first, then
  search for the removed names and compile", because clean 0.4.0 code can
  still name them. A name that 1.0 removes has to be deleted from the `hide`
  list of an import, where it becomes an `undefined_hidden_name` warning (the
  code still compiles). The usual case is the `hide whenListen` that the
  README asked for next to `bloc_test`. The analyzer also does not report a
  deprecated use inside the app's own `@Deprecated` declarations, under an
  ignore comment, where `analysis_options.yaml` turns `deprecated_member_use`
  off, in files excluded from analysis, or through a `dynamic` receiver,
  which fails only at run time. A short "Upgrading from 0.x" section of the
  README gathers every replacement, because a constraint such as `^0.2.0` or
  `^0.3.1` does not admit 0.4.0: such a project never saw all of the
  deprecation warnings. The replacements stand today in two README tables
  (under "Effects" and "Conditions"), in two README paragraphs
  (`RestartableTask.run` under "Async helpers for Cubits", the lookups under
  "Optional lookups"), in the CHANGELOG of 0.4.0 (`BlocSelectedCondition`
  and `BlocEffectListenerWithBloc`) and, for `SingleChildEffectListener`,
  only in its deprecation message (`BlocEffectListener`, a
  `SingleChildWidget` inside `MultiBlocListener`). The install snippet
  reads `^1.0.0`.
- The API freeze table in the PRD and the task specs are updated. The
  statements that speak of 1.0 as coming are removed or reworded in the
  README (the list of deprecated APIs, the notes "removed in 1.0", the
  `hide whenListen` paragraph, the introduction of "Versioning"), in the PRD
  (the API freeze table with its heading "v0.x scope", the entry
  "v1.0.0 - API Freeze", the version it says it describes) and in the task
  specs that stay.

### Versioning from 1.0

Published in the README:

- the public API is everything exported from
  `package:bloc_plus/bloc_plus.dart`;
- a major version is needed to remove or rename an export, to change a
  signature incompatibly, to change the superclass of a widget, to change
  documented behaviour, or to add an annotation that makes the analyzer
  report code that was clean before, such as `@protected`. `@Deprecated` is
  the exception (next item);
- a minor version may add exports, members and optional parameters, support a
  new major of a dependency when no signature here changes, raise the minimum
  Dart or Flutter SDK or the minimum version of a dependency (a new major
  included), and deprecate an API, which is then removed no earlier than the
  next major;
- not covered: classes that `implement` this package's classes or mixins by
  hand (`EffectsSource` is the exception, and gets no new member without a
  major), subclasses of its classes and widgets, and overriding members of
  its widgets. Applying the mixins with `with`, or building on them with
  `mixin X on ...`, is covered. Where a widget is documented as a
  `flutter_bloc` widget with something added, the rest of its behaviour is
  that of the `flutter_bloc` version the app resolves; a change there is not
  a change of this package;
- a member added in a minor may clash with a member of the same name in a
  class that applies a mixin or extends a class of this package, and an
  optional parameter added to a method of a mixin breaks an override of that
  method. Neither is treated as a breaking change.

### Reviewed and kept

The second review proposed to cut or reshape these as well. Each one stays as
it is, for a reason that a replacement would have to match:

- `guarded` makes the closed check part of the type. Its result is `T?`, so
  where the result is used as a non-null value (an exhaustive `switch` over a
  sealed result, `.match` on an `Either`, a member, a non-nullable parameter)
  a forgotten check is a compile error; an `else`, a `default` branch or `?.`
  still compiles, which the dartdoc warns about. The manual
  `final r = await op(); if (isClosed) return;` compiles without its check
  and then throws or runs on after `close()`. `guarded` also does not start
  the operation on a closed cubit and drops a failure that arrives after
  `close()`. The first has a one-line manual replacement; the second is one
  line in a `catch` that exists and a `try`/`catch` around the `await`
  otherwise. It is for work with a non-null result: void work keeps the
  manual guard.
- `BlocConsumerWithEffects` resolves the bloc once for the builder, the
  listener and the effects. In the composed form a `bloc:` that is forgotten
  on one of the widgets makes that widget look the bloc up: it listens to the
  provided instance without an error, or throws `ProviderNotFoundException`
  when none is provided.
- The `*WithBloc` widgets hand the callback the bloc that the widget listens
  to. With an explicit `bloc:` that is not the provided one,
  `context.read<B>()` in the callback throws or returns another instance.
- `BlocSelectorWithBloc.selectorShouldRebuild` is a custom comparison with
  the value that is shown. `BlocSelector` compares with `!=` only, and
  `buildWhen` compares with the previous state, whether it was built or not.
- `CancellationToken` keeps its constructor, `cancel()` and `run`: tests need
  a real token, and one token can cover several operations that run in
  parallel. `RestartableTask` stays public, as the engine of the mixin and
  for "latest wins" outside a bloc.
- `TaskOutcome` stays a `final class` with `isCompleted` and `value`. A
  sealed pair of subclasses can be added in a 1.x minor without breaking it.
  It does not make the compiler force the check, because `value` stays on
  the base type: it offers a checked path, a `switch` over the two subtypes.
  Forcing the check needs a major.
- `BlocEffectListener.onEffect` stays `(context, effect)`, although
  `BlocConsumerWithEffects` hands the bloc to its callbacks. A third argument
  would let `E` be inferred from `bloc:` in code at language version 3.7 or
  later, but it would change every existing listener, and the case it helps
  is an explicit `bloc:` without type arguments. A listener that hands over
  the bloc can be added in a 1.x minor.

### Dropped from the plan

- Reshaping `selectOrNull` into a nullable twin of provider's `select`: the
  helpers are deprecated instead.
- Repairing the builder and the listener by overriding `createState()`: about
  126 lines of copied subscription lifecycle, against a composition of the
  upstream widgets that needs none.
- `@sealed` as a step before `final class`.
- A selector-based listener: `listenWhen: whenChanged(...)` covers it.
- More async modes for Cubits: no new API. "Ignore while running" is one
  line with `isTaskRunning` (the README recipe in 0.4.0), and
  `bloc_concurrency` covers a `Bloc`. A queue per key is not planned; if it is
  ever needed, it comes as a separate mixin in a 1.x minor.
- Renaming the `BlocEffectListenerWithBloc` typedef: it is removed instead.
- Raising the minimum SDK to Dart 3.7: type inference depends on the language
  version of the app, so the package gains nothing.
- Replaying or buffering an effect for a listener that subscribes later: an
  effect that nothing listens to stays lost, as the README and the dartdoc of
  `emitEffect` say. If replay is ever needed, it comes as a separate mixin in
  a 1.x minor.

## Guardrails

The following remain out of scope unless product direction changes:

- replacing `flutter_bloc`
- event bus patterns
- framework-specific code generation
- APIs that depend on non-public `flutter_bloc` internals
- abstractions that hide provider lookup or effect delivery semantics
- more `*WithBloc` widget variants or a `MultiBlocBuilder`
- more `BuildContext` lookup helpers (provider already supports nullable
  lookups such as `context.read<T?>()`)
- more policy combinators
- event transformers for `Bloc` (covered by `bloc_concurrency`)
- general-purpose cancellation tokens (timeouts, merging) or structured
  concurrency
- a custom analyzer plugin or a DevTools extension

## Release notes (0.2.0)

- Policy composition and effect filtering shipped as additive APIs.
- `MultiEffectListener` shipped as a composition convenience.
- Higher-level async helpers shipped with lifecycle and cancellation tests.
- The combined state-and-effect consumer shipped as a thin composition of
  existing primitives rather than a new runtime model.
