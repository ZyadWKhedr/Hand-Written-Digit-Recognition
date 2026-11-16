import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:handwritten_digit_recognition/controllers/drawing_controller.dart';
import 'package:handwritten_digit_recognition/models/digit_prediction.dart';
import 'package:handwritten_digit_recognition/models/model_metadata_info.dart';
import 'package:handwritten_digit_recognition/services/image_processing_service.dart';

void main() {
  group('DigitPrediction Model Tests', () {
    test('Calculates confidence percentage and total latency correctly', () {
      final prediction = DigitPrediction(
        digit: 7,
        confidence: 0.9845,
        probabilities: [0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.9845, 0.005, 0.004],
        preprocessingTime: const Duration(milliseconds: 5),
        inferenceTime: const Duration(milliseconds: 3),
      );

      expect(prediction.digit, equals(7));
      expect(prediction.confidencePercentage, equals('98.5%'));
      expect(prediction.totalLatency, equals(const Duration(milliseconds: 8)));
    });
  });

  group('ModelMetadataInfo Tests', () {
    test('Formats model size correctly and loads defaults', () {
      final metadata = ModelMetadataInfo.mnistDefaults();

      expect(metadata.modelName, equals('mnist-12.onnx'));
      expect(metadata.inputShape, equals([1, 1, 28, 28]));
      expect(metadata.outputShape, equals([1, 10]));
      expect(metadata.formattedSize, equals('25.5 KB'));
    });
  });

  group('DrawingController Tests', () {
    test('Records strokes, updates coordinates, undoes, and clears', () {
      final controller = DrawingController();
      expect(controller.isEmpty, isTrue);

      // Start stroke
      controller.startStroke(const Offset(10, 10));
      expect(controller.isEmpty, isFalse);
      expect(controller.strokes.length, equals(1));
      expect(controller.strokes.first.points.length, equals(1));

      // Update stroke
      controller.updateStroke(const Offset(20, 20));
      expect(controller.strokes.first.points.length, equals(2));

      // Start second stroke
      controller.startStroke(const Offset(50, 50));
      expect(controller.strokes.length, equals(2));

      // Undo last stroke
      controller.undo();
      expect(controller.strokes.length, equals(1));

      // Clear
      controller.clear();
      expect(controller.isEmpty, isTrue);
      expect(controller.strokes.isEmpty, isTrue);
    });

    test('Loads predefined sample digits (0-9)', () {
      final controller = DrawingController();

      for (int digit = 0; digit <= 9; digit++) {
        controller.loadSampleDigit(digit);
        expect(controller.isEmpty, isFalse, reason: 'Digit $digit should generate strokes');
        expect(controller.strokes.isNotEmpty, isTrue);
      }
    });
  });

  group('ImageProcessingService Tests', () {
    test('Generates stroke samples with valid coordinates for all digits', () {
      for (int digit = 0; digit <= 9; digit++) {
        final strokes = ImageProcessingService.getSampleStrokes(digit);
        expect(strokes.isNotEmpty, isTrue);
        for (final stroke in strokes) {
          expect(stroke.points.isNotEmpty, isTrue);
          for (final p in stroke.points) {
            expect(p.dx, inInclusiveRange(0.0, 280.0));
            expect(p.dy, inInclusiveRange(0.0, 280.0));
          }
        }
      }
    });

    test('Processes empty strokes into 784 black pixels (0.0)', () async {
      final service = ImageProcessingService();
      final result = await service.processStrokesToMnistInput([]);

      expect(result.pixels.length, equals(784));
      expect(result.pixels.every((p) => p == 0.0), isTrue);
      expect(result.previewBytes.isNotEmpty, isTrue);
    });
  });

  group('Softmax Math Verification', () {
    test('Correctly computes softmax probabilities and argmax', () {
      // Raw logits where index 3 has the highest score
      final logits = [1.2, 0.5, -0.8, 8.4, 0.1, -1.2, 0.0, 2.1, 0.3, 0.2];

      final maxLogit = logits.reduce(math.max);
      final exponentials = logits.map((s) => math.exp(s - maxLogit)).toList();
      final sum = exponentials.reduce((a, b) => a + b);
      final probabilities = exponentials.map((v) => v / sum).toList();

      // Probabilities must sum to 1.0
      final totalProb = probabilities.reduce((a, b) => a + b);
      expect(totalProb, closeTo(1.0, 1e-6));

      // Highest probability must be at index 3
      var bestIndex = 0;
      for (var i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > probabilities[bestIndex]) {
          bestIndex = i;
        }
      }
      expect(bestIndex, equals(3));
      expect(probabilities[3], greaterThan(0.95));
    });
  });
}
