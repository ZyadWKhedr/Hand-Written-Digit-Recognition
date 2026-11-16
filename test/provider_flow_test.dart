import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:handwritten_digit_recognition/models/digit_prediction.dart';
import 'package:handwritten_digit_recognition/models/model_metadata_info.dart';
import 'package:handwritten_digit_recognition/providers/digit_recognition_provider.dart';
import 'package:handwritten_digit_recognition/services/image_processing_service.dart';
import 'package:handwritten_digit_recognition/services/mnist_classifier.dart';
import 'package:handwritten_digit_recognition/views/home_page.dart';
import 'package:handwritten_digit_recognition/widgets/prediction_result_card.dart';

/// Test double simulating MnistClassifier for deterministic testing without native JNI.
class MockMnistClassifier extends MnistClassifier {
  bool initializedCalled = false;
  int predictCallCount = 0;

  @override
  bool get isInitialized => initializedCalled;

  @override
  ModelMetadataInfo get metadataInfo => ModelMetadataInfo.mnistDefaults();

  @override
  Future<void> initialize() async {
    initializedCalled = true;
  }

  @override
  Future<DigitPrediction> predict(
    List<double> pixels, {
    Duration preprocessingDuration = Duration.zero,
  }) async {
    predictCallCount++;
    // Returns 4 on first segment call, 1 on second segment call, or 5 if called once
    final digit = predictCallCount == 1 ? 4 : 1;
    final probs = [0.01, 0.01, 0.01, 0.01, 0.01, 0.90, 0.02, 0.01, 0.02, 0.01];
    return DigitPrediction(
      digit: digit,
      confidence: 0.94,
      probabilities: probs,
      preprocessingTime: preprocessingDuration,
      inferenceTime: const Duration(milliseconds: 3),
    );
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('Single-digit recognition flow updates UI with digit and inline tensor preview', (tester) async {
    final mockClassifier = MockMnistClassifier();
    final provider = DigitRecognitionProvider(classifier: mockClassifier);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(provider.isModelReady, isTrue);

    // Load sample digit
    await provider.loadSampleDigit(4);
    await tester.pumpAndSettle();

    // Verify prediction card shows digit 4 and 94.0% confidence
    expect(find.byType(PredictionResultCard), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.text('94.0%'), findsWidgets);

    // Verify inline tensor thumbnail is rendered
    expect(find.byType(Image), findsOneWidget);

    // Verify Clear button resets the prediction
    final clearBtn = find.widgetWithText(CupertinoButton, 'Clear');
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Auto-detects as soon as you pause'), findsOneWidget);
  });

  testWidgets('Two-digit recognition flow segments and recognizes 41', (tester) async {
    final mockClassifier = MockMnistClassifier();
    final provider = DigitRecognitionProvider(classifier: mockClassifier);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    // Load two-digit strokes for "41"
    final strokes41 = ImageProcessingService.getTwoDigitSampleStrokes(4, 1);
    for (final s in strokes41) {
      provider.drawingController.startStroke(s.points.first);
      for (int i = 1; i < s.points.length; i++) {
        provider.drawingController.updateStroke(s.points[i]);
      }
      provider.drawingController.endStroke();
    }

    await provider.recognize();
    await tester.pumpAndSettle();

    // Verify prediction card displays "41"
    expect(provider.currentPrediction?.text, equals('41'));
    expect(find.text('41'), findsOneWidget);
    expect(find.text('Number 41'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
