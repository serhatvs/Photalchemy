# Track A — Own-trained battle policy

**Owner:** Serhat Yavuz, collaborating with Kadir on rules, legal actions, and battle simulation.

Train and evaluate a model that **uses the available card types strategically, chooses legal actions and tries to defeat the player**. Track A is no longer a photo-scene classifier. Color-to-card generation is deterministic and belongs to the normal game domain.

Read:
- [Competitive opponent training/evaluation plan](TRACK_A_PLAN.md)
- [Synthetic battle-decision manifest schema](dataset_manifest_schema.csv)
- [Model card template](MODEL_CARD_TEMPLATE.md)

The model needs reproducible simulated battles, independent baselines, grouped validation, win-rate metrics with uncertainty, a model card and honest failure analysis. No battle dataset, trained weights, learned policy or measured win rate exists yet.

Do not commit private player data, photo datasets, credentials or large generated datasets.
