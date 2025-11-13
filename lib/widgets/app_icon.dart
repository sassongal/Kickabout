import 'package:flutter/material.dart';
import 'package:kickadoor/core/app_assets.dart';

/// Custom App Icon Widget - Uses custom icon assets instead of Material Icons
class AppIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final Color? color;
  final BoxFit fit;

  const AppIcon({
    super.key,
    required this.assetPath,
    this.size = 24,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to a simple placeholder if icon fails to load
        return Icon(
          Icons.image_not_supported,
          size: size,
          color: color ?? Colors.grey,
        );
      },
    );
  }

  // Convenience constructors for common icons
  factory AppIcon.home({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconHomeDashboard, size: size, color: color);

  factory AppIcon.games({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconGamesSchedule, size: size, color: color);

  factory AppIcon.map({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconMapLocation, size: size, color: color);

  factory AppIcon.discover({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconDiscoverHubs, size: size, color: color);

  factory AppIcon.leaderboard({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconLeaderboardTrophy, size: size, color: color);

  factory AppIcon.messages({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconMessagesChat, size: size, color: color);

  factory AppIcon.notifications({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconNotificationsBell, size: size, color: color);

  factory AppIcon.profile({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconProfilePlayer, size: size, color: color);

  factory AppIcon.create({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconCreatePlus, size: size, color: color);

  factory AppIcon.hubs({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconHubsCommunities, size: size, color: color);

  factory AppIcon.teamMaker({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconTeamMaker, size: size, color: color);

  factory AppIcon.editProfile({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconEditProfile, size: size, color: color);

  factory AppIcon.following({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconFollowing, size: size, color: color);

  factory AppIcon.followers({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconFollowers, size: size, color: color);

  factory AppIcon.post({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconPostFeed, size: size, color: color);

  factory AppIcon.manageRoles({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconManageRoles, size: size, color: color);

  factory AppIcon.admin({double? size, Color? color}) =>
      AppIcon(assetPath: AppAssets.iconAdminTools, size: size, color: color);
}

