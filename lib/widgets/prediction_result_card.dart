import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/digit_recognition_provider.dart';

/// Minimalist Apple-style compact hero prediction card.
///
/// Displays the detected digit, confidence badge, latency, and the 28x28
/// tensor preview inline in a single compact row (< 80px tall).
/// Stateless and strictly under 200 lines.
class PredictionResultCard extends StatelessWidget {
  const PredictionResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DigitRecognitionProvider>();
    final prediction = provider.currentPrediction;
    final isRecognizing = provider.isRecognizing;
    final previewBytes = provider.preprocessedPreviewBytes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Large Hero Digit or Placeholder
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: prediction != null
                  ? CupertinoColors.activeBlue.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: isRecognizing
                  ? const CupertinoActivityIndicator(radius: 11)
                  : Text(
                      prediction != null ? '${prediction.digit}' : '—',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: prediction != null ? CupertinoColors.activeBlue : Colors.white24,
                        letterSpacing: -1,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Metadata Description (Digit, Confidence %, Latency)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prediction != null) ...[
                  Row(
                    children: [
                      Text(
                        'Digit ${prediction.digit}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeGreen.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          prediction.confidencePercentage,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.activeGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${(prediction.inferenceTime.inMicroseconds / 1000.0).toStringAsFixed(1)} ms · On-Device ONNX',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ] else ...[
                  Text(
                    isRecognizing ? 'Detecting...' : 'Ready',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Auto-detects as soon as you pause',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Inline 28x28 Tensor Thumbnail (What the Model Sees)
          if (previewBytes != null) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: '28x28 Tensor Input',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  previewBytes,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
