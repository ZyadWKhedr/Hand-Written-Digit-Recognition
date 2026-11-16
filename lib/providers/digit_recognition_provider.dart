import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../controllers/drawing_controller.dart';
import '../models/digit_prediction.dart';
import '../models/model_metadata_info.dart';
import '../services/image_processing_service.dart';
import '../services/mnist_classifier.dart';

/// Current status of the ONNX Runtime model lifecycle.
enum ModelStatus {
  uninitialized,
  loading,
  ready,
  error,
}

/// Central state provider managing ONNX session lifecycle, image preprocessing,
/// on-device inference execution, and UI synchronization.
class DigitRecognitionProvider extends ChangeNotifier {
  final MnistClassifier _classifier;
  final ImageProcessingService _imageService;
  final DrawingController _drawingController;

  ModelStatus _status = ModelStatus.uninitialized;
  String? _errorMessage;
  bool _isRecognizing = false;

  DigitPrediction? _currentPrediction;
  Uint8List? _preprocessedPreviewBytes;
  List<double>? _currentInputTensorPixels;

  DigitRecognitionProvider({
    MnistClassifier? classifier,
    ImageProcessingService? imageService,
    DrawingController? drawingController,
  })  : _classifier = classifier ?? MnistClassifier(),
        _imageService = imageService ?? ImageProcessingService(),
        _drawingController = drawingController ?? DrawingController() {
    // Re-run or notify when drawing changes if needed
    _drawingController.addListener(_onDrawingChanged);
  }

  // --- Getters ---

  ModelStatus get status => _status;
  bool get isModelReady => _status == ModelStatus.ready;
  bool get isLoading => _status == ModelStatus.loading;
  bool get isRecognizing => _isRecognizing;
  String? get errorMessage => _errorMessage;

  DrawingController get drawingController => _drawingController;
  DigitPrediction? get currentPrediction => _currentPrediction;
  Uint8List? get preprocessedPreviewBytes => _preprocessedPreviewBytes;
  List<double>? get currentInputTensorPixels => _currentInputTensorPixels;
  ModelMetadataInfo? get metadataInfo => _classifier.metadataInfo;

  void _onDrawingChanged() {
    // If user cleared the canvas, reset the prediction
    if (_drawingController.isEmpty && _currentPrediction != null) {
      _currentPrediction = null;
      _preprocessedPreviewBytes = null;
      _currentInputTensorPixels = null;
    }
    notifyListeners();
  }

  /// Initializes the ONNX Runtime session and loads the model from assets.
  Future<void> initialize() async {
    if (_status == ModelStatus.loading || _status == ModelStatus.ready) return;

    _status = ModelStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _classifier.initialize();
      _status = ModelStatus.ready;
    } catch (e) {
      _status = ModelStatus.error;
      _errorMessage = 'Failed to load ONNX model: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Converts the canvas strokes into a 28x28 grayscale tensor and runs ONNX inference.
  Future<void> recognize() async {
    if (_status != ModelStatus.ready || _isRecognizing) return;
    if (_drawingController.isEmpty) return;

    _isRecognizing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Preprocess: Rasterize, bound, scale & center into 28x28 normalized pixel tensor
      final processed = await _imageService.processStrokesToMnistInput(
        _drawingController.strokes,
      );

      _currentInputTensorPixels = processed.pixels;
      _preprocessedPreviewBytes = processed.previewBytes;

      // 2. Inference: Execute ONNX Runtime session with [1, 1, 28, 28] tensor
      final prediction = await _classifier.predict(
        processed.pixels,
        preprocessingDuration: processed.duration,
      );

      _currentPrediction = prediction;
    } catch (e) {
      _errorMessage = 'Inference error: $e';
    } finally {
      _isRecognizing = false;
      notifyListeners();
    }
  }

  /// Clears the drawing canvas and discards the active prediction.
  void clear() {
    _drawingController.clear();
    _currentPrediction = null;
    _preprocessedPreviewBytes = null;
    _currentInputTensorPixels = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads a predefined digit sample (0-9) and automatically executes recognition if model is ready.
  Future<void> loadSampleDigit(int digit) async {
    _drawingController.loadSampleDigit(digit);
    if (isModelReady) {
      await recognize();
    }
  }

  @override
  void dispose() {
    _drawingController.removeListener(_onDrawingChanged);
    _drawingController.dispose();
    _classifier.dispose();
    super.dispose();
  }
}
