import 'package:flutter/material.dart';

/// A custom-painted soccer pitch background with a tactical/premium aesthetic.
class TacticalPitchBackground extends StatelessWidget {
  final Color baseColor;
  final bool isHalfPitch;

  const TacticalPitchBackground({
    super.key,
    this.baseColor = const Color(0xFF388E3C),
    this.isHalfPitch = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PitchPainter(
        color: baseColor.withValues(alpha: 0.1),
        isHalfPitch: isHalfPitch,
      ),
    );
  }
}

class PitchPainter extends CustomPainter {
  final Color color;
  final bool isHalfPitch;

  PitchPainter({required this.color, required this.isHalfPitch});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Offset.zero & size;

    // Draw outer boundary with rounded corners
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      paint,
    );

    // Draw center line or half-way line
    if (!isHalfPitch) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      // Center circle
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width * 0.15,
        paint,
      );
    }

    // Goal areas
    _drawGoalArea(canvas, size, paint, true); // Top
    if (!isHalfPitch) {
      _drawGoalArea(canvas, size, paint, false); // Bottom
    }

    // Corner arcs
    const arcSize = 20.0;
    // Top Left
    canvas.drawArc(
      Rect.fromLTWH(-arcSize, -arcSize, arcSize * 2, arcSize * 2),
      0,
      1.57,
      false,
      paint,
    );
    // Top Right
    canvas.drawArc(
      Rect.fromLTWH(size.width - arcSize, -arcSize, arcSize * 2, arcSize * 2),
      1.57,
      1.57,
      false,
      paint,
    );
  }

  void _drawGoalArea(Canvas canvas, Size size, Paint paint, bool isTop) {
    final boxWidth = size.width * 0.6;
    final boxHeight = size.height * 0.15;
    final x = (size.width - boxWidth) / 2;

    // Large box
    canvas.drawRect(
      Rect.fromLTWH(
          x, isTop ? 0 : size.height - boxHeight, boxWidth, boxHeight),
      paint,
    );

    // Small box
    final sBoxWidth = size.width * 0.3;
    final sBoxHeight = size.height * 0.05;
    final sx = (size.width - sBoxWidth) / 2;
    canvas.drawRect(
      Rect.fromLTWH(
          sx, isTop ? 0 : size.height - sBoxHeight, sBoxWidth, sBoxHeight),
      paint,
    );

    // Penalty spot
    canvas.drawCircle(
      Offset(size.width / 2,
          isTop ? boxHeight * 0.8 : size.height - boxHeight * 0.8),
      2,
      paint..style = PaintingStyle.fill,
    );
    paint.style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
