import 'dart:typed_data';

/// Small, normalized visual summary computed from image pixel samples.
class PhotoFeatures {
  PhotoFeatures({
    required this.brightness,
    required this.saturation,
    required this.contrast,
  }) {
    _requireNormalized(brightness, 'brightness');
    _requireNormalized(saturation, 'saturation');
    _requireNormalized(contrast, 'contrast');
  }

  final double brightness;
  final double saturation;
  final double contrast;

  static void _requireNormalized(double value, String name) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw RangeError.value(value, name, 'Must be finite and in [0, 1]');
    }
  }
}

/// *Proposed* human-labeled classes for Track A, pending team approval.
enum SceneCategory { nature, urban, interior, objectCloseup }

class ScenePrediction {
  ScenePrediction({
    required this.category,
    required this.confidence,
    required this.modelVersion,
  }) {
    PhotoFeatures._requireNormalized(confidence, 'confidence');
    if (modelVersion.trim().isEmpty) {
      throw ArgumentError.value(
          modelVersion, 'modelVersion', 'Cannot be empty');
    }
  }

  final SceneCategory category;
  final double confidence;
  final String modelVersion;
}

class PhotoAnalysis {
  const PhotoAnalysis({required this.features, required this.prediction});

  final PhotoFeatures features;
  final ScenePrediction prediction;
}

/// Camera/decoder and trained-model integration belong in separate adapters.
///
/// Caller must validate image size/type and handle permission or model errors.
/// A concrete implementation is intentionally not provided until Track A is
/// trained; this interface does not itself satisfy the course's ML requirement.
abstract class PhotoAnalyzer {
  Future<PhotoAnalysis> analyze(Uint8List encodedImageBytes);
}
