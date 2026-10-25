# Instructions for AI coding assistants — Photalchemy

This file describes the repository's working rules. It is **not permission to use AI where COMP205 prohibits it**. The syllabus has Red, Yellow and Green zones; follow the currently applicable course restrictions, especially for graded lab sessions and individual assessments.

## Context

Photalchemy is a planned Flutter/Dart mobile game: real-world photo capture → photo-based card generation → location-aware rarity → card inventory → turn-based dungeon battles. The COMP205 project requires Firebase Auth/Firestore/FCM, tests and CI, a trained model (Track A), and a GenAI feature (Track B). Features may still be unimplemented; do not imply otherwise.

## Before making changes

1. Read `README.md`, `CONTRIBUTING.md`, `TEAM.md`, and `docs/ARCHITECTURE.md`.
2. Work only on a task branch with a linked issue; **never push/commit directly to `main`** or merge without human review.
3. Identify the module owner and keep the change within the requested scope.
4. For architecture or API changes, write the contract and request teammate agreement.
5. If necessary context or requirements are missing, document assumptions explicitly; do not invent credentials, datasets, team agreements or claimed test results.

## Implementation conventions

- Use **feature-first Flutter organization**; small features may start flat and split into `data/`, `domain/` and `presentation/` only as needed.
- Keep UI free of raw Firebase queries and model-training code. Wrap cloud, location, camera and inference services behind testable interfaces.
- Battle rules/state transitions should be deterministic and testable; the LLM may **propose actions** but the game engine validates legal moves and computes results.
- The trained photo model must have reproducible training/evaluation. Do not claim simple hand-authored color rules satisfy Track A.
- Track B needs an evaluation dataset of at least 20 cases and logged expected-versus-actual behavior.
- Do not store raw precise location or upload photos without a defined need, user consent, and retention policy.
- Never commit API keys, service accounts, tokens, personal photos, private recordings or large raw datasets.

## Tests and evidence

Once Flutter exists: use `dart format .`, `flutter analyze` and `flutter test` as appropriate. Add focused unit/widget tests for changed behavior. Never state tests passed unless run. CI configuration is `.github/workflows/ci.yml`.

When AI coding is permitted and used, save genuine AI Decision Records in `docs/adr/` for milestone evidence: prompt/context (sanitized), accepted diff/commit, verification, at least one rejected suggestion with reason. **The person submitting the code remains responsible for every line.**

## Git and PR boundaries

- Branches: `feat/<issue>-<topic>`, `fix/<issue>-<topic>`, `docs/<topic>`, `chore/<topic>`.
- Commits: conventional subjects (e.g. `feat: implement battle state`).
- PR needs a teammate review and passing CI. No force-push to shared branches, no rewriting `main`, no unreviewed self-merges.
- Avoid wide refactors or generated-file churn without explicit task scope.
