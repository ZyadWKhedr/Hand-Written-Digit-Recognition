import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/digit_recognition_provider.dart';

/// Minimalist Apple-style prediction header card.
///
/// Automatically updates in real-time as digits are auto-detected.
/// Stateless and strictly under 200 lines.
class PredictionResultCard extends StatelessWidget {
  const PredictionResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DigitRecognitionProvider>();
    final prediction = provider.currentPrediction;
    final isRecognizing = provider.isRecognizing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Large Hero Digit or Placeholder
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: prediction != null
                  ? CupertinoColors.activeBlue.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: isRecognizing
                  ? const CupertinoActivityIndicator(radius: 12)
                  : Text(
                      prediction != null ? '${prediction.digit}' : '—',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: prediction != null ? CupertinoColors.activeBlue : Colors.white24,
                        letterSpacing: -1,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Metadata Description
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeGreen.withValues(alpha: 0.15),
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
                  const SizedBox(height: 4),
                  Text(
                    'Inference: ${(prediction.inferenceTime.inMicroseconds / 1000.0).toStringAsFixed(1)} ms · On-Device',
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
                  const SizedBox(height: 3),
                  Text(
                    'Auto-detects as soon as you pause',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
