import 'dart:typed_data';
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

  test('mixed extremes and saturated red are reproducible', () {
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

  test('invalid pixels and empty inputs fail', () {
    expect(() => RgbPixel(red: -1, green: 0, blue: 0), throwsRangeError);
    expect(() => RgbPixel(red: 0, green: 256, blue: 0), throwsRangeError);
    expect(() => extractor.extract(<RgbPixel>[]), throwsArgumentError);
    expect(
      () => PhotoFeatures(brightness: double.nan, saturation: 0, contrast: 0),
      throwsRangeError,
    );
    expect(
      () => PhotoFeatures(brightness: 0, saturation: 1.1, contrast: 0),
      throwsRangeError,
    );
  });

  test(
    'large uniform pixel set does not trigger floating point NaN in contrast',
    () {
      final uniformPixels = List.generate(
        500,
        (_) => RgbPixel(red: 120, green: 120, blue: 120),
      );
      final features = extractor.extract(uniformPixels);
      expect(features.contrast, 0.0);
      expect(features.contrast.isFinite, isTrue);
    },
  );

  test('extractFromBytes extracts features from RGB and RGBA buffers', () {
    final rgbBytes = Uint8List.fromList([255, 0, 0, 0, 255, 0]);
    final rgbFeatures = extractor.extractFromBytes(rgbBytes, bytesPerPixel: 3);
    expect(rgbFeatures.brightness, greaterThan(0));
    expect(rgbFeatures.saturation, greaterThan(0));

    final rgbaBytes = Uint8List.fromList([255, 0, 0, 255, 0, 255, 0, 255]);
    final rgbaFeatures =
        extractor.extractFromBytes(rgbaBytes, bytesPerPixel: 4);
    expect(rgbaFeatures.brightness, closeTo(rgbFeatures.brightness, 1e-9));

    expect(
      () => extractor.extractFromBytes(rgbBytes, bytesPerPixel: 2),
      throwsArgumentError,
    );
    expect(
      () => extractor.extractFromBytes(Uint8List(2), bytesPerPixel: 3),
      throwsArgumentError,
    );
  });

  test('PhotoFeatures JSON serialization and equality work as expected', () {
    final original = PhotoFeatures(
      brightness: 0.75,
      saturation: 0.5,
      contrast: 0.25,
    );
    final json = original.toJson();
    final restored = PhotoFeatures.fromJson(json);

    expect(restored, equals(original));
    expect(restored.hashCode, equals(original.hashCode));

    expect(
      () => PhotoFeatures.fromJson({'brightness': 0.5}),
      throwsFormatException,
    );
    expect(
      () => PhotoFeatures.fromJson({
        'brightness': -0.1,
        'saturation': 0.5,
        'contrast': 0.5,
      }),
      throwsRangeError,
    );
  });

  test('RgbPixel value equality and formatting', () {
    final p1 = RgbPixel(red: 10, green: 20, blue: 30);
    final p2 = RgbPixel(red: 10, green: 20, blue: 30);
    final p3 = RgbPixel(red: 10, green: 25, blue: 30);

    expect(p1, equals(p2));
    expect(p1.hashCode, equals(p2.hashCode));
    expect(p1, isNot(equals(p3)));
    expect(p1.toString(), contains('R: 10, G: 20, B: 30'));
  });

  test('color features produce each provisional card type', () {
    final examples = <CardType, PhotoFeatures>{
      CardType.attack:
          PhotoFeatures(brightness: 0.8, saturation: 0.3, contrast: 0.2),
      CardType.defense:
          PhotoFeatures(brightness: 0.3, saturation: 0.3, contrast: 0.2),
      CardType.stun:
          PhotoFeatures(brightness: 0.3, saturation: 0.8, contrast: 0.2),
      CardType.reflect:
          PhotoFeatures(brightness: 0.3, saturation: 0.2, contrast: 0.8),
    };
    for (final entry in examples.entries) {
      final card = generator.generate(
        id: 'c',
        ownerId: 'user',
        rarity: CardRarity.common,
        features: entry.value,
      );
      expect(card.type, entry.key);
      expect(card.stats.strength, inInclusiveRange(1, 10));
      expect(card.generationVersion, 'color-v0');
    }
  });

  test('generateFromBytes creates card directly from pixel bytes', () {
    final rgbBytes = Uint8List.fromList([255, 255, 255, 255, 255, 255]);
    final card = generator.generateFromBytes(
      id: 'bright-card',
      ownerId: 'alchemist-1',
      bytes: rgbBytes,
      rarity: CardRarity.rare,
    );
    expect(card.id, 'bright-card');
    expect(card.ownerId, 'alchemist-1');
    expect(card.type, CardType.attack);
    expect(card.rarity, CardRarity.rare);
    expect(card.stats.strength, greaterThanOrEqualTo(5));
  });

  test('CardStats JSON serialization, validation, and equality', () {
    const stats = CardStats(strength: 7);
    final json = stats.toJson();
    expect(json, {'strength': 7});

    final restored = CardStats.fromJson(json);
    expect(restored, equals(stats));
    expect(restored.hashCode, equals(stats.hashCode));
    expect(restored.toString(), contains('strength: 7'));

    expect(() => CardStats.fromJson({'strength': 'not-int'}),
        throwsFormatException);
    expect(() => CardStats.fromJson({'strength': 0}), throwsRangeError);
    expect(() => CardStats.fromJson({'strength': 11}), throwsRangeError);
  });

  test('GameCard JSON serialization and copyWith', () {
    final card = GameCard(
      id: 'card-101',
      ownerId: 'user-42',
      type: CardType.stun,
      rarity: CardRarity.epic,
      stats: const CardStats(strength: 9),
      generationVersion: 'color-v0',
    );

    final json = card.toJson();
    final restored = GameCard.fromJson(json);

    expect(restored, equals(card));
    expect(restored.hashCode, equals(card.hashCode));
    expect(restored.toString(), contains('card-101'));

    final modified = card.copyWith(
      ownerId: 'user-99',
      stats: const CardStats(strength: 5),
    );
    expect(modified.ownerId, 'user-99');
    expect(modified.stats.strength, 5);
    expect(modified.type, CardType.stun);
    expect(modified.id, card.id);
  });

  test('GameCard.fromJson rejects malformed and tampered inputs', () {
    final validJson = {
      'id': 'c1',
      'ownerId': 'u1',
      'type': 'attack',
      'rarity': 'common',
      'stats': {'strength': 5},
      'generationVersion': 'color-v0',
    };

    expect(
      () => GameCard.fromJson({...validJson, 'type': 'super_weapon'}),
      throwsFormatException,
    );
    expect(
      () => GameCard.fromJson({...validJson, 'rarity': 'mythic_god'}),
      throwsFormatException,
    );
    expect(
      () => GameCard.fromJson({...validJson, 'id': 12345}),
      throwsFormatException,
    );
  });

  test('overlapping photo features have deterministic priority', () {
    final card = generator.generate(
      id: 'overlap',
      ownerId: 'player',
      rarity: CardRarity.common,
      features: PhotoFeatures(brightness: 1, saturation: 1, contrast: 1),
    );
    expect(card.type, CardType.reflect);
    expect(card.stats.strength, 10);
  });

  test('repeat generation is stable and rarity increases strength', () {
    final features =
        PhotoFeatures(brightness: 0.2, saturation: 0.4, contrast: 0.2);
    GameCard makeCard(CardRarity rarity) => generator.generate(
          id: 'stable',
          ownerId: 'player',
          features: features,
          rarity: rarity,
        );
    final common = makeCard(CardRarity.common);
    final repeated = makeCard(CardRarity.common);
    final rare = makeCard(CardRarity.rare);
    expect(common.type, repeated.type);
    expect(common.stats.strength, repeated.stats.strength);
    expect(rare.stats.strength, greaterThan(common.stats.strength));
  });

  test('invalid card metadata and stats fail', () {
    expect(
      () => GameCard(
        id: ' ',
        ownerId: 'user',
        type: CardType.attack,
        rarity: CardRarity.common,
        stats: const CardStats(strength: 2),
        generationVersion: 'color-v0',
      ),
      throwsArgumentError,
    );
    expect(
      () => GameCard(
        id: 'a' * 129,
        ownerId: 'user',
        type: CardType.attack,
        rarity: CardRarity.common,
        stats: const CardStats(strength: 2),
        generationVersion: 'color-v0',
      ),
      throwsArgumentError,
    );
  });
}
