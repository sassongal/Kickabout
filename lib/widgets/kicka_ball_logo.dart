import 'package:flutter/material.dart';
import 'dart:math' as math;

/// KICKA BALL Logo Widget - Hand-drawn, vintage style
class KickaBallLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? primaryColor;
  final Color? secondaryColor;

  const KickaBallLogo({
    super.key,
    this.size = 120,
    this.showText = true,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? const Color(0xFFFF6B35); // Orange
    final secondary = secondaryColor ?? const Color(0xFF2D5016); // Dark Green
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular Emblem
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _KickaBallLogoPainter(
              primaryColor: primary,
              secondaryColor: secondary,
            ),
          ),
        ),
        // Text
        if (showText) ...[
          const SizedBox(height: 16),
          _LogoText(
            primaryColor: primary,
            secondaryColor: secondary,
          ),
        ],
      ],
    );
  }
}

class _KickaBallLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _KickaBallLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final outerRadius = radius;
    final innerRadius = radius * 0.75;

    // Outer green ring
    final outerPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, outerRadius, outerPaint);

    // Inner orange circle
    final innerPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, innerRadius, innerPaint);

    // Soccer ball (upper right)
    final ballCenter = Offset(
      center.dx + innerRadius * 0.3,
      center.dy - innerRadius * 0.3,
    );
    final ballRadius = innerRadius * 0.25;
    
    _drawSoccerBall(canvas, ballCenter, ballRadius);

    // Soccer shoe (lower left)
    final shoePosition = Offset(
      center.dx - innerRadius * 0.4,
      center.dy + innerRadius * 0.2,
    );
    
    _drawSoccerShoe(canvas, shoePosition, innerRadius * 0.4);
  }

  void _drawSoccerBall(Canvas canvas, Offset center, double radius) {
    // White base
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, whitePaint);

    // Black outlines for panels
    final blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1;

    // Draw pentagon and hexagon pattern (simplified)
    final path = Path();
    
    // Center pentagon
    final pentagonRadius = radius * 0.3;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final x = center.dx + pentagonRadius * math.cos(angle);
      final y = center.dy + pentagonRadius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, blackPaint);

    // Hexagons around (simplified as circles)
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final hexCenter = Offset(
        center.dx + radius * 0.5 * math.cos(angle),
        center.dy + radius * 0.5 * math.sin(angle),
      );
      canvas.drawCircle(hexCenter, radius * 0.15, blackPaint);
    }
  }

  void _drawSoccerShoe(Canvas canvas, Offset position, double size) {
    final shoePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final greenPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Shoe body (simplified shape)
    final shoePath = Path();
    shoePath.moveTo(position.dx, position.dy);
    shoePath.quadraticBezierTo(
      position.dx - size * 0.3,
      position.dy - size * 0.2,
      position.dx - size * 0.1,
      position.dy - size * 0.5,
    );
    shoePath.quadraticBezierTo(
      position.dx + size * 0.2,
      position.dy - size * 0.6,
      position.dx + size * 0.5,
      position.dy - size * 0.4,
    );
    shoePath.quadraticBezierTo(
      position.dx + size * 0.6,
      position.dy - size * 0.1,
      position.dx + size * 0.4,
      position.dy + size * 0.2,
    );
    shoePath.quadraticBezierTo(
      position.dx + size * 0.2,
      position.dy + size * 0.3,
      position.dx,
      position.dy + size * 0.2,
    );
    shoePath.close();
    
    canvas.drawPath(shoePath, shoePaint);

    // White sole
    final solePath = Path();
    solePath.moveTo(position.dx, position.dy + size * 0.2);
    solePath.lineTo(position.dx + size * 0.4, position.dy + size * 0.2);
    solePath.lineTo(position.dx + size * 0.3, position.dy + size * 0.35);
    solePath.lineTo(position.dx - size * 0.1, position.dy + size * 0.35);
    solePath.close();
    canvas.drawPath(solePath, whitePaint);

    // Green stripes
    final stripePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.08;
    
    for (int i = 0; i < 3; i++) {
      final y = position.dy - size * 0.2 + (i * size * 0.15);
      canvas.drawLine(
        Offset(position.dx + size * 0.1, y),
        Offset(position.dx + size * 0.4, y),
        stripePaint,
      );
    }

    // Green laces
    final lacePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.05;
    
    for (int i = 0; i < 3; i++) {
      final x = position.dx + size * 0.15 + (i * size * 0.1);
      canvas.drawLine(
        Offset(x, position.dy - size * 0.3),
        Offset(x, position.dy - size * 0.1),
        lacePaint,
      );
    }

    // Green collar/trim
    final collarPath = Path();
    collarPath.moveTo(position.dx - size * 0.1, position.dy - size * 0.5);
    collarPath.quadraticBezierTo(
      position.dx + size * 0.1,
      position.dy - size * 0.55,
      position.dx + size * 0.3,
      position.dy - size * 0.5,
    );
    collarPath.lineTo(position.dx + size * 0.3, position.dy - size * 0.45);
    collarPath.quadraticBezierTo(
      position.dx + size * 0.1,
      position.dy - size * 0.5,
      position.dx - size * 0.1,
      position.dy - size * 0.45,
    );
    collarPath.close();
    canvas.drawPath(collarPath, greenPaint);

    // Speed lines
    final speedLinePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.06;
    
    for (int i = 0; i < 3; i++) {
      final startX = position.dx - size * 0.2 - (i * size * 0.08);
      final startY = position.dy + size * 0.1;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX - size * 0.1, startY + size * 0.05),
        speedLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_KickaBallLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

class _LogoText extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const _LogoText({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Shadow/outline
        Text(
          'KICKA BALL',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = secondaryColor,
          ),
        ),
        // Main text
        Text(
          'KICKA BALL',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: primaryColor,
          ),
        ),
      ],
    );
  }
}

