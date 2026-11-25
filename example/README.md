# bloc_plus example

The example app demonstrates:

- `BlocConsumerWithEffects`
- targeted rebuilds with a plain predicate as `buildWhen`
- custom equality with `whenChanged(..., equals: ...)`
- `BlocEffectListener` inside a `MultiBlocListener`, with an `if` at the top
  of `onEffect` that picks the effects it handles
- `RestartableTasksMixin.runLatestOutcome` and `TaskOutcome`

Run:

```bash
cd example
flutter pub get
flutter run
```
