import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/digit_recognition_provider.dart';

/// Minimalist Apple-style compact hero prediction card.
///
/// Displays the detected digit/number (e.g. 41), confidence badge, latency,
/// and the segmented tensor preview thumbnail inline in a single compact row (< 80px tall).
/// Stateless and strictly under 200 lines.
class PredictionResultCard extends StatelessWidget {
  const PredictionResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DigitRecognitionProvider>();
    final prediction = provider.currentPrediction;
    final isRecognizing = provider.isRecognizing;
    final previewBytes = provider.preprocessedPreviewBytes;

    final hasMultipleDigits = prediction != null && prediction.text.length > 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Hero Digit/Number Display
          Container(
            width: hasMultipleDigits ? 56 : 48,
            height: 48,
            decoration: BoxDecoration(
              color: prediction != null
                  ? CupertinoColors.activeBlue.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isRecognizing
                  ? const CupertinoActivityIndicator(radius: 10)
                  : Text(
                      prediction != null ? prediction.text : '—',
                      style: TextStyle(
                        fontSize: hasMultipleDigits ? 22 : 28,
                        fontWeight: FontWeight.w700,
                        color: prediction != null
                            ? CupertinoColors.activeBlue
                            : Colors.white24,
                        letterSpacing: -1,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // Metadata Description (Digit/Number, Confidence %, Latency)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prediction != null) ...[
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          hasMultipleDigits
                              ? 'Number ${prediction.text}'
                              : 'Digit ${prediction.text}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeGreen.withValues(
                            alpha: 0.16,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          prediction.confidencePercentage,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.activeGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(prediction.inferenceTime.inMicroseconds / 1000.0).toStringAsFixed(1)} ms',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ] else ...[
                  Text(
                    isRecognizing ? 'Detecting...' : 'Ready',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Auto-detects as soon as you pause',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Inline Segmented Tensor Thumbnail
          if (previewBytes != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: hasMultipleDigits
                  ? 'Segmented Tensors'
                  : '28x28 Tensor Input',
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  previewBytes,
                  fit: BoxFit.contain,
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
