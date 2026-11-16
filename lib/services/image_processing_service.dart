import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/drawing_stroke.dart';

/// Educational image processing service that converts user canvas drawing strokes
/// into the 28x28 grayscale tensor format required by the MNIST model.
///
/// Implements standard MNIST preprocessing techniques:
/// 1. Stroke rasterization onto an off-screen bitmap canvas.
/// 2. Bounding box detection of the drawn digit.
/// 3. Aspect-ratio preserving scale and centering into a 20x20 bounding box
///    centered within a 28x28 frame (the official MNIST specification).
/// 4. Grayscale luminance extraction and normalization `[0.0, 1.0]`.
class ImageProcessingService {
  static const int targetDimension = 28;

  /// Renders [strokes] into a 28x28 grayscale pixel array [0.0, 1.0] and PNG bytes.
  ///
  /// Returns a record with:
  /// - `pixels`: 784 normalized float values (`[1, 1, 28, 28]` flattened).
  /// - `previewBytes`: PNG encoded 28x28 image bytes for educational UI preview.
  /// - `duration`: Total preprocessing time elapsed.
  Future<({List<double> pixels, Uint8List previewBytes, Duration duration})>
      processStrokesToMnistInput(
    List<DrawingStroke> strokes, {
    double canvasSize = 280.0,
  }) async {
    final stopwatch = Stopwatch()..start();

    // If no strokes were drawn, return all-black background
    if (strokes.isEmpty || strokes.every((s) => s.points.isEmpty)) {
      final blackPixels = List<double>.filled(targetDimension * targetDimension, 0.0);
      final emptyImage = img.Image(width: targetDimension, height: targetDimension);
      img.fill(emptyImage, color: img.ColorRgb8(0, 0, 0));
      final pngBytes = Uint8List.fromList(img.encodePng(emptyImage));
      stopwatch.stop();

      return (
        pixels: blackPixels,
        previewBytes: pngBytes,
        duration: stopwatch.elapsed,
      );
    }

    // 1. Calculate bounding box of all strokes
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      for (final p in stroke.points) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
    }

    // Add margin for stroke width
    const strokeMargin = 16.0;
    minX = math.max(0.0, minX - strokeMargin);
    maxX = math.min(canvasSize, maxX + strokeMargin);
    minY = math.max(0.0, minY - strokeMargin);
    maxY = math.min(canvasSize, maxY + strokeMargin);

    final boxWidth = math.max(1.0, maxX - minX);
    final boxHeight = math.max(1.0, maxY - minY);

    // 2. Rasterize strokes directly into a pure-Dart image canvas
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

    // 4. Crop to bounding box
    final cropped = img.copyCrop(
      fullImage,
      x: minX.toInt(),
      y: minY.toInt(),
      width: boxWidth.toInt(),
      height: boxHeight.toInt(),
    );

    // 5. Fit bounding box into a 20x20 box, maintaining aspect ratio
    const int mnistDigitTarget = 20;
    final scale = mnistDigitTarget / math.max(boxWidth, boxHeight);
    final scaledWidth = math.max(1, (boxWidth * scale).toInt());
    final scaledHeight = math.max(1, (boxHeight * scale).toInt());

    final resizedDigit = img.copyResize(
      cropped,
      width: scaledWidth,
      height: scaledHeight,
      interpolation: img.Interpolation.linear,
    );

    // 6. Create 28x28 black frame and paste centered digit inside (4px margin on all sides)
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

    // 7. Extract normalized pixels [0.0, 1.0]
    final pixels = <double>[];
    for (var y = 0; y < targetDimension; y++) {
      for (var x = 0; x < targetDimension; x++) {
        final pixel = mnistImage.getPixel(x, y);
        // Single channel or RGB grayscale luminance
        final val = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114) / 255.0;
        pixels.add(val.clamp(0.0, 1.0));
      }
    }

    final previewBytes = Uint8List.fromList(img.encodePng(mnistImage));
    stopwatch.stop();

    return (
      pixels: pixels,
      previewBytes: previewBytes,
      duration: stopwatch.elapsed,
    );
  }

  /// Generates predefined stroke coordinates for demo digits (0-9).
  ///
  /// Useful for testing and interactive educational demos.
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
        // Figure 8 shape
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
}
