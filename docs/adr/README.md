# AI Decision Records (ADRs)

The COMP205 syllabus requires **three genuine ADRs with each of P1, P2 and P3**. Each should be **no more than one page** and contain: the AI prompt, the resulting change/diff, and at least one suggestion that was rejected with an explanation. Do not fabricate an AI interaction to fill a quota.

Create files such as `P1-01-photo-pipeline.md`, `P2-02-agent-tools.md` and `P3-03-test-refinement.md` only for real work. Remove secrets, raw personal data and private photos from prompts.

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
