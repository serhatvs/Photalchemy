# ADR: Immutable Firestore Battle History Subcollection and Event-Driven Opt-In FCM Alerts
- Milestone: P2
- Date: 2026-11-27
- Author: Şükrü Can Öztürk (@sukrucanozturk98)
- Related issue / PR / commit: Issue #24 / PR #23

## Goal and prompt
Design user progression persistence for dungeon encounters and connect opted-in FCM notifications to real gameplay events:
1. Persist completed dungeon encounters per authenticated user in Cloud Firestore so win/loss records survive app restarts.
2. Prevent clients from retroactively altering past defeats into victories or forging out-of-range turn/HP metrics.
3. Replace purely manual demo notification triggers with event-driven alerts tied to meaningful gameplay milestones (Epic card transmutation, sector depletion, and dungeon victory), strictly gated by user opt-in consent.

Prompt to AI:
> "We need to persist player battle outcomes in Cloud Firestore and trigger FCM notifications on real game events. Should we store mutable `wins` and `losses` integer counters directly on the `/users/{userId}` profile document, or store immutable match records in `/users/{userId}/battles/{battleId}`?"

## Accepted suggestion and resulting change
Implemented immutable battle match records under `/users/{userId}/battles/{battleId}` in `firestore.rules`, `RuleEnforcingInMemoryFirestoreGateway`, and `FirestoreBattleHistoryRepository` (`lib/features/auth/domain/battle_history_repository.dart`), and wired event-driven FCM triggers in `AppController`:
- **Immutable Audit Trail (`allow update: if false`):** Each completed battle writes a validated `BattleHistoryRecord` (`outcome in ['victory','defeat','draw']`, `turnsPlayed` in `1..51`, `playerFinalHp` and `enemyFinalHp` in `0..10`). Once created, a battle record cannot be overwritten or mutated.
- **Derived Win/Loss Record:** `AppController` loads `/users/{userId}/battles` on sign-in and computes `victoriesCount`, `defeatsCount`, and total matches displayed in `AccountPage`.
- **Consent-Gated Gameplay FCM Alerts:** When `_notificationsEnabled` is `true`, `AppController` automatically dispatches opted-in notifications on:
  1. Synthesizing an `epic` card (`Epic Card Transmuted!`).
  2. Reaching the anti-farming threshold in the current ~1.1 km cell (`Sector Resonance Depleted`).
  3. Winning a dungeon encounter (`Dungeon Victory Recorded!`).

## Rejected AI suggestion
The AI initially suggested adding mutable `winCount` and `lossCount` integer fields directly to `/users/{userId}` and allowing any client `update` on `/users/{userId}` to set arbitrary integer values, plus sending promotional re-engagement push notifications every 15 minutes via a background timer even before the user opted into notifications.

**Why rejected:**
1. **Trivial Stat Tampering:** Because `/users/{userId}` must allow `update` for `notificationsEnabled` and `cellCaptureCounts`, storing raw mutable `winCount` integers on the profile document allows a client to set `winCount: 9999` in a single profile update without playing any matches. An append-only `/users/{userId}/battles/{battleId}` subcollection with `allow update: if false` and bounded turn/HP invariants enforces one validated document per completed match.
2. **Privacy & Consent Violation:** Firing unsolicited timer notifications without explicit opt-in violates `PRIVACY.md` and mobile OS notification guidelines.

## Verification
- Verified via `test/features/auth/domain/battle_history_repository_test.dart`:
  - Authenticated owner can record and query `/users/{userId}/battles/{battleId}`.
  - Unauthenticated and cross-user (`user_bob` accessing `user_alice`) reads/writes are rejected.
  - Mutating an existing battle document (`battle-1`) or writing out-of-range `turnsPlayed: 999` is rejected by `firestore.rules`.
