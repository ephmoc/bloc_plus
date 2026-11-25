# bloc_plus example

The example app demonstrates:

- `BlocConsumerWithEffects`
- targeted rebuilds with a plain predicate as `buildWhen`
- custom equality with `whenChanged(..., equals: ...)`
- effects as `sealed` classes, handled with an exhaustive `switch` or with an
  if-case for one subtype, by `BlocEffectListener` inside a
  `MultiBlocListener` and by `BlocConsumerWithEffects`
- `RestartableTasksMixin.runLatestOutcome` and `TaskOutcome`

Run:

```bash
cd example
flutter pub get
flutter run
```
