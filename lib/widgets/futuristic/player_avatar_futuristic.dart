import 'package:flutter/material.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/widgets/optimized_image.dart';

/// Futuristic player avatar with level indicator
class PlayerAvatarFuturistic extends StatelessWidget {
  final User user;
  final double radius;
  final int? level;
  final bool showLevel;

  const PlayerAvatarFuturistic({
    super.key,
    required this.user,
    this.radius = 24,
    this.level,
    this.showLevel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: FuturisticColors.primaryGradient,
            border: Border.all(
              color: FuturisticColors.secondary,
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
                color: FuturisticColors.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: FuturisticColors.background,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: FuturisticTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Icon(
      Icons.person,
      size: radius,
      color: Colors.white,
    );
  }
}
