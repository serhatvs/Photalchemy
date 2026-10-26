# Photo-to-card and enemy-policy contracts — Issue #5

**Status:** P1 prototype. The user-defined AI goal is to **play cards strategically against the player and try to win**. The trained model is NOT a photo-scene classifier.

## Two separate flows

```text
Real-world photo --(Ali: decode/perms)--> color features (brightness,
  saturation, contrast) --(Serhat: deterministic mapping)--> GameCard
  --(Şükrü: trusted validation/storage)--> Player inventory

Battle state + enemy hand + public player information
  --(Kadir: deterministic game engine lists legal actions)-->
  EnemyObservation + legalActions
        |--> Serhat: own-trained action scorer (Track A)
        |--> Kadir: tool-calling LLM opponent (Track B)
  --proposed action ID--> validateEnemyAction --> battle engine applies rules
```

## Card contract (provisional)

- `GameCard`: id, ownerId, `CardType` (attack/defense/stun/reflect), `CardRarity`, `CardStats.strength` (1–10) and `generationVersion=color-v0`.
- `PhotoFeatures`: normalized brightness/saturation/contrast in [0,1].
- `PhotoAnalyzer`: interface that converts camera bytes into `PhotoFeatures`; actual photo decode/permission adapter is not implemented.
- `CardGenerator`: deterministic provisional priority: contrast ≥0.60 → reflect; otherwise brightness ≥0.65 → attack; otherwise saturation ≥0.65 → stun; otherwise defense. Strength is bounded, with a rarity modifier. **These thresholds are design placeholders to approve with the team, not trained ML.**
- `LegalEnemyAction`: action ID, card type, strength, human-readable effect. `EnemyObservation`: enemy/player HP, visible shields, allowed actions; no hidden player hand.
- `EnemyPolicy.chooseAction`: model chooses an action ID. `validateEnemyAction` rejects any hallucinated/illegal ID, and only Kadir's deterministic engine may change game state.

## Division of work

- **Serhat:** cards/colors/domain validation, own-trained battle-policy Track A and evaluation.
- **Kadir:** deterministic battle engine, card effect semantics, legal move generation, Track B LLM agent and ≥20 scenarios.
- **Ali:** capture/permission UI, photo decoding, collection and combat UI.
- **Şükrü:** authenticated card persistence and safe location-based rarity. A mobile client must not be trusted to grant itself rarity, cards or ownership.

## Cross-module decisions before merge

1. Confirm how defense/stun/reflect affect turns, shields and damage, and how strength scales each effect.
2. Confirm the visible state and fairness rules for the AI: which enemy/player cards can be seen, turn timing and legal options.
3. Confirm color thresholds and whether rarity changes type or magnitude, without requiring learned photo classification.
4. Confirm training data strategy: generated self-play/simulated battles on the *real* rules, preventing leakage by whole matches and seeds.
5. Decide runtime for trained policy and for LLM tools; provide deterministic fallback for unavailable model/API.

## Current limitations

These files implement color statistics, card metadata and **AI observation/tool boundary contracts only**. They do not implement image decoding, a battle engine, opponent strategy, trained weights or an integrated playable turn. Unit tests validate boundaries; no win rate can be claimed.
