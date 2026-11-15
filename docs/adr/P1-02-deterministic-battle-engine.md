# ADR-002: Deterministic Pure-State Battle Engine and Cycle Prevention

**Date:** 2026-11-04  **Author:** Serhat Yavuz  **Milestone:** P1  
**Tool and model used:** AI coding assistant (sanitized engine design prompt; human-verified implementation in PR #11 / commit `16d8948` & PR #15)

## Context
Photalchemy's dungeon combat supports four card archetypes (`attack`, `defense`, `stun`, `reflect`) used simultaneously by the player and an AI opponent. For both fair gameplay and generating clean synthetic match trajectories for Track A training, the combat engine needed to be deterministic, pure-state, immune to negative HP or infinite reflect loops, and guaranteed to terminate.

## Prompt
```
Implement turn-based combat resolution for Photalchemy. The engine must support
attacks, shields, stuns, and reflection. Ensure infinite reflection cycles are
mathematically impossible, health values are clamped at zero, and matches
terminate cleanly within 50 turns.
```

## Result
Implemented `BattleEngine`, `BattleState`, and `BattleCombatant` in `lib/features/battle/domain/battle_engine.dart` (landed via PR #11, squash commit `16d8948`, with boundary tests expanded in PR #15):
- Resolves turns simultaneously across explicit pure phases (stun check → defense shield grant → reflect mitigation → shield-first damage absorption → HP clamp `[0, maxHp]` → stun state update).
- Prevents infinite reflection loops by computing reflection strictly once from base incoming attack damage without recursive re-reflection.
- Bounds matches at `maxAllowedTurns = 50` with an explicit HP tie-breaker returning `CombatantSide` (`player`, `enemy`, or `draw`).

## Rejected suggestion(s) — at least one
The AI initially proposed an asynchronous initiative-based turn queue where the faster combatant acts first, mutates opponent HP in place, and checks defeat before the second combatant acts.
**Rejected because:** (1) sequential initiative introduces first-mover bias on sudden-death turns, (2) in-place mutation complicates state snapshots and reactive Flutter UI rendering, and (3) initiative tie-breaking noise corrupts Track A synthetic training targets.

## Verification
- `flutter test test/features/battle/domain/battle_engine_test.dart`: verified simultaneous resolution, shield absorption, stun turn skips and expiration, mutual reflect cancellation without recursion, max-turn HP tie-break, and lethal damage HP clamping at `0`.
- `flutter test test/features/battle/domain/synthetic_match_generator_test.dart`: verified bounded match rollouts and deterministic seeds.

## What I learned
Pure, immutable state transitions with simultaneous turn phases make both UI testing and reproducible ML dataset generation dramatically simpler and bug-resistant.
