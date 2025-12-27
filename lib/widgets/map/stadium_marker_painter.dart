import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Premium 3D Stadium Marker Painter
///
/// Creates a high-end 3D shield/stadium marker with:
/// - Gradient fill for depth
/// - Deep shadow for 3D elevation
/// - Gold accent border for premium feel
/// - Mode-specific colors
///
/// Design inspired by sports team crests and stadium architecture.
class StadiumMarkerPainter extends CustomPainter {
  final Color primaryColor;
  final Color? secondaryColor;
  final IconData? icon;
  final String? label;
  final bool showShadow;
  final double elevation;

  StadiumMarkerPainter({
    required this.primaryColor,
    this.secondaryColor,
    this.icon,
    this.label,
    this.showShadow = true,
    this.elevation = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Draw shadow first (if enabled)
    if (showShadow) {
      _drawShadow(canvas, center, radius);
    }

    // Draw main shield shape with gradient
    _drawShield(canvas, center, radius);

    // Draw gold accent border
    _drawBorder(canvas, center, radius);

    // Draw icon if provided
    if (icon != null) {
      _drawIcon(canvas, center, radius);
    }

    // Draw label if provided
    if (label != null && label!.isNotEmpty) {
      _drawLabel(canvas, center, radius);
    }
  }

  /// Draw 3D shadow for elevation effect
  void _drawShadow(Canvas canvas, Offset center, double radius) {
    final shadowPath = _createShieldPath(
      center.translate(0, elevation / 2),
      radius,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevation);

    canvas.drawPath(shadowPath, shadowPaint);
  }

  /// Draw main shield with gradient fill
  void _drawShield(Canvas canvas, Offset center, double radius) {
    final shieldPath = _createShieldPath(center, radius);

    // Create gradient from primary to secondary color (or darker primary)
    final gradientColors = [
      primaryColor,
      secondaryColor ?? _darkenColor(primaryColor, 0.2),
    ];

    final gradient = ui.Gradient.linear(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gradientColors,
      [0.0, 1.0],
    );

    final shieldPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(shieldPath, shieldPaint);
  }

  /// Draw gold accent border
  void _drawBorder(Canvas canvas, Offset center, double radius) {
    final borderPath = _createShieldPath(center, radius);

    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700) // Gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(borderPath, borderPaint);

    // Inner subtle highlight for 3D effect
    final highlightPath = _createShieldPath(center.translate(0, -1), radius - 2);
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(highlightPath, highlightPaint);
  }

  /// Draw icon in center
  void _drawIcon(Canvas canvas, Offset center, double radius) {
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon!.codePoint),
        style: TextStyle(
          fontSize: radius * 0.8,
          fontFamily: icon!.fontFamily,
          package: icon!.fontPackage,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );
  }

  /// Draw label below shield
  void _drawLabel(Canvas canvas, Offset center, double radius) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label!,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 3,
              color: Colors.black.withOpacity(0.7),
              offset: const Offset(0, 1),
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
        center.dy + radius + 8,
      ),
    );
  }

  /// Create shield path (rounded rectangle with pointed bottom)
  Path _createShieldPath(Offset center, double radius) {
    final path = Path();
    final top = center.dy - radius;
    final bottom = center.dy + radius;
    final left = center.dx - radius * 0.8;
    final right = center.dx + radius * 0.8;

    // Start at top-left corner
    path.moveTo(left + radius * 0.3, top);

    // Top edge with rounded corners
    path.quadraticBezierTo(
      center.dx,
      top - radius * 0.1,
      right - radius * 0.3,
      top,
    );

    // Right edge
    path.lineTo(right, bottom - radius * 0.4);

    // Bottom point (shield tip)
    path.quadraticBezierTo(
      right - radius * 0.2,
      bottom,
      center.dx,
      bottom + radius * 0.2,
    );
    path.quadraticBezierTo(
      left + radius * 0.2,
      bottom,
      left,
      bottom - radius * 0.4,
    );

    // Left edge back to top
    path.lineTo(left, top + radius * 0.3);
    path.quadraticBezierTo(
      left,
      top,
      left + radius * 0.3,
      top,
    );

    path.close();
    return path;
  }

  /// Darken a color by a percentage
  Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  @override
  bool shouldRepaint(covariant StadiumMarkerPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.icon != icon ||
        oldDelegate.label != label ||
        oldDelegate.showShadow != showShadow ||
        oldDelegate.elevation != elevation;
  }
}

/// Simple circular marker painter (fallback for low-end devices)
class SimpleMarkerPainter extends CustomPainter {
  final Color color;
  final IconData? icon;

  SimpleMarkerPainter({
    required this.color,
    this.icon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Draw circle
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, borderPaint);

    // Draw icon if provided
    if (icon != null) {
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon!.codePoint),
          style: TextStyle(
            fontSize: radius * 0.8,
            fontFamily: icon!.fontFamily,
            package: icon!.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(
          center.dx - iconPainter.width / 2,
          center.dy - iconPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SimpleMarkerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.icon != icon;
  }
}
