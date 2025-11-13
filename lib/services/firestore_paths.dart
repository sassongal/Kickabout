import 'package:kickadoor/core/constants.dart';

/// Firestore path constants matching the schema
class FirestorePaths {
  // Users
  static String user(String uid) => '${AppConstants.usersCollection}/$uid';
  static String users() => AppConstants.usersCollection;

  // Hubs
  static String hub(String hubId) => '${AppConstants.hubsCollection}/$hubId';
  static String hubs() => AppConstants.hubsCollection;

  // Games
  static String game(String gameId) => '${AppConstants.gamesCollection}/$gameId';
  static String games() => AppConstants.gamesCollection;

  // Game Signups
  static String gameSignup(String gameId, String uid) =>
      '${AppConstants.gamesCollection}/$gameId/${AppConstants.signupsSubcollection}/$uid';
  static String gameSignups(String gameId) =>
      '${AppConstants.gamesCollection}/$gameId/${AppConstants.signupsSubcollection}';

  // Game Teams
  static String gameTeam(String gameId, String teamId) =>
      '${AppConstants.gamesCollection}/$gameId/${AppConstants.teamsSubcollection}/$teamId';
  static String gameTeams(String gameId) =>
      '${AppConstants.gamesCollection}/$gameId/${AppConstants.teamsSubcollection}';

  // Game Events
  static String gameEvent(String gameId, String eventId) =>
      '${AppConstants.gamesCollection}/$gameId/${AppConstants.eventsSubcollection}/$eventId';
  static String gameEvents(String gameId) =>
      '${AppConstants.gamesCollection}/$gameId/${AppConstants.eventsSubcollection}';

  // Ratings
  static String ratingHistory(String uid, String ratingId) =>
      '${AppConstants.ratingsCollection}/$uid/${AppConstants.historySubcollection}/$ratingId';
  static String ratingHistories(String uid) =>
      '${AppConstants.ratingsCollection}/$uid/${AppConstants.historySubcollection}';
}

