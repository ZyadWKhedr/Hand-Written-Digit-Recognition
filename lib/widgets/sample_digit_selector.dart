import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/digit_recognition_provider.dart';

/// Clean Apple-style horizontal sample chips (0-9).
///
/// Stateless and strictly under 200 lines.
class SampleDigitSelector extends StatelessWidget {
  const SampleDigitSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DigitRecognitionProvider>();
    final isBusy = provider.isRecognizing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'SAMPLE DIGITS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.35),
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                color: const Color(0xFF1B1B22),
                borderRadius: BorderRadius.circular(12),
                onPressed: isBusy ? null : () => provider.loadSampleDigit(index),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
