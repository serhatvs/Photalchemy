# Photalchemy — Proposed Architecture

> **Status:** Architecture proposal for COMP205; no Flutter app or AI model is implemented in the repository yet. Confirm interfaces and privacy choices as a team before implementing.

## Modules and ownership

```text
lib/
  main.dart                     Flutter entrypoint (created during Flutter setup)
  app/                          App bootstrap, routes, theme, providers
  core/                         Shared clients, errors, permissions, utilities
  features/
    auth/                       Firebase sign-in, account state          [Şükrü]
    exploration/                Location permission and rarity           [Şükrü]
    camera/                     Camera/capture UX                         [Ali]
    cards/                      Photo features → card attributes         [Serhat]
    collection/                 Inventory UI and filtering               [Ali]
    battle/                     Turn-based engine, dungeon, AI adapter   [Kadir]
ml/                             Training notebooks/scripts/model card   [Serhat]
evaluation/                     Track B test cases + scoring             [Kadir]
assets/                         Licensed game art and static assets
test/                           Unit and widget tests
integration_test/               User journey tests
docs/adr/                       AI Decision Records for P1-P3
```

**Keep feature internals private:** a feature can use `data/`, `domain/` and `presentation/` subfolders as it grows. Do not create layers until they reduce complexity. The structure follows Flutter's normal root-level `pubspec.yaml` / `android/` layout once `flutter create` has been used.

## Planned data flow

1. **Sign in:** Flutter UI → Auth repository → Firebase Auth. Per-user data is accessed through authenticated repositories, not from UI widgets.
2. **Capture:** camera requests runtime permission, captures a photo and passes an in-memory/local reference to the photo analysis module.
3. **Transmute:** color/features + **trained** Track A model (exact targets to be confirmed) produce candidate card attributes. A deterministic validator assigns legal effects/values.
4. **Location rarity:** optional user permission → coarse/deduplicated location signal → rule evaluation; any remote persistence must minimize sensitive geodata. A non-location fallback is needed for emulator/privacy testing.
5. **Collection:** validated card metadata is stored/retrieved per authenticated user in Firestore, with rules preventing access to other accounts.
6. **Battle:** deterministic engine manages HP, turns, available actions and effects. Track B agent can request a **bounded list of legal tools/actions**; the engine validates the request and owns state mutation. Handle AI timeouts with a deterministic fallback.
7. **Notification:** FCM used for relevant opted-in game notifications (specific events to be defined).

## Contracts to agree before integration

- `Card`: id, ownerId, class (`attack/defense/stun/reflect`), stats, rarity, and a source-photo *reference if needed*; never rely on a raw image in the domain object.
- `PhotoAnalyzer`: local image input → feature vector / model output; report model version and confidence when available.
- `RarityPolicy`: coarse exploration signal + history summary → bounded rarity modifier, with no-location fallback.
- `BattleEngine`: current state + validated player/enemy action → next state and event log (pure where possible).
- `EnemyAgent`: sanitized battle state + allowed actions → proposed action. Always validate against engine rules.
- `CardRepository` / `ProfileRepository`: user-scoped persistence APIs; handle auth expiry and offline failures.

These are **interface directions**, not final schemas. Keep versioning and migrations in mind when Firestore persistence begins.

## Scope and quality constraints

- **MVP first:** login → take or select a photo → receive a card → view collection → one dungeon encounter.
- **Track A:** consented/legal training data, reproducible preprocessing, train/test separation grouped by relevant source, baseline, performance metrics, confidence intervals, model card.
- **Track B:** 20+ predefined scenarios/queries with expected tool usage, legal-action checks, correctness and failure handling.
- **Privacy:** camera, precise location and cloud uploads require purpose/permission review; prefer local inference and coarse location representations.
- **Tests:** domain tests for card/stat validation and battle turns, widget tests for essential screens, integration test for the MVP path, CI on pull requests.
- **Course:** signed APK, GitHub Actions, `TEAM.md`, `AGENTS.md`, AI Decision Records and understandable individual commits.

## Decisions still open

- Model target labels and training data source.
- Whether inference runs on device (e.g. LiteRT) or through a secured backend.
- Exact rarity formula and privacy policy for repeat locations.
- Agent provider, costs, tool schema and deterministic offline fallback.
- Final Firestore schema, photo storage policy and notification events.

Record agreed decisions in GitHub Issues or separate design documents instead of guessing.
