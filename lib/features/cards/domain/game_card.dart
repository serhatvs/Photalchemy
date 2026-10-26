/// Metadata for a card generated from photo color features.
///
/// Named GameCard to avoid Flutter Material's Card type.
enum CardType { attack, defense, stun, reflect }

enum CardRarity { common, uncommon, rare, epic }

class CardStats {
  CardStats({required this.strength}) {
    RangeError.checkValueInInterval(strength, 1, 10, 'strength');
  }

  /// Provisional magnitude: effect-specific use must be agreed with Kadir.
  final int strength;
}

class GameCard {
  GameCard({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.rarity,
    required this.stats,
    required this.generationVersion,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Cannot be empty');
    }
    if (ownerId.trim().isEmpty) {
      throw ArgumentError.value(ownerId, 'ownerId', 'Cannot be empty');
    }
    if (generationVersion.trim().isEmpty) {
      throw ArgumentError.value(
        generationVersion,
        'generationVersion',
        'Cannot be empty',
      );
    }
  }

  final String id;
  final String ownerId;
  final CardType type;
  final CardRarity rarity;
  final CardStats stats;
  final String generationVersion;

  // Intentionally no raw photo, EXIF or coordinates.
}
