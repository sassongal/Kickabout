import 'package:flutter/material.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer effect for skeleton loaders
class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: FuturisticColors.surfaceVariant,
      highlightColor: FuturisticColors.surface,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// Skeleton box widget
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: FuturisticColors.surfaceVariant,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton circle widget
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: FuturisticColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Skeleton player card
class SkeletonPlayerCard extends StatelessWidget {
  const SkeletonPlayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SkeletonCircle(size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 120, height: 12),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 80, height: 12),
                ],
              ),
            ),
            const SkeletonBox(width: 60, height: 24, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}

/// Skeleton game card
class SkeletonGameCard extends StatelessWidget {
  const SkeletonGameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonBox(width: 100, height: 20),
                const Spacer(),
                const SkeletonBox(width: 80, height: 16),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const SkeletonBox(width: 150, height: 14),
            const SizedBox(height: 16),
            Row(
              children: [
                const SkeletonCircle(size: 32),
                const SizedBox(width: 8),
                const SkeletonCircle(size: 32),
                const SizedBox(width: 8),
                const SkeletonCircle(size: 32),
                const Spacer(),
                const SkeletonBox(width: 60, height: 24, borderRadius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton hub card
class SkeletonHubCard extends StatelessWidget {
  const SkeletonHubCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonBox(width: 120, height: 20),
                const Spacer(),
                const SkeletonBox(width: 60, height: 16),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            Row(
              children: [
                const SkeletonBox(width: 100, height: 12),
                const SizedBox(width: 16),
                const SkeletonBox(width: 80, height: 12),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SkeletonCircle(size: 24),
                const SizedBox(width: 8),
                const SkeletonCircle(size: 24),
                const SizedBox(width: 8),
                const SkeletonCircle(size: 24),
                const Spacer(),
                const SkeletonBox(width: 50, height: 20, borderRadius: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton list item
class SkeletonListItem extends StatelessWidget {
  final bool showAvatar;
  final bool showTrailing;

  const SkeletonListItem({
    super.key,
    this.showAvatar = true,
    this.showTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: showAvatar ? const SkeletonCircle(size: 40) : null,
      title: const SkeletonBox(width: double.infinity, height: 16),
      subtitle: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: SkeletonBox(width: 150, height: 12),
      ),
      trailing: showTrailing
          ? const SkeletonBox(width: 60, height: 24, borderRadius: 12)
          : null,
    );
  }
}

/// Skeleton grid item
class SkeletonGridItem extends StatelessWidget {
  const SkeletonGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SkeletonCircle(size: 64),
            const SizedBox(height: 12),
            const SkeletonBox(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            const SkeletonBox(width: 100, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Simple skeleton loader widget
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

