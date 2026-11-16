import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/model_metadata_info.dart';
import '../providers/digit_recognition_provider.dart';
import '../widgets/drawing_canvas_widget.dart';
import '../widgets/model_info_sheet.dart';
import '../widgets/prediction_result_card.dart';
import '../widgets/sample_digit_selector.dart';

/// Single-screen, zero-scroll Apple-style interface for on-device handwritten digit recognition.
///
/// Designed specifically for video demonstrations: all controls, predictions,
/// and the enlarged drawing canvas fit seamlessly within a single frame without scrolling.
/// Completely stateless and under 200 lines.
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
          // Apple-style Clear Action
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

          // Educational Model Specs Sheet Trigger
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
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Prediction Header (Digit + Confidence + Latency + 28x28 Preview)
              PredictionResultCard(),
              SizedBox(height: 12),

              // Expanded Responsive Apple Drawing Canvas (Fills center without scrolling)
              Expanded(
                child: DrawingCanvasWidget(),
              ),
              SizedBox(height: 12),

              // Bottom Quick-Select Sample Chips (0 - 9)
              SampleDigitSelector(),
              SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
