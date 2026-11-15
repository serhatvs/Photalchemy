# Photalchemy Team Agreement

**Course:** COMP 205 Mobile Programming — Fall 2026  
**Team Name:** Lunerya (Team No: **T13**)  
**Project Title:** Photalchemy  
**Status:** Draft working agreement — **@sukrucanozturk98** confirmed in Issue #7; remaining coordination items below await explicit sign-off from all four members.

## Members and Roles

| Name | GitHub | Role(s) | Primary responsibilities | Main collaboration |
| --- | --- | --- | --- | --- |
| Serhat Yavuz | [@serhatvs](https://github.com/serhatvs) | AI Lead & Architecture / Quality Lead | Own-trained competitive battle policy (Track A), color-to-card generator, architecture, model evaluation and quality coordination | Ali (photo capture/color adapter), Kadir (battle engine/legal moves) |
| Ali Çavdar | [@cavdara549-create](https://github.com/cavdara549-create) | UI Lead | Flutter UI/UX, navigation, camera, inventory and battle screens, widget tests | Serhat (inference), Kadir (battle state) |
| Şükrü Öztürk | [@sukrucanozturk98](https://github.com/sukrucanozturk98) | Back-end Lead | Firebase Auth, Firestore, security rules, FCM, player persistence and location rarity | Ali (UI data), Serhat (rarity rules) |
| Kadir Zongur | [@kadirzongur64-byte](https://github.com/kadirzongur64-byte) | Gameplay & GenAI Lead | Turn-based combat, cards/effects integration, dungeon systems, GenAI enemy agent (Track B), 20+ evaluation scenarios | Ali (battle UI), Serhat (card/domain boundaries) |

**Every team member writes code, contributes tests/reviews, and can explain the complete application at oral defense.** Assignments can change by team agreement and should be reflected in this file and the issue board.

## Communication
- **Channel we use:** GitHub Issues/PRs for technical decisions and review; team messaging group for quick coordination (primary channel & SLA to be confirmed by all four members in Issue #7).
- **We reply to each other within:** To be confirmed by all four members (target: within 24 hours on weekdays; state absences early).

## Meetings
- **Fixed weekly meeting:** Weekly COMP 205 Friday project hour + additional weekly sync time (day/time/place to be finalized by all four members in Issue #7).
- **Who writes the short meeting notes:** Rotating / posted in GitHub Issue #7 or `docs/`.

## Working rules
- **Branches and pull requests:** We follow [CONTRIBUTING.md](CONTRIBUTING.md): one issue → feature branch → PR → CI green → **independent teammate review** → squash merge. **Nobody pushes directly to `main`, including the repository owner.** Enforced via GitHub ruleset `Photalchemy - Protect main`.
- **Definition of done:** code + tests + CI green (`verify`) + reviewed + security/privacy checked.
- **We commit small, with clear messages** (conventional subjects such as `feat:`, `fix:`, `test:`, `docs:`).

## Decisions
- Prefer evidence and small prototypes over opinions. For interface changes, involve affected module owners.
- Try to reach consensus; if no consensus is possible, document tradeoffs in a GitHub Issue, run a reversible prototype, and decide by majority vote (with the relevant module lead guiding their subsystem).

## If someone stops contributing
1. We talk to them privately within one week.
2. If nothing changes, we record agreed task reassignments and inform the instructor in the project hour before the milestone deadline.
*(Remember: in the individual oral defense every member explains their own commits.)*

## Course responsibilities
- **Both AI tracks in depth** for our four-member team (Team size = 4): Track A own-trained battle policy with grouped validation, confidence intervals, and model card; Track B tool-calling enemy agent with at least 20 evaluation scenarios, prompt-injection test, and offline fallback.
- **Milestones:** P0 Proposal (25 Oct), P1 Skeleton (13 Nov), P2 AI Progress (25 Dec), P3 Code Freeze (3 Jan, 23:59), Final Demo & Oral Defense (4 & 6 Jan).
- **ADRs & Sub-agent feature:** Three genuine AI Decision Records per milestone P1–P3; `AGENTS.md` + sub-agent workflow transcript by P3.
- Respect course AI-use zones; never submit code you cannot explain or share secrets/personal data with AI tools.

## Agreements to finalize together (Issue #7)
- [ ] Confirm this division of responsibility (Confirmed: Şükrü; pending: Serhat, Ali, Kadir).
- [x] Use GitHub Issues/PRs + team chat for coordination (confirm exact chat SLA).
- [ ] Choose fixed weekly meeting time outside COMP 205 project hour.
- [x] Ensure all four members have repository write access and commit history.
- [ ] Confirm course-staff visibility/access requirements and finalize signatures below.

## Signatures (type your name and date)
- Şükrü Öztürk — Confirmed role/responsibilities in Issue #7 (2026-11-11)
- Serhat Yavuz — Pending final signature
- Ali Çavdar — Pending final signature
- Kadir Zongur — Pending final signature
