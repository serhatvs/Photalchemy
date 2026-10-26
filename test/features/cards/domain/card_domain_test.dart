import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/features/cards/domain/card_generator.dart';
import 'package:photalchemy/features/cards/domain/color_feature_extractor.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';
import 'package:photalchemy/features/cards/domain/photo_analysis.dart';

void main() {
  const extractor = ColorFeatureExtractor();
  const generator = CardGenerator();

  test('black and white samples have expected normalized features', () {
    final black = extractor.extract([RgbPixel(red: 0, green: 0, blue: 0)]);
    expect(black.brightness, 0);
    expect(black.saturation, 0);
    expect(black.contrast, 0);

    final white = extractor.extract([
      RgbPixel(red: 255, green: 255, blue: 255),
    ]);
    expect(white.brightness, closeTo(1, 1e-10));
    expect(white.saturation, 0);
    expect(white.contrast, 0);
  });

  test('pixel contrast and saturation are reproducible', () {
    final pixels = [
      RgbPixel(red: 0, green: 0, blue: 0),
      RgbPixel(red: 255, green: 255, blue: 255),
    ];
    final result = extractor.extract(pixels);
    expect(result.brightness, closeTo(0.5, 1e-10));
    expect(result.contrast, closeTo(1, 1e-10));
    expect(result.saturation, 0);

    final red = extractor.extract([RgbPixel(red: 255, green: 0, blue: 0)]);
    expect(red.saturation, closeTo(1, 1e-10));
  });

  test('invalid pixels and empty samples are rejected', () {
    expect(
      () => RgbPixel(red: -1, green: 0, blue: 0),
      throwsRangeError,
    );
    expect(
      () => RgbPixel(red: 0, green: 256, blue: 0),
      throwsRangeError,
    );
    expect(() => extractor.extract(<RgbPixel>[]), throwsArgumentError);
  });

  test('non-finite and out-of-range features/confidence are rejected', () {
    expect(
      () => PhotoFeatures(brightness: double.nan, saturation: 0, contrast: 0),
      throwsRangeError,
    );
    expect(
      () => PhotoFeatures(brightness: 0, saturation: 1.1, contrast: 0),
      throwsRangeError,
    );
    expect(
      () => ScenePrediction(
        category: SceneCategory.nature,
        confidence: -0.1,
        modelVersion: 'test',
      ),
      throwsRangeError,
    );
    expect(
      () => ScenePrediction(
        category: SceneCategory.nature,
        confidence: 0.7,
        modelVersion: ' ',
      ),
      throwsArgumentError,
    );
  });

  test('all proposed scene classes map to legal card types', () {
    const expected = {
      SceneCategory.nature: CardType.defense,
      SceneCategory.urban: CardType.reflect,
      SceneCategory.interior: CardType.stun,
      SceneCategory.objectCloseup: CardType.attack,
    };

    for (final entry in expected.entries) {
      final card = generator.generate(
        id: 'card-1',
        ownerId: 'test-user',
        rarity: CardRarity.common,
        analysis: PhotoAnalysis(
          features:
              PhotoFeatures(brightness: 0.5, saturation: 0.5, contrast: 0.5),
          prediction: ScenePrediction(
            category: entry.key,
            confidence: 0.8,
            modelVersion: 'example-v0',
          ),
        ),
      );
      expect(card.type, entry.value);
      expect(card.stats.strength, inInclusiveRange(1, 10));
    }
  });

  test('generation is deterministic and rarity changes strength', () {
    final analysis = PhotoAnalysis(
      features: PhotoFeatures(brightness: 0.3, saturation: 0.5, contrast: 0.2),
      prediction: ScenePrediction(
        category: SceneCategory.objectCloseup,
        confidence: 0.9,
        modelVersion: 'candidate-v0',
      ),
    );
    final first = generator.generate(
      id: 'c',
      ownerId: 'u',
      analysis: analysis,
      rarity: CardRarity.common,
    );
    final second = generator.generate(
      id: 'c',
      ownerId: 'u',
      analysis: analysis,
      rarity: CardRarity.common,
    );
    final rare = generator.generate(
      id: 'c',
      ownerId: 'u',
      analysis: analysis,
      rarity: CardRarity.rare,
    );
    expect(first.type, second.type);
    expect(first.stats.strength, second.stats.strength);
    expect(rare.stats.strength, greaterThan(first.stats.strength));
    expect(rare.stats.strength, lessThanOrEqualTo(10));
  });

  test('rejects malformed card identifiers and stats', () {
    expect(() => CardStats(strength: 0), throwsRangeError);
    expect(() => CardStats(strength: 11), throwsRangeError);
    expect(
      () => GameCard(
        id: ' ',
        ownerId: 'user',
        type: CardType.attack,
        rarity: CardRarity.common,
        stats: CardStats(strength: 2),
        modelVersion: 'v0',
      ),
      throwsArgumentError,
    );
  });

  test('maximum feature values always generate a bounded card', () {
    final card = generator.generate(
      id: 'bounded',
      ownerId: 'user',
      rarity: CardRarity.epic,
      analysis: PhotoAnalysis(
        features: PhotoFeatures(brightness: 1, saturation: 1, contrast: 1),
        prediction: ScenePrediction(
          category: SceneCategory.urban,
          confidence: 1,
          modelVersion: 'v0',
        ),
      ),
    );
    expect(card.stats.strength, 10);
  });
}
