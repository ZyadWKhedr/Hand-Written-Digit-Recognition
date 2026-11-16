import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drawing_stroke.dart';
import '../providers/digit_recognition_provider.dart';

/// Clean, expanded Apple-style drawing canvas widget.
///
/// Automatically auto-detects digits when the user finishes a stroke.
/// Stateless and strictly under 200 lines.
class DrawingCanvasWidget extends StatelessWidget {
  final double? fixedSize;

  const DrawingCanvasWidget({
    super.key,
    this.fixedSize,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DigitRecognitionProvider>();
    final controller = provider.drawingController;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Expand to fill available width (capped at 420 for tablets/desktop)
        final effectiveSize = fixedSize ?? constraints.maxWidth.clamp(280.0, 420.0);

        return Center(
          child: Container(
            width: effectiveSize,
            height: effectiveSize,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D11),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Touch Drawing Surface with Auto-Detect Hooks
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    provider.onStrokeStarted();
                    controller.startStroke(details.localPosition);
                  },
                  onPanUpdate: (details) {
                    controller.updateStroke(details.localPosition);
                  },
                  onPanEnd: (_) {
                    controller.endStroke();
                    provider.onStrokeEnded();
                  },
                  child: CustomPaint(
                    size: Size(effectiveSize, effectiveSize),
                    painter: _DrawingPainter(strokes: controller.strokes),
                  ),
                ),

                // Subtle Apple-style placeholder
                if (controller.isEmpty)
                  IgnorePointer(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.pencil_outline,
                            size: 44,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Write a digit',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Minimal Floating Undo Pill
                if (!controller.isEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () {
                        controller.undo();
                        provider.onStrokeEnded();
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.arrow_counterclockwise, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Undo',
                            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for rendering smooth white strokes onto the canvas.
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
