# AI Decision Records (ADRs)

The COMP205 syllabus requires **three genuine ADRs with each of P1, P2 and P3**. Each should be **no more than one page** and contain: the AI prompt, the resulting change/diff, and at least one suggestion that was rejected with an explanation. Do not fabricate an AI interaction to fill a quota.

## Milestone P1 Records (Foundational Architecture & AI Policy)
1. [P1-01: Deterministic Color Feature Extraction Pipeline](P1-01-deterministic-color-pipeline.md) — Rejected pre-trained CV photo-scene classifier in favor of privacy-preserving offline statistical extraction.
2. [P1-02: Deterministic Pure-State Battle Engine](P1-02-deterministic-battle-engine.md) — Rejected asynchronous sequential initiative mutation in favor of simultaneous turn resolution and infinite reflection loop prevention.
3. [P1-03: SafeFallbackPolicy Wrapper and Runtime Action Whitelisting](P1-03-safe-fallback-policy.md) — Rejected direct engine mutation tool-calling in favor of decoupled observations, whitelisted action validation, and automated timeout fallbacks.

## Milestone P2 Records
*(Planned for P2 implementation)*

## Milestone P3 Records
*(Planned for P3 implementation)*

## Template

```markdown
# ADR: <short title>
- Milestone: P1 / P2 / P3
- Date:
- Author:
- Related issue / PR / commit:

## Goal and prompt
<Sanitized prompt, relevant constraints and context>

## Accepted suggestion and resulting change
<What changed? Link to diff/commit and explain why it works>

## Rejected AI suggestion
<What was suggested, why it was rejected, and what was done instead>

## Verification
<Tests run, manual checks, results and limitations>
```
