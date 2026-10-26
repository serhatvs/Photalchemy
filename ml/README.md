# Track A — Own-trained photo model

**Owner:** Serhat Yavuz (collaborates with Ali on camera/model integration).

This directory will contain reproducible **training/preprocessing/evaluation code**, model metadata and a model card. It is not yet implemented.

### Required evidence
- Explain data provenance, consent/licensing and labels.
- Separate train/test groups to avoid leakage; use grouped cross-validation where appropriate.
- Compare with an explicit baseline and report metrics with confidence intervals.
- Record model architecture, limitations, failure examples and inference requirements in a model card.
- Export a versioned mobile-compatible model if on-device inference is chosen.

**Do not commit:** private photographs, unconsented data, access tokens, large datasets or automatically downloaded model weights. Store only safe scripts, small synthetic examples and documented acquisition steps. The precise prediction task is still a team design decision.

### Current proposal for Issue #5

- [Track A dataset, training and evaluation plan](TRACK_A_PLAN.md)
- [Manifest schema (header only)](dataset_manifest_schema.csv)
- [Model card template](MODEL_CARD_TEMPLATE.md)

No actual training images, model weights or evaluation metrics are present.
