import 'game_card.dart';
import 'photo_analysis.dart';

/// Transparent, deterministic photo-to-card prototype.
///
/// The thresholds are provisional gameplay values, NOT an ML classifier.
/// Own-trained Track A will learn ENEMY GAMEPLAY POLICY, not photo categories.
class CardGenerator {
  const CardGenerator();

  GameCard generate({
    required String id,
    required String ownerId,
    required PhotoFeatures features,
    required CardRarity rarity,
  }) {
    // Priority resolves overlap deterministically; exact balance remains TBD.
    final CardType type;
    if (features.contrast >= 0.6) {
      type = CardType.reflect;
    } else if (features.brightness >= 0.65) {
      type = CardType.attack;
    } else if (features.saturation >= 0.65) {
      type = CardType.stun;
    } else {
      type = CardType.defense;
    }

    final score = (4 * features.brightness +
            3 * features.saturation +
            2 * features.contrast)
        .round();
    final strength = (1 + score + rarity.index).clamp(1, 10).toInt();

    return GameCard(
      id: id,
      ownerId: ownerId,
      type: type,
      rarity: rarity,
      stats: CardStats(strength: strength),
      generationVersion: 'color-v0',
    );
  }
}
