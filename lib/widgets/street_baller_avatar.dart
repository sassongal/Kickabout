import 'dart:math' as math;

import 'package:flutter/material.dart';

class StreetBallerAvatar extends StatelessWidget {
  final double size;

  const StreetBallerAvatar({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StreetBallerPainter(),
      ),
    );
  }
}

class _StreetBallerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFF8FBFF),
          Color(0xFFE2EEFF),
        ],
        center: Alignment(-0.2, -0.3),
        radius: 1.0,
      ).createShader(rect);
    canvas.drawCircle(center, radius, backgroundPaint);

    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(clipPath);

    final groundPaint = Paint()..color = const Color(0xFFECEFF1);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      groundPaint,
    );

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.62),
        width: size.width * 0.56,
        height: size.height * 0.36,
      ),
      Radius.circular(size.width * 0.1),
    );
    final bodyPaint = Paint()..color = const Color(0xFF1565C0);
    canvas.drawRRect(bodyRect, bodyPaint);

    final stripePaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final stripeWidth = size.width * 0.07;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx - stripeWidth * 1.4,
          size.height * 0.48,
          stripeWidth,
          size.height * 0.24,
        ),
        Radius.circular(stripeWidth / 2),
      ),
      stripePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx + stripeWidth * 0.4,
          size.height * 0.48,
          stripeWidth,
          size.height * 0.24,
        ),
        Radius.circular(stripeWidth / 2),
      ),
      stripePaint,
    );

    final headCenter = Offset(center.dx, size.height * 0.28);
    final headRadius = size.width * 0.18;
    final skinPaint = Paint()..color = const Color(0xFFF1C27D);
    canvas.drawCircle(headCenter, headRadius, skinPaint);

    final hairPaint = Paint()..color = const Color(0xFF2E1B10);
    final hairPath = Path()
      ..moveTo(headCenter.dx - headRadius, headCenter.dy - headRadius * 0.1)
      ..quadraticBezierTo(
        headCenter.dx,
        headCenter.dy - headRadius * 1.2,
        headCenter.dx + headRadius,
        headCenter.dy - headRadius * 0.1,
      )
      ..lineTo(headCenter.dx + headRadius, headCenter.dy + headRadius * 0.2)
      ..quadraticBezierTo(
        headCenter.dx,
        headCenter.dy - headRadius * 0.1,
        headCenter.dx - headRadius,
        headCenter.dy + headRadius * 0.2,
      )
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    final bandanaPaint = Paint()..color = const Color(0xFF90CAF9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.1),
          width: headRadius * 1.6,
          height: headRadius * 0.35,
        ),
        Radius.circular(headRadius * 0.2),
      ),
      bandanaPaint,
    );

    final eyePaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius * 0.35, headCenter.dy - headRadius * 0.1),
      headRadius * 0.08,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + headRadius * 0.35, headCenter.dy - headRadius * 0.1),
      headRadius * 0.08,
      eyePaint,
    );

    final smileRect = Rect.fromCenter(
      center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.35),
      width: headRadius * 0.8,
      height: headRadius * 0.5,
    );
    canvas.drawArc(
      smileRect,
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = headRadius * 0.1,
    );

    final ballCenter = Offset(size.width * 0.74, size.height * 0.78);
    final ballRadius = size.width * 0.12;
    final ballPaint = Paint()..color = Colors.white;
    canvas.drawCircle(ballCenter, ballRadius, ballPaint);
    final ballLinePaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ballRadius * 0.2;
    canvas.drawCircle(ballCenter, ballRadius * 0.6, ballLinePaint);

    canvas.restore();

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04;
    canvas.drawCircle(
      center,
      radius - borderPaint.strokeWidth / 2,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
