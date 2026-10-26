# Security Policy — Photalchemy

> **Status:** Engineering policy for a course prototype, not a claim that the app has passed a security audit. Applies to everyone contributing to the repository.

## Reporting a security issue

**Do not publish exploit details, leaked keys, personal photos or real location records in a public GitHub Issue or PR.** If GitHub **Private Vulnerability Reporting** is enabled, use the repository's **Security → Report a vulnerability** flow. Otherwise contact repository maintainers privately through a previously established team channel; if necessary, ask a COMP205 instructor/TA for a private route. No public security-contact email has been designated. Do not include exploit payloads in shared chat. Security maintainers: Şükrü (backend) and Serhat (architecture), with all affected module owners involved.

For suspected leaked credentials: immediately disable/rotate the affected key, invalidate active sessions if warranted, assess exposure and log a sanitized incident summary. **Deleting a Git commit does not revoke exposed credentials.** Handle user-data incidents privately and seek appropriate university/legal guidance.

## Assets, boundaries and risks

| Asset / boundary | Threat example | Required design control |
| --- | --- | --- |
| Player accounts | Unauthorized account access | Firebase Authentication; least privilege; server-side authorization for protected operations |
| Firestore cards/profiles | Reading or modifying another player's cards | Default-deny Firestore rules, per-user document ownership, negative rule tests, validated writes |
| Photo capture | Personal details/EXIF exposure or maliciously large files | Request camera permission at use, validate type/size, strip metadata before upload, prefer local processing; do not persist raw photos by default |
| Location/rarity | Exact route leakage, spoofing and farming | Only collect if the user chooses; prefer coarse cells or privacy-preserving visit summaries; validate rarity grants and abuse limits in trusted code |
| GenAI enemy agent | Prompt injection or illegal game-state mutation | Treat all model output as untrusted, use an allowlisted tool schema, validate moves in the battle engine, rate-limit and time out requests; deterministic fallback |
| Inference/ML | Model/data poisoning, malformed image input | Track dataset provenance, validate input and output shapes, version trained model and report failure cases |
| Mobile build / CI | Secret exposure, compromised dependency, release signing theft | Restrict GitHub Actions permissions, review dependency changes, do not commit keys; protect release signing credentials |

## Implementation rules

- **No plaintext credentials in Git**: service-account JSON, private keys, tokens, signing keystores, API provider secrets, or personal Firebase admin credentials. Use supported CI secret storage with least privilege when credentials become necessary.
- Firebase client configuration is *not sufficient to authorize access* even when public. Protect database and storage with security rules; validate authenticated identity on every privileged operation. Restrict relevant API keys appropriately where supported.
- Do not put an unrestricted LLM provider key in a distributed mobile application. Use an authorized gateway or platform SDK with suitable authentication, quotas and abuse controls.
- Never trust client-provided rarity, card ownership, damage, purchases or inventory grants. Validate critical state transitions at the correct trusted boundary; clarify which rules must be server authoritative before implementing PvP or shared economy.
- Reject unsupported MIME types, excessive file sizes, unexpected image dimensions, malicious/invalid tool arguments and malformed API responses without crashing.
- Scope runtime permissions to the feature; provide a functional non-location fallback for emulator and permission-denied users. Do not ask for background location unless the team documents an essential use case.
- Log error categories, not raw photos, auth tokens, prompts with personal data, exact locations or entire private user documents.
- Rate-limit and quota costly APIs; apply request timeouts, retries with backoff where safe and transparent offline errors.
- Follow [PRIVACY.md](PRIVACY.md) for consent, retention and minimization.

## Security checks before merging

- [ ] New Firestore read/write paths are access-scoped and have a **denied-user** test.
- [ ] New remote or AI operations validate auth, input, permissions and rate limits.
- [ ] Any camera/location/notification permission is explained in-app and has denial behavior.
- [ ] No secrets or user content in commits, fixtures, screenshots, logs or ADR prompts.
- [ ] Sensitive behavior is covered by meaningful tests or a recorded risk/issue.
- [ ] Dependencies and CI workflows are reviewed for unexpected privileges.

## GitHub repository settings (manual)

Maintain **protected `main`** (PR + independent approval + CI). Enable GitHub secret scanning/push protection and private vulnerability reporting **if available under the repository/account plan**. Restrict Actions permissions and review Dependabot alerts; do not rely on these settings being enabled solely because this file exists.

**Review and update this policy** when real authentication, storage, backend, model provider, release signing or location-processing decisions are made.
