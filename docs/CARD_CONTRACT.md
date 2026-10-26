# Card generation contract — P1 proposal (Issue #5)

**Status:** Functional Dart prototype; gameplay mapping and learned labels await team approval. Owner: Serhat; interfaces to agree with Ali (capture), Şükrü (storage/rarity), Kadir (battle).

## Proposed pipeline

```text
Camera image bytes [Ali]
    → validate size/type + decode/image sample [not implemented]
    → ColorFeatureExtractor(decoded RGB samples) [deterministic prototype]
    → PhotoAnalyzer(image bytes) [interface only; train own model for Track A]
    → ScenePrediction + PhotoFeatures
    → CardGenerator + server/trusted rarity decision
    → GameCard metadata (no raw photo or coordinates)
    → Persistence adapter [Şükrü] → battle engine [Kadir]
```

### Dart contracts

- `PhotoAnalyzer.analyze(Uint8List)` returns `PhotoAnalysis(features, prediction)`; no image decoder, ML inference adapter or model is implemented yet.
- `PhotoFeatures`: `brightness`, `saturation`, `contrast`, each finite and in **[0,1]**.
- `ScenePrediction`: proposed `SceneCategory` (nature, urban, interior, objectCloseup), normalized confidence and nonempty model version.
- `GameCard` (the conceptual Card type; named to avoid collision with Flutter's Material `Card` widget): id, ownerId, card type, rarity, strength, modelVersion. Does **not** hold image bytes, EXIF or location.
- `CardStats.strength`: prototype integer **1–10**, not a confirmed battle damage formula.
- `CardGenerator`: pure/deterministic mapping, no Firebase/camera/network dependency. Scene→type mapping for this prototype: nature→defense; urban→reflect; interior→stun; close-up object→attack. The proposed strength is clamped to 1–10 and incorporates normalized color features and rarity bonus.

## Responsibilities and boundaries

- **Ali:** camera permissions, capture UX, input validation and decoding; passes bytes to an adapter. No model or Firebase logic in widgets.
- **Serhat:** features, trained Track A predictor/inference adapter, card generation validation.
- **Şükrü:** trusted/authenticated owner ID and card ID generation/validation, location rarity decisions, Firestore rules and persistence. **Never trust a card's client-provided owner or rarity** for any valuable server operation.
- **Kadir:** determines what strength means for attack/defense/stun/reflect, implements deterministic turn effects. LLM proposes legal enemy actions only; it does not mutate card stats.

## Decisions to confirm at interface review

1. Do we want scene category to set card type, or should it instead affect a visual modifier while color sets type? The current code uses a **provisional mapping**, not a final product decision.
2. Are nature/urban/interior/objectCloseup the right human-labeled classes for a dataset that can actually be collected and fairly evaluated?
3. Is `strength 1–10` useful for all four card effects? Should we use effect-specific stats after battle-engine discussion?
4. Does inference happen on device (LiteRT) or via authenticated backend? No unrestricted LLM or paid-provider key belongs in the app.
5. How will rarity avoid repeated exact locations while minimizing collected geodata? Must work with location denied.

## Testing

Pure Dart unit tests in `test/features/cards/domain/card_domain_test.dart` cover edge RGB samples, normalization, invalid values, deterministic generation, all four mappings and strength bounds. Actual camera/photo-decoder tests, trained-model evaluations and Firebase rules tests are intentionally not claimed here.
