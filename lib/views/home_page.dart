import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/model_metadata_info.dart';
import '../providers/digit_recognition_provider.dart';
import '../widgets/drawing_canvas_widget.dart';
import '../widgets/model_info_sheet.dart';
import '../widgets/prediction_result_card.dart';
import '../widgets/preprocessed_preview_card.dart';
import '../widgets/probabilities_chart.dart';
import '../widgets/sample_digit_selector.dart';

/// Clean Apple HIG inspired interface for on-device handwritten digit recognition.
///
/// Features auto-detection on stroke completion without manual "Detect Now" buttons.
/// Expanded drawing canvas and minimalist aesthetics. Completely stateless (< 200 lines).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DigitRecognitionProvider>();
    final canClear = !provider.drawingController.isEmpty || provider.currentPrediction != null;

    // Auto-initialize ONNX model on first build if uninitialized
    if (provider.status == ModelStatus.uninitialized) {
      Future.microtask(() => provider.initialize());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Digit Recognition',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        actions: [
          // Apple-style Clear Action Button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: canClear ? provider.clear : null,
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: canClear ? CupertinoColors.activeBlue : Colors.white24,
              ),
            ),
          ),

          // Model Info Trigger
          IconButton(
            icon: const Icon(CupertinoIcons.info_circle, size: 22),
            color: Colors.white70,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Auto-Detection Card
              const PredictionResultCard(),
              const SizedBox(height: 18),

              // Enlarged Responsive Apple Drawing Canvas (Auto-Detects on Pause)
              const DrawingCanvasWidget(),
              const SizedBox(height: 18),

              // Quick Test Sample Chips (0-9)
              const SampleDigitSelector(),
              const SizedBox(height: 18),

              // Educational Tensor Preview (Only shown when active)
              const PreprocessedPreviewCard(),
              if (provider.preprocessedPreviewBytes != null) const SizedBox(height: 16),

              // Softmax Probabilities Breakdown
              const ProbabilitiesChart(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
