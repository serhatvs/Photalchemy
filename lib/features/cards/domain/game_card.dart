/// Immutable, persistence-neutral data contract for a generated battle card.
///
/// The name GameCard avoids a collision with Flutter's Material Card widget.
enum CardType { attack, defense, stun, reflect }

enum CardRarity { common, uncommon, rare, epic }

class CardStats {
  CardStats({required this.strength}) {
    RangeError.checkValueInInterval(strength, 1, 10, 'strength');
  }

  /// Provisional shared magnitude. Kadir will define effect-specific semantics.
  final int strength;
}

class GameCard {
  GameCard({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.rarity,
    required this.stats,
    required this.modelVersion,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Cannot be empty');
    }
    if (ownerId.trim().isEmpty) {
      throw ArgumentError.value(ownerId, 'ownerId', 'Cannot be empty');
    }
    if (modelVersion.trim().isEmpty) {
      throw ArgumentError.value(
          modelVersion, 'modelVersion', 'Cannot be empty');
    }
  }

  final String id;
  final String ownerId;
  final CardType type;
  final CardRarity rarity;
  final CardStats stats;
  final String modelVersion;

  // No original photo, EXIF coordinates or raw precise location stored here.
}
