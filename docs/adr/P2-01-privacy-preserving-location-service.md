# ADR: Privacy-Preserving LocationService Abstraction and Multi-Cell Anti-Farming Controls
- Milestone: P2
- Date: 2026-11-27
- Author: Şükrü Can Öztürk (@sukrucanozturk98)
- Related issue / PR / commit: Issue #22

## Goal and prompt
Design a runtime location service and UI workflow for Photalchemy that:
1. Decouples `AppController` and `ExplorePage` from raw platform GPS sensors and single hardcoded coordinates.
2. Enforces `PRIVACY.md` data minimization by quantizing coordinates into ~1.1 km coarse cells (`CoarseLocation`) at the service boundary before reaching application state or Cloud Firestore.
3. Allows players to opt out of location sharing at any time while keeping card transmutation functional via deterministic color-only baseline rarity.
4. Surfaces per-cell anti-farming decay (`captures / repeatDecayThreshold`) clearly in the UI and allows deterministic multi-cell travel on Android emulators and in automated CI tests.

Prompt to AI:
> "We need to replace the single static demo location in `AppController` with a `LocationService` that supports multiple exploration zones, runtime opt-out, and per-cell anti-farming decay visibility in `ExplorePage`. Should we stream continuous fine-grained GPS coordinates (`Stream<Position>`) from a background geolocator plugin and store visit history timestamps in Firestore, or expose on-demand quantized ~1.1km `LocationSnapshot` reads?"

## Accepted suggestion and resulting change
Implemented `LocationService`, `LocationSnapshot`, `ExplorationCellPreset`, and `SimulatedLocationService` in `lib/features/exploration/domain/location_service.dart`, and wired them into `AppController` and `ExplorePage`:
- **On-Demand Snapshot Only:** Location is sampled strictly on user-initiated capture (`captureAndTransmute()`), never polled in the background.
- **Boundary Quantization & Privacy Opt-Out:** `LocationSnapshot` strips coordinates (`location: null`) whenever `permission` is `denied` or `optedOut`. When `granted`, only ~1.1 km `CoarseLocation` keys (e.g., `38.72:35.48`) are exposed and incremented in `/users/{userId}.cellCaptureCounts`.
- **Multi-Cell Exploration & Anti-Farming Feedback:** `ExplorePage` displays the active coarse cell, remaining exploration bonus captures before anti-farming decay (`repeatDecayThreshold = 4`), an instant `Location On / Opted Out` privacy toggle, and sector chips (`Campus Plaza`, `Citadel Ruins`, `Volcanic Foothills`, `Sunken Marsh`) for deterministic emulator/CI evaluation.

## Rejected AI suggestion
The AI initially suggested subscribing to a continuous GPS coordinate stream (`geolocator` position stream with 5-meter distance filter) and persisting a timestamped array of exact `(latitude, longitude, timestamp)` breadcrumbs in `/users/{userId}/location_history` to calculate distance traveled between card captures.

**Why rejected:**
1. **Privacy & GDPR / Course Policy Violation:** Storing timestamped precise GPS trails in Cloud Firestore creates a permanent movement tracking log of where the user lives and walks, violating `PRIVACY.md` data minimization.
2. **Battery & Background Permission Overhead:** Continuous GPS streaming drains mobile battery and requires invasive background location permissions that are unnecessary when location only affects card rarity at the moment of photo capture.
3. **Emulator & CI Brittleness:** Relying on live hardware GPS streams without a deterministic cell-preset service makes automated widget/integration testing of multi-cell exploration and anti-farming decay flaky in headless GitHub Actions runners.

## Verification
- Verified via `test/features/exploration/domain/location_service_test.dart`:
  - `SimulatedLocationService` transitions across ~1.1 km coarse cells and strips coordinates when opted out.
  - `AppController` increments per-cell capture counts up to `repeatDecayThreshold` (4), marks the cell depleted, resets the bonus when traveling to a new cell, and skips location persistence when opted out.
  - `ExplorePage` widget tests verify the cell status banner, sector switching chips, and privacy opt-out toggle.
