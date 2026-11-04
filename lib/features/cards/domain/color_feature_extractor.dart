import 'dart:math' as math;
import 'dart:typed_data';
import 'photo_analysis.dart';

class RgbPixel {
  RgbPixel({required this.red, required this.green, required this.blue}) {
    validateChannel(red, 'red');
    validateChannel(green, 'green');
    validateChannel(blue, 'blue');
  }

  final int red;
  final int green;
  final int blue;

  static void validateChannel(int value, String name) {
    RangeError.checkValueInInterval(value, 0, 255, name);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RgbPixel &&
          runtimeType == other.runtimeType &&
          red == other.red &&
          green == other.green &&
          blue == other.blue;

  @override
  int get hashCode => Object.hash(red, green, blue);

  @override
  String toString() => 'RgbPixel(R: $red, G: $green, B: $blue)';
}

/// Deterministic, non-ML baseline feature extraction from *decoded* RGB
/// samples. Does not decode files, load ML weights or access camera/location.
class ColorFeatureExtractor {
  const ColorFeatureExtractor();

  PhotoFeatures extract(Iterable<RgbPixel> pixels) {
    var count = 0;
    var meanBrightness = 0.0;
    var brightnessM2 = 0.0;
    var meanSaturation = 0.0;

    for (final p in pixels) {
      count += 1;
      final brightness =
          (0.2126 * p.red + 0.7152 * p.green + 0.0722 * p.blue) / 255.0;
      final maxValue = math.max(p.red, math.max(p.green, p.blue));
      final minValue = math.min(p.red, math.min(p.green, p.blue));
      final saturation = maxValue == 0 ? 0.0 : (maxValue - minValue) / maxValue;

      meanSaturation += (saturation - meanSaturation) / count;
      final delta = brightness - meanBrightness;
      meanBrightness += delta / count;
      brightnessM2 += delta * (brightness - meanBrightness);
    }

    if (count == 0) {
      throw ArgumentError('At least one pixel is required');
    }

    // Guard against floating point catastrophic cancellation yielding tiny negative values.
    final variance = math.max(0.0, brightnessM2 / count);
    final contrast = (2 * math.sqrt(variance)).clamp(0.0, 1.0).toDouble();

    return PhotoFeatures(
      brightness: meanBrightness.clamp(0.0, 1.0).toDouble(),
      saturation: meanSaturation.clamp(0.0, 1.0).toDouble(),
      contrast: contrast,
    );
  }

  /// Extracts features from decoded packed bytes (RGB or RGBA).
  /// Downsamples deterministically if image has more than [maxSamples] pixels to protect UI responsiveness.
  PhotoFeatures extractFromBytes(
    Uint8List bytes, {
    int bytesPerPixel = 3,
    int maxSamples = 10000,
  }) {
    if (bytesPerPixel < 3 || bytesPerPixel > 4) {
      throw ArgumentError.value(
        bytesPerPixel,
        'bytesPerPixel',
        'Expected 3 (RGB) or 4 (RGBA)',
      );
    }
    if (bytes.length < bytesPerPixel) {
      throw ArgumentError('Insufficient byte length for at least one pixel');
    }

    final totalPixels = bytes.length ~/ bytesPerPixel;
    final step = math.max(1, totalPixels ~/ maxSamples);

    final samples = <RgbPixel>[];
    for (var i = 0; i < totalPixels; i += step) {
      final offset = i * bytesPerPixel;
      samples.add(
        RgbPixel(
          red: bytes[offset],
          green: bytes[offset + 1],
          blue: bytes[offset + 2],
        ),
      );
    }

    return extract(samples);
  }
}
