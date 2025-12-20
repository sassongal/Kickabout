import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/optimized_image.dart';

/// Premium player avatar with level indicator and Hero animation support
class PremiumAvatar extends StatelessWidget {
  final User user;
  final double radius;
  final int? level;
  final bool showLevel;
  final bool enableHero;
  final String? heroTag;

  const PremiumAvatar({
    super.key,
    required this.user,
    this.radius = 24,
    this.level,
    this.showLevel = false,
    this.enableHero = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final avatarWidget = Stack(
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: PremiumColors.primaryGradient,
            border: Border.all(
              color: PremiumColors.secondary,
              width: 2,
            ),
          ),
          child: user.photoUrl != null
              ? ClipOval(
                  child: OptimizedImage(
                    imageUrl: user.photoUrl!,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    errorWidget: _defaultAvatar(),
                  ),
                )
              : _defaultAvatar(),
        ),
        if (showLevel && level != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: PremiumColors.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: PremiumColors.background,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: PremiumTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    // Wrap with Hero animation if enabled
    if (enableHero) {
      final tag = heroTag ?? 'avatar_${user.uid}';
      return Hero(
        tag: tag,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _defaultAvatar() {
    return Icon(
      Icons.person,
      size: radius,
      color: Colors.white,
    );
  }
}
