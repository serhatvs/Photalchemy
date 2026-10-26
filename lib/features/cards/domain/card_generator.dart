import 'game_card.dart';
import 'photo_analysis.dart';

/// Transparent gameplay mapping. It is not the custom-trained ML model.
///
/// Proposed scene-to-class assignment should be approved with the battle lead
/// before being treated as final gameplay balance.
class CardGenerator {
  const CardGenerator();

  GameCard generate({
    required String id,
    required String ownerId,
    required PhotoAnalysis analysis,
    required CardRarity rarity,
  }) {
    final type = switch (analysis.prediction.category) {
      SceneCategory.nature => CardType.defense,
      SceneCategory.urban => CardType.reflect,
      SceneCategory.interior => CardType.stun,
      SceneCategory.objectCloseup => CardType.attack,
    };

    final features = analysis.features;
    final rawStrength = 1 +
        (4 * features.brightness +
                3 * features.saturation +
                2 * features.contrast)
            .round() +
        rarity.index;

    return GameCard(
      id: id,
      ownerId: ownerId,
      type: type,
      rarity: rarity,
      stats: CardStats(strength: rawStrength.clamp(1, 10).toInt()),
      modelVersion: analysis.prediction.modelVersion,
    );
  }
}
