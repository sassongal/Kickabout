import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';

/// Optimized image widget with caching and error handling
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final String? placeholder;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Widget? placeholderWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.errorWidget,
    this.placeholderWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Use cached network image for network URLs
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholderWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Center(
                child: KineticLoadingAnimation(size: 24),
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ),
            ),
        // FIX: Cap memory cache at 500px default to prevent buffer overflow
        memCacheWidth: width?.toInt() ?? 500,
        memCacheHeight: height?.toInt() ?? 500,
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
        // FIX: Add fade effects to reduce visual jank
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    } else {
      // Use asset image for local assets
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ),
            ),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return placeholderWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(
                  child: KineticLoadingAnimation(size: 24),
                ),
              );
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
