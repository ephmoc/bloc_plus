# bloc_plus example

The example app demonstrates:

- `BlocConsumerWithEffects`
- targeted rebuilds with a plain predicate as `buildWhen`
- custom equality with `whenChanged(..., equals: ...)`
- `BlocEffectListener` with `effectWhen`, inside a `MultiBlocListener`
- `RestartableTasksMixin.runLatestOutcome` and `TaskOutcome`

Run:

```bash
cd example
flutter pub get
flutter run
```
