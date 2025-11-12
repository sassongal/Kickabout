import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
        placeholder: (context, url) => placeholderWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget: (context, url, error) => errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ),
            ),
        memCacheWidth: width != null ? width!.toInt() : null,
        memCacheHeight: height != null ? height!.toInt() : null,
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
      );
    } else {
      // Use asset image for local assets
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ),
            ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholderWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
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

