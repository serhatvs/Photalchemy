# ADR: SafeFallbackPolicy Wrapper and Runtime Action Whitelisting for Track A & B
- Milestone: P1
- Date: 2026-11-04
- Author: Serhat
- Related issue / PR / commit: PR #11 (commits `1fe06a3`, `04673ab`)

## Goal and prompt
Design the opponent policy contract and execution boundary for Track A (supervised/RL policy) and Track B (LLM tool-calling agent) that:
1. Prevents untrusted AI outputs, prompt injections, or malformed JSON from altering game rules or game state.
2. Prevents application freezing or deadlocks when external LLM APIs experience high latency or timeouts.
3. Automatically falls back to a competitive deterministic baseline if the primary policy fails.

Prompt to AI:
> "We need an architecture for the opponent policy that accommodates both an offline trained model (Track A) and an LLM tool-calling agent (Track B). The game engine must be authoritative. Untrusted model decisions must be validated against legal moves, timed out if slow, and cleanly intercepted without crashing."

## Accepted suggestion and resulting change
Created the `EnemyPolicy` contract and `SafeFallbackEnemyPolicy` in `lib/features/battle/domain/enemy_policy.dart`:
- `EnemyObservation` only exposes public combatant information (HP, shield, stun state, legal actions). No hidden decks, credentials, or private photos.
- `validateEnemyAction` enforces strict action ID whitelisting before any move is submitted to the engine.
- `SafeFallbackEnemyPolicy` wraps any primary policy with:
  1. A configurable timeout (default 1500 ms).
  2. Exception and malformed proposal handling.
  3. Automatic fallback to `HeuristicEnemyPolicy`.
  4. Observability via `fallbackActivations` counter for evaluation auditing.

## Rejected AI suggestion
The AI suggested giving the LLM tool-calling agent direct executable tool definitions that manipulate engine state (e.g., `tool_call: reduce_player_hp(amount)` or `tool_call: grant_enemy_shield(amount)`).

**Why rejected:**
1. **Security & Prompt Injection Risk:** If the opponent is an LLM with direct state manipulation tools, an adversarial prompt inside a card description or user name could instruct the model to call `reduce_player_hp(999)`, completely bypassing combat logic.
2. **Asymmetry:** Track A (tabular/neural network model) produces action classifications, not arbitrary function calls. Having Track B manipulate game state directly breaks the unified interface between Track A and Track B.
3. **Engine Authority Violation:** The game engine must remain the single source of truth for all game mechanics.

## Verification
- Verified via `test/features/battle/domain/battle_scenario_test.dart` and `test/features/battle/domain/enemy_policy_test.dart`:
  - 20 Track B evaluation scenarios benchmarked with `EvaluationRunner`.
  - Intentionally hanging policy triggered the 10ms timeout fallback.
  - Hallucinated card ID was rejected by `validateEnemyAction` and triggered fallback with zero crashes.
