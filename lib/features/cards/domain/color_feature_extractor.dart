import 'dart:math' as math;
import 'photo_analysis.dart';

class RgbPixel {
  RgbPixel({required this.red, required this.green, required this.blue}) {
    RangeError.checkValueInInterval(red, 0, 255, 'red');
    RangeError.checkValueInInterval(green, 0, 255, 'green');
    RangeError.checkValueInInterval(blue, 0, 255, 'blue');
  }

  final int red;
  final int green;
  final int blue;
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
          (0.2126 * p.red + 0.7152 * p.green + 0.0722 * p.blue) / 255;
      final maxValue = math.max(p.red, math.max(p.green, p.blue));
      final minValue = math.min(p.red, math.min(p.green, p.blue));
      final saturation = maxValue == 0
          ? 0.0
          : (maxValue - minValue) / maxValue;

      meanSaturation += (saturation - meanSaturation) / count;
      final delta = brightness - meanBrightness;
      meanBrightness += delta / count;
      brightnessM2 += delta * (brightness - meanBrightness);
    }

    if (count == 0) {
      throw ArgumentError('At least one pixel is required');
    }

    // Twice population standard deviation, clamped to the unit interval.
    final contrast =
        (2 * math.sqrt(brightnessM2 / count)).clamp(0.0, 1.0).toDouble();

    return PhotoFeatures(
      brightness: meanBrightness.clamp(0.0, 1.0).toDouble(),
      saturation: meanSaturation.clamp(0.0, 1.0).toDouble(),
      contrast: contrast,
    );
  }
}
