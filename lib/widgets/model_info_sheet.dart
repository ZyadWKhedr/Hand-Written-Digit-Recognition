import 'package:flutter/material.dart';
import '../models/model_metadata_info.dart';

/// Educational modal bottom sheet detailing ONNX model specifications,
/// tensor dimensions, and runtime properties.
class ModelInfoSheet extends StatelessWidget {
  final ModelMetadataInfo metadata;

  const ModelInfoSheet({super.key, required this.metadata});

  static void show(BuildContext context, ModelMetadataInfo metadata) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ModelInfoSheet(metadata: metadata),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 24),
              const SizedBox(width: 8),
              Text(
                'ONNX Model Specification',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Model File', metadata.modelName),
          _buildInfoRow('Model Size', metadata.formattedSize),
          _buildInfoRow('Input Name', metadata.inputName),
          _buildInfoRow('Input Shape', '${metadata.inputShape} (${metadata.inputType})'),
          _buildInfoRow('Output Name', metadata.outputName),
          _buildInfoRow('Output Shape', '${metadata.outputShape} (${metadata.outputType})'),
          _buildInfoRow('Execution Provider', metadata.executionProvider),
          const Divider(height: 24),
          Text(
            'Inference Pipeline:',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Raw Canvas → 28x28 Resizing → ITU-R BT.601 Grayscale → '
            'Normalization [0.0, 1.0] → Float32 Tensor [1, 1, 28, 28] → '
            'ONNX Runtime Inference → Softmax Logits → Top Class Prediction.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
