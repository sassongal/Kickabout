import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stats Ring component matching Figma design
/// Shows a circular progress indicator with value and label
class StatsRing extends StatefulWidget {
  final int value;
  final int maxValue;
  final String label;
  final double size;
  final Color color;

  const StatsRing({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    this.size = 80,
    this.color = const Color(0xFF1976D2), // Primary blue
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
      duration: const Duration(milliseconds: 500),
    );
    
    _animation = Tween<double>(begin: 0, end: percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Transform.rotate(
                    angle: -math.pi / 2,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _CirclePainter(
                        progress: 1.0,
                        strokeWidth: 8,
                        color: const Color(0xFFE0E0E0), // Surface variant
                        radius: radius,
                      ),
                    ),
                  ),
                  // Progress circle
                  Transform.rotate(
                    angle: -math.pi / 2,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _CirclePainter(
                        progress: _animation.value,
                        strokeWidth: 8,
                        color: widget.color,
                        radius: radius,
                      ),
                    ),
                  ),
                  // Center value
                  Text(
                    '${widget.value}',
                    style: GoogleFonts.montserrat(
                      fontSize: widget.size * 0.25, // Adaptive font size
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
          ],
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

  _CirclePainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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
        oldDelegate.color != color;
  }
}

