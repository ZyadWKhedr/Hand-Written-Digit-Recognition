/// Represents the result of running handwritten digit recognition on an image.
///
/// Contains the most likely digit (0-9), its probability/confidence score,
/// the full probability distribution across all 10 digit classes, and execution
/// metrics (latency) for benchmarking on-device performance.
class DigitPrediction {
  /// The predicted digit class, from 0 through 9.
  final int digit;

  /// The confidence score of the prediction, ranging from 0.0 (0%) to 1.0 (100%).
  /// This is calculated by applying the Softmax function over raw model logits.
  final double confidence;

  /// Probability distribution across all 10 classes (index 0 corresponds to digit 0,
  /// index 9 corresponds to digit 9). All probabilities sum to 1.0.
  final List<double> probabilities;

  /// Time spent in the preprocessing stage (resizing, grayscale conversion, normalization).
  final Duration preprocessingTime;

  /// Time spent executing inference inside the ONNX Runtime engine.
  final Duration inferenceTime;

  const DigitPrediction({
    required this.digit,
    required this.confidence,
    required this.probabilities,
    required this.preprocessingTime,
    required this.inferenceTime,
  });

  /// Total round-trip pipeline duration (preprocessing + model inference).
  Duration get totalLatency => preprocessingTime + inferenceTime;

  /// Formatted confidence percentage string, e.g. "98.4%".
  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
}
