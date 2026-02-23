# AGENTS.md

This file defines mandatory execution rules for coding agents working in this repository.

## 1. Mission

- Build and maintain `bloc_plus` as a Flutter package.
- Implement features module-by-module according to PRD and task specs in `docs/tasks/`.
- Keep behavior explicit, type-safe, and compatible with public `flutter_bloc` APIs.

## 2. Source of Truth

When instructions conflict, use this priority order:

1. Direct user instruction in current chat.
2. `AGENTS.md` (this file).
3. `docs/bloc_plus_PRD.md`.
4. `docs/tasks/*.md`.

If any conflict remains unresolved, stop and ask the user.

## 3. Package Bootstrap Rule

Bootstrap is an initialization step. Do not re-run scaffold generation in an already initialized repository unless the user explicitly requests it.

Before implementing modules, ensure package scaffold exists at repo root:

- Required for initialization: `pubspec.yaml`, `lib/`, `test/`.
- `example/` is recommended, but its absence alone must not trigger scaffold regeneration.
- If missing, run:
  - `flutter create --template=package .` (preferred in this repo), or
  - `flutter create --template=package bloc_plus` (from parent dir).

Do not create nested `bloc_plus/bloc_plus`.
Do not run `flutter create` in a populated repository just to restore optional artifacts.

## 4. Module Delivery Strategy

- Implement one module at a time.
- Finish each module end-to-end before moving to next:
  - code,
  - tests,
  - exports,
  - docs updates if needed,
  - validation commands passing.

Default sequence (follow unless user instruction or explicit task dependency requires a different order):

1. `ui_with_bloc`
2. `context_extensions`
3. `policies`
4. `async_safety`
5. `effects`

## 5. Public API Safety

- Use only public APIs from dependencies.
- Do not depend on private internals or undocumented behavior.
- If a PRD snippet references unavailable/non-public API, implement equivalent behavior using public APIs and keep contract semantics.

## 6. Testing Policy (Mandatory)

### 6.1 Core Rules

- Every public API change requires tests in the same change set.
- For widgets: use widget tests.
- For utilities/mixins/policies: use unit tests.
- Include both positive and negative cases.
- Avoid brittle assertions that depend on incidental framework behavior.

### 6.2 Given-When-Then Convention (Required)

All tests MUST follow Given-When-Then structure.

Rules:

- Test names should communicate scenario and expected outcome.
- Inside each test, use comments in this exact style:
  - `// Given`
  - `// When`
  - `// Then`
- Keep each section short and explicit.
- Prefer one behavior assertion group per test.

Template:

```dart
testWidgets('does X when Y', (tester) async {
  // Given
  // setup

  // When
  // action

  // Then
  // expectations
});
```

### 6.3 Minimum Contract Coverage

For each new public API:

- success path,
- missing dependency/provider path,
- conditional path (`buildWhen`/`listenWhen`/comparators),
- explicit override path (e.g., explicit `bloc` parameter),
- disposal/lifecycle behavior if relevant.

## 7. Validation Commands (Run Before Completion)

Run all:

1. `flutter pub get`
2. `dart format --set-exit-if-changed .`
3. `flutter analyze`
4. `flutter test`

If full suite is heavy, run targeted tests during development, but final response must include full-suite result or explicitly state what was not run.

## 8. Code Quality Rules

- Keep code simple and explicit; avoid unnecessary abstraction.
- Preserve null safety and strong typing.
- Do not add heavy dependencies without user approval.
- Keep public exports intentional through `lib/bloc_plus.dart`.
- Add comments only where they add real value.

## 9. Change Reporting in Final Message

When a module is completed, include:

- what was implemented,
- files changed,
- validation results,
- any known limitations or deferred items.

If something could not be completed, state the blocker and attempted workaround.

## 10. Versioning & Changelog Policy

- Follow semantic versioning in `pubspec.yaml`.
- Update `CHANGELOG.md` in the same change set for any user-visible behavior change.
- For public API additions or behavior changes, include at least:
  - what changed,
  - migration impact (if any),
  - release type rationale (`patch`/`minor`/`major`).

## 11. Dependency & Lockfile Policy

- Keep dependency constraints intentional and explicit in `pubspec.yaml`.
- When dependency constraints change, run `flutter pub get` and commit resulting lockfile updates.
- Prefer latest compatible patch/minor within declared constraints unless user requests stricter pinning.
- Do not add new runtime dependencies without user approval.

## 12. Public API Governance

- Any public API change must update all relevant surfaces in the same change set:
  - exports in `lib/bloc_plus.dart`,
  - usage docs in `README.md`,
  - runnable examples when applicable (`example/` if present).
- Do not expose experimental/internal APIs through package exports unless explicitly requested.

## 13. Test Completion Criteria

- A module is not done unless tests cover all required contract paths from section 6.3.
- Include negative tests for invalid/missing provider scenarios where relevant.
- Include lifecycle/disposal tests for APIs interacting with streams, subscriptions, or widget lifecycle.
- Keep tests deterministic; avoid timing-sensitive assertions unless strictly necessary.

## 14. Backward Compatibility & Deprecation

- Avoid breaking public API without explicit user approval.
- If a breaking change is required, document migration steps in `CHANGELOG.md` and update README usage accordingly.
- Prefer deprecation-first transitions when feasible:
  - keep old API available temporarily,
  - mark deprecations clearly,
  - provide replacement guidance.

## 15. CI Parity Rule

- Local validation must mirror CI gates as closely as possible.
- Minimum required pre-completion command order:
  1. `flutter pub get`
  2. `dart format --set-exit-if-changed .`
  3. `flutter analyze`
  4. `flutter test`
- If any command cannot be run, explicitly report which command was skipped and why.
