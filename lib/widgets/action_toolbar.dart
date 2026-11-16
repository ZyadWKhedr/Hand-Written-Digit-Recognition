import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/digit_recognition_provider.dart';

/// Stateless toolbar containing primary recognition and canvas control buttons.
class ActionToolbar extends StatelessWidget {
  const ActionToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DigitRecognitionProvider>();
    final isBusy = provider.isRecognizing || !provider.isModelReady;
    final canRecognize = !provider.drawingController.isEmpty && !isBusy;

    return Row(
      children: [
        // Primary Recognize Action
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            icon: provider.isRecognizing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.psychology_outlined),
            label: Text(
              provider.isRecognizing ? 'Running Inference...' : 'Recognize Digit',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: canRecognize ? () => provider.recognize() : null,
          ),
        ),
        const SizedBox(width: 12),

        // Clear Canvas Action
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Clear'),
            onPressed: provider.drawingController.isEmpty && provider.currentPrediction == null
                ? null
                : () => provider.clear(),
          ),
        ),
      ],
    );
  }
}
