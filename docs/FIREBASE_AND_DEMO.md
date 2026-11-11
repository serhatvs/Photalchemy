# Firebase Foundation & P1 Emulator Demo Walkthrough

This document covers the **Issue #4** Firebase setup, Firestore data model, default-deny security rules, offline/permission fallbacks, and the **Issue #9** P1 Android Emulator Demo Walkthrough.

---

## 1. Safe Per-Developer Firebase Setup (No Secrets in Git)

Per [`SECURITY.md`](../SECURITY.md) and [`PRIVACY.md`](../PRIVACY.md), **no service-account keys, private tokens, or environment-specific `google-services.json` files are committed to Git**.

### Default Local & CI Mode (Zero Cloud Credentials Required)
Out of the box, [`AppShell`](../lib/app/app_shell.dart) runs with:
- [`MockAuthRepository`](../lib/features/auth/domain/auth_repository.dart) for deterministic sign-in/sign-out.
- [`RuleEnforcingInMemoryFirestoreGateway`](../lib/core/storage/firestore_gateway.dart) backing [`FirestoreProfileRepository`](../lib/features/auth/domain/profile_repository.dart) and [`FirestoreCardRepository`](../lib/features/cards/data/firestore_card_repository.dart), which enforces the exact rules defined in [`firestore.rules`](../firestore.rules).
- [`MockFcmNotificationService`](../lib/core/notifications/notification_service.dart) for opted-in FCM topic subscription and notification delivery.

This allows any developer, reviewer, or CI runner to clone the repository and run the full P1 application and test suite immediately without sharing keys.

### Optional Firebase Emulator Suite Setup
To run against the local Firebase Emulator Suite (configured in [`firebase.json`](../firebase.json)):
1. Install the Firebase CLI (`npm install -g firebase-tools`).
2. Start the Auth (port `9099`) and Firestore (port `8080`) emulators from the repository root:
   ```bash
   firebase emulators:start --only auth,firestore
   ```
3. The Emulator Suite automatically loads [`firestore.rules`](../firestore.rules).

---

## 2. Firestore Data Model & Security Rules (`firestore.rules`)

All Firestore paths are **default-deny**. Only two user-scoped paths are permitted, and both require `request.auth != null && request.auth.uid == userId`:

| Path | Purpose | Enforced Schema Invariants |
| --- | --- | --- |
| `/users/{userId}` | [`UserProfile`](../lib/features/auth/domain/profile_repository.dart) | `id == userId`, `isAnonymous is bool`, `notificationsEnabled is bool`, `cellCaptureCounts is map` (coarse `~1.1 km` grid counts only; no raw GPS coordinates). |
| `/users/{userId}/cards/{cardId}` | [`GameCard`](../lib/features/cards/domain/game_card.dart) | `id == cardId`, `ownerId == userId`, `type in ['attack','defense','stun','reflect']`, `rarity in ['common','uncommon','rare','epic']`, `stats.strength` integer in `1..10`, `generationVersion is string`; **cards are immutable once minted (`allow update: if false`)** to prevent post-mint rarity or strength escalation. |

### Negative Security Tests
Automated unit tests in [`profile_repository_test.dart`](../test/features/auth/domain/profile_repository_test.dart) and [`firestore_card_repository_test.dart`](../test/features/cards/data/firestore_card_repository_test.dart) verify:
- Unauthenticated reads/writes are rejected (`unauthenticated`).
- Cross-user reads, writes, and deletes (`user_bob` accessing `users/user_alice/...`) are rejected (`permission-denied`).
- Out-of-range card tampering (`stats.strength: 999`) is rejected (`permission-denied`).
- Unlisted root collections are blocked by the default-deny rule.

---

## 3. Offline, Error, and Permission-Denied States

| Boundary | Behavior & Verification |
| --- | --- |
| **Camera Permission Denied** | [`ExplorePage`](../lib/features/exploration/presentation/explore_page.dart) displays an explanation screen (`Camera Access Required`) and a `Grant Camera Permission` action instead of crashing. |
| **Location Denied / Opted Out** | [`RarityPolicy.determineRarity`](../lib/features/exploration/domain/rarity_policy.dart) falls back deterministically to color-feature baseline rarity when `LocationPermission` is `denied` or `optedOut`. |
| **Firestore Offline / Error** | [`CollectionPage`](../lib/features/collection/presentation/collection_page.dart) displays an error state with a `Try Again` action; repositories throw typed `CardRepositoryException` / `ProfileRepositoryException`. |
| **FCM Notification Denial** | [`MockFcmNotificationService`](../lib/core/notifications/notification_service.dart) blocks topic subscriptions when permission is denied, and [`AppShell`](../lib/app/app_shell.dart) notifies the user via SnackBar without crashing. |
| **Enemy AI Timeout / Invalid Move** | [`SafeFallbackEnemyPolicy`](../lib/features/battle/domain/enemy_policy.dart) enforces a `1500 ms` timeout and [`validateEnemyAction`](../lib/features/battle/domain/enemy_policy.dart), falling back to [`HeuristicEnemyPolicy`](../lib/features/battle/domain/enemy_policy.dart). |

---

## 4. P1 Android Emulator Demo Walkthrough (13 November 2026)

### Prerequisites
```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

### Running on the Android Emulator
1. Start an Android emulator (e.g., `Photalchemy_API_35`) and launch the app:
   ```bash
   flutter run
   ```
2. **Explore & Transmute (`Explore` tab)**:
   - Observe the `Color-v0 mode` capture frame.
   - Tap **Capture & Transmute** to sample color features and synthesize a new [`GameCard`](../lib/features/cards/domain/game_card.dart) with bounded strength (`1–10`).
3. **Inspect Inventory (`Cards` tab)**:
   - Tap the **Cards** navigation tab.
   - Verify the starter card (`starter-ember`) and newly transmuted cards (`card-2`, etc.) appear in the collection grid with their archetype color, rarity badge, and `STR` rating.
4. **Play Turn-Based Dungeon Combat (`Battle` tab)**:
   - Tap the **Battle** navigation tab.
   - Observe **Enemy Alchemist** (`HP: 10 / 10`) vs **Player** (`HP: 10 / 10`).
   - Tap an action chip (`slash (4)`, `guard (3)`, or `stun-blast (2)`) to resolve a simultaneous combat turn against [`HeuristicEnemyPolicy`](../lib/features/battle/domain/enemy_policy.dart) using [`BattleEngine`](../lib/features/battle/domain/battle_engine.dart).
5. **Sign In & Test FCM Notification Opt-In (`Account` tab)**:
   - Tap the **Account** navigation tab and tap **Sign in with Google**.
   - Verify the account transitions from `Guest Alchemist` to `Alchemist Account` (`alchemist@photalchemy.io`) and creates the user profile in [`FirestoreProfileRepository`](../lib/features/auth/domain/profile_repository.dart).
   - Toggle **Dungeon Alerts (FCM)** on, then tap **Send Demo FCM Alert** to verify the in-app FCM notification banner.
