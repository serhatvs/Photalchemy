# ADR-003: SafeFallbackPolicy Wrapper and Runtime Action Whitelisting for Track A & B

**Date:** 2026-11-04  **Author:** Serhat Yavuz  **Milestone:** P1  
**Tool and model used:** AI coding assistant (sanitized security/contract prompt; human-verified implementation in PR #11 / commit `16d8948`)

## Context
Photalchemy requires both an own-trained competitive policy (Track A) and a generative tool-calling LLM opponent (Track B). Untrusted LLM outputs, prompt injections embedded in card/player metadata, or network timeouts must never freeze the UI, leak hidden player cards, or allow illegal HP/state mutations.

## Prompt
```
We need an architecture for the opponent policy that accommodates both an offline
trained model (Track A) and an LLM tool-calling agent (Track B). The game engine
must be authoritative. Untrusted model decisions must be validated against legal
moves, timed out if slow, and cleanly intercepted without crashing.
```

## Result
Implemented `EnemyObservation`, `LegalEnemyAction`, `validateEnemyAction`, and `SafeFallbackEnemyPolicy` in `lib/features/battle/domain/enemy_policy.dart`, plus 20 predefined evaluation cases in `lib/features/battle/domain/battle_scenario.dart` (landed via PR #11, commit `16d8948`, and wired into `AppController`):
- `EnemyObservation` exposes only public battle state (HP, shields, turn number, stun flags, legal action IDs) — no hidden hand, deck order, photos, or credentials.
- `validateEnemyAction` strictly whitelists proposed IDs against `observation.legalActions`.
- `SafeFallbackEnemyPolicy` enforces a configurable timeout (`1500 ms` default), catches exceptions/hallucinated IDs, increments `fallbackActivations`, and falls back deterministically to `HeuristicEnemyPolicy`.

## Rejected suggestion(s) — at least one
The AI initially suggested giving the Track B LLM direct state-mutating tool definitions such as `reduce_player_hp(amount)` or `grant_enemy_shield(amount)`.
**Rejected because:** (1) direct state-mutation tools create a critical prompt-injection vulnerability (adversarial text could trigger `reduce_player_hp(999)`), (2) Track A outputs discrete action rankings rather than arbitrary mutations, and (3) the deterministic `BattleEngine` must remain the sole authority over combat state.

## Verification
- `flutter test test/features/battle/domain/enemy_policy_test.dart`: verified hanging policies trigger the timeout fallback and hallucinated/injected action IDs are rejected safely.
- `flutter test test/features/battle/domain/battle_scenario_test.dart`: verified all 20 Track B scenarios run through `EvaluationRunner` with 100% legal-action compliance.

## What I learned
Treating AI opponents strictly as untrusted action proposers behind a deterministic validator unifies Track A and Track B while neutralizing prompt-injection and latency risks.
