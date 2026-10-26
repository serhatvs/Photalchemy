import 'dart:typed_data';

/// Photo statistics only. Card generation does not require a learned image model.
class PhotoFeatures {
  PhotoFeatures({
    required this.brightness,
    required this.saturation,
    required this.contrast,
  }) {
    for (final value in [brightness, saturation, contrast]) {
      if (!value.isFinite || value < 0 || value > 1) {
        throw RangeError.value(value, 'photo feature', 'Expected [0, 1]');
      }
    }
  }

  final double brightness;
  final double saturation;
  final double contrast;
}

/// An adapter will decode the encoded photo and compute color statistics.
/// Camera/file decoding, validation and permissions are NOT implemented here.
abstract class PhotoAnalyzer {
  Future<PhotoFeatures> analyze(Uint8List encodedImageBytes);
}
