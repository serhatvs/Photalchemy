# ADR-001: Deterministic Color Feature Extraction Pipeline for Photo-to-Card Generation

**Date:** 2026-11-04  **Author:** Serhat Yavuz  **Milestone:** P1  
**Tool and model used:** AI coding assistant (sanitized architecture review prompt; human-verified implementation in PR #11 / commit `16d8948`)

## Context
Photalchemy converts real-world photos into playable battle cards (`attack`, `defense`, `stun`, `reflect`) with bounded strength (`1–10`). We needed a pipeline that runs completely offline with zero cloud API keys, preserves user privacy by never uploading raw photos, executes fast without `NaN` errors on uniform monochrome frames, and avoids conflating card generation with COMP 205's Track A own-trained ML requirement (which governs the enemy battle policy).

## Prompt
```
We need to convert captured camera pixels into GameCard stats and archetypes.
Should we use an on-device pre-trained classifier or statistical color extraction?
Ensure zero network latency, offline execution, and strict safety against NaN on
uniform monochrome images.
```

## Result
Implemented `ColorFeatureExtractor` in `lib/features/cards/domain/color_feature_extractor.dart` and `CardGenerator` in `lib/features/cards/domain/card_generator.dart` (landed via PR #11, squash commit `16d8948`, and wired into `AppController.captureAndTransmute()`):
- Extracts normalized `brightness`, `saturation`, and `contrast` in `[0, 1]` from RGB/RGBA byte buffers.
- Uses a deterministic downsampling stride (`maxSamples = 10000`) to protect UI responsiveness on large camera buffers.
- Clamps variance (`math.max(0.0, brightnessM2 / count)`) before `math.sqrt` to eliminate `NaN` on uniform frames.
- Maps features deterministically to `CardType` and bounded `CardStats.strength` (`1..10`).

## Rejected suggestion(s) — at least one
The AI initially suggested embedding a pre-trained TensorFlow Lite / MobileNet computer-vision classifier to label photos ("forest", "fire", "water", "metal") and map semantic labels to card types.
**Rejected because:** (1) it adds ~25 MB of binary bloat, (2) semantic classifiers hallucinate unpredictably on abstract/blurred indoor photos, and (3) an off-the-shelf CV classifier does not satisfy COMP 205 Track A's requirement to train our *own* ML/DL model for the competitive enemy battle policy.

## Verification
- `flutter test test/features/cards/domain/card_domain_test.dart`: verified uniform `0x00`/`0xFF`/gray inputs produce `0.0` contrast without `NaN`, 10,000+ byte buffers process cleanly, and JSON round-trip preserves values.
- `flutter test test/app/app_controller_test.dart`: verified `captureAndTransmute()` synthesizes all 4 archetypes from sample RGB frames.

## What I learned
Separating deterministic game mechanics (color statistics) from learned AI behavior (Track A battle policy) keeps the app fast, private, and aligned with course assessment criteria.
