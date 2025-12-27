import 'package:kattrick/models/models.dart';
import 'package:kattrick/shared/domain/models/value_objects/match_logging_policy.dart';

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
    final policy = hub.settings.matchLoggingPolicy;

    switch (policy) {
      case MatchLoggingPolicy.managerOnly:
        return false; // כבר בדקנו מנהלים למעלה

      case MatchLoggingPolicy.moderators:
        return hub.moderatorIds.contains(userId);

      case MatchLoggingPolicy.anyParticipant:
        // כל חבר פעיל בהאב יכול
        return hub.activeMemberIds.contains(userId);
    }
  }
}
