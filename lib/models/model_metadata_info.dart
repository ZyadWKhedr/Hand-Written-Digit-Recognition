/// Holds inspected metadata and operational characteristics of the loaded ONNX model.
///
/// Used for educational display so developers can inspect tensor names, shapes,
/// data types, and supported execution providers in real time.
class ModelMetadataInfo {
  final String modelName;
  final String inputName;
  final List<int> inputShape;
  final String inputType;
  final String outputName;
  final List<int> outputShape;
  final String outputType;
  final String executionProvider;
  final int modelSizeBytes;

  const ModelMetadataInfo({
    required this.modelName,
    required this.inputName,
    required this.inputShape,
    required this.inputType,
    required this.outputName,
    required this.outputShape,
    required this.outputType,
    required this.executionProvider,
    required this.modelSizeBytes,
  });

  /// Formatted model size string, e.g. "25.5 KB".
  String get formattedSize {
    final kb = modelSizeBytes / 1024.0;
    return '${kb.toStringAsFixed(1)} KB';
  }

  /// Default metadata for the validated MNIST ONNX model zoo asset.
  factory ModelMetadataInfo.mnistDefaults() {
    return const ModelMetadataInfo(
      modelName: 'mnist-12.onnx',
      inputName: 'Input3',
      inputShape: [1, 1, 28, 28],
      inputType: 'float32',
      outputName: 'Plus214_Output_0',
      outputShape: [1, 10],
      outputType: 'float32',
      executionProvider: 'CPU (Default)',
      modelSizeBytes: 26143,
    );
  }
}
