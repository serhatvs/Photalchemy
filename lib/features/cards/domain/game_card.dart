/// Metadata for a card generated from photo color features.
///
/// Named GameCard to avoid Flutter Material's Card type.
enum CardType { attack, defense, stun, reflect }

enum CardRarity { common, uncommon, rare, epic }

class CardStats {
  const CardStats({required this.strength})
      : assert(strength >= 1 && strength <= 10, 'strength must be in [1, 10]');

  static void validateStrength(int strength) {
    RangeError.checkValueInInterval(strength, 1, 10, 'strength');
  }

  factory CardStats.fromJson(Map<String, dynamic> json) {
    final raw = json['strength'];
    if (raw is! int) {
      throw const FormatException('Expected integer value for strength');
    }
    validateStrength(raw);
    return CardStats(strength: raw);
  }

  /// Provisional magnitude: effect-specific use must be agreed with Kadir.
  final int strength;

  Map<String, dynamic> toJson() => {'strength': strength};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardStats &&
          runtimeType == other.runtimeType &&
          strength == other.strength;

  @override
  int get hashCode => strength.hashCode;

  @override
  String toString() => 'CardStats(strength: $strength)';
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
    if (id.length > 128) {
      throw ArgumentError.value(id, 'id', 'Exceeds maximum length of 128');
    }
    if (ownerId.trim().isEmpty) {
      throw ArgumentError.value(ownerId, 'ownerId', 'Cannot be empty');
    }
    if (ownerId.length > 128) {
      throw ArgumentError.value(
        ownerId,
        'ownerId',
        'Exceeds maximum length of 128',
      );
    }
    if (generationVersion.trim().isEmpty) {
      throw ArgumentError.value(
        generationVersion,
        'generationVersion',
        'Cannot be empty',
      );
    }
    CardStats.validateStrength(stats.strength);
  }

  factory GameCard.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final ownerId = json['ownerId'];
    final typeName = json['type'];
    final rarityName = json['rarity'];
    final statsMap = json['stats'];
    final generationVersion = json['generationVersion'];

    if (id is! String ||
        ownerId is! String ||
        typeName is! String ||
        rarityName is! String ||
        statsMap is! Map<String, dynamic> ||
        generationVersion is! String) {
      throw const FormatException('Missing or invalid card JSON fields');
    }

    final CardType type;
    try {
      type = CardType.values.byName(typeName);
    } catch (_) {
      throw FormatException('Unknown CardType: $typeName');
    }

    final CardRarity rarity;
    try {
      rarity = CardRarity.values.byName(rarityName);
    } catch (_) {
      throw FormatException('Unknown CardRarity: $rarityName');
    }

    return GameCard(
      id: id,
      ownerId: ownerId,
      type: type,
      rarity: rarity,
      stats: CardStats.fromJson(statsMap),
      generationVersion: generationVersion,
    );
  }

  final String id;
  final String ownerId;
  final CardType type;
  final CardRarity rarity;
  final CardStats stats;
  final String generationVersion;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'type': type.name,
        'rarity': rarity.name,
        'stats': stats.toJson(),
        'generationVersion': generationVersion,
      };

  GameCard copyWith({
    String? id,
    String? ownerId,
    CardType? type,
    CardRarity? rarity,
    CardStats? stats,
    String? generationVersion,
  }) {
    return GameCard(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      stats: stats ?? this.stats,
      generationVersion: generationVersion ?? this.generationVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameCard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          type == other.type &&
          rarity == other.rarity &&
          stats == other.stats &&
          generationVersion == other.generationVersion;

  @override
  int get hashCode => Object.hash(
        id,
        ownerId,
        type,
        rarity,
        stats,
        generationVersion,
      );

  @override
  String toString() => 'GameCard(id: $id, owner: $ownerId, type: ${type.name}, '
      'rarity: ${rarity.name}, strength: ${stats.strength}, v: $generationVersion)';
}
