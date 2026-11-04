import 'dart:math' as math;
import 'package:photalchemy/features/cards/domain/game_card.dart';
import 'package:photalchemy/features/cards/domain/photo_analysis.dart';

enum LocationPermission { granted, denied, optedOut }

/// Coarse geohash-like cell coordinate (~1.1km grid at equator).
///
/// Strips precise GPS tracking to comply with data minimization requirements in PRIVACY.md.
class CoarseLocation {
  const CoarseLocation({required this.latitude, required this.longitude});

  factory CoarseLocation.fromCoordinates(double lat, double lon) {
    // Quantize to 2 decimal places (~1.1 km precision)
    final coarseLat = (lat * 100).round() / 100.0;
    final coarseLon = (lon * 100).round() / 100.0;
    return CoarseLocation(latitude: coarseLat, longitude: coarseLon);
  }

  final double latitude;
  final double longitude;

  String get cellKey =>
      '${latitude.toStringAsFixed(2)}:${longitude.toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoarseLocation &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'CoarseLocation($cellKey)';
}

/// Computes card rarity deterministically while enforcing privacy, opt-out,
/// and repeated-location decay to prevent farming.
class RarityPolicy {
  const RarityPolicy({this.repeatDecayThreshold = 4});

  /// Maximum captures in the same coarse location cell before anti-farming decay applies.
  final int repeatDecayThreshold;

  CardRarity determineRarity({
    required PhotoFeatures features,
    required LocationPermission permission,
    CoarseLocation? location,
    Map<String, int> cellCaptureCounts = const {},
    math.Random? random,
  }) {
    final rng = random ?? math.Random(features.hashCode);

    // 1. Opt-out and Denial Fallback (mandatory per QUALITY.md and TESTING.md)
    if (permission != LocationPermission.granted || location == null) {
      return _baselineRarity(features, rng);
    }

    // 2. Anti-farming / Repeated Location Boundary
    final capturesInCell = cellCaptureCounts[location.cellKey] ?? 0;
    if (capturesInCell >= repeatDecayThreshold) {
      // Degrade rarity to prevent single-location abuse
      return CardRarity.common;
    }

    // 3. Exploration Bonus: Higher chance of rare/epic when visiting diverse cells
    final score = features.contrast * 0.4 +
        features.saturation * 0.4 +
        features.brightness * 0.2;

    if (score >= 0.8) {
      return CardRarity.epic;
    } else if (score >= 0.6) {
      return CardRarity.rare;
    } else if (score >= 0.35) {
      return CardRarity.uncommon;
    } else {
      return CardRarity.common;
    }
  }

  CardRarity _baselineRarity(PhotoFeatures features, math.Random rng) {
    final score = features.contrast * 0.5 + features.saturation * 0.5;
    if (score >= 0.75) {
      return CardRarity.rare;
    } else if (score >= 0.4) {
      return CardRarity.uncommon;
    }
    return CardRarity.common;
  }
}
