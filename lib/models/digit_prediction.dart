/// Represents the result of running handwritten digit recognition on an image.
///
/// Supports both single digits (0-9) and multi-digit numbers (e.g. 41).
/// Contains the recognized text, confidence score, class probability distribution,
/// and latency metrics for on-device performance benchmarking.
class DigitPrediction {
  /// The primary or first predicted digit class (0 through 9).
  final int digit;

  /// The recognized number as a string, supporting multi-digit numbers e.g. "41".
  final String text;

  /// Individual digits recognized in left-to-right order, e.g. [4, 1].
  final List<int> digits;

  /// Overall confidence score of the prediction, ranging from 0.0 (0%) to 1.0 (100%).
  final double confidence;

  /// Probability distribution across all 10 classes for the primary digit.
  final List<double> probabilities;

  /// Individual sub-predictions for each segmented digit.
  final List<DigitPrediction> segments;

  /// Time spent in the preprocessing stage (resizing, grayscale conversion, normalization).
  final Duration preprocessingTime;

  /// Time spent executing inference inside the ONNX Runtime engine.
  final Duration inferenceTime;

  const DigitPrediction({
    required this.digit,
    String? text,
    List<int>? digits,
    required this.confidence,
    required this.probabilities,
    this.segments = const [],
    required this.preprocessingTime,
    required this.inferenceTime,
  })  : text = text ?? '$digit',
        digits = digits ?? const [];

  /// Total round-trip pipeline duration (preprocessing + model inference).
  Duration get totalLatency => preprocessingTime + inferenceTime;

  /// Formatted confidence percentage string, e.g. "98.4%".
  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
}
