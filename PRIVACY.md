# Privacy and Data Handling — Photalchemy

> **Status:** Internal data-minimization design guidance. This is **not** a production privacy notice, consent form or legal compliance certification. Review actual deployments and requirements under relevant law (including KVKK) before collecting real user data.

Photalchemy's planned camera and location features may involve sensitive personal information. **Prefer local image inference, coarse exploration signals and the minimum retained data**. No actual retention period, data processor, storage region or live user policy has been decided yet.

## Data inventory (proposed)

| Category | Why needed | Safest default | Open decision |
| --- | --- | --- | --- |
| Firebase authentication identifier | Authenticate and scope inventory | Store only necessary account fields | Account deletion behavior and provider setup |
| Captured photos | Create cards from photos | Process on device; don't upload or retain raw images | Whether any user opt-in upload is genuinely required |
| Image-derived card metadata | Persist playable collection | Store only computed card data/limited provenance | Precise card schema and user deletion support |
| Location signal | Explore/repeat-location rarity | Ask foreground consent; calculate coarse location cell/history summary, not exact trails | Cell resolution, anti-cheat limitations, deletion and retention |
| Battle progress | Resume games | Store minimal progress and event metadata | Retention and conflict resolution |
| GenAI battle requests | Choose enemy actions | Send only sanitized abstract battle state, not photos or precise GPS | Provider, logging and model training/data policies |
| Diagnostics | Debug failures | Anonymous/redacted error category only | Opt-in and expiration |

## Permission behavior

Explain in-app **why** camera, location or notification permission is requested, and request each when the corresponding feature is used. Rejecting permission must not crash the app; provide emulator/demo and no-location fallback flows. Do not request background location without a new design review and clearly justified feature.

If a cloud feature genuinely needs user data, document the data sent, its purpose, user control, recipients, retention/deletion and safeguards **before** enabling that upload. Avoid turning on analytics or crash logging with personal identifiers by default.

## Handling and deletion

- Avoid embedding user photos in logs, Git commits, tickets, PR screenshots, model datasets or AI prompts.
- Strip EXIF metadata before any approved image sharing/upload. Validate file types/sizes.
- Document how an account can delete its stored card/profile data and how cached local data is cleared before releasing to real users.
- Keep production, demo and ML-training datasets separate. Track training consent/provenance and anonymize where feasible.
- A user's precise location should not be included in LLM context; use a coarse, minimum-necessary summary for gameplay if required.
- Define retention/deletion and consent wording with the team before the app collects real data. Do not make up a retention period here.

## Review owners

Şükrü (Firebase, location persistence), Serhat (photo/ML data), Ali (UI consent) and Kadir (LLM inputs) are jointly responsible for their data flows. See [SECURITY.md](SECURITY.md), [QUALITY.md](QUALITY.md), and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
