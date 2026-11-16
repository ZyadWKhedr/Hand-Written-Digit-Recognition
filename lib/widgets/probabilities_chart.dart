import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/digit_recognition_provider.dart';

/// Minimalist Apple-style horizontal bar chart displaying Softmax probabilities (0-9).
///
/// Stateless and strictly under 200 lines.
class ProbabilitiesChart extends StatelessWidget {
  const ProbabilitiesChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DigitRecognitionProvider>();
    final prediction = provider.currentPrediction;

    final probabilities = prediction?.probabilities ?? List.filled(10, 0.0);
    final topDigit = prediction?.digit ?? -1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF18181F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.chart_bar_alt_fill,
                size: 16,
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(width: 8),
              const Text(
                'Confidence Breakdown',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              if (prediction != null)
                Text(
                  'Top: ${prediction.digit} (${prediction.confidencePercentage})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(10, (digit) {
            final prob = probabilities[digit];
            final isTop = digit == topDigit;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '$digit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                        color: isTop
                            ? CupertinoColors.activeBlue
                            : Colors.white60,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: prob,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isTop
                              ? CupertinoColors.activeBlue
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${(prob * 100).toStringAsFixed(1)}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                        color: isTop
                            ? CupertinoColors.activeBlue
                            : Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
