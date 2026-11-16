import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

import '../models/digit_prediction.dart';
import '../models/model_metadata_info.dart';

/// Service responsible for loading the ONNX MNIST model, preparing input tensors,
/// executing on-device inference using ONNX Runtime, and post-processing the output.
///
/// ### Educational Pipeline Overview:
/// 1. **Asset Loading**: Bundled `.onnx` model file extracted to disk and loaded into an [OrtSession].
/// 2. **Preprocessing**: Image bytes decoded, resized to 28x28, converted to grayscale, and normalized [0.0, 1.0].
/// 3. **Tensor Construction**: Flattened 784 float values formatted into an [OrtValue] with shape `[1, 1, 28, 28]`.
/// 4. **Inference Execution**: [OrtSession.run] invoked with named input tensors.
/// 5. **Postprocessing**: Softmax applied over output logits to produce normalized probabilities.
/// 6. **Resource Cleanup**: Native tensor memory explicitly freed via [OrtValue.dispose].
class MnistClassifier {
  static const String modelAssetPath = 'assets/models/mnist-12.onnx';
  static const int inputDimension = 28;
  static const int totalPixelCount = inputDimension * inputDimension; // 784

  final OnnxRuntime _runtime = OnnxRuntime();
  OrtSession? _session;
  ModelMetadataInfo? _metadataInfo;

  /// Whether the ONNX session is loaded and ready for inference.
  bool get isInitialized => _session != null;

  /// Inspected model metadata retrieved after initialization.
  ModelMetadataInfo? get metadataInfo => _metadataInfo;

  /// Initializes the ONNX Runtime inference session from the asset bundle.
  ///
  /// Reuses a single inference session across all predictions to avoid
  /// the heavy overhead of re-parsing the ONNX computational graph.
  Future<void> initialize() async {
    if (_session != null) return;

    try {
      _session = await _runtime.createSessionFromAsset(modelAssetPath);

      // Extract model metadata for educational inspection
      final inputNames = _session!.inputNames;
      final outputNames = _session!.outputNames;

      _metadataInfo = ModelMetadataInfo(
        modelName: 'mnist-12.onnx',
        inputName: inputNames.isNotEmpty ? inputNames.first : 'Input3',
        inputShape: const [1, 1, 28, 28],
        inputType: 'float32',
        outputName: outputNames.isNotEmpty ? outputNames.first : 'Plus214_Output_0',
        outputShape: const [1, 10],
        outputType: 'float32',
        executionProvider: 'CPU Execution Provider',
        modelSizeBytes: 26143,
      );
    } catch (e) {
      _session = null;
      rethrow;
    }
  }

  /// Transforms raw image bytes into the normalized float list required by the model.
  ///
  /// Steps:
  /// - Decodes PNG/JPEG bytes into an [img.Image] object.
  /// - Resizes the image to 28 x 28 pixels using bilinear interpolation.
  /// - Converts RGB color channels to single-channel luminance (Grayscale):
  ///   `Luminance = 0.299*R + 0.587*G + 0.114*B`
  /// - Normalizes pixel range from `[0, 255]` integers to `[0.0, 1.0]` floats.
  ///
  /// Throws an [Exception] if the image cannot be decoded.
  Future<List<double>> preprocess(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Could not decode input image bytes');
    }

    final resized = img.copyResize(
      decoded,
      width: inputDimension,
      height: inputDimension,
      interpolation: img.Interpolation.linear,
    );

    final pixels = <double>[];
    for (var y = 0; y < inputDimension; y++) {
      for (var x = 0; x < inputDimension; x++) {
        final pixel = resized.getPixel(x, y);

        // Standard ITU-R BT.601 formula for relative luminance
        final grayscale = (
          0.299 * pixel.r +
          0.587 * pixel.g +
          0.114 * pixel.b
        ) / 255.0;

        pixels.add(grayscale.toDouble());
      }
    }

    return pixels;
  }

  /// Runs on-device inference using the loaded ONNX model.
  ///
  /// Expects exactly 784 normalized float values corresponding to the 28x28 image.
  /// Applies numerically stable Softmax to the 10 output logits to return confidence scores.
  ///
  /// **Resource Management**: Automatically disposes of input and output [OrtValue]
  /// native pointers inside a `finally` block to prevent native memory leaks.
  Future<DigitPrediction> predict(
    List<double> pixels, {
    Duration preprocessingDuration = Duration.zero,
  }) async {
    final session = _session;
    if (session == null) {
      throw StateError('MnistClassifier has not been initialized. Call initialize() first.');
    }

    if (pixels.length != totalPixelCount) {
      throw ArgumentError(
        'Expected exactly $totalPixelCount pixel values (28x28), but received ${pixels.length}',
      );
    }

    // 1. Construct the input tensor: Shape [1, 1, 28, 28] = [batch, channel, height, width]
    final inputTensor = await OrtValue.fromList(
      Float32List.fromList(pixels),
      [1, 1, inputDimension, inputDimension],
    );

    Map<String, OrtValue>? outputs;
    final inferenceStopwatch = Stopwatch()..start();

    try {
      // 2. Execute inference through ONNX Runtime
      outputs = await session.run({
        session.inputNames.first: inputTensor,
      });

      inferenceStopwatch.stop();

      // 3. Extract output tensor and flatten raw logits
      final outputTensor = outputs[session.outputNames.first]!;
      final rawList = await outputTensor.asFlattenedList();
      final scores = rawList.map((value) => (value as num).toDouble()).toList();

      // 4. Compute Softmax with max-subtraction to avoid numeric overflow:
      //    P(i) = exp(s_i - max(s)) / sum(exp(s_j - max(s)))
      final maxScore = scores.reduce(math.max);
      final exponentials = scores
          .map((score) => math.exp(score - maxScore))
          .toList();
      final sum = exponentials.reduce((a, b) => a + b);
      final probabilities = exponentials
          .map((value) => value / sum)
          .toList();

      // 5. Select the class with the maximum probability (ArgMax)
      var bestIndex = 0;
      for (var i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > probabilities[bestIndex]) {
          bestIndex = i;
        }
      }

      return DigitPrediction(
        digit: bestIndex,
        confidence: probabilities[bestIndex],
        probabilities: probabilities,
        preprocessingTime: preprocessingDuration,
        inferenceTime: inferenceStopwatch.elapsed,
      );
    } finally {
      // 6. Native memory cleanup: Always release OrtValue tensors
      await inputTensor.dispose();
      if (outputs != null) {
        for (final output in outputs.values) {
          await output.dispose();
        }
      }
    }
  }

  /// Closes the ONNX Runtime session and releases all associated native resources.
  Future<void> dispose() async {
    await _session?.close();
    _session = null;
    _metadataInfo = null;
  }
}
