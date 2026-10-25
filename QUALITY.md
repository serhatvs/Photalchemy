# Engineering Quality Standards — Photalchemy

> **Status:** Proposed team standards. Requirements become measurable once the first Flutter application and test suite exist; do not report unimplemented checks as passed.

**Quality coordination:** Serhat, with Ali (UI), Şükrü (backend/security) and Kadir (gameplay/agent) owning quality in their respective modules. Everyone is accountable for their code.

## Merge gates

A PR is mergeable only when:

1. It relates to a clear issue or states why an issue is unnecessary; the description identifies expected behavior and scope.
2. A **different teammate** reviews and approves it; affected module owners are consulted for shared contracts.
3. CI passes. No direct commits/force pushes to `main`.
4. Dart/Flutter code is formatted, analyzed without newly introduced issues, and tested for the changed behavior.
5. All review conversations are resolved, documentation is updated, and security/privacy impact is checked.
6. The author can explain the implementation without delegating responsibility to an AI tool.

**Do not game metrics:** a large quantity of shallow tests is less valuable than representative edge-case coverage. Track coverage trends after tests exist; aim to cover critical pure business rules thoroughly. Agree on an enforceable threshold only once an initial baseline has been measured.

## Design and maintainability

- Prefer **feature-first** Flutter modules (`lib/features/...`) over a single giant file or unnecessary enterprise layering.
- Keep UI widgets focused on presentation; isolate Firebase, permissions, network calls, camera, image inference and persistence behind interfaces.
- Enforce consistent domain models, explicit null/error handling and typed input/output; avoid global mutable game state.
- Keep **battle resolution deterministic**; agents suggest actions, but validated game rules resolve them.
- Add new libraries only after documenting need and checking maintenance, license, transitive dependencies and mobile compatibility.
- Avoid unrelated formatting/refactor churn in feature PRs. Reviewability matters to the four-person team.
- Design error, empty, loading, offline and permission-denied states rather than implementing only the happy path.
- Track decisions affecting more than one module in a GitHub Issue or `docs/ARCHITECTURE.md`.

## Validation targets

| Area | Minimum evidence |
| --- | --- |
| Core gameplay | Unit tests for damage/defense/stun/reflect, turn order, illegal moves and reproducibility |
| Photo-to-card | Repeatable feature extraction and legal card output for representative and malformed images |
| Firebase | Authentication/session behavior, deny-by-default rules, negative cross-user access tests |
| Flutter UX | Widget tests for major screens and required loading/denied/empty states |
| Location | Opt-out, permission denial, coarse handling and repeated-location rarity boundaries |
| Track A | Provenance; grouped train/test splits; baseline, metrics and uncertainty; model card |
| Track B | 20+ scenario/query evaluations; legal-tool validation, bad-output and timeout fallback tests |
| Delivery | Installable signed APK, a documented emulator demo path and checked release configuration |

For exact test examples and commands, see [TESTING.md](TESTING.md). For mandatory safeguards, see [SECURITY.md](SECURITY.md).

## Performance and reliability

Before final demo, benchmark representative hardware/emulator behavior for startup, photo processing, one battle turn, Firestore reads/writes and agent latency. **Do not invent performance targets or results**; document the measured device/model, data size, median/worst observed latency and known limitations. Use caching only when correctness and privacy remain intact.

Any external dependency must have a plausible offline/timeout error path. Long-running image or model work must not freeze the UI. Protect user progress from transient network failures; document what remains offline-capable.

## Definition of done

A feature is done when its acceptance criteria pass; tests and docs exist; CI is green; a reviewer approves; security/privacy implications have been considered; the PR is merged; and the relevant owner can demonstrate it on emulator or device.

## Milestone gates

- **P1 (13 Nov):** runnable skeleton (once created), Auth/Firestore/FCM baseline, CI, first tests, documented module contracts and three genuine ADRs.
- **P2 (25 Dec):** measurable progress on **both deep AI tracks**, Track A evaluation method/model card draft, Track B 20+ evaluation scenarios, integrated playable behavior and three genuine ADRs.
- **P3 (3 Jan, 23:59):** tested gameplay loop, security/privacy review, stable release APK, docs/evaluations complete and three genuine ADRs.

Milestones and scope follow course documents and may change if staff publish revisions. Do not consider a deadline met solely because its checklist is written here.

## Code review prompts

Can another teammate explain the diff? Are edge cases and failure recovery handled? Are game state and persistence protected from invalid actions? Does the change expose location/photos/secrets or inject LLM output into trusted logic? Are tests representative, and are any untested assumptions called out?
