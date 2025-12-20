import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';

class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Premium light theme colors with subtle shimmer
    final base = widget.baseColor ?? PremiumColors.surfaceVariant;
    final highlight = widget.highlightColor ?? PremiumColors.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 16.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
              tileMode: TileMode.clamp,
              transform:
                  _SlidingGradientTransform(slidePercent: _animation.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class SkeletonGameCard extends StatelessWidget {
  const SkeletonGameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: PremiumSpacing.sm,
        vertical: PremiumSpacing.xs,
      ),
      padding: EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: PremiumColors.surface,
        borderRadius: BorderRadius.circular(PremiumRadii.lg),
        border: Border.all(color: PremiumColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SkeletonLoader(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader(width: 120, height: 16),
                    SizedBox(height: 8),
                    SkeletonLoader(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonLoader(
              width: double.infinity, height: 40, borderRadius: 12),
        ],
      ),
    );
  }
}

class SkeletonPlayerCard extends StatelessWidget {
  const SkeletonPlayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: PremiumSpacing.sm),
      padding: EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: PremiumColors.surface,
        borderRadius: BorderRadius.circular(PremiumRadii.md),
        border: Border.all(color: PremiumColors.border),
      ),
      child: Row(
        children: [
          const SkeletonLoader(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoader(width: 100, height: 14),
                SizedBox(height: 6),
                SkeletonLoader(width: 60, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonHubCard extends StatelessWidget {
  const SkeletonHubCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: PremiumSpacing.md),
      height: 160,
      decoration: BoxDecoration(
        color: PremiumColors.surface,
        borderRadius: BorderRadius.circular(PremiumRadii.lg),
        border: Border.all(color: PremiumColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(
              width: double.infinity, height: 100, borderRadius: 16),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const SkeletonLoader(width: 32, height: 32, borderRadius: 16),
                const SizedBox(width: 8),
                const SkeletonLoader(width: 100, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
