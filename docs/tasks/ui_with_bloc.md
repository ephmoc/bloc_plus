# Task Spec - ui_with_bloc (UI Layer Enhancements)

> Status: delivered in 0.1.0. In 0.3.0 the bounds widened to
> `B extends StateStreamable<S>`, `BlocListenerWithBloc` got a `const`
> constructor, and `BlocConsumerWithBloc` resolves the bloc once per build.
> In 0.4.0 `BlocBuilderWithBloc` and `BlocListenerWithBloc` compose
> `BlocBuilder` and `BlocListener` and resolve the bloc once per build as
> well, so they follow the provided bloc after `bloc` becomes `null`. The
> signatures below are the ones in `lib/` at 0.4.0.

## Preconditions

- Flutter package scaffold exists in repo root (`pubspec.yaml`, `lib/`, `test/`, `example/`)
- If missing, bootstrap first with:
  - `flutter create --template=package bloc_plus` (from parent directory), or
  - `flutter create --template=package .` (from package root)
- In this repository, prefer `flutter create --template=package .` to avoid `bloc_plus/bloc_plus`.

## Scope

- Implement `BlocBuilderWithBloc`
- Implement `BlocListenerWithBloc`
- Implement `BlocConsumerWithBloc`
- Implement `BlocSelectorWithBloc`
- Keep behavior parity with corresponding `flutter_bloc` widgets plus bloc instance in callbacks,
  except that they follow the provided bloc after `bloc:` becomes `null` (0.4.0)
  and in the two other cases of 0.4.0 under Public Contract

## Signatures (0.4.0)

- `const BlocBuilderWithBloc<B extends StateStreamable<S>, S>({required builder, bloc, buildWhen})`,
  a `StatelessWidget` that returns a `BlocBuilder`; `builder(context, bloc, state)`
- `const BlocListenerWithBloc<B extends StateStreamable<S>, S>({required listener, bloc, listenWhen, child})`,
  a `SingleChildStatelessWidget` that returns a `BlocListener`; `listener(context, bloc, state)`
- `const BlocConsumerWithBloc<B extends StateStreamable<S>, S>({required listener, required builder, bloc, buildWhen, listenWhen})`
- `const BlocSelectorWithBloc<B extends StateStreamable<S>, S, T>({required selector, required builder, bloc, selectorShouldRebuild})`;
  `builder(context, bloc, selected)`, `selectorShouldRebuild(previous, current)`
- Typedefs: `BlocWidgetBuilderWithBloc<B, S>`, `BlocWidgetListenerWithBloc<B, S>`,
  `BlocSelectorBuilderWithBloc<B, S, T>`, `BlocSelectedCondition<T>` (deprecated
  in 0.4.0, removed in 1.0: `selectorShouldRebuild` is a `BlocCondition<T>`,
  the same function type)

## Out Of Scope

- `policies` module
- `async_safety` utilities
- `effects` module

## Public Contract

- `bloc` is optional; when omitted, resolve from `BuildContext`
- Missing bloc in context must throw provider-not-found error (same semantics as `flutter_bloc`)
- `buildWhen` / `listenWhen` semantics must match `flutter_bloc`
- `BlocSelectorWithBloc` rebuilds only on selected value change by default (`!=`)
- `BlocSelectorWithBloc` accepts custom `selectorShouldRebuild(previous, current)`;
  `previous` is the last built selection (since 0.2.2)
- When `bloc:` changes from an instance to `null`, `BlocBuilderWithBloc`,
  `BlocListenerWithBloc` (both since 0.4.0) and `BlocConsumerWithBloc` follow
  the provided bloc at once, unlike `BlocBuilder` and `BlocListener`, which
  keep the previous instance; `buildWhen` and `listenWhen` then get their
  previous state from the new bloc
- `BlocListenerWithBloc` without a `child`, outside a multi widget such as
  `MultiBlocListener`, renders `SizedBox.shrink()` with every supported
  `flutter_bloc` (0.4.0); `BlocListener` asserts on a missing child before
  9.1.2
- `BlocSelectorWithBloc` follows a replaced provided bloc also when its
  element was already dirty (0.4.0): the old bloc emitted a state that
  changed the selection, and the provided bloc was replaced before the next
  frame while the widget instance was reused. `BlocSelector` stays on the
  old bloc

## Target Files

- `lib/src/widgets/bloc_builder_with_bloc.dart`
- `lib/src/widgets/bloc_listener_with_bloc.dart`
- `lib/src/widgets/bloc_consumer_with_bloc.dart`
- `lib/src/widgets/bloc_selector_with_bloc.dart`
- `lib/src/widgets/widgets.dart` (barrel)
- `lib/bloc_plus.dart` (exports)

## Tests (Contract)

- `test/widgets/bloc_builder_with_bloc_test.dart`
- `test/widgets/bloc_listener_with_bloc_test.dart`
- `test/widgets/bloc_consumer_with_bloc_test.dart`
- `test/widgets/bloc_selector_with_bloc_test.dart`
- `test/widgets/state_streamable_widgets_test.dart` (0.3.0)
- `test/widgets/with_bloc_widgets_contract_test.dart`

Required cases:

- builder/listener receive bloc instance used by widget
- explicit `bloc:` overrides context lookup
- missing provider throws
- `buildWhen` and `listenWhen` are respected
- selector default compare prevents unnecessary rebuilds
- custom `selectorShouldRebuild` controls rebuild behavior
- works with a `StateStreamable<S>` that is not a bloc (0.3.0)
- `BlocConsumerWithBloc` follows the provided bloc right after `bloc:` changes
  to null (0.3.0)
- `BlocBuilderWithBloc` and `BlocListenerWithBloc` follow the provided bloc
  after `bloc:` changes to null and after the provider is replaced, take the
  previous state for `buildWhen` / `listenWhen` from the new bloc, and do not
  create a lazily provided bloc while `bloc:` is set; the listener composes
  inside `MultiBlocListener` (0.4.0)
- `BlocListenerWithBloc` without a `child` renders `SizedBox.shrink()`, and
  `BlocSelectorWithBloc` follows a provided bloc that is replaced while its
  element is already dirty (0.4.0)

## Example App Updates

- Historical: the example app at 0.3.0 shows only `BlocBuilderWithBloc` of
  these four widgets; the README lists all four.
- Add a page/section showing all four widgets with one shared bloc
- Show mixed usage with standard `flutter_bloc` widgets in the same tree

## Acceptance Criteria (DoD)

- All public APIs compile and are exported
- Widget tests pass for all required cases
- `flutter analyze` has no new warnings/errors from this module
- Example app demonstrates each widget (historical, see above)
- Dartdoc added for all public classes/params

## Validation Commands

- `dart format .`
- `flutter analyze`
- `flutter test test/widgets`

## Agent Constraints

- Do not change public API outside PRD contract
- Prefer composition over fragile inheritance internals
- Do not introduce extra dependencies
