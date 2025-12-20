import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Premium Stats Ring component with high-fidelity gradients
/// Shows a circular progress indicator with value and label
class StatsRing extends StatefulWidget {
  final int value;
  final int maxValue;
  final String label;
  final double size;
  final Color color;
  final bool useGradient;

  const StatsRing({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    this.size = 80,
    this.color = const Color(0xFF1976D2), // Primary blue
    this.useGradient = true,
  });

  @override
  State<StatsRing> createState() => _StatsRingState();
}

class _StatsRingState extends State<StatsRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final percentage = (widget.value / widget.maxValue).clamp(0.0, 1.0);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Smoother, longer animation
    );

    _animation = Tween<double>(begin: 0, end: percentage).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubicEmphasized, // Premium ease curve
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(StatsRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.maxValue != widget.maxValue) {
      final percentage = (widget.value / widget.maxValue).clamp(0.0, 1.0);
      _animation = Tween<double>(begin: _animation.value, end: percentage)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.size * 0.35; // Adaptive radius based on size
    // Reduce circle size to leave space for label (80px total - 12px for label = 68px max for circle)
    final circleSize = 68.0;
    final labelHeight = 12.0;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          height: 80, // Fixed height to match parent constraint
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Transform.rotate(
                      angle: -math.pi / 2,
                      child: CustomPaint(
                        size: Size(circleSize, circleSize),
                        painter: _CirclePainter(
                          progress: 1.0,
                          strokeWidth: 7,
                          color: PremiumColors.border,
                          radius: radius * (circleSize / widget.size),
                        ),
                      ),
                    ),
                    // Progress circle with optional gradient
                    Transform.rotate(
                      angle: -math.pi / 2,
                      child: CustomPaint(
                        size: Size(circleSize, circleSize),
                        painter: _CirclePainter(
                          progress: _animation.value,
                          strokeWidth: 7,
                          color: widget.color,
                          radius: radius * (circleSize / widget.size),
                          useGradient: widget.useGradient,
                        ),
                      ),
                    ),
                    // Center value
                    Text(
                      '${widget.value}',
                      style: PremiumTypography.heading3.copyWith(
                        fontSize: circleSize * 0.25, // Adaptive font size
                        fontWeight: FontWeight.w700,
                        color: PremiumColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Label with fixed height
              SizedBox(
                height: labelHeight,
                child: Text(
                  widget.label,
                  style: PremiumTypography.bodySmall.copyWith(
                    fontSize: 9, // Further reduced
                    color: PremiumColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final double radius;
  final bool useGradient;

  _CirclePainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.radius,
    this.useGradient = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Apply gradient or solid color
    if (useGradient && progress > 0) {
      final sweepGradient = SweepGradient(
        colors: [
          color,
          color.withValues(alpha: 0.6),
          color,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      );
      paint.shader = sweepGradient.createShader(rect);
    } else {
      paint.color = color;
    }

    // Draw arc
    canvas.drawArc(
      rect,
      0,
      math.pi * 2 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.useGradient != useGradient;
  }
}

