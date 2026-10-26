# Photalchemy Team Agreement

**Course:** COMP205 Mobile Programming — Fall 2026  
**Team:** Serhat Yavuz, Ali Çavdar, Şükrü Öztürk, Kadir Zongur  
**Status:** Proposed working agreement — each member should review and confirm the unfilled coordination details below.

## Roles and ownership

| Member | GitHub | Primary responsibilities | Main collaboration |
| --- | --- | --- | --- |
| Serhat Yavuz | [@serhatvs](https://github.com/serhatvs) | Own-trained competitive battle policy (Track A), color-to-card generator, architecture, model evaluation and quality coordination | Ali (photo capture/color adapter), Kadir (battle engine/legal moves) |
| Ali Çavdar | [@cavdara549-create](https://github.com/cavdara549-create) | Flutter UI/UX, navigation, camera, inventory and battle screens, widget tests | Serhat (inference), Kadir (battle state) |
| Şükrü Öztürk | [@sukrucanozturk98](https://github.com/sukrucanozturk98) | Firebase Auth, Firestore, security rules, FCM, player persistence and location rarity | Ali (UI data), Serhat (rarity rules) |
| Kadir Zongur | [@kadirzongur64-byte](https://github.com/kadirzongur64-byte) | Turn-based combat, cards/effects integration, dungeon systems, GenAI enemy agent (Track B), 20+ evaluation scenarios | Ali (battle UI), Serhat (card/domain boundaries) |

**Every team member writes code, contributes tests/reviews, and can explain the complete application at oral defense.** Assignments can change by team agreement and should be reflected in this file and the issue board.

## Communication and cadence

- **Main communication channel:** To be agreed by all four members.
- **Weekly meeting time outside COMP205 project hour:** To be agreed by all four members.
- **Expected response time to important messages:** Agree on a realistic window; state absences as early as possible.
- Use **GitHub Issues** for tasks and technical decisions, **PR discussions** for code review, and `docs/` for lasting architecture/evaluation decisions. Avoid relying on chat-only requirements.
- Report progress and blockers at least once per week. Prepare something reviewable for each course milestone.

## Decisions, disagreements and absent contributors

- Prefer evidence and small prototypes over opinions. For interface changes, involve affected module owners.
- Try to reach consensus. If no consensus is possible, write down the options/tradeoffs in an issue, choose a reversible small experiment, and revisit together.
- If someone cannot finish an issue, they should flag it early so it can be split/reassigned without blame.
- If a member repeatedly stops participating, first contact them privately, then discuss responsibilities openly with the team, record agreed reassignments, and raise unresolved participation problems with course staff before the deadline.

## Required engineering workflow

We follow [CONTRIBUTING.md](CONTRIBUTING.md): one issue → feature branch → PR → CI → **independent review** → squash merge. **Nobody pushes directly to `main`, including the repository owner.** Branch rules must enforce this on GitHub.

## Course responsibilities

- **Both AI tracks in depth** for our four-member team: Track A trained model with evaluation/model card, Track B RAG or tool-calling agent with at least 20 evaluation queries.
- P1 (13 Nov): skeleton, backend and CI. P2 (25 Dec): AI progress. P3 freeze (3 Jan, 23:59): final code and documentation. Dates are subject to official course updates.
- Three AI Decision Records for each P1–P3 milestone; prepare them based on actual work, not fabricated examples.
- Respect course AI-use zones. Never submit work that its author cannot explain; never share secret or personal data with AI tools.

## Agreements to finalize together

- [ ] Confirm this division of responsibility.
- [ ] Confirm communication channel and expected response window.
- [ ] Choose weekly meeting time.
- [ ] Ensure all four members have repository access.
- [ ] Confirm any course-staff access requirements and agree on project visibility/privacy.
