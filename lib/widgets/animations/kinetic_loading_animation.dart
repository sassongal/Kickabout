import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'dart:math' as math;

/// A premium, high-fidelity kinetic loading animation.
/// Features a rotating tactical ring with scanning pulses and glow effects.
class KineticLoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;

  const KineticLoadingAnimation({
    super.key,
    this.size = 80,
    this.color,
  });

  @override
  State<KineticLoadingAnimation> createState() =>
      _KineticLoadingAnimationState();
}

class _KineticLoadingAnimationState extends State<KineticLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? PremiumColors.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _KineticLoadingPainter(
              progress: _controller.value,
              color: themeColor,
            ),
          );
        },
      ),
    );
  }
}

class _KineticLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _KineticLoadingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw background track (dimmed)
    paint.color = color.withValues(alpha: 0.1);
    canvas.drawCircle(center, radius - 4, paint);

    // Draw rotating segments
    paint.color = color;
    paint.strokeCap = StrokeCap.round;

    final rotation = progress * 2 * math.pi;

    for (int i = 0; i < 3; i++) {
      final startAngle = rotation + (i * 2 * math.pi / 3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 4),
        startAngle,
        0.5,
        false,
        paint,
      );
    }

    // Draw outer "scout" ring
    paint.strokeWidth = 1.0;
    paint.color = color.withValues(alpha: 0.3);
    canvas.drawCircle(center, radius, paint);

    // Draw scanning pulse
    final pulseProgress = (progress * 2) % 1.0;
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: (1.0 - pulseProgress) * 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, (radius - 4) * pulseProgress, pulsePaint);

    // Draw tactical markers
    paint.style = PaintingStyle.fill;
    paint.color = color;
    for (int i = 0; i < 4; i++) {
      final angle = rotation * 0.5 + (i * math.pi / 2);
      final markerOffset = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawCircle(markerOffset, 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _KineticLoadingPainter oldDelegate) => true;
}
