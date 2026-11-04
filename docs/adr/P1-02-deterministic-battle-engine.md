# ADR: Deterministic Pure-State Battle Engine and Cycle Prevention
- Milestone: P1
- Date: 2026-11-04
- Author: Serhat
- Related issue / PR / commit: PR #11 (commits `32f6db3`, `4c95fc8`)

## Goal and prompt
Design and implement the battle simulation engine for Photalchemy that:
1. Executes turn-based combat with 4 elemental mechanics: damage, shield absorption, stun, and damage reflection.
2. Resolves turns simultaneously so neither player nor AI holds an arbitrary first-mover advantage.
3. Completely prevents infinite damage reflection loops when both sides play reflect cards.
4. Generates identical, reproducible battle states for synthetic dataset training.

Prompt to AI:
> "Implement turn-based combat resolution for Photalchemy. The engine must support attacks, shields, stuns, and reflection. Ensure infinite reflection cycles are mathematically impossible, health values are clamped at zero, and matches terminate cleanly within 50 turns."

## Accepted suggestion and resulting change
Implemented `BattleEngine` in `lib/features/battle/domain/battle_engine.dart`:
- Simultaneous round evaluation: Actions are submitted simultaneously and resolved across distinct phases (Status phase -> Shield phase -> Defense mitigation phase -> Reflection calculation -> Damage application).
- Shield absorption prioritizes shield reduction before decreasing combatant HP.
- Infinite reflection prevention: Reflected damage is calculated strictly once from base incoming damage without triggering recursive re-reflection counters.
- Bounded match simulator: `simulateMatch` caps execution at `maxTurns: 50` to guarantee termination, returning an explicit `BattleResult` (`playerWon`, `enemyWon`, or `draw`).

## Rejected AI suggestion
The AI proposed an asynchronous turn queue with initiative ordering where the fastest combatant executes their action, directly mutates opponent HP, and checks for death before the second combatant acts.

**Why rejected:**
1. **First-mover Bias:** Sequential execution unfairly rewards the first mover, making sudden-death turns non-deterministic based solely on initiative tiebreaking.
2. **State Race Conditions:** Sequential in-place mutation complicates undo, replay verification, and reactive Flutter widget rendering.
3. **Dataset Noise:** Unpredictable initiative ordering introduces noisy target labels into synthetic datasets generated for Track A policy training.

## Verification
- Verified via `test/features/battle/domain/battle_engine_test.dart` and `test/features/battle/domain/synthetic_match_generator_test.dart`:
  - Verified mutual reflect cards resolve once without infinite recursion or stack overflows.
  - Verified shield absorption absorbs partial and total attack values.
  - Verified matches never exceed 50 turns and produce zero negative HP states.
