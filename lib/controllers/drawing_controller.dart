import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';
import '../services/image_processing_service.dart';

/// Controller encapsulating touch gesture state, stroke point buffering,
/// and canvas drawing operations.
class DrawingController extends ChangeNotifier {
  final List<DrawingStroke> _strokes = [];
  double _strokeWidth = 20.0;
  Color _strokeColor = Colors.white;

  /// Unmodifiable list of completed and active strokes.
  List<DrawingStroke> get strokes => List.unmodifiable(_strokes);

  /// Current stroke thickness used for drawing.
  double get strokeWidth => _strokeWidth;

  /// Stroke color (defaults to white for MNIST contrast).
  Color get strokeColor => _strokeColor;

  /// Whether the drawing canvas has any strokes.
  bool get isEmpty => _strokes.isEmpty || _strokes.every((s) => s.points.isEmpty);

  /// Updates stroke thickness.
  set strokeWidth(double width) {
    if (_strokeWidth != width) {
      _strokeWidth = width;
      notifyListeners();
    }
  }

  /// Begins a new stroke when the user touches down or clicks on the canvas.
  void startStroke(Offset point) {
    _strokes.add(
      DrawingStroke(
        points: [point],
        strokeWidth: _strokeWidth,
        color: _strokeColor,
      ),
    );
    notifyListeners();
  }

  /// Appends a new coordinate to the currently active stroke.
  void updateStroke(Offset point) {
    if (_strokes.isEmpty) {
      startStroke(point);
      return;
    }
    _strokes.last.points.add(point);
    notifyListeners();
  }

  /// Finalizes the current stroke on touch/pointer release.
  void endStroke() {
    notifyListeners();
  }

  /// Clears all strokes from the canvas.
  void clear() {
    if (_strokes.isNotEmpty) {
      _strokes.clear();
      notifyListeners();
    }
  }

  /// Removes the last drawn stroke.
  void undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  /// Loads predefined sample strokes for digit [0-9].
  void loadSampleDigit(int digit, {double size = 280.0}) {
    _strokes.clear();
    _strokes.addAll(ImageProcessingService.getSampleStrokes(digit, size: size));
    notifyListeners();
  }
}
