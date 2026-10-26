# Contributing to Photalchemy

This is a **four-person COMP205 project**. Keep the process light, reviewable and fair. See [TEAM.md](TEAM.md) for primary owners, [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for module boundaries, [SECURITY.md](SECURITY.md) and [PRIVACY.md](PRIVACY.md) for safety, [QUALITY.md](QUALITY.md) and [TESTING.md](TESTING.md) for quality gates, and [AGENTS.md](AGENTS.md) for AI-assistant rules.

## Non-negotiable rules

1. **Never commit, push or force-push directly to `main`.** Work on a short-lived branch and merge through a pull request (PR).
2. **Link work to an issue** (except tiny documentation fixes). Keep one clear outcome per PR.
3. **At least one teammate other than the author must approve** before merging. Request review from the relevant module owner/supporter.
4. **CI must pass**, all review comments must be resolved, and the author must test their changes.
5. **Do not self-merge an unreviewed PR**, rewrite shared branch history without agreement, or push secrets and personal user data.
6. **Squash-merge** accepted PRs, then delete their branches. Keep `main` always demoable.
7. Each member is responsible for understanding, explaining, and testing every accepted change in their own area. Document AI-assisted work as required by the syllabus.

> GitHub must enforce these by a branch ruleset. A text file alone cannot stop a push; see **Repository admin setup** below.

## Branches and commits

Start from the current `main`:

```bash
git switch main
git pull --ff-only origin main
git switch -c feat/42-card-inventory
# edit and test
git add -A
git commit -m "feat: add card inventory view"
git push -u origin feat/42-card-inventory
```

Branch prefixes: `feat/` (feature), `fix/` (bug), `test/` (tests), `docs/` (documentation), `chore/` (tooling), `experiment/` (disposable exploration). Include issue number when available: `feat/42-card-inventory`. Never develop on `main`.

Commit subjects: `feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`. Prefer small commits with meaningful messages. **Never force-push a branch someone else is working on without asking.**

## Issue → PR → review → merge

1. Open/claim a GitHub issue describing **why**, **scope**, **acceptance criteria**, **owner**, and **P1/P2/P3 milestone**.
2. Work in your area. For cross-module changes, agree on the data/API contract with the other owner before coding.
3. Open a **draft PR early** if feedback is needed. Before requesting review, link the issue (e.g. `Closes #42`) and complete the PR template.
4. Run relevant commands locally once Flutter has been initialized:
   - `flutter pub get`
   - `dart format .` (format only intended Dart files)
   - `flutter analyze`
   - `flutter test`
5. Ask for review from **at least one teammate**; ask a cross-module reviewer when touching integration boundaries. The reviewer must actually inspect the diff and relevant behavior.
6. Resolve feedback, wait for CI, and **squash-merge** only after approval and checks. Delete the branch.
7. If the PR becomes very large (rough guideline: over ~400 handwritten lines), split it into smaller logical PRs where feasible.

Do not use `git push --force` to bypass review. Fix conflicts on your branch, not by pushing to `main`.

## Module ownership

- **Serhat:** ML/photo analysis, card generation domain, architecture and quality coordination.
- **Ali:** Flutter UI, navigation, camera and collection views.
- **Şükrü:** Firebase/Auth/Firestore/FCM, location/rarity persistence.
- **Kadir:** battle engine, dungeon gameplay, tool-calling enemy agent and evaluation.

Ownership is **responsibility, not exclusivity**. Any teammate may contribute with the owner's collaboration and review. For detailed paired reviews, see `.github/CODEOWNERS` and `TEAM.md`.

For every PR, consult [QUALITY.md](QUALITY.md) for the definition of done and [SECURITY.md](SECURITY.md) for risk checks; include the test evidence described in [TESTING.md](TESTING.md).

## Definition of done

A task is done when its acceptance criteria are met; the code builds, is formatted and tested; security/privacy impact is considered; tests and docs are updated where relevant; the reviewed PR is merged; and another teammate can explain the interface it introduces.

For AI components: include reproducible evaluation, baseline/failure cases and data provenance as appropriate. For Firebase: ensure per-user access rules and no leaked credentials. For location/photos: collect only what the feature needs, with explicit permission where relevant.

## Repository admin setup (required to truly protect `main`)

In GitHub go to **Settings → Rules → Rulesets → New branch ruleset** (or **Settings → Branches** if that is the available interface). Target branch: `main`. Enable:

- Require a pull request before merging.
- Require **at least 1 approval**, and prevent dismissing the need for reviews by pushing new changes (dismiss stale approvals, if supported).
- Require review from CODEOWNERS, **once all listed members have accepted repository access**.
- Require conversation resolution before merging.
- Require the CI status check named **`verify`** (after it appears in Actions).
- Block force pushes and branch deletion; avoid bypass permissions for routine work.
- Apply protections to administrators too, if available.

These settings cannot be enforced by documentation or CODEOWNERS alone. Configure them in GitHub settings and verify by attempting a test push/PR (without risking actual code).
