/// A class that holds all the route paths for the app.
/// This is used to avoid hardcoding strings and to have a single source of truth for all routes.
class AppPaths {
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String welcome = '/welcome';
  static const String profileSetup = '/profile/setup';
  static const String onboarding = '/onboarding'; // legacy, unused
  static const String register = '/register'; // legacy, unused
  static const String home = '/';

  // Location
  static const String discoverHubs = '/discover';
  static const String map = '/map';
  static const String weatherDetail = '/weather';
  static const String mapPicker = '/map-picker';

  // Players
  static const String playersBoard = '/players';
  static const String playersMap = '/players/map';
  static const String community = '/community';

  // Hubs
  static const String hubsBoard = '/hubs-board';
  static const String hubs = '/hubs';
  static const String createHub = '/hubs/create';
  static const String hubDetail = '/hubs/:id';
  static const String hubSettings = '/hubs/:id/settings';
  static const String manageHubRoles = '/hubs/:id/manage-roles';
  static const String hubPlayers = '/hubs/:id/players';
  static const String hubRules = '/hubs/:id/rules';
  static const String hubManageRequests = '/hubs/:id/requests';

  // Events & Games
  static const String createHubEvent = '/hubs/:id/events/create';
  static const String editHubEvent = '/hubs/:id/events/:eventId/edit';
  static const String logGame = '/hubs/:id/events/:eventId/log-game';
  static const String eventTeamMaker = '/hubs/:id/events/:eventId/team-maker';
  static const String gameDetail = '/games/:id';
  static const String teamMaker = '/games/:id/team-maker';
  static const String gameChat = '/games/:id/chat';

  // Profile
  static const String playerProfile = '/profile/:uid';
  static const String editProfile = '/profile/:uid/edit';
  static const String privacySettings = '/profile/:uid/privacy';
  static const String settings = '/profile/:uid/settings';
  static const String notificationSettings = '/profile/:uid/notifications';

  // Social
  static const String notifications = '/notifications';
  static const String messages = '/messages';
}
