# COMP 205 — Milestone P1 Report (App Skeleton, Backend & CI)

**Course:** COMP 205 Mobile Programming (Fall 2026)  
**Team Name:** Lunerya  
**Team Number:** T13  
**Project Title:** Photalchemy  
**Repository:** https://github.com/serhatvs/Photalchemy  
**Milestone:** P1 — Skeleton (13 November 2026)  
**Report Date:** 15 November 2026  

---

## 1. Executive Summary

Photalchemy is a location-based, turn-based Android card game built with Flutter where real-world photo color statistics are transmuted into playable cards (`attack`, `defense`, `stun`, `reflect`) for strategic dungeon combat.

For **Milestone P1**, Team Lunerya (T13) established a clean feature-first Flutter architecture with `ChangeNotifier`-based state management (`AppController`), four navigable screens (`Explore`, `Cards`, `Battle`, `Account`), deterministic color-to-card generation, a simultaneous turn-based `BattleEngine`, rule-enforced Firestore repositories with default-deny `firestore.rules`, FCM notification opt-in scaffolding, GitHub Actions CI (`verify`), **91 unit and widget tests**, **1 end-to-end integration test**, a verified **Android debug APK build**, and **3 P1 AI Decision Records (ADRs)**.

---

## 2. Team Structure & Repository Contributions (Team Lunerya — T13)

| Member | GitHub | Role(s) | P1 Contributions |
| --- | --- | --- | --- |
| Serhat Yavuz | `@serhatvs` | AI Lead, Architecture & Quality Lead | Repository structure & governance docs, CI workflow, `GameCard`/`ColorFeatureExtractor`/`CardGenerator` contracts, Track A plan & `SyntheticMatchDatasetGenerator`, `BattleEngine` & `SafeFallbackEnemyPolicy`, `AppController` state management, integration test, P1 ADRs & P1 Report |
| Ali Çavdar | `@cavdara549-create` | UI Lead | Flutter Android bootstrap exploration (`feat/3-flutter-bootstrap`), `AsyncStateView` (`EmptyStateView`, `LoadingStateView`, `ErrorStateView`) and `async_state_view_test.dart`, README setup guidance |
| Şükrü Öztürk | `@sukrucanozturk98` | Back-end Lead | Immutable card grant enforcement (`allow update: if false`) in `firestore.rules` & `RuleEnforcingInMemoryFirestoreGateway`, wiring `RarityPolicy` & `incrementCellCapture` in `AppShell`, PR reviews/approvals (#13, #15), Issue #7 role confirmation |
| Kadir Zongur | `@kadirzongur64-byte` | Gameplay & GenAI Lead | Battle engine boundary verification and edge-case tests for max-turn HP tie-breaking and lethal damage clamping (PR #15 / Issue #6) |

*Note on Issue #7 (`TEAM.md`):* `@sukrucanozturk98` has confirmed responsibilities on Issue #7; final signatures and exact off-class weekly meeting slot/SLA in `TEAM.md` remain open for sign-off by all four members.

---

## 3. GitHub Repository & Engineering Process Analysis

Development follows short-lived feature branches, linked GitHub Issues (`#3`–`#9`), automated CI checks, and squash merges into protected `main` (`Photalchemy - Protect main` ruleset enforcing PRs, linear history, 1+ approving review, CODEOWNER review, resolved threads, and green `verify` check).

### Branch & Pull Request Inventory (as of 15 November 2026)
- **Merged to `main`:**
  - PR #1 (`chore/repository-workflow`): repository governance (`CONTRIBUTING.md`, `SECURITY.md`, `PRIVACY.md`, `QUALITY.md`, `TESTING.md`, `.github/CODEOWNERS`, CI).
  - PR #2 (`dependabot`): `actions/checkout` v4 → v7.
  - PR #10 (`feat/3-flutter-app-shell`, Issue #3): initial Flutter navigation shell and screen scaffolds.
  - PR #11 (`feat/5-card-domain-and-ml-plan`, Issue #5): card/color domain, `BattleEngine`, `EnemyPolicy`, `SyntheticMatchDatasetGenerator`, Track B 20 scenarios, `RarityPolicy`, and P1 ADRs.
- **Approved & CI-Green Open PRs (awaiting CODEOWNER / final merge):**
  - **PR #13** (`feat/9-p1-android-firebase-integration`, Issues #4 & #9): Android platform files (`android/`), `firebase.json`, `firestore.rules`, `FirestoreProfileRepository`, `FirestoreCardRepository`, `MockFcmNotificationService`, `docs/FIREBASE_AND_DEMO.md`. Approved by `@sukrucanozturk98`; Codex review finding on post-mint card mutation resolved in `9e16949`.
  - **PR #15** (`feature/battle-engine-skeleton`, Issue #6): edge-case battle tests by `@kadirzongur64-byte`, approved by `@sukrucanozturk98`.
- **P1 Completion Branch (`feat/p1-completion-and-report`):**
  - Combines PR #13 + PR #15 + Ali's `AsyncStateView` (`c1781bc`), replaces `setState`-only shell state with `AppController` (`ChangeNotifier` + `ListenableBuilder`), wires `ColorFeatureExtractor` & `SafeFallbackEnemyPolicy` & card sync into the live app, adds `integration_test/app_test.dart`, aligns `TEAM.md` and `docs/adr/P1-01..03.md` with COMP 205 templates, and delivers this P1 Report.

---

## 4. Mobile App Architecture & Implemented P1 Skeleton

### 4.1 Navigation, State Management & Screens (`lib/`)
- **State management (`lib/app/app_controller.dart`, `lib/app/app_shell.dart`):**
  - `AppController extends ChangeNotifier` decouples UI from repositories and domain engines, exposed via `ListenableBuilder` in `AppShell` (avoiding `setState`-only architecture per COMP 205 Section 3.1).
- **Four core screens:**
  1. **Explore (`lib/features/exploration/presentation/explore_page.dart`):** Displays capture frame (`Color-v0 mode`), handles camera permission-denied state (`Camera Access Required` + `Grant Camera Permission`), and triggers `AppController.captureAndTransmute()`, which extracts color statistics via `ColorFeatureExtractor.extractFromBytes`, computes location-aware rarity via `RarityPolicy`, generates a bounded `GameCard`, and persists to Firestore + cell visit count when signed in.
  2. **Cards (`lib/features/collection/presentation/collection_page.dart`):** Displays user cards (`starter-ember` and newly transmuted cards) with archetype color, rarity badge, and `STR 1–10`. Uses `LoadingStateView`, `ErrorStateView` (with `Try Again`), and `EmptyStateView` from `lib/core/widgets/async_state_view.dart`.
  3. **Battle (`lib/features/battle/presentation/battle_page.dart`):** Displays Enemy Alchemist vs. Player HP bars, shields, `STUNNED` badges, turn counter, last turn summary (`TurnResult.summary`), action chips for all 4 archetypes (`slash`, `guard`, `stun-blast`, `mirror-ward`), turn-resolution spinner, and a `Play Again` button on match completion. Uses `SafeFallbackEnemyPolicy(primaryPolicy: HeuristicEnemyPolicy())` + `validateEnemyAction` + `BattleEngine`.
  4. **Account (`lib/features/auth/presentation/account_page.dart`):** Supports Guest vs. Authenticated view (`MockAuthRepository`), Sign-in/Sign-out (which loads/clears persisted cards from `CardRepository`), opt-in `Dungeon Alerts (FCM)` toggle, and `Send Demo FCM Alert`.

---

## 5. Backend, Security, Privacy & Notifications

- **Authentication (`lib/features/auth/domain/auth_repository.dart`):** `AuthRepository` interface decoupled from Firebase SDK, with `MockAuthRepository` for credential-free local and CI verification.
- **Cloud Firestore Data Model & Rules (`firestore.rules`, `firebase.json`, `lib/core/storage/firestore_gateway.dart`):**
  - Strict **default-deny** (`match /{document=**} { allow read, write: if false; }`).
  - `/users/{userId}` (`UserProfile`): owner-only read/write, stores only `id`, `isAnonymous`, `notificationsEnabled`, and coarse `~1.1 km` `cellCaptureCounts` (no raw GPS coordinates).
  - `/users/{userId}/cards/{cardId}` (`GameCard`): owner-only read/create/delete, schema-validated (`type` in 4 classes, `rarity` in 4 tiers, `stats.strength` int in `1..10`, `generationVersion` string), and **immutable after minting (`allow update: if false`)** to prevent post-mint rarity/strength escalation.
  - `RuleEnforcingInMemoryFirestoreGateway` mirrors `firestore.rules` in unit tests, verifying unauthenticated rejection, cross-user isolation, out-of-range payload rejection, card-update immutability, and offline `unavailable` error handling.
- **Notifications (`lib/core/notifications/notification_service.dart`):** Opt-in `NotificationService` (`MockFcmNotificationService` for P1) enforces permission checks before topic subscription (`dungeon_alerts`) and surfaces denial cleanly via SnackBar.
- **Secrets Hygiene:** Zero API keys, service accounts, or `google-services.json` files committed to Git (`SECURITY.md`, `PRIVACY.md`).

---

## 6. AI Tracks Readiness (Team Size = 4: Both Tracks Deep)

| Track | COMP 205 Requirement | P1 Foundation Completed | Planned for P2 |
| --- | --- | --- | --- |
| **Track A (Own Model)** | Train own ML/DL model, grouped 5-fold CV, baseline + 95% CI, model card | `ml/TRACK_A_PLAN.md`, `ml/dataset_manifest_schema.csv`, `ml/MODEL_CARD_TEMPLATE.md`, `BattleEngine`, `SyntheticMatchDatasetGenerator` (seed/match-grouped isolation), `RandomEnemyPolicy` & `HeuristicEnemyPolicy` baselines | Generate full simulated match dataset, train action-value MLP, run grouped 5-fold CV & bootstrap/95% CI vs. baselines, complete model card |
| **Track B (Generative AI)** | Tool-calling agent (≥2 tools) or RAG via Firebase AI Logic / server, ≥20 evaluation queries, prompt-injection test, offline fallback | `EnemyObservation` (sanitized public state), `validateEnemyAction` whitelist, `SafeFallbackEnemyPolicy` (timeout + exception fallback), `PredefinedScenarios.all20` + `EvaluationRunner` in `battle_scenario.dart` | Connect live tool-calling LLM backend (keys off-client), benchmark ≥20 scenarios including prompt-injection cases, record expected vs. actual pass rate |

---

## 7. P1 AI Decision Records (ADRs)

All three P1 ADRs are documented in `docs/adr/` following `ADR_TEMPLATE.md`:
1. [`P1-01-deterministic-color-pipeline.md`](adr/P1-01-deterministic-color-pipeline.md) — Rejected on-device pre-trained MobileNet CV classifier in favor of offline, `NaN`-safe statistical `ColorFeatureExtractor`.
2. [`P1-02-deterministic-battle-engine.md`](adr/P1-02-deterministic-battle-engine.md) — Rejected asynchronous initiative turn queue in favor of simultaneous pure-state turn phases with single-pass reflection.
3. [`P1-03-safe-fallback-policy.md`](adr/P1-03-safe-fallback-policy.md) — Rejected direct state-mutating LLM tools (`reduce_player_hp`) in favor of `EnemyObservation`, `validateEnemyAction` whitelisting, and `SafeFallbackEnemyPolicy`.

---

## 8. Verification Evidence (Observed Results)

All checks below were executed on the final P1 codebase (`feat/p1-completion-and-report`):

| Check | Command | Observed Result |
| --- | --- | --- |
| Formatting | `dart format --output=none --set-exit-if-changed lib test integration_test` | Passed — 40 files checked, 0 formatting changes needed |
| Static Analysis | `flutter analyze` | Passed — `No issues found!` |
| Unit & Widget Tests | `flutter test` | Passed — **91 / 91 tests passed** (domain, repositories, security rules, `AppController`, `AppShell`, `AsyncStateView`, `BattlePage`, `CollectionPage`, `ExplorePage`, `AccountPage`, 20 Track B scenarios, `SyntheticMatchDatasetGenerator`) |
| Integration Test | `flutter test -d flutter-tester integration_test` | Passed — **1 / 1 end-to-end MVP test passed** (`Explore` capture → `Cards` → `Battle` turn → `Account` sign-in, FCM opt-in & demo alert → sign-out) |
| Android APK Build | `flutter build apk --debug` | Passed — built `build\app\outputs\flutter-apk\app-debug.apk` (175,341,805 bytes) |
| GitHub Actions CI | `.github/workflows/ci.yml` (`verify`) | Configured to enforce governance files, `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`, and `flutter test -d flutter-tester integration_test` |

---

## 9. Known Limitations & P2 Action Plan

1. **GitHub PR Merges & Issue #7:** PR #13, PR #15, and the P1 completion PR need CODEOWNER approval & squash-merge to `main`; members still need to add final signatures and weekly meeting time in `TEAM.md` (Issue #7).
2. **Live Firebase Project & Release Signing:** Current P1 demo runs against `MockAuthRepository`, `RuleEnforcingInMemoryFirestoreGateway`, and `MockFcmNotificationService` so CI and reviewers need zero secrets; P2 will connect a dedicated COMP 205 Firebase project (with `google-services.json` excluded from Git) and configure release keystore signing (`P2` milestone deliverable).
3. **Real Camera & Location Plugins:** P1 uses deterministic sample RGB frame bytes and `CoarseLocation` demo coordinates (`38.7205, 35.4826`); P2 will integrate Android camera/image decoding and foreground location permissions with opt-out fallback.
4. **Deep AI Tracks (P2 — 25 Dec 2026):** Train & evaluate Track A own-trained battle policy (Serhat) and integrate live Track B tool-calling LLM opponent + ≥20 evaluation report (Kadir).
