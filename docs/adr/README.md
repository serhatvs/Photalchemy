# AI Decision Records (ADRs)

The COMP205 syllabus requires **three genuine ADRs with each of P1, P2 and P3**. Each should be **no more than one page** and contain: the AI prompt, the resulting change/diff, and at least one suggestion that was rejected with an explanation. Do not fabricate an AI interaction to fill a quota.

## Milestone P1 Records (Foundational Architecture & AI Policy)
1. [P1-01: Deterministic Color Feature Extraction Pipeline](P1-01-deterministic-color-pipeline.md) — Rejected pre-trained CV photo-scene classifier in favor of privacy-preserving offline statistical extraction.
2. [P1-02: Deterministic Pure-State Battle Engine](P1-02-deterministic-battle-engine.md) — Rejected asynchronous sequential initiative mutation in favor of simultaneous turn resolution and infinite reflection loop prevention.
3. [P1-03: SafeFallbackPolicy Wrapper and Runtime Action Whitelisting](P1-03-safe-fallback-policy.md) — Rejected direct engine mutation tool-calling in favor of decoupled observations, whitelisted action validation, and automated timeout fallbacks.

## Milestone P2 Records
1. [P2-01: Privacy-Preserving LocationService Abstraction and Multi-Cell Anti-Farming Controls](P2-01-privacy-preserving-location-service.md) — Rejected continuous fine-grained GPS breadcrumb streaming in favor of on-demand ~1.1 km coarse `LocationSnapshot` reads, runtime privacy opt-out, and deterministic multi-cell travel.

## Milestone P3 Records
*(Planned for P3 implementation)*

## Template (COMP 205 `ADR_TEMPLATE.md`)

```markdown
# ADR-NNN: <short title>

**Date:**  **Author:**  **Milestone:** P1 / P2 / P3
**Tool and model used:** (e.g., OpenCode + Muse Spark 1.3)

## Context
What were you trying to do? What was the problem? (2–4 sentences)

## Prompt
```
<the prompt you gave, shortened if long>
```

## Result
What did the AI produce? Link to the commit or paste the key part of the diff.

## Rejected suggestion(s) — at least one
What did the AI suggest that you did NOT accept, and why?

## Verification
How did you check that the accepted code is correct? (tests, manual test, review)

## What I learned
One or two sentences.
```
