# ADR: Deterministic Color Feature Extraction Pipeline for Photo-to-Card Generation
- Milestone: P1
- Date: 2026-11-04
- Author: Serhat
- Related issue / PR / commit: Issue #5 / PR #11 (commits `4163c85`, `65f6734`)

## Goal and prompt
Design a photo-to-card transformation system for Photalchemy that:
1. Operates offline without external cloud API dependencies.
2. Respects user privacy by extracting lightweight numerical statistics rather than uploading raw photos.
3. Provides deterministic, testable mapping to core card archetypes (`attack`, `defense`, `stun`, `reflect`).
4. Avoids conflating card generation with the COMP205 ML requirement (where the team's own-trained model must govern the enemy battle policy).

Prompt to AI:
> "We need to convert captured camera pixels into `GameCard` stats and archetypes. Should we use an on-device pre-trained classifier or statistical color extraction? Ensure zero network latency, offline execution, and strict safety against `NaN` on uniform monochrome images."

## Accepted suggestion and resulting change
Implement `ColorFeatureExtractor` in `lib/features/cards/domain/color_feature_extractor.dart`:
- Extracts normalized brightness, saturation, and contrast variance from RGB/RGBA byte streams.
- Employs downsampling stride for large camera buffers (avoiding memory spikes and frame drops).
- Implements numerical clamping and zero-variance guards (`variance == 0 ? 0.0 : math.sqrt(...)`) to eliminate `NaN` / division by zero.
- Directly feeds `CardGenerator.generateFromBytes` to deterministically assign card type and clamped strength (1 to 10).

## Rejected AI suggestion
The AI initially suggested embedding an on-device TensorFlow Lite / MobileNet computer vision classifier to categorize photos into semantic labels ("forest", "fire", "water", "metal") and map those labels to card types.

**Why rejected:**
1. **Bundle Bloat:** Adding a pre-trained model and TFLite runtime adds ~25 MB to the application binary.
2. **Fragility & Non-determinism:** Semantic classifiers hallucinate incorrect labels on abstract, blurred, or indoor photos, leading to user confusion.
3. **Course Alignment:** The COMP205 syllabus requires the team's *own* trained model to solve the Track A requirement (Enemy Battle Policy). Using an off-the-shelf CV model for photo classification does not satisfy the Track A learning requirement and wastes project scope.

## Verification
- Unit tests in `test/features/cards/domain/card_domain_test.dart` verify:
  - Uniform black (0x00), uniform white (0xFF), and uniform gray yield zero contrast variance without `NaN`.
  - Stride downsampling on 10,000+ byte image buffers completes in < 5 ms.
  - Serialization to/from JSON preserves floating point precision.
