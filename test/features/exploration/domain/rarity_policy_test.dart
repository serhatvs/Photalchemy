import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';
import 'package:photalchemy/features/cards/domain/photo_analysis.dart';
import 'package:photalchemy/features/exploration/domain/rarity_policy.dart';

void main() {
  const policy = RarityPolicy(repeatDecayThreshold: 4);

  group('CoarseLocation', () {
    test('quantizes precise GPS coordinates to ~1.1km cell grid', () {
      final loc1 = CoarseLocation.fromCoordinates(38.720845, 35.482619);
      final loc2 = CoarseLocation.fromCoordinates(38.724999, 35.484999);

      // Both should map to 38.72 : 35.48
      expect(loc1.cellKey, '38.72:35.48');
      expect(loc2.cellKey, '38.72:35.48');
      expect(loc1, equals(loc2));
      expect(loc1.hashCode, equals(loc2.hashCode));
    });
  });

  group('RarityPolicy', () {
    final vibrant =
        PhotoFeatures(brightness: 0.9, saturation: 0.9, contrast: 0.9);
    final muted =
        PhotoFeatures(brightness: 0.2, saturation: 0.2, contrast: 0.2);

    test('falls back gracefully when permission is denied or opted out', () {
      final denied = policy.determineRarity(
        features: vibrant,
        permission: LocationPermission.denied,
      );
      final optedOut = policy.determineRarity(
        features: muted,
        permission: LocationPermission.optedOut,
      );

      expect(
          denied,
          isIn([
            CardRarity.common,
            CardRarity.uncommon,
            CardRarity.rare,
            CardRarity.epic
          ]));
      expect(optedOut, isIn([CardRarity.common, CardRarity.uncommon]));
    });

    test('rewards diverse exploration with rare/epic cards', () {
      final loc = CoarseLocation.fromCoordinates(41.01, 28.97);
      final rarity = policy.determineRarity(
        features: vibrant,
        permission: LocationPermission.granted,
        location: loc,
        cellCaptureCounts: {'41.01:28.97': 1}, // Low capture count in cell
      );

      expect(rarity, equals(CardRarity.epic));
    });

    test('anti-farming decay caps rarity to common when threshold is exceeded',
        () {
      final loc = CoarseLocation.fromCoordinates(41.01, 28.97);
      final decayedRarity = policy.determineRarity(
        features: vibrant, // Normally produces epic
        permission: LocationPermission.granted,
        location: loc,
        cellCaptureCounts: {'41.01:28.97': 5}, // Exceeds threshold of 4
      );

      expect(decayedRarity, equals(CardRarity.common));
    });
  });
}
