import 'package:flutter/material.dart';
import 'package:kattrick/core/app_assets.dart';

/// Kattrick Logo Widget - Uses the official logo image
class KickaBallLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final double size;
  final bool showText;
  final BoxFit fit;

  const KickaBallLogo({
    super.key,
    this.width,
    this.height,
    this.size = 120,
    this.showText = true,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Image
        Image.asset(
          AppAssets.logo,
          width: width ?? size,
          height: height ?? size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to a simple placeholder if image fails to load
            return Container(
              width: width ?? size,
              height: height ?? size,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sports_soccer,
                size: 48,
                color: Colors.grey,
              ),
            );
          },
        ),
        // Text (optional - logo already contains text)
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'KATTRICK',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}


