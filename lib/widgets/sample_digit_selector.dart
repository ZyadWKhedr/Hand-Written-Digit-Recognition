import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/digit_recognition_provider.dart';

/// Stateless widget rendering horizontal quick-select chips for testing digits 0 through 9.
class SampleDigitSelector extends StatelessWidget {
  const SampleDigitSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DigitRecognitionProvider>();
    final isBusy = provider.isRecognizing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Quick Test Samples:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ActionChip(
                label: Text(
                  '$index',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: isBusy ? null : () => provider.loadSampleDigit(index),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ],
    );
  }
}
