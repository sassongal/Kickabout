import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// A dynamic, animated background for a premium premium feel.
/// Combines a flowing mesh gradient with a tactical tech-grid overlay.
class KineticBackground extends StatefulWidget {
  final Widget child;
  final bool showGrid;

  const KineticBackground({
    super.key,
    required this.child,
    this.showGrid = true,
  });

  @override
  State<KineticBackground> createState() => _KineticBackgroundState();
}

class _KineticBackgroundState extends State<KineticBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Animated Mesh Gradient
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: MeshGradientPainter(
                  progress: _controller.value,
                  primaryColor: PremiumColors.primary,
                  secondaryColor: PremiumColors.secondary,
                  backgroundColor: PremiumColors.background,
                ),
              );
            },
          ),
        ),

        // Layer 2: Tactical Grid Overlay
        if (widget.showGrid)
          Positioned.fill(
            child: const IgnorePointer(
              child: CustomPaint(
                painter: TacticalGridPainter(),
              ),
            ),
          ),

        // Layer 3: Content
        widget.child,
      ],
    );
  }
}

class MeshGradientPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;

  MeshGradientPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Fill background
    canvas.drawRect(Offset.zero & size, paint..color = backgroundColor);

    // Points defined for the mesh
    // Point 1: Primary - Floating around top-left
    final p1 = Offset(
      size.width * (0.2 + 0.15 * math.sin(progress * 2 * math.pi)),
      size.height * (0.2 + 0.1 * math.cos(progress * 2 * math.pi)),
    );

    // Point 2: Secondary - Floating around center-right
    final p2 = Offset(
      size.width * (0.8 + 0.1 * math.cos(progress * 2 * math.pi + 1)),
      size.height * (0.5 + 0.2 * math.sin(progress * 2 * math.pi + 2)),
    );

    // Point 3: Accent - Floating around bottom-left
    final p3 = Offset(
      size.width * (0.3 + 0.2 * math.sin(progress * 2 * math.pi + 4)),
      size.height * (0.8 + 0.1 * math.cos(progress * 2 * math.pi + 3)),
    );

    _drawBlob(canvas, size, p1, primaryColor.withValues(alpha: 0.15), 0.7);
    _drawBlob(canvas, size, p2, secondaryColor.withValues(alpha: 0.12), 0.6);
    _drawBlob(canvas, size, p3, primaryColor.withValues(alpha: 0.1), 0.8);
  }

  void _drawBlob(Canvas canvas, Size size, Offset center, Color color,
      double radiusScale) {
    final radius = size.shortestSide * radiusScale;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gradient = RadialGradient(
      colors: [color, color.withValues(alpha: 0)],
      stops: const [0.0, 1.0],
    ).createShader(rect);

    canvas.drawCircle(center, radius, Paint()..shader = gradient);
  }

  @override
  bool shouldRepaint(MeshGradientPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class TacticalGridPainter extends CustomPainter {
  const TacticalGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PremiumColors.textTertiary.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    const gridSize = 40.0;

    // Draw vertical lines
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw some tech accents (corners)
    final accentPaint = Paint()
      ..color = PremiumColors.primary.withValues(alpha: 0.08)
      ..strokeWidth = 2.0;

    const margin = 20.0;
    const cornerSize = 15.0;

    // Top Left
    canvas.drawLine(const Offset(margin, margin),
        const Offset(margin + cornerSize, margin), accentPaint);
    canvas.drawLine(const Offset(margin, margin),
        const Offset(margin, margin + cornerSize), accentPaint);

    // Top Right
    canvas.drawLine(Offset(size.width - margin, margin),
        Offset(size.width - margin - cornerSize, margin), accentPaint);
    canvas.drawLine(Offset(size.width - margin, margin),
        Offset(size.width - margin, margin + cornerSize), accentPaint);

    // Bottom Left
    canvas.drawLine(Offset(margin, size.height - margin),
        Offset(margin + cornerSize, size.height - margin), accentPaint);
    canvas.drawLine(Offset(margin, size.height - margin),
        Offset(margin, size.height - margin - cornerSize), accentPaint);

    // Bottom Right
    canvas.drawLine(
        Offset(size.width - margin, size.height - margin),
        Offset(size.width - margin - cornerSize, size.height - margin),
        accentPaint);
    canvas.drawLine(
        Offset(size.width - margin, size.height - margin),
        Offset(size.width - margin, size.height - margin - cornerSize),
        accentPaint);
  }

  @override
  bool shouldRepaint(TacticalGridPainter oldDelegate) => false;
}
