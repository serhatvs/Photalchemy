# Test Strategy — Photalchemy

> The current repository contains **placeholders**, not yet a runnable Flutter application. Commands and test matrix below define the intended future workflow, not existing passing tests.

**Coordination:** Serhat (quality), with Kadir (gameplay/agent), Şükrü (backend), and Ali (UI).

## Testing pyramid and ownership

| Level | Target and examples | Owner |
| --- | --- | --- |
| Unit / pure domain | Card classification constraints, legal stat ranges, combat turn order, stun duration, reflect edge cases, repeatability | Serhat + Kadir |
| Widget | Auth error states, camera permission-denied screen, inventory/empty states, battle controls and accessibility | Ali |
| Service / repository | Mock Firebase repositories, offline retries, auth failures, invalid card writes, persisted inventory isolation | Şükrü |
| Firebase rules | Authenticated owner allowed; unauthenticated and cross-user reads/writes rejected; invalid writes blocked | Şükrü |
| Track A evaluation | Baseline, grouped train/test isolation, macro-F1/confusion matrix where applicable, confidence intervals and model card | Serhat |
| Track B evaluation | At least 20 fixed scenarios with legal/illegal actions, malformed tool calls, timeouts, prompt injection and deterministic fallback | Kadir |
| End-to-end | Sign in → choose/capture image → receive card → inspect collection → battle, including denial/offline paths | All |

## Local checks (after Flutter initialization)

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test --coverage
```

`integration_test/` requires an emulator/device and an integration-test harness; set it up when the MVP screen flow exists. Do not require cloud credentials in normal PR unit/widget tests. Use test doubles/emulators and disposable test accounts rather than production data.

To test Firestore rules, use the Firebase Emulator Suite and a dedicated security-rules test suite once Firestore schema/rules are defined. Rule tests should assert both **allowed** and **denied** paths. Do not claim the current GitHub CI verifies Firebase rules until that job has been added.

## CI acceptance

`.github/workflows/ci.yml` provides a `verify` check on PRs to `main`. Before `pubspec.yaml` is added, it validates required repository files. After Flutter initialization, it should also run formatting, static analysis and `flutter test`. Later include emulator-backed rules/integration checks when stable enough to automate.

**Required for every PR:** relevant local test results or a reason the check cannot yet run, updated tests for changed behavior, review approval and passing CI. New failing tests do not get skipped silently.

## Critical edge-case checklist

- Zero, negative or overflow-like damage; HP never below allowed bounds; reflect cannot loop indefinitely.
- Stun applied/expired at turn boundaries; no duplicate turns; agent cannot choose impossible moves.
- Empty deck/inventory; duplicate photo or repeat location; invalid/huge or permission-denied photo.
- Firebase token expired, offline state, denied cross-user access, write conflicts or duplicate requests.
- No location permission and no GPS/emulator signal; no upload without consent.
- GenAI malformed JSON/tool args, prompt injection from an untrusted field, provider outage and timeout.
- ML missing/ambiguous features, model mismatch, data leakage across photo/session/location groups.

## Evidence for P1/P2/P3

Keep reproducible test setup, evaluation fixtures and sanitized results in the repository where possible. Use synthetic or consented data; no private photos, exact locations, API keys or raw personal logs in test fixtures. Reference issue/PR IDs for important fixed bugs and newly added regression tests.

Release verification requires a clean install of the **signed APK** on a fresh emulator/device, smoke testing of the full MVP, and an explanation of features unavailable offline.
