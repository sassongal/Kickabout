/// קבועים כלליים לאפליקציה
class AppConstants {
  // App Info
  static const String appName = 'Kattrick';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String gamesCollection = 'games';
  static const String hubsCollection = 'hubs';
  static const String ratingsCollection = 'ratings';

  // Game Subcollections
  static const String signupsSubcollection = 'signups';
  static const String teamsSubcollection = 'teams';
  static const String eventsSubcollection = 'events';
  static const String historySubcollection = 'history';

  // Team Configuration
  static const List<int> supportedTeamCounts = [2, 3, 4, 5, 6];
  static const int minPlayersPerTeam = 3;
  static const double teamBalanceThreshold = 0.1; // 10% difference

  // Global Rating Constants (for system-wide player ratings)
  static const double minGlobalRating = 0.0;
  static const double maxGlobalRating = 10.0;
  static const double defaultGlobalRating = 5.0;

  // Hub Manager Rating Constants (1-7 scale) - PRIMARY RATING SYSTEM
  static const double minManagerRating = 1.0;
  static const double maxManagerRating = 7.0;
  static const double defaultManagerRating = 4.0;
  static const double ratingIncrement = 0.5;
  static const int ratingDecayDays = 30;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;

  // WhatsApp
  static const String whatsappPhonePrefix = '972';
  static const String whatsappWebUrl = 'https://wa.me';

  // Storage Paths
  static const String profilePhotosPath = 'profile_photos';
  static const String gamePhotosPath = 'game_photos';
  static const String hubPhotosPath = 'hub_photos';

  // Localization
  static const String defaultLocale = 'he';
  static const List<String> supportedLocales = ['he', 'en'];
}
