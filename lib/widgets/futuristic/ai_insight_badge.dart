import 'package:flutter/material.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';

/// AI-powered insight badge with animated glow
class AIInsightBadge extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color? color;

  const AIInsightBadge({
    super.key,
    required this.text,
    required this.icon,
    this.color,
  });

  @override
  State<AIInsightBadge> createState() => _AIInsightBadgeState();
}

class _AIInsightBadgeState extends State<AIInsightBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? FuturisticColors.secondary;
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(_glowAnimation.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(_glowAnimation.value * 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                widget.text.toUpperCase(),
                style: FuturisticTypography.labelSmall.copyWith(
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

