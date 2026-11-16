import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/model_metadata_info.dart';
import '../providers/digit_recognition_provider.dart';
import '../widgets/action_toolbar.dart';
import '../widgets/drawing_canvas_widget.dart';
import '../widgets/model_info_sheet.dart';
import '../widgets/prediction_result_card.dart';
import '../widgets/preprocessed_preview_card.dart';
import '../widgets/probabilities_chart.dart';
import '../widgets/sample_digit_selector.dart';

/// Main screen for the On-Device Handwritten Digit Recognition demo.
///
/// Fully stateless widget complying with the architecture rules (< 200 lines).
/// Delegates all state and ML business logic to [DigitRecognitionProvider].
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DigitRecognitionProvider>();
    final theme = Theme.of(context);

    // Auto-initialize ONNX model on first build if uninitialized
    if (provider.status == ModelStatus.uninitialized) {
      Future.microtask(() => provider.initialize());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ONNX Digit Recognition',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Model status indicator pill
          _buildStatusPill(provider.status),
          const SizedBox(width: 8),

          // Educational Model Specs Sheet Trigger
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Model Specifications',
            onPressed: () {
              final meta = provider.metadataInfo ?? ModelMetadataInfo.mnistDefaults();
              ModelInfoSheet.show(context, meta);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Educational Banner
              Text(
                'On-Device Inference Pipeline',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Draw a digit to run local inference with ONNX Runtime.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Interactive Drawing Canvas
              const DrawingCanvasWidget(size: 280),
              const SizedBox(height: 16),

              // Quick Test Sample Chips (0-9)
              const SampleDigitSelector(),
              const SizedBox(height: 16),

              // Action Toolbar (Recognize & Clear)
              const ActionToolbar(),
              const SizedBox(height: 16),

              // Error display if inference or loading failed
              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MaterialBanner(
                    content: Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    actions: [
                      TextButton(
                        onPressed: provider.initialize,
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                ),

              // Prediction Result Card
              const PredictionResultCard(),
              const SizedBox(height: 16),

              // Educational Tensor Input Preview
              const PreprocessedPreviewCard(),
              const SizedBox(height: 16),

              // Softmax Probability Distribution Bar Chart
              const ProbabilitiesChart(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(ModelStatus status) {
    Color color;
    String label;

    switch (status) {
      case ModelStatus.ready:
        color = Colors.green;
        label = 'ONNX Ready';
        break;
      case ModelStatus.loading:
        color = Colors.orange;
        label = 'Loading...';
        break;
      case ModelStatus.error:
        color = Colors.red;
        label = 'Model Error';
        break;
      case ModelStatus.uninitialized:
        color = Colors.grey;
        label = 'Standby';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
