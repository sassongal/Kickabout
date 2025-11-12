import 'package:flutter/material.dart';
import 'package:kickabout/theme/futuristic_theme.dart';

/// Futuristic gradient button with glow effect
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? iconWidget; // Support for custom icons (AppIcon)
  final bool isLoading;
  final Gradient? gradient;
  final double? width;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.iconWidget,
    this.isLoading = false,
    this.gradient,
    this.width,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? FuturisticColors.primaryGradient;
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.onPressed != null && !widget.isLoading
                ? [
                    BoxShadow(
                      color: FuturisticColors.secondary.withOpacity(
                        _glowAnimation.value * 0.5,
                      ),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else if (widget.iconWidget != null) ...[
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: widget.iconWidget,
                      ),
                      const SizedBox(width: 8),
                    ]
                    else if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label.toUpperCase(),
                      style: FuturisticTypography.labelLarge.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

