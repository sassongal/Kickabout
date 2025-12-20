import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Data visualization ring - shows multiple metrics in a radar-like display
class DataRing extends StatelessWidget {
  final Map<String, double> metrics; // Label -> value (0.0 to 1.0)
  final double size;
  final Color? color;

  const DataRing({
    super.key,
    required this.metrics,
    this.size = 200,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? PremiumColors.secondary;
    
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DataRingPainter(
          metrics: metrics,
          color: color,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                'PERFORMANCE',
                style: PremiumTypography.techHeadline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataRingPainter extends CustomPainter {
  final Map<String, double> metrics;
  final Color color;

  _DataRingPainter({
    required this.metrics,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final entries = metrics.entries.toList();
    final angleStep = (2 * math.pi) / entries.length;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = PremiumColors.surfaceVariant
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < entries.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    // Draw concentric circles
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(
        center,
        radius * i / 4,
        gridPaint,
      );
    }

    // Draw data points
    final dataPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < entries.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = entries[i].value;
      final distance = radius * value;
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, dataPaint);
    
    // Fill with gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, fillPaint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < entries.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = entries[i].value;
      final distance = radius * value;
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_DataRingPainter oldDelegate) {
    return oldDelegate.metrics != metrics || oldDelegate.color != color;
  }
}

