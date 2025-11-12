/// App Assets Helper - Centralized asset path management
/// 
/// This class provides easy access to all app assets (images, icons, logos)
/// to ensure consistency and easy maintenance.
class AppAssets {
  AppAssets._(); // Private constructor to prevent instantiation

  // Logo
  static const String logo = 'assets/logo/kickadoor_logo.png';

  // Splash Screen
  static const String splashLoading = 'assets/images/splash/loading_screen.png';

  // Navigation Icons (Bar - 9 icons)
  static const String iconHomeDashboard = 'assets/icons/icon_home_dashboard.png';
  static const String iconGamesSchedule = 'assets/icons/icon_games_schedule.png';
  static const String iconMapLocation = 'assets/icons/icon_map_location.png';
  static const String iconDiscoverHubs = 'assets/icons/icon_discover_hubs.png';
  static const String iconLeaderboardTrophy = 'assets/icons/1762984084048.png'; // TODO: Replace when available
  static const String iconMessagesChat = 'assets/icons/icon_messages_chat.png';
  static const String iconNotificationsBell = 'assets/icons/icon_notifications_bell.png';
  static const String iconProfilePlayer = 'assets/icons/1762984094548.png'; // TODO: Replace when available
  static const String iconCreatePlus = 'assets/icons/icon_create_plus.png';

  // Action Icons (Advanced Actions - 9 icons)
  static const String iconHubsCommunities = 'assets/icons/1762984137699.png';
  static const String iconTeamMaker = 'assets/icons/1762984142222.png';
  static const String iconEditProfile = 'assets/icons/1762984145923.png';
  static const String iconFollowing = 'assets/icons/1762984149943.png';
  static const String iconFollowers = 'assets/icons/1762984154022.png';
  static const String iconPostFeed = 'assets/icons/1762984157340.png';
  static const String iconManageRoles = 'assets/icons/1762984161671.png';
  static const String iconAdminTools = 'assets/icons/1762984165203.png';
  // Note: There's one more icon (1762984168735.png) - assign as needed

  // Helper method to get all icon paths
  static List<String> get allIcons => [
        iconHomeDashboard,
        iconGamesSchedule,
        iconMapLocation,
        iconDiscoverHubs,
        iconLeaderboardTrophy,
        iconMessagesChat,
        iconNotificationsBell,
        iconProfilePlayer,
        iconCreatePlus,
        iconHubsCommunities,
        iconTeamMaker,
        iconEditProfile,
        iconFollowing,
        iconFollowers,
        iconPostFeed,
        iconManageRoles,
        iconAdminTools,
      ];
}

