import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Premium Hub Marker Painter
///
/// Creates a modern, glowing shield/gathering icon for Hubs.
/// Design features:
/// - Shield shape representing community protection
/// - Gradient fill with PremiumColors
/// - Glowing effect for premium feel
/// - Multiple users icon to represent gathering
class HubMarkerPainter extends CustomPainter {
  final String? label;
  final bool showGlow;

  HubMarkerPainter({
    this.label,
    this.showGlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Draw glow effect (if enabled)
    if (showGlow) {
      _drawGlow(canvas, center, radius);
    }

    // Draw main shield shape with gradient
    _drawShield(canvas, center, radius);

    // Draw icon (gathering/group icon)
    _drawGatheringIcon(canvas, center, radius);

    // Draw label if provided
    if (label != null && label!.isNotEmpty) {
      _drawLabel(canvas, center, radius);
    }
  }

  /// Draw glowing effect for premium feel
  void _drawGlow(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..color = PremiumColors.accent.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(center, radius * 1.5, glowPaint);
  }

  /// Draw shield with gradient
  void _drawShield(Canvas canvas, Offset center, double radius) {
    final shieldPath = _createShieldPath(center, radius);

    // Gradient from accent to accentDark
    final gradient = ui.Gradient.linear(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      [PremiumColors.accent, PremiumColors.accentDark],
      [0.0, 1.0],
    );

    final shieldPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(shieldPath, shieldPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(shieldPath, borderPaint);
  }

  /// Draw gathering/group icon (3 people)
  void _drawGatheringIcon(Canvas canvas, Offset center, double radius) {
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Center person (larger)
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.2),
      radius * 0.2,
      iconPaint,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.15),
      radius * 0.25,
      iconPaint,
    );

    // Left person (smaller)
    canvas.drawCircle(
      Offset(center.dx - radius * 0.4, center.dy),
      radius * 0.15,
      iconPaint,
    );
    canvas.drawCircle(
      Offset(center.dx - radius * 0.4, center.dy + radius * 0.3),
      radius * 0.18,
      iconPaint,
    );

    // Right person (smaller)
    canvas.drawCircle(
      Offset(center.dx + radius * 0.4, center.dy),
      radius * 0.15,
      iconPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.4, center.dy + radius * 0.3),
      radius * 0.18,
      iconPaint,
    );
  }

  /// Create shield path
  Path _createShieldPath(Offset center, double radius) {
    final path = Path();
    final top = center.dy - radius;
    final bottom = center.dy + radius;
    final left = center.dx - radius * 0.8;
    final right = center.dx + radius * 0.8;

    path.moveTo(left + radius * 0.3, top);
    path.quadraticBezierTo(
        center.dx, top - radius * 0.1, right - radius * 0.3, top);
    path.lineTo(right, bottom - radius * 0.4);
    path.quadraticBezierTo(
        right - radius * 0.2, bottom, center.dx, bottom + radius * 0.2);
    path.quadraticBezierTo(
        left + radius * 0.2, bottom, left, bottom - radius * 0.4);
    path.lineTo(left, top + radius * 0.3);
    path.quadraticBezierTo(left, top, left + radius * 0.3, top);
    path.close();
    return path;
  }

  /// Draw label below marker
  void _drawLabel(Canvas canvas, Offset center, double radius) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label!,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 3,
              color: Colors.black.withOpacity(0.8),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(
        center.dx - labelPainter.width / 2,
        center.dy + radius + 6,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant HubMarkerPainter oldDelegate) {
    return oldDelegate.label != label || oldDelegate.showGlow != showGlow;
  }
}

/// Premium Player Marker Painter
///
/// Creates a dynamic avatar pin with status indicator.
/// Design features:
/// - Pin shape with circular top
/// - Gradient from primary to primaryDark
/// - Status indicator (e.g., "Looking for game")
/// - Subtle pulsing glow
class PlayerMarkerPainter extends CustomPainter {
  final String? status; // e.g., "available", "busy", "looking"
  final bool showGlow;

  PlayerMarkerPainter({
    this.status,
    this.showGlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 3);
    final radius = size.width / 3;

    // Draw glow effect (if enabled)
    if (showGlow) {
      _drawGlow(canvas, center, radius);
    }

    // Draw pin shape
    _drawPin(canvas, center, radius);

    // Draw status indicator
    if (status == 'available' || status == 'looking') {
      _drawStatusIndicator(canvas, center, radius);
    }
  }

  /// Draw glowing effect for pulsing indicator
  void _drawGlow(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..color = PremiumColors.primaryLight.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, radius * 1.4, glowPaint);
  }

  /// Draw pin shape with gradient
  void _drawPin(Canvas canvas, Offset center, double radius) {
    // Draw circular head
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final gradient = ui.Gradient.linear(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      [PremiumColors.primary, PremiumColors.primaryDark],
      [0.0, 1.0],
    );

    final circlePaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(circlePath, circlePaint);

    // Draw pin tail (pointing down)
    final tailPath = Path();
    tailPath.moveTo(center.dx - radius * 0.3, center.dy + radius * 0.8);
    tailPath.lineTo(center.dx, center.dy + radius * 2);
    tailPath.lineTo(center.dx + radius * 0.3, center.dy + radius * 0.8);
    tailPath.close();

    final tailPaint = Paint()
      ..color = PremiumColors.primaryDark
      ..style = PaintingStyle.fill;

    canvas.drawPath(tailPath, tailPaint);

    // Border for circle
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, radius, borderPaint);

    // Inner user icon (simple circle for head + body)
    final personPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.2),
      radius * 0.25,
      personPaint,
    );
    // Body
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.3),
      radius * 0.35,
      personPaint,
    );
  }

  /// Draw status indicator (small circle in top-right)
  void _drawStatusIndicator(Canvas canvas, Offset center, double radius) {
    final indicatorCenter = Offset(
      center.dx + radius * 0.7,
      center.dy - radius * 0.7,
    );

    // Outer glow
    final glowPaint = Paint()
      ..color = PremiumColors.success.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(indicatorCenter, radius * 0.3, glowPaint);

    // Inner solid circle
    final statusPaint = Paint()
      ..color = PremiumColors.success
      ..style = PaintingStyle.fill;

    canvas.drawCircle(indicatorCenter, radius * 0.25, statusPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(indicatorCenter, radius * 0.25, borderPaint);
  }

  @override
  bool shouldRepaint(covariant PlayerMarkerPainter oldDelegate) {
    return oldDelegate.status != status || oldDelegate.showGlow != showGlow;
  }
}

/// Premium Venue Marker Painter
///
/// Creates a 3D-style pitch/stadium pin.
/// Design features:
/// - 3D stadium/pitch shape
/// - Gradient from secondary to secondaryDark
/// - Field lines for realistic pitch appearance
/// - Elevated shadow for depth
class VenueMarkerPainter extends CustomPainter {
  final String? label;
  final bool showShadow;

  VenueMarkerPainter({
    this.label,
    this.showShadow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width * 0.7;
    final height = size.height * 0.5;

    // Draw shadow (if enabled)
    if (showShadow) {
      _drawShadow(canvas, center, width, height);
    }

    // Draw pitch shape
    _drawPitch(canvas, center, width, height);

    // Draw field lines
    _drawFieldLines(canvas, center, width, height);

    // Draw label if provided
    if (label != null && label!.isNotEmpty) {
      _drawLabel(canvas, center, height);
    }
  }

  /// Draw 3D shadow for elevation
  void _drawShadow(Canvas canvas, Offset center, double width, double height) {
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(0, 3),
        width: width,
        height: height,
      ),
      const Radius.circular(8),
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawRRect(shadowRect, shadowPaint);
  }

  /// Draw pitch with gradient (grass green)
  void _drawPitch(Canvas canvas, Offset center, double width, double height) {
    final pitchRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      const Radius.circular(8),
    );

    // Gradient from secondary (grass green) to darker
    final gradient = ui.Gradient.linear(
      Offset(center.dx, center.dy - height / 2),
      Offset(center.dx, center.dy + height / 2),
      [PremiumColors.secondary, PremiumColors.secondaryDark],
      [0.0, 1.0],
    );

    final pitchPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawRRect(pitchRect, pitchPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(pitchRect, borderPaint);
  }

  /// Draw field lines for realistic pitch appearance
  void _drawFieldLines(
      Canvas canvas, Offset center, double width, double height) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Center line (vertical)
    canvas.drawLine(
      Offset(center.dx, center.dy - height / 2 + 4),
      Offset(center.dx, center.dy + height / 2 - 4),
      linePaint,
    );

    // Center circle
    canvas.drawCircle(center, width * 0.15, linePaint);

    // Penalty areas (simplified)
    final penaltyWidth = width * 0.3;
    final penaltyHeight = height * 0.4;

    // Left penalty area
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx - width / 2 + penaltyWidth / 2, center.dy),
        width: penaltyWidth,
        height: penaltyHeight,
      ),
      linePaint,
    );

    // Right penalty area
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx + width / 2 - penaltyWidth / 2, center.dy),
        width: penaltyWidth,
        height: penaltyHeight,
      ),
      linePaint,
    );
  }

  /// Draw label below venue
  void _drawLabel(Canvas canvas, Offset center, double height) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label!,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 3,
              color: Colors.black.withOpacity(0.8),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(
        center.dx - labelPainter.width / 2,
        center.dy + height / 2 + 6,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant VenueMarkerPainter oldDelegate) {
    return oldDelegate.label != label || oldDelegate.showShadow != showShadow;
  }
}
