import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Premium circular progress ring with high-fidelity gradients
class ProgressRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? label;
  final Widget? centerWidget;
  final bool showPercentage;
  final bool useGradient;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 8,
    this.color,
    this.label,
    this.centerWidget,
    this.showPercentage = false,
    this.useGradient = true,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubicEmphasized, // Premium ease curve
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: oldWidget.progress, end: widget.progress)
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
    final color = widget.color ?? PremiumColors.secondary;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: 1.0,
                  strokeWidth: widget.strokeWidth,
                  color: PremiumColors.border,
                ),
              ),
              // Progress ring with gradient
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  color: color,
                  useGradient: widget.useGradient,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.centerWidget != null)
                    widget.centerWidget!
                  else if (widget.showPercentage)
                    Text(
                      '${(_animation.value * 100).toInt()}%',
                      style: PremiumTypography.heading2.copyWith(
                        color: color,
                      ),
                    ),
                  if (widget.label != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.label!,
                      style: PremiumTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final bool useGradient;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    this.useGradient = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
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
          color.withValues(alpha: 0.7),
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
      -math.pi / 2, // Start from top
      math.pi * 2 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.useGradient != useGradient;
  }
}

