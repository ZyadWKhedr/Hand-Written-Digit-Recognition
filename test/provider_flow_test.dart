import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:handwritten_digit_recognition/models/digit_prediction.dart';
import 'package:handwritten_digit_recognition/models/model_metadata_info.dart';
import 'package:handwritten_digit_recognition/providers/digit_recognition_provider.dart';
import 'package:handwritten_digit_recognition/services/mnist_classifier.dart';
import 'package:handwritten_digit_recognition/views/home_page.dart';
import 'package:handwritten_digit_recognition/widgets/prediction_result_card.dart';
import 'package:handwritten_digit_recognition/widgets/probabilities_chart.dart';
import 'package:handwritten_digit_recognition/widgets/preprocessed_preview_card.dart';

/// Test double simulating MnistClassifier for deterministic testing without native JNI.
class MockMnistClassifier extends MnistClassifier {
  bool initializedCalled = false;

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
    final probs = [0.01, 0.01, 0.01, 0.01, 0.01, 0.90, 0.02, 0.01, 0.02, 0.01];
    return DigitPrediction(
      digit: 5,
      confidence: 0.90,
      probabilities: probs,
      preprocessingTime: preprocessingDuration,
      inferenceTime: const Duration(milliseconds: 4),
    );
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('Full recognition flow updates UI with digit 5 and probabilities', (tester) async {
    final mockClassifier = MockMnistClassifier();
    final provider = DigitRecognitionProvider(classifier: mockClassifier);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify ready state
    expect(provider.isModelReady, isTrue);
    expect(find.text('ONNX Ready'), findsOneWidget);

    // Load sample digit 5
    await provider.loadSampleDigit(5);
    await tester.pumpAndSettle();

    // Verify prediction card shows digit 5 and 90.0% confidence
    expect(find.byType(PredictionResultCard), findsOneWidget);
    expect(find.text('5'), findsWidgets); // digit in badge and button
    expect(find.text('Confidence: 90.0%'), findsOneWidget);

    // Verify preview card and probabilities chart are populated
    expect(find.byType(PreprocessedPreviewCard), findsOneWidget);
    expect(find.text('What the Model Sees (Tensor Input)'), findsOneWidget);
    expect(find.byType(ProbabilitiesChart), findsOneWidget);
    expect(find.text('90.0%'), findsOneWidget);

    // Verify Clear button resets the prediction
    final clearBtn = find.widgetWithText(OutlinedButton, 'Clear');
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    expect(find.text('Draw a digit above or tap a sample to run ONNX inference'), findsOneWidget);
  });
}
