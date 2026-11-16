import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as img;

import '../models/drawing_stroke.dart';

/// Educational image processing service that converts user canvas drawing strokes
/// into the 28x28 grayscale tensor format required by the MNIST model.
///
/// Supports both single digits (0-9) and multi-digit segmentation (e.g. 41).
class ImageProcessingService {
  static const int targetDimension = 28;

  /// Legacy single-digit processor for backwards compatibility.
  Future<({List<double> pixels, Uint8List previewBytes, Duration duration})>
      processStrokesToMnistInput(
    List<DrawingStroke> strokes, {
    double canvasSize = 280.0,
  }) async {
    final result = await processStrokesToMultiDigitInputs(strokes, canvasSize: canvasSize);
    return (
      pixels: result.digitsPixels.first,
      previewBytes: result.previewBytes,
      duration: result.duration,
    );
  }

  /// Processes and segments [strokes] into one or multiple 28x28 digit tensors.
  ///
  /// For multi-digit inputs (e.g. "41"), detects the horizontal separation between
  /// digits, crops each digit independently, scales each to fit a 20x20 box inside
  /// a 28x28 frame, and returns a list of normalized 784-float tensors.
  Future<({List<List<double>> digitsPixels, Uint8List previewBytes, Duration duration})>
      processStrokesToMultiDigitInputs(
    List<DrawingStroke> strokes, {
    double canvasSize = 280.0,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (strokes.isEmpty || strokes.every((s) => s.points.isEmpty)) {
      final blackPixels = List<double>.filled(targetDimension * targetDimension, 0.0);
      final emptyImage = img.Image(width: targetDimension, height: targetDimension);
      img.fill(emptyImage, color: img.ColorRgb8(0, 0, 0));
      stopwatch.stop();

      return (
        digitsPixels: [blackPixels],
        previewBytes: Uint8List.fromList(img.encodePng(emptyImage)),
        duration: stopwatch.elapsed,
      );
    }

    // 1. Rasterize all strokes onto an off-screen bitmap
    final fullImage = img.Image(
      width: canvasSize.toInt(),
      height: canvasSize.toInt(),
      numChannels: 1,
    );
    img.fill(fullImage, color: img.ColorRgb8(0, 0, 0));

    final whiteColor = img.ColorRgb8(255, 255, 255);
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final radius = (stroke.strokeWidth / 2.0).round();

      for (int i = 0; i < stroke.points.length; i++) {
        final p = stroke.points[i];
        img.fillCircle(
          fullImage,
          x: p.dx.toInt(),
          y: p.dy.toInt(),
          radius: radius,
          color: whiteColor,
        );
        if (i > 0) {
          final prev = stroke.points[i - 1];
          img.drawLine(
            fullImage,
            x1: prev.dx.toInt(),
            y1: prev.dy.toInt(),
            x2: p.dx.toInt(),
            y2: p.dy.toInt(),
            color: whiteColor,
            thickness: stroke.strokeWidth,
          );
        }
      }
    }

    // 2. Compute horizontal density projection (column pixel sums)
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    final columnCounts = List<int>.filled(canvasSize.toInt(), 0);
    for (var x = 0; x < canvasSize.toInt(); x++) {
      var count = 0;
      for (var y = 0; y < canvasSize.toInt(); y++) {
        final p = fullImage.getPixel(x, y);
        if (p.r > 20) {
          count++;
          if (x < minX) minX = x.toDouble();
          if (x > maxX) maxX = x.toDouble();
          if (y < minY) minY = y.toDouble();
          if (y > maxY) maxY = y.toDouble();
        }
      }
      columnCounts[x] = count;
    }

    if (minX.isInfinite) {
      final blackPixels = List<double>.filled(targetDimension * targetDimension, 0.0);
      final emptyImage = img.Image(width: targetDimension, height: targetDimension);
      img.fill(emptyImage, color: img.ColorRgb8(0, 0, 0));
      stopwatch.stop();

      return (
        digitsPixels: [blackPixels],
        previewBytes: Uint8List.fromList(img.encodePng(emptyImage)),
        duration: stopwatch.elapsed,
      );
    }

    final totalWidth = maxX - minX + 1;
    final totalHeight = maxY - minY + 1;

    // 3. Multi-digit segmentation: Detect vertical split valley between digits
    int? splitX;
    if (totalWidth >= 28 && totalWidth >= totalHeight * 0.70) {
      final searchStart = (minX + totalWidth * 0.20).toInt();
      final searchEnd = (maxX - totalWidth * 0.20).toInt();

      var minVal = 999999;
      int bestX = searchStart;

      for (var x = searchStart; x <= searchEnd; x++) {
        final val = columnCounts[x];
        if (val < minVal) {
          minVal = val;
          bestX = x;
        }
      }

      final maxPeak = columnCounts.sublist(minX.toInt(), maxX.toInt() + 1).reduce(math.max);
      if (minVal == 0 || (minVal <= maxPeak * 0.25 && totalWidth >= totalHeight * 0.85)) {
        // Find center of valley
        int gapStart = bestX;
        while (gapStart > searchStart && columnCounts[gapStart - 1] == minVal) {
          gapStart--;
        }
        int gapEnd = bestX;
        while (gapEnd < searchEnd && columnCounts[gapEnd + 1] == minVal) {
          gapEnd++;
        }
        splitX = (gapStart + gapEnd) ~/ 2;
      }
    }

    // 4. Extract individual digit tensors
    if (splitX != null) {
      // Two-digit segmentation (e.g. "41")
      final digit1 = _extractDigitSegment(fullImage, minX.toInt(), splitX);
      final digit2 = _extractDigitSegment(fullImage, splitX, maxX.toInt());

      if (digit1 != null && digit2 != null) {
        final mnist1 = _fitToMnist(digit1);
        final mnist2 = _fitToMnist(digit2);

        // Composite dual 28x28 preview side-by-side with separator
        final combinedPreview = img.Image(width: targetDimension * 2 + 2, height: targetDimension);
        img.fill(combinedPreview, color: img.ColorRgb8(0, 0, 0));
        img.compositeImage(combinedPreview, mnist1.mnistImage, dstX: 0, dstY: 0);

        // Thin separator line
        img.drawLine(
          combinedPreview,
          x1: targetDimension,
          y1: 2,
          x2: targetDimension,
          y2: targetDimension - 3,
          color: img.ColorRgb8(70, 70, 90),
        );

        img.compositeImage(combinedPreview, mnist2.mnistImage, dstX: targetDimension + 2, dstY: 0);

        stopwatch.stop();
        return (
          digitsPixels: [mnist1.pixels, mnist2.pixels],
          previewBytes: Uint8List.fromList(img.encodePng(combinedPreview)),
          duration: stopwatch.elapsed,
        );
      }
    }

    // Single-digit fallback
    final singleDigit = _extractDigitSegment(fullImage, minX.toInt(), maxX.toInt());
    final mnist = _fitToMnist(singleDigit ?? fullImage);
    stopwatch.stop();

    return (
      digitsPixels: [mnist.pixels],
      previewBytes: Uint8List.fromList(img.encodePng(mnist.mnistImage)),
      duration: stopwatch.elapsed,
    );
  }

  /// Extracts tightly bounded crop within horizontal columns [xStart] to [xEnd].
  img.Image? _extractDigitSegment(img.Image src, int xStart, int xEnd) {
    int sMinX = xEnd;
    int sMaxX = xStart;
    int sMinY = src.height;
    int sMaxY = 0;
    bool found = false;

    for (int x = xStart; x <= xEnd; x++) {
      for (int y = 0; y < src.height; y++) {
        if (src.getPixel(x, y).r > 20) {
          found = true;
          if (x < sMinX) sMinX = x;
          if (x > sMaxX) sMaxX = x;
          if (y < sMinY) sMinY = y;
          if (y > sMaxY) sMaxY = y;
        }
      }
    }

    if (!found) return null;

    final width = math.max(1, sMaxX - sMinX + 1);
    final height = math.max(1, sMaxY - sMinY + 1);

    return img.copyCrop(src, x: sMinX, y: sMinY, width: width, height: height);
  }

  /// Centers and scales a cropped digit into the MNIST 20x20 in 28x28 box format.
  ({List<double> pixels, img.Image mnistImage}) _fitToMnist(img.Image cropped) {
    const int mnistDigitTarget = 20;
    final boxWidth = cropped.width;
    final boxHeight = cropped.height;

    final scale = mnistDigitTarget / math.max(boxWidth, boxHeight);
    final scaledWidth = math.max(1, (boxWidth * scale).toInt());
    final scaledHeight = math.max(1, (boxHeight * scale).toInt());

    final resizedDigit = img.copyResize(
      cropped,
      width: scaledWidth,
      height: scaledHeight,
      interpolation: img.Interpolation.linear,
    );

    final mnistImage = img.Image(
      width: targetDimension,
      height: targetDimension,
      numChannels: 1,
    );
    img.fill(mnistImage, color: img.ColorRgb8(0, 0, 0));

    final offsetX = (targetDimension - scaledWidth) ~/ 2;
    final offsetY = (targetDimension - scaledHeight) ~/ 2;

    img.compositeImage(
      mnistImage,
      resizedDigit,
      dstX: offsetX,
      dstY: offsetY,
    );

    final pixels = <double>[];
    for (var y = 0; y < targetDimension; y++) {
      for (var x = 0; x < targetDimension; x++) {
        final pixel = mnistImage.getPixel(x, y);
        final val = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114) / 255.0;
        pixels.add(val.clamp(0.0, 1.0));
      }
    }

    return (pixels: pixels, mnistImage: mnistImage);
  }

  /// Generates predefined stroke coordinates for demo digits (0-9).
  static List<DrawingStroke> getSampleStrokes(int digit, {double size = 280.0}) {
    final c = size / 2;
    final r = size * 0.32;

    switch (digit) {
      case 0:
        final points = <Offset>[];
        for (var angle = 0.0; angle <= 360.0; angle += 10.0) {
          final rad = angle * math.pi / 180.0;
          points.add(Offset(c + r * 0.7 * math.cos(rad), c + r * math.sin(rad)));
        }
        return [DrawingStroke(points: points, strokeWidth: 20.0)];

      case 1:
        return [
          DrawingStroke(
            points: [
              Offset(c - 20, c - r + 30),
              Offset(c, c - r),
              Offset(c, c + r),
            ],
            strokeWidth: 20.0,
          ),
          DrawingStroke(
            points: [Offset(c - 40, c + r), Offset(c + 40, c + r)],
            strokeWidth: 20.0,
          ),
        ];

      case 2:
        return [
          DrawingStroke(
            points: [
              Offset(c - r * 0.6, c - r + 20),
              Offset(c - r * 0.3, c - r),
              Offset(c + r * 0.4, c - r),
              Offset(c + r * 0.6, c - r + 30),
              Offset(c + r * 0.4, c - 10),
              Offset(c - r * 0.6, c + r),
              Offset(c + r * 0.6, c + r),
            ],
            strokeWidth: 20.0,
          ),
        ];

      case 3:
        return [
          DrawingStroke(
            points: [
              Offset(c - r * 0.6, c - r),
              Offset(c + r * 0.5, c - r),
              Offset(c + 10, c - 10),
              Offset(c + r * 0.6, c + 15),
              Offset(c + r * 0.4, c + r),
              Offset(c - r * 0.6, c + r - 10),
            ],
            strokeWidth: 20.0,
          ),
        ];

      case 4:
        return [
          DrawingStroke(
            points: [
              Offset(c + 30, c - r),
              Offset(c - r * 0.6, c + 10),
              Offset(c + r * 0.6, c + 10),
            ],
            strokeWidth: 20.0,
          ),
          DrawingStroke(
            points: [Offset(c + 30, c - 40), Offset(c + 30, c + r)],
            strokeWidth: 20.0,
          ),
        ];

      case 5:
        return [
          DrawingStroke(
            points: [
              Offset(c + r * 0.5, c - r),
              Offset(c - r * 0.4, c - r),
              Offset(c - r * 0.5, c - 10),
              Offset(c + r * 0.5, c - 5),
              Offset(c + r * 0.6, c + 40),
              Offset(c - r * 0.5, c + r),
            ],
            strokeWidth: 20.0,
          ),
        ];

      case 6:
        return [
          DrawingStroke(
            points: [
              Offset(c + r * 0.4, c - r + 20),
              Offset(c - r * 0.5, c - 20),
              Offset(c - r * 0.6, c + 30),
              Offset(c, c + r),
              Offset(c + r * 0.5, c + 30),
              Offset(c, c),
              Offset(c - r * 0.6, c + 20),
            ],
            strokeWidth: 20.0,
          ),
        ];

      case 7:
        return [
          DrawingStroke(
            points: [
              Offset(c - r * 0.6, c - r),
              Offset(c + r * 0.6, c - r),
              Offset(c - 10, c + r),
            ],
            strokeWidth: 20.0,
          ),
        ];

      case 8:
        final points = <Offset>[];
        for (var angle = -90.0; angle <= 270.0; angle += 15.0) {
          final rad = angle * math.pi / 180.0;
          final topY = c - r * 0.5;
          points.add(Offset(c + r * 0.45 * math.cos(rad), topY + r * 0.45 * math.sin(rad)));
        }
        for (var angle = 90.0; angle <= 450.0; angle += 15.0) {
          final rad = angle * math.pi / 180.0;
          final bottomY = c + r * 0.5;
          points.add(Offset(c + r * 0.55 * math.cos(rad), bottomY + r * 0.55 * math.sin(rad)));
        }
        return [DrawingStroke(points: points, strokeWidth: 20.0)];

      case 9:
        return [
          DrawingStroke(
            points: [
              Offset(c + r * 0.5, c),
              Offset(c - r * 0.4, c - 10),
              Offset(c - r * 0.4, c - r + 30),
              Offset(c + r * 0.4, c - r + 10),
              Offset(c + r * 0.5, c + r),
            ],
            strokeWidth: 20.0,
          ),
        ];

      default:
        return [];
    }
  }

  /// Generates a two-digit sample (e.g. 41) for testing multi-digit segmentation.
  static List<DrawingStroke> getTwoDigitSampleStrokes(int digit1, int digit2, {double size = 280.0}) {
    final s1 = getSampleStrokes(digit1, size: size * 0.55);
    final s2 = getSampleStrokes(digit2, size: size * 0.55);

    final combined = <DrawingStroke>[];
    for (final s in s1) {
      combined.add(
        DrawingStroke(
          points: s.points.map((p) => Offset(p.dx + size * 0.05, p.dy + size * 0.22)).toList(),
          strokeWidth: s.strokeWidth * 0.8,
        ),
      );
    }
    for (final s in s2) {
      combined.add(
        DrawingStroke(
          points: s.points.map((p) => Offset(p.dx + size * 0.48, p.dy + size * 0.22)).toList(),
          strokeWidth: s.strokeWidth * 0.8,
        ),
      );
    }
    return combined;
  }
}
