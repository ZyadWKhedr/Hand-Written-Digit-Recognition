import 'package:flutter/cupertino.dart';
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
      backgroundColor: const Color(0xFF1C1C24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ModelInfoSheet(metadata: metadata),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(CupertinoIcons.info_circle, size: 20, color: CupertinoColors.activeBlue),
              SizedBox(width: 8),
              Text(
                'ONNX Model Specification',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
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
          const Divider(height: 24, color: Colors.white12),
          const Text(
            'Inference Pipeline:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Raw Canvas → 28x28 Resizing → ITU-R BT.601 Grayscale → '
            'Normalization [0.0, 1.0] → Float32 Tensor [1, 1, 28, 28] → '
            'ONNX Runtime Inference → Softmax Logits → Top Class Prediction.',
            style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white60)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
