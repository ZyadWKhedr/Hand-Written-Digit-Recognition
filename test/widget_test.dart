import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:handwritten_digit_recognition/main.dart';
import 'package:handwritten_digit_recognition/providers/digit_recognition_provider.dart';
import 'package:handwritten_digit_recognition/widgets/drawing_canvas_widget.dart';
import 'package:handwritten_digit_recognition/widgets/sample_digit_selector.dart';
import 'package:handwritten_digit_recognition/widgets/prediction_result_card.dart';

void main() {
  testWidgets('Renders Apple-style UI, auto-detects, and responds to interactions', (WidgetTester tester) async {
    // Build root app
    await tester.pumpWidget(const HandwrittenDigitApp());
    await tester.pump();

    // Verify AppBar
    expect(find.text('Digit Recognition'), findsOneWidget);

    // Verify Drawing Canvas Widget (expanded drawing area)
    expect(find.byType(DrawingCanvasWidget), findsOneWidget);
    expect(find.text('Write a digit'), findsOneWidget);

    // Verify Quick Test Samples
    expect(find.byType(SampleDigitSelector), findsOneWidget);
    expect(find.text('SAMPLE DIGITS'), findsOneWidget);

    // Verify Prediction Result Card initial state (Ready / auto-detect info)
    expect(find.byType(PredictionResultCard), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Auto-detects as soon as you pause'), findsOneWidget);

    // Verify no manual "Recognize Digit" button exists
    expect(find.text('Recognize Digit'), findsNothing);

    // Tap a sample chip (e.g. digit '3')
    final sampleChip = find.widgetWithText(CupertinoButton, '3');
    expect(sampleChip, findsOneWidget);
    await tester.ensureVisible(sampleChip);
    await tester.tap(sampleChip);
    await tester.pump();

    // After loading a sample, hint placeholder is gone
    expect(find.text('Write a digit'), findsNothing);

    // Tap Clear action button in AppBar
    final clearButton = find.widgetWithText(CupertinoButton, 'Clear');
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pump();

    // After clearing, hint returns
    expect(find.text('Write a digit'), findsOneWidget);
  });

  testWidgets('Model info modal sheet displays ONNX specifications', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => DigitRecognitionProvider(),
        child: const MaterialApp(home: HandwrittenDigitApp()),
      ),
    );
    await tester.pump();

    // Find and tap the info button in AppBar
    final infoButton = find.byTooltip('Model Specifications');
    expect(infoButton, findsOneWidget);
    await tester.tap(infoButton);
    await tester.pumpAndSettle();

    // Verify Model Specification Modal contents
    expect(find.text('ONNX Model Specification'), findsOneWidget);
    expect(find.text('mnist-12.onnx'), findsOneWidget);
    expect(find.text('Input Shape'), findsOneWidget);
    expect(find.text('Output Shape'), findsOneWidget);
  });
}
