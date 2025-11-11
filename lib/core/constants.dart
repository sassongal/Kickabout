/// קבועים כלליים לאפליקציה
class AppConstants {
  // App Info
  static const String appName = 'Kickabout';
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
  static const List<int> supportedTeamCounts = [2, 3, 4];
  static const int minPlayersPerTeam = 3;
  static const double teamBalanceThreshold = 0.1; // 10% difference
  
  // Rating Constants
  static const double minRating = 1.0;
  static const double maxRating = 10.0;
  static const double defaultRating = 5.0;
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
  
  // Localization
  static const String defaultLocale = 'he';
  static const List<String> supportedLocales = ['he', 'en'];
}

/// מסרים של שגיאות
class ErrorMessages {
  static const String networkError = 'שגיאת רשת. נסה שוב.';
  static const String authError = 'שגיאת אימות. נסה להתחבר מחדש.';
  static const String permissionError = 'אין לך הרשאה לבצע פעולה זו.';
  static const String unknownError = 'שגיאה לא ידועה. נסה שוב.';
  static const String insufficientPlayers = 'אין מספיק שחקנים למשחק.';
  static const String gameNotFound = 'המשחק לא נמצא.';
  static const String hubNotFound = 'ההוב לא נמצא.';
}

/// מסרים של הצלחה
class SuccessMessages {
  static const String gameCreated = 'המשחק נוצר בהצלחה!';
  static const String playerAdded = 'השחקן נוסף בהצלחה!';
  static const String teamFormed = 'הקבוצות נוצרו בהצלחה!';
  static const String statsSaved = 'הסטטיסטיקות נשמרו בהצלחה!';
  static const String hubCreated = 'ההוב נוצר בהצלחה!';
}

