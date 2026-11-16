import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drawing_stroke.dart';
import '../providers/digit_recognition_provider.dart';

/// Stateless widget providing an interactive touch/mouse canvas for handwriting digits.
///
/// Draws on a high-contrast black background with white strokes to match the MNIST
/// training distribution ([0.0 = black, 1.0 = white]).
class DrawingCanvasWidget extends StatelessWidget {
  final double size;

  const DrawingCanvasWidget({
    super.key,
    this.size = 280.0,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DigitRecognitionProvider>();
    final controller = provider.drawingController;

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Interactive touch surface
            GestureDetector(
              onPanStart: (details) => controller.startStroke(details.localPosition),
              onPanUpdate: (details) => controller.updateStroke(details.localPosition),
              onPanEnd: (_) => controller.endStroke(),
              child: CustomPaint(
                size: Size(size, size),
                painter: _DrawingPainter(strokes: controller.strokes),
              ),
            ),

            // Hint label when canvas is untouched
            if (controller.isEmpty)
              IgnorePointer(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.draw_outlined,
                        size: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Draw a digit (0 – 9) here',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Canvas action buttons (Undo & Clear)
            if (!controller.isEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.undo, size: 18),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Undo last stroke',
                      onPressed: controller.undo,
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.clear, size: 18),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Clear canvas',
                      onPressed: provider.clear,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for rendering list of [DrawingStroke]s onto the canvas.
class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  _DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < stroke.points.length; i++) {
        if (i == 0) {
          path.moveTo(stroke.points[i].dx, stroke.points[i].dy);
        } else {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
