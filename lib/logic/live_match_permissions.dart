import 'package:kattrick/models/models.dart';

enum MatchLoggingPolicy {
  managerOnly, // רק מנהלים
  managerAndModerators, // מנהלים ומודרייטורים
  everyone, // כל חברי ההאב
}

class LiveMatchPermissions {
  /// בדיקה האם למשתמש יש הרשאה לתעד משחק באירוע ספציפי
  static bool canLogMatch({
    required String userId,
    required Hub hub,
    required HubEvent event,
  }) {
    // 1. יוצר האירוע או יוצר ההאב תמיד יכולים
    if (userId == event.createdBy || userId == hub.createdBy) return true;

    // 2. מנהלים תמיד יכולים
    if (hub.managerIds.contains(userId)) return true;

    // 3. בדיקת רשמים שמונו אד-הוק לאירוע הזה (Authorized Scorers)
    // (נניח שדה authorizedScorers ב-HubEvent, או שנבדוק ברשימה מקומית)
    // if (event.authorizedScorers.contains(userId)) return true;

    // 4. בדיקה לפי מדיניות ההאב (Hub Settings)
    final policyString =
        hub.settings['matchLoggingPolicy'] as String? ?? 'managerOnly';
    final policy = _parsePolicy(policyString);

    switch (policy) {
      case MatchLoggingPolicy.managerOnly:
        return false; // כבר בדקנו מנהלים למעלה

      case MatchLoggingPolicy.managerAndModerators:
        return hub.moderatorIds.contains(userId);

      case MatchLoggingPolicy.everyone:
        // כל חבר פעיל בהאב יכול
        return hub.activeMemberIds.contains(userId);
    }
  }

  static MatchLoggingPolicy _parsePolicy(String value) {
    // Normalize policy strings to handle variations
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case 'everyone':
      case 'all':
      case 'כולם':
        return MatchLoggingPolicy.everyone;
      case 'moderators':
      case 'managerandmoderators':
      case 'manager_and_moderators':
      case 'managers_and_moderators':
      case 'מנהלים ומודרייטורים':
        return MatchLoggingPolicy.managerAndModerators;
      case 'manageronly':
      case 'manager_only':
      case 'managers':
      case 'מנהלים בלבד':
      default:
        return MatchLoggingPolicy.managerOnly;
    }
  }

  /// Convert policy enum to normalized Firestore string
  static String toFirestoreString(MatchLoggingPolicy policy) {
    switch (policy) {
      case MatchLoggingPolicy.everyone:
        return 'everyone';
      case MatchLoggingPolicy.managerAndModerators:
        return 'managerAndModerators';
      case MatchLoggingPolicy.managerOnly:
        return 'managerOnly';
    }
  }

  /// טקסט להצגה בהגדרות
  static String getPolicyLabel(MatchLoggingPolicy policy) {
    switch (policy) {
      case MatchLoggingPolicy.managerOnly:
        return 'מנהלים בלבד';
      case MatchLoggingPolicy.managerAndModerators:
        return 'מנהלים ומודרייטורים';
      case MatchLoggingPolicy.everyone:
        return 'כל המשתתפים';
    }
  }
}
