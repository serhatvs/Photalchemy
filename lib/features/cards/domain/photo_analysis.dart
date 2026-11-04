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

  factory PhotoFeatures.fromJson(Map<String, dynamic> json) {
    final b = (json['brightness'] as num?)?.toDouble();
    final s = (json['saturation'] as num?)?.toDouble();
    final c = (json['contrast'] as num?)?.toDouble();

    if (b == null || s == null || c == null) {
      throw const FormatException('Missing required photo feature keys');
    }
    return PhotoFeatures(brightness: b, saturation: s, contrast: c);
  }

  final double brightness;
  final double saturation;
  final double contrast;

  Map<String, dynamic> toJson() => {
        'brightness': brightness,
        'saturation': saturation,
        'contrast': contrast,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoFeatures &&
          runtimeType == other.runtimeType &&
          brightness == other.brightness &&
          saturation == other.saturation &&
          contrast == other.contrast;

  @override
  int get hashCode => Object.hash(brightness, saturation, contrast);

  @override
  String toString() =>
      'PhotoFeatures(brightness: ${brightness.toStringAsFixed(3)}, '
      'saturation: ${saturation.toStringAsFixed(3)}, '
      'contrast: ${contrast.toStringAsFixed(3)})';
}

/// An adapter will decode the encoded photo and compute color statistics.
/// Camera/file decoding, validation and permissions are NOT implemented here.
abstract class PhotoAnalyzer {
  Future<PhotoFeatures> analyze(Uint8List encodedImageBytes);
}
