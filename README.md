# bloc_plus

[![CI](https://github.com/ephmoc/bloc_plus/actions/workflows/ci.yml/badge.svg)](https://github.com/ephmoc/bloc_plus/actions/workflows/ci.yml)
[![PR Checks](https://github.com/ephmoc/bloc_plus/actions/workflows/pr.yml/badge.svg)](https://github.com/ephmoc/bloc_plus/actions/workflows/pr.yml)
[![pub package](https://img.shields.io/pub/v/bloc_plus)](https://pub.dev/packages/bloc_plus)
[![license](https://img.shields.io/github/license/ephmoc/bloc_plus)](https://github.com/ephmoc/bloc_plus/blob/main/LICENSE)
[![style: flutter_lints](https://img.shields.io/badge/style-flutter__lints-40c4ff)](https://pub.dev/packages/flutter_lints)
[![codecov](https://codecov.io/gh/ephmoc/bloc_plus/branch/main/graph/badge.svg)](https://codecov.io/gh/ephmoc/bloc_plus)

`bloc_plus` extends `flutter_bloc` with ergonomic widgets, null-safe context
extensions, and reusable rebuild/listen policies.

## Features

- `BlocBuilderWithBloc`, `BlocListenerWithBloc`, `BlocConsumerWithBloc`,
  `BlocSelectorWithBloc`
- BuildContext extensions:
  - `readOrNull<B>()`
  - `watchOrNull<B>()`
  - `selectOrNull<B, S, T>(selector)`
  - `withBloc<B, R>(fn)`
- Reusable policies:
  - Rebuild: `distinct`, `onChange`, `always`, `never`
  - Listen: `distinctListen`, `onChangeListen`, `alwaysListen`, `neverListen`
- Async safety:
  - `SafeEmitMixin`
  - `CancellationToken`
  - `RestartableTask`
- Effects:
  - `HasEffects`
  - `EffectListener`

## Getting started

Add dependency:

```yaml
dependencies:
  bloc_plus: ^0.1.0
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

### Policies

```dart
class PolicyView extends StatelessWidget {
  const PolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final rebuildPolicy = onChange<MyState, int>((s) => s.count);
    final listenPolicy = onChangeListen<MyState, bool>((s) => s.isLoading);

    return BlocListenerWithBloc<MyCubit, MyState>(
      listenWhen: listenPolicy.shouldListen,
      listener: (context, bloc, state) {},
      child: BlocBuilderWithBloc<MyCubit, MyState>(
        buildWhen: rebuildPolicy.shouldRebuild,
        builder: (context, bloc, state) => Text('${state.count}'),
      ),
    );
  }
}
```

### Async safety

```dart
class MyCubit extends Cubit<int> with SafeEmitMixin<int> {
  MyCubit() : super(0);

  Future<void> load() async {
    final value = await guarded(() async => 1);
    if (value != null) safeEmit(value);
  }
}
```

### Effects

```dart
class AuthCubit extends Cubit<int> with HasEffects<int, String> {
  AuthCubit() : super(0);
}

class AuthEffectsView extends StatelessWidget {
  const AuthEffectsView({super.key});

  @override
  Widget build(BuildContext context) {
    return EffectListener<AuthCubit, int, String>(
      onEffect: (context, effect) {},
      child: const SizedBox.shrink(),
    );
  }
}
```

## Status

Implemented modules:

- `ui_with_bloc`
- `context_extensions`
- `policies`
- `async_safety`
- `effects`

## Release process (without verified publisher)

1. Update `pubspec.yaml` version and matching section in `CHANGELOG.md`.
2. Merge to `main`.
3. Create and push tag:

```bash
git tag -a v0.1.0 -m "bloc_plus 0.1.0"
git push origin v0.1.0
```

4. Run workflow `Publish` manually in GitHub Actions:
   - `ref`: `v0.1.0`
   - `dry_run_only`: `false`
5. Repository secret required for publish: `PUB_CREDENTIALS_JSON`
   (content of local `~/.pub-cache/credentials.json` from account with
   pub.dev publish access).
