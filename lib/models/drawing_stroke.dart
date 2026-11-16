import 'package:flutter/material.dart';

/// Represents a continuous touch/mouse stroke on the drawing canvas.
///
/// A collection of strokes forms the handwritten digit drawn by the user.
class DrawingStroke {
  /// The sequence of 2D coordinates that make up the stroke.
  final List<Offset> points;

  /// The stroke width used for drawing this stroke (mimics stroke thickness of MNIST).
  final double strokeWidth;

  /// The color of the stroke. Typically white (`Colors.white`) on a black background
  /// to match MNIST training distribution.
  final Color color;

  DrawingStroke({
    required this.points,
    this.strokeWidth = 18.0,
    this.color = Colors.white,
  });

  /// Creates a copy with optionally modified properties.
  DrawingStroke copyWith({
    List<Offset>? points,
    double? strokeWidth,
    Color? color,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      color: color ?? this.color,
    );
  }
}
