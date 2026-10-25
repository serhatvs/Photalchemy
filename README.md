# Photalchemy

**Explore the real world. Turn photos into cards. Fight your way home.**

Photalchemy is a **location-based, turn-based card game for mobile** where the places you visit and the photos you take shape your deck. The game combines real-world exploration, photo-based card generation, and strategic dungeon battles.

> **Project status:** Early planning / pre-development. The mechanics described below are the current design direction, not a list of completed features.

## The Story

You are an alchemist whose experiment goes wrong, leaving you trapped inside a mysterious dungeon. Your bag is more than an ordinary bag: it connects the dungeon to the real world.

Use that connection to bring the world into your adventure. Capture photos, transform them into cards, defeat enemies, grow stronger, and find a way home.

## Core Gameplay

1. **Explore** — Visit different places in the real world.
2. **Capture** — Take photos using your phone.
3. **Transmute** — Convert each photo into a playable card based on its visual properties.
4. **Build a strategy** — Choose when to attack, defend, stun, or reflect an enemy's move.
5. **Battle** — Progress through turn-based dungeon encounters and improve your collection.

### Photo-to-Card System

The proposed card-generation system analyzes **color distribution and intensity** in an image rather than relying on full object recognition. Those visual properties help determine the resulting card's type or attributes.

Location contributes to **card rarity and power**. Repeatedly taking pictures in the same area may yield weaker cards, while exploring unfamiliar places should offer better opportunities. The exact distance thresholds and balance rules are still being designed.

### Card Classes

The initial design includes four core card classes:

| Class | Role |
| --- | --- |
| **Attack** | Deal damage to enemies. |
| **Defense** | Reduce or block incoming damage. |
| **Stun** | Disrupt an enemy's turn or action. |
| **Reflect** | Turn an opponent's attack back against them. |

Further card attributes, effects, and balancing rules are subject to prototyping.

### Dungeon Battles

Combat is designed around **turn-based card choices**, with enemies that respond to the player's strategy. **AI-assisted enemy decision-making** is being considered; the final approach has not yet been selected.

## Why Photalchemy?

Many mobile games can be played without ever changing your surroundings. Photalchemy aims to make *going somewhere new* part of the game: exploring your city becomes a meaningful way to expand your deck.

Instead of rewarding players for repeatedly photographing one spot, the design encourages discovery and variety.

## COMP205 Project Requirements

Photalchemy is being developed as a four-person term project for **COMP205 Mobile Programming** at Abdullah Gül University (Fall 2026). Its planned implementation must satisfy the course requirements in addition to its gameplay goals.

| Area | Planned implementation / required evidence |
| --- | --- |
| Mobile application | Flutter and Dart |
| Backend | Firebase Authentication, Cloud Firestore and Firebase Cloud Messaging (FCM) |
| Track A — own-trained ML/DL | Train a photo-analysis model on an appropriate labeled dataset; compare it with a baseline; report grouped cross-validation, confidence interval and a model card |
| Track B — Generative AI | Develop a tool-calling dungeon enemy agent and evaluate at least **20** predefined scenarios/queries |
| Engineering quality | Automated tests, GitHub Actions continuous integration and code reviews |
| Deliverables | Signed release APK, README, `TEAM.md`, `AGENTS.md` and AI Decision Records (ADRs) |

**Important:** The AI features in this table are proposed implementations of the required tracks, **not completed features**. Simple rule-based color extraction alone would not count as an own-trained model, and a rule-based enemy alone would not count as a GenAI tool-calling agent.

The syllabus requires **both AI tracks in depth for a four-person team**. P1, P2 and P3 each require **three ADRs**, documenting an AI prompt, the resulting code change and at least one rejected suggestion with justification. Everyone must understand and be able to explain their own contributions at the individual oral defense.

## Development Roadmap

Dates follow the COMP205 Fall 2026 syllabus. Tasks are planned, not yet completed.

### P1 — App Skeleton, Backend and CI (13 November 2026)

- [ ] Agree on gameplay rules and interfaces between modules.
- [ ] Create Flutter screens, routes and mock card/battle data (Ali).
- [ ] Set up Firebase Authentication, Firestore models/security rules and notification scaffolding (Şükrü).
- [ ] Prototype deterministic photo features and define the training dataset / evaluation protocol (Serhat).
- [ ] Implement a testable turn-based battle-state skeleton and mock enemy actions (Kadir).
- [ ] Configure CI, automated tests, repository documentation and P1 ADRs (Serhat + Şükrü, with contributions from everyone).

### P2 — AI Implementation Progress (25 December 2026)

- [ ] Train and evaluate the photo model, with baseline, grouped validation and model card (Serhat).
- [ ] Implement the tool-calling enemy agent, its guarded battle tools and a 20+ case evaluation set (Kadir).
- [ ] Integrate camera capture, card inventory and battle UI with live game state (Ali).
- [ ] Connect persisted cards, user data and location-aware rarity to backend services (Şükrü).
- [ ] Run end-to-end integration tests and prepare P2 ADRs (all members).

### P3 — Code Freeze (3 January 2027, 23:59)

- [ ] Complete the exploration → capture → transmutation → battle loop.
- [ ] Finish usability, privacy, security and gameplay-balance checks.
- [ ] Verify CI and release a signed installable Android APK.
- [ ] Finalize `README.md`, `TEAM.md`, `AGENTS.md`, model card, evaluations and P3 ADRs.
- [ ] Prepare final demonstration and individual code explanations.

**Final demos and oral defenses:** 4 and 6 January 2027, according to the syllabus.

## Getting Started

Photalchemy is currently in the **concept and planning phase**. No runnable application or installation instructions are available yet. Setup steps will be added when the first implementation is committed.

## Team and Responsibilities

The four team members each own a primary area, while reviewing and supporting other systems. **All members are expected to write code, participate in reviews, and understand the full gameplay and data flow.**

| Member | Role | Primary responsibilities |
| --- | --- | --- |
| [Serhat Yavuz](https://github.com/serhatvs) | **AI/ML & Architecture Lead** | Track A dataset, own-trained image model, evaluation and model card; photo-to-card logic; architecture and interfaces; AI Decision Records and quality coordination |
| [Ali Çavdar](https://github.com/cavdara549-create) | **Flutter & UI/UX Lead** | Navigation, visual design, camera capture, card collection, battle screens and animations; widget tests and release interface |
| [Şükrü Öztürk](https://github.com/sukrucanozturk98) | **Backend & Cloud Lead** | Firebase Auth, Firestore, security rules, notifications, player profiles and card persistence; location-based rarity, backend tests and CI support |
| [Kadir Zongur](https://github.com/kadirzongur64-byte) | **Gameplay & GenAI Lead** | Turn-based battle engine, card effects, dungeon encounters, enemy tool-calling agent (Track B), its 20+ evaluation scenarios and gameplay tests |

### Shared Ownership / Review Matrix

| Subsystem | Primary owner | Supporting member |
| --- | --- | --- |
| Photo analysis and trained ML model | Serhat | Ali |
| Card generation and attributes | Serhat | Kadir |
| Flutter UI, camera and navigation | Ali | Serhat |
| Battle screens and animations | Ali | Kadir |
| Firebase authentication and persistence | Şükrü | Ali |
| Location / rarity validation | Şükrü | Serhat |
| Turn-based battle engine | Kadir | Ali |
| GenAI enemy agent and tool safety | Kadir | Serhat |
| Automated tests and CI | Serhat | Şükrü |
| Signed Android APK | Ali | Şükrü |
| Documentation and ADRs | All members | Serhat coordinates |

These are the current **proposed ownership assignments** and may be refined as the team finalizes its architecture. Detailed working agreements, review expectations and communication rules belong in `TEAM.md`.

## License

Distributed under the [MIT License](LICENSE).
