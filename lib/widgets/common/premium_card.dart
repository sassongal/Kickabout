import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Premium card with glassmorphism, subtle glow, and shadcn-inspired aesthetics
class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool showGlow;
  final bool glassmorphism;
  final Color? glowColor;
  final PremiumCardElevation elevation;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.showGlow = false,
    this.glassmorphism = false,
    this.glowColor,
    this.elevation = PremiumCardElevation.sm,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

enum PremiumCardElevation { none, sm, md, lg, xl }

class _PremiumCardState extends State<PremiumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    if (widget.showGlow) {
      _glowController.repeat(reverse: true);
    }
    
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
    final borderColor = widget.borderColor ?? PremiumColors.border;
    final effectiveGlowColor = widget.glowColor ?? PremiumColors.secondary;

    // Get shadow based on elevation
    List<BoxShadow> shadows = switch (widget.elevation) {
      PremiumCardElevation.none => [],
      PremiumCardElevation.sm => PremiumShadows.sm,
      PremiumCardElevation.md => PremiumShadows.md,
      PremiumCardElevation.lg => PremiumShadows.lg,
      PremiumCardElevation.xl => PremiumShadows.xl,
    };

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final cardContent = Container(
          margin: widget.margin ?? EdgeInsets.symmetric(
            horizontal: PremiumSpacing.sm,
            vertical: PremiumSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: widget.glassmorphism
                ? PremiumColors.surface.withValues(alpha: 0.8)
                : PremiumColors.surface,
            borderRadius: BorderRadius.circular(PremiumRadii.lg),
            border: Border.all(
              color: widget.showGlow
                  ? effectiveGlowColor.withValues(alpha: _glowAnimation.value * 0.5)
                  : borderColor,
              width: 1,
            ),
            boxShadow: [
              ...shadows,
              if (widget.showGlow)
                ...PremiumShadows.glow(
                  effectiveGlowColor,
                  intensity: _glowAnimation.value * 0.2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PremiumRadii.lg),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(PremiumRadii.lg),
                child: Padding(
                  padding: widget.padding ?? EdgeInsets.all(PremiumSpacing.md),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );

        // Apply backdrop blur for glassmorphism
        if (widget.glassmorphism) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(PremiumRadii.lg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: cardContent,
            ),
          );
        }

        return cardContent;
      },
    );
  }
}

