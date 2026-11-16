import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:handwritten_digit_recognition/main.dart';
import 'package:handwritten_digit_recognition/providers/digit_recognition_provider.dart';
import 'package:handwritten_digit_recognition/widgets/drawing_canvas_widget.dart';
import 'package:handwritten_digit_recognition/widgets/sample_digit_selector.dart';
import 'package:handwritten_digit_recognition/widgets/action_toolbar.dart';
import 'package:handwritten_digit_recognition/widgets/prediction_result_card.dart';

void main() {
  testWidgets('Renders all core widgets and responds to user interactions', (WidgetTester tester) async {
    // Build root app
    await tester.pumpWidget(const HandwrittenDigitApp());
    await tester.pump();

    // Verify AppBar and Header
    expect(find.text('ONNX Digit Recognition'), findsOneWidget);
    expect(find.text('On-Device Inference Pipeline'), findsOneWidget);

    // Verify Drawing Canvas Widget
    expect(find.byType(DrawingCanvasWidget), findsOneWidget);
    expect(find.text('Draw a digit (0 – 9) here'), findsOneWidget);

    // Verify Quick Test Samples
    expect(find.byType(SampleDigitSelector), findsOneWidget);
    expect(find.text('Quick Test Samples:'), findsOneWidget);

    // Verify Action Toolbar
    expect(find.byType(ActionToolbar), findsOneWidget);
    expect(find.text('Recognize Digit'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    // Verify Prediction Result Card initial state
    expect(find.byType(PredictionResultCard), findsOneWidget);
    expect(find.text('Draw a digit above or tap a sample to run ONNX inference'), findsOneWidget);

    // Tap a sample chip (e.g. digit '3')
    final sampleChip = find.widgetWithText(ActionChip, '3');
    expect(sampleChip, findsOneWidget);
    await tester.tap(sampleChip);
    await tester.pump();

    // After loading a sample, hint text should be gone
    expect(find.text('Draw a digit (0 – 9) here'), findsNothing);

    // Tap Clear button
    final clearButton = find.widgetWithText(OutlinedButton, 'Clear');
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pump();

    // After clearing, hint text returns
    expect(find.text('Draw a digit (0 – 9) here'), findsOneWidget);
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
