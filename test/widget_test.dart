import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:handwritten_digit_recognition/main.dart';
import 'package:handwritten_digit_recognition/providers/digit_recognition_provider.dart';
import 'package:handwritten_digit_recognition/widgets/drawing_canvas_widget.dart';
import 'package:handwritten_digit_recognition/widgets/prediction_result_card.dart';

void main() {
  testWidgets('Renders clean zero-scroll interface, draws directly, and auto-detects', (WidgetTester tester) async {
    // Build root app
    await tester.pumpWidget(const HandwrittenDigitApp());
    await tester.pump();

    // Verify AppBar
    expect(find.text('Digit Recognition'), findsOneWidget);

    // Verify Drawing Canvas Widget (expanded spacious drawing area)
    expect(find.byType(DrawingCanvasWidget), findsOneWidget);
    expect(find.text('Write a digit'), findsOneWidget);

    // Verify Sample Digits chips are removed
    expect(find.text('SAMPLE DIGITS'), findsNothing);

    // Verify Prediction Result Card initial state (Ready / auto-detect info)
    expect(find.byType(PredictionResultCard), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Auto-detects as soon as you pause'), findsOneWidget);

    // Draw directly on the canvas with touch gesture
    await tester.drag(find.byType(DrawingCanvasWidget), const Offset(60, 60));
    await tester.pump();

    // After drawing, placeholder hint is gone
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
