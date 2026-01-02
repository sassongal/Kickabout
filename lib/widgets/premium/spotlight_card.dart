import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/premium/premium_prism_shader.dart';

class SpotlightCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color? spotlightColor;
  final double spotlightRadius;
  final bool usePrism;

  const SpotlightCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.spotlightColor,
    this.spotlightRadius = 300,
    this.usePrism = false,
  });

  @override
  State<SpotlightCard> createState() => _SpotlightCardState();
}

class _SpotlightCardState extends State<SpotlightCard> {
  Offset _mousePosition = Offset.zero;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final spotlightColor =
        widget.spotlightColor ?? PremiumColors.primary.withValues(alpha: 0.15);

    return Padding(
      padding: widget.margin,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        onHover: (event) {
          setState(() {
            _mousePosition = event.localPosition;
          });
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: widget.usePrism
                  ? Colors.black.withValues(alpha: 0.4)
                  : PremiumColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.usePrism
                    ? Colors.white.withValues(alpha: 0.1)
                    : PremiumColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Prism Effect
                if (widget.usePrism)
                  const Positioned.fill(
                    child: PremiumPrismShader(alpha: 0.05),
                  ),

                // Spotlight Effect (only if prism is off or we want both?)
                // Let's keep spotlight only if isHovering and not prism, or both.
                // Actually, let's allow both.
                if (_isHovering)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SpotlightPainter(
                        position: _mousePosition,
                        color: spotlightColor,
                        radius: widget.spotlightRadius,
                      ),
                    ),
                  ),

                // Content
                Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset position;
  final Color color;
  final double radius;

  _SpotlightPainter({
    required this.position,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: position, radius: radius),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) {
    return position != oldDelegate.position ||
        color != oldDelegate.color ||
        radius != oldDelegate.radius;
  }
}
