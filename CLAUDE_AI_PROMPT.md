# פרומפט מקיף ל-Claude AI - פיתוח רשת חברתית ל-Kickabout

## הקשר (Context)

אתה מפתח תוכנה בכיר המתמחה ביצירת רשתות חברתיות מבוססות-מיקום. לפניך פרויקט Flutter קיים בשם **Kickabout** - אפליקציה לניהול משחקי כדורגל שכונתיים בישראל. המטרה היא להפוך את האפליקציה לרשת חברתית פעילה ומושכת לשחקני כדורגל.

**Repository**: https://github.com/sassongal/Kickabout

---

## שלב 1: ניתוח ראשוני מעמיק

### 1.1 בדיקת מבנה הפרויקט

**בצע את הפעולות הבאות:**

1. **סקור את מבנה התיקיות:**
   - בדוק את `lib/` - זהה את המבנה הנוכחי
   - בדוק את `pubspec.yaml` - זהה את כל ה-dependencies
   - בדוק את `README.md` - הבן את התכונות הקיימות
   - בדוק את `ANALYSIS_AND_ROADMAP.md` - הבן את התכנית הקיימת

2. **זהה את הטכנולוגיות המדויקות:**
   - Flutter SDK version (מ-`pubspec.yaml`)
   - State management (Riverpod version)
   - Routing (GoRouter version)
   - Firebase services (Auth, Firestore, Storage)
   - Location packages (geolocator, geocoding, google_maps_flutter)

3. **מיפוי Models:**
   - רשום את כל ה-models ב-`lib/models/`
   - זהה אילו models כוללים מיקום גיאוגרפי (GeoPoint, geohash)
   - זהה אילו models קשורים לתכונות חברתיות (FeedPost, ChatMessage, Notification)

4. **מיפוי Repositories:**
   - רשום את כל ה-repositories ב-`lib/data/`
   - זהה אילו repositories תומכים ב-location queries
   - זהה אילו repositories תומכים ב-social features

5. **מיפוי Screens:**
   - רשום את כל ה-screens ב-`lib/screens/`
   - זהה מסכים הקשורים למיקום (location/)
   - זהה מסכים הקשורים לתכונות חברתיות (social/)

### 1.2 הערכת הפונקציונליות הקיימת

**צור טבלה מפורטת:**

| תכונה | סטטוס | מיקום בקוד | הערות |
|------|-------|------------|-------|
| Authentication | ✅ | `lib/services/auth_service.dart` | Anonymous + Email/Password |
| Hubs Management | ✅ | `lib/screens/hub/` | יצירה, רשימה, פרטים |
| Games Management | ✅ | `lib/screens/game/` | יצירה, ניהול, team maker |
| Ratings System | ✅ | `lib/data/ratings_repository.dart` | 8 קטגוריות דירוג |
| Location Services | ✅ | `lib/services/location_service.dart` | GPS, geocoding, geohash |
| Maps Integration | ✅ | `lib/screens/location/map_screen.dart` | Google Maps |
| Hub Discovery | ✅ | `lib/screens/location/discover_hubs_screen.dart` | חיפוש לפי רדיוס |
| Social Feed | ✅ | `lib/screens/social/feed_screen.dart` | פיד פעילות |
| Hub Chat | ✅ | `lib/screens/social/hub_chat_screen.dart` | צ'אט בזמן אמת |
| Notifications | ✅ | `lib/screens/social/notifications_screen.dart` | מרכז התראות |
| Gamification | ❌ | - | חסר |
| Follow/Unfollow | ❌ | - | חסר |
| Comments on Posts | ❌ | - | חסר |
| Push Notifications | ❌ | - | חסר (רק in-app) |
| Leaderboards | ❌ | - | חסר |
| Game Chat | ❌ | - | חסר (רק hub chat) |
| Private Messages | ❌ | - | חסר |

### 1.3 זיהוי פערים קריטיים

**זהה את הפערים הבאים:**

#### פערים בתכונות חברתיות:
1. **תגובות על פוסטים** - אין יכולת להגיב על פוסטים ב-feed
2. **Follow/Unfollow** - אין מערכת חברויות בין שחקנים
3. **Game Chat** - אין צ'אט ייעודי למשחקים (רק hub chat)
4. **Private Messages** - אין הודעות פרטיות בין שחקנים
5. **Social Graph** - אין מעקב אחר קשרים חברתיים

#### פערים בגיימיפיקציה:
1. **Points System** - אין מערכת נקודות
2. **Levels** - אין מערכת רמות
3. **Badges** - אין תגי הישגים
4. **Achievements** - אין הישגים
5. **Leaderboards** - אין שולחנות מובילים

#### פערים ב-Notifications:
1. **Push Notifications** - אין FCM integration
2. **Notification Preferences** - אין הגדרות התראות
3. **Notification Types** - סוגי התראות מוגבלים

#### פערים ב-UX/UI:
1. **Home Screen** - אין מסך בית מרכזי
2. **Discovery UX** - חיפוש הובים יכול להיות משופר
3. **Profile Enhancement** - פרופיל שחקן יכול להיות עשיר יותר
4. **Social Interactions** - אינטראקציות חברתיות מוגבלות

---

## שלב 2: תכנון ארכיטקטוני

### 2.1 מבנה Firestore מורחב

**הצע מבנה Firestore מורחב:**

```javascript
// מבנה קיים - לשמור
/users/{uid}
  - name, email, photoUrl, phoneNumber
  - location: GeoPoint?
  - geohash: string?
  - hubIds: string[]
  - currentRankScore: number
  - preferredPosition: string
  - totalParticipations: number

/hubs/{hubId}
  - name, description, createdBy
  - location: GeoPoint?
  - geohash: string?
  - radius: number?
  - memberIds: string[]
  - settings: map

/games/{gameId}
  - createdBy, hubId, gameDate
  - location: string? (legacy)
  - locationPoint: GeoPoint?
  - geohash: string?
  - venueId: string?
  - teamCount: 2/3/4
  - status: teamSelection|teamsFormed|inProgress|completed|statsInput

// מבנה חדש - להוסיף
/users/{uid}/following/{followingId}
  - createdAt: timestamp
  - notificationEnabled: boolean

/users/{uid}/followers/{followerId}
  - createdAt: timestamp

/users/{uid}/gamification
  - points: number
  - level: number
  - badges: string[] // ['first_game', 'ten_games', 'mvp', etc.]
  - achievements: map
  - stats: {
      gamesPlayed: number,
      gamesWon: number,
      goals: number,
      assists: number,
      saves: number
    }

/hubs/{hubId}/feed/posts/{postId}
  - authorId: string
  - content: string?
  - type: 'game' | 'achievement' | 'rating' | 'post'
  - gameId: string?
  - achievementId: string?
  - likes: string[] // user IDs
  - createdAt: timestamp
  - commentsCount: number // denormalized

/hubs/{hubId}/feed/posts/{postId}/comments/{commentId}
  - authorId: string
  - text: string
  - likes: string[] // user IDs
  - createdAt: timestamp

/hubs/{hubId}/chat/messages/{messageId}
  - authorId: string
  - text: string
  - readBy: string[] // user IDs
  - createdAt: timestamp

/games/{gameId}/chat/messages/{messageId}
  - authorId: string
  - text: string
  - readBy: string[] // user IDs
  - createdAt: timestamp

/notifications/{uid}/items/{notifId}
  - type: 'game' | 'message' | 'like' | 'comment' | 'follow' | 'achievement'
  - title: string
  - body: string
  - data: map
  - read: boolean
  - createdAt: timestamp

/private_messages/{conversationId}
  - participants: string[] // [uid1, uid2]
  - lastMessage: string
  - lastMessageAt: timestamp
  - unreadCount: map // {uid1: count, uid2: count}

/private_messages/{conversationId}/messages/{messageId}
  - authorId: string
  - text: string
  - read: boolean
  - createdAt: timestamp

/leaderboards/{type} // 'points' | 'games' | 'goals' | 'assists'
  - userId: string
  - score: number
  - rank: number
  - updatedAt: timestamp
```

### 2.2 ארכיטקטורת Features

**הצע מבנה features-based:**

```
lib/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── auth_service.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       └── register_screen.dart
│   ├── hubs/
│   │   ├── data/
│   │   │   └── hubs_repository.dart
│   │   ├── domain/
│   │   │   └── hubs_service.dart
│   │   └── presentation/
│   │       ├── hub_list_screen.dart
│   │       ├── hub_detail_screen.dart
│   │       └── create_hub_screen.dart
│   ├── games/
│   │   └── ... (קיים)
│   ├── social/
│   │   ├── feed/
│   │   │   ├── data/
│   │   │   │   ├── feed_repository.dart
│   │   │   │   └── comments_repository.dart
│   │   │   ├── domain/
│   │   │   │   └── feed_service.dart
│   │   │   └── presentation/
│   │   │       ├── feed_screen.dart
│   │   │       └── post_detail_screen.dart
│   │   ├── chat/
│   │   │   ├── data/
│   │   │   │   ├── chat_repository.dart
│   │   │   │   └── private_messages_repository.dart
│   │   │   ├── domain/
│   │   │   │   └── chat_service.dart
│   │   │   └── presentation/
│   │   │       ├── hub_chat_screen.dart
│   │   │       ├── game_chat_screen.dart
│   │   │       ├── messages_list_screen.dart
│   │   │       └── private_chat_screen.dart
│   │   ├── follow/
│   │   │   ├── data/
│   │   │   │   └── follow_repository.dart
│   │   │   ├── domain/
│   │   │   │   └── follow_service.dart
│   │   │   └── presentation/
│   │   │       ├── following_screen.dart
│   │   │       └── followers_screen.dart
│   │   └── notifications/
│   │       ├── data/
│   │       │   └── notifications_repository.dart
│   │       ├── domain/
│   │       │   └── notifications_service.dart
│   │       └── presentation/
│   │           └── notifications_screen.dart
│   ├── gamification/
│   │   ├── data/
│   │   │   └── gamification_repository.dart
│   │   ├── domain/
│   │   │   ├── points_service.dart
│   │   │   ├── badges_service.dart
│   │   │   └── achievements_service.dart
│   │   └── presentation/
│   │       ├── leaderboard_screen.dart
│   │       ├── achievements_screen.dart
│   │       └── profile_gamification_widget.dart
│   └── location/
│       ├── data/
│       │   └── location_repository.dart
│       ├── domain/
│       │   └── location_service.dart
│       └── presentation/
│           ├── map_screen.dart
│           ├── discover_hubs_screen.dart
│           └── map_picker_screen.dart
├── core/
│   ├── models/
│   ├── widgets/
│   ├── utils/
│   └── constants.dart
└── main.dart
```

---

## שלב 3: רשימת שיפורים מסודרת לפי עדיפות

### עדיפות גבוהה (Critical) - חודש 1-2

#### 3.1 תגובות על פוסטים (Comments)
**מדוע קריטי:** ללא תגובות, ה-feed הוא חד-כיווני ולא מעודד אינטראקציה.

**מה ליישם:**
1. **Model:**
   ```dart
   @freezed
   class Comment with _$Comment {
     const factory Comment({
       required String commentId,
       required String postId,
       required String hubId,
       required String authorId,
       required String text,
       @Default([]) List<String> likes,
       @TimestampConverter() required DateTime createdAt,
     }) = _Comment;
   }
   ```

2. **Repository:**
   ```dart
   class CommentsRepository {
     Stream<List<Comment>> watchComments(String hubId, String postId);
     Future<String> createComment(String hubId, String postId, String authorId, String text);
     Future<void> likeComment(String hubId, String postId, String commentId, String userId);
   }
   ```

3. **UI:**
   - הוסף `CommentCard` widget
   - עדכן `FeedScreen` - הוסף כפתור "תגובות" וצג מספר תגובות
   - צור `PostDetailScreen` - מסך פרטי פוסט עם תגובות מלאות

4. **Notifications:**
   - יצירת notification אוטומטית כשמישהו מגיב על פוסט

#### 3.2 Follow/Unfollow System
**מדוע קריטי:** מערכת חברויות היא בסיס לרשת חברתית.

**מה ליישם:**
1. **Model:**
   ```dart
   @freezed
   class FollowRelationship with _$FollowRelationship {
     const factory FollowRelationship({
       required String followerId,
       required String followingId,
       @TimestampConverter() required DateTime createdAt,
       @Default(true) bool notificationEnabled,
     }) = _FollowRelationship;
   }
   ```

2. **Repository:**
   ```dart
   class FollowRepository {
     Future<void> follow(String followerId, String followingId);
     Future<void> unfollow(String followerId, String followingId);
     Stream<bool> watchIsFollowing(String followerId, String followingId);
     Stream<List<User>> watchFollowing(String userId);
     Stream<List<User>> watchFollowers(String userId);
     Stream<int> watchFollowingCount(String userId);
     Stream<int> watchFollowersCount(String userId);
   }
   ```

3. **UI:**
   - הוסף כפתור "עקוב" ב-`PlayerProfileScreen`
   - צור `FollowingScreen` ו-`FollowersScreen`
   - עדכן `PlayerProfileScreen` - הצג מספר עוקבים/עוקב

4. **Feed Enhancement:**
   - עדכן `FeedScreen` - אפשר סינון לפי following
   - הוסף "פוסטים מאנשים שאתה עוקב אחריהם"

#### 3.3 Push Notifications (FCM)
**מדוע קריטי:** התראות push מעודדות engagement וחזרה לאפליקציה.

**מה ליישם:**
1. **Dependencies:**
   ```yaml
   dependencies:
     firebase_messaging: ^15.0.0
     flutter_local_notifications: ^17.0.0
   ```

2. **Service:**
   ```dart
   class PushNotificationService {
     Future<void> initialize();
     Future<String?> getFCMToken();
     Future<void> requestPermission();
     void setupMessageHandlers();
   }
   ```

3. **Firebase Functions:**
   ```javascript
   exports.sendPushNotification = functions.firestore
     .document('notifications/{uid}/items/{notifId}')
     .onCreate(async (snap, context) => {
       // Send FCM notification
     });
   ```

4. **Integration:**
   - עדכן `NotificationsRepository` - שמירת FCM tokens
   - הוסף deep linking מה-notifications

#### 3.4 Home Screen Enhancement
**מדוע קריטי:** מסך בית מרכזי משפר UX ומעודד engagement.

**מה ליישם:**
1. **Screen:**
   ```dart
   class HomeScreen extends ConsumerWidget {
     // Sections:
     // 1. "משחקים לידך" - משחקים קרובים
     // 2. "הובים מומלצים" - הובים קרובים
     // 3. "פיד פעילות" - פוסטים מ-following
     // 4. "משחקים קרובים" - משחקים בשבוע הקרוב
   }
   ```

2. **Features:**
   - Quick actions: יצירת משחק, חיפוש הובים
   - Personalized content: משחקים מומלצים, הובים קרובים
   - Activity summary: מספר התראות, משחקים קרובים

### עדיפות בינונית (High) - חודש 3-4

#### 3.5 Gamification System
**Points & Levels:**
```dart
class PointsService {
  static int calculateGamePoints(GameResult result) {
    int points = 0;
    points += 10; // Base participation
    if (result.won) points += 20;
    points += (result.goals * 5);
    points += (result.assists * 3);
    if (result.isMVP) points += 15;
    return points;
  }
  
  static int calculateLevel(int totalPoints) {
    return sqrt(totalPoints / 100).floor() + 1;
  }
}
```

**Badges & Achievements:**
```dart
enum BadgeType {
  firstGame,
  tenGames,
  fiftyGames,
  hundredGames,
  firstGoal,
  hatTrick,
  mvp,
  leader,
  consistent,
  social,
}

class BadgeService {
  Future<void> checkAndAwardBadges(String userId, GameResult result);
  Stream<List<Badge>> watchBadges(String userId);
}
```

#### 3.6 Leaderboards
```dart
class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getLeaderboard({
    LeaderboardType type = LeaderboardType.points,
    String? hubId,
    TimePeriod period = TimePeriod.allTime,
  });
}

enum LeaderboardType {
  points,
  gamesPlayed,
  goals,
  assists,
  rating,
  winRate,
}
```

#### 3.7 Game Chat
```dart
class GameChatScreen extends ConsumerWidget {
  final String gameId;
  // Similar to HubChatScreen but for games
}
```

#### 3.8 Private Messages
```dart
class PrivateMessagesRepository {
  Stream<List<Conversation>> watchConversations(String userId);
  Stream<List<Message>> watchMessages(String conversationId);
  Future<void> sendMessage(String conversationId, String authorId, String text);
  Future<String> createConversation(String userId1, String userId2);
}
```

### עדיפות נמוכה (Nice-to-Have) - חודש 5-6

#### 3.9 Advanced Features
- **Event Calendar** - לוח שנה למשחקים
- **Player Recommendations** - המלצות על שחקנים להכיר
- **Hub Analytics** - סטטיסטיקות הוב
- **Game Photos** - העלאת תמונות ממשחקים
- **Player Stories** - סיפורים/עדכונים זמניים
- **Tournaments** - טורנירים מאורגנים

---

## שלב 4: דוגמאות קוד קונקרטיות

### 4.1 Comments Repository - דוגמה מלאה

```dart
// lib/data/comments_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';

class CommentsRepository {
  final FirebaseFirestore _firestore;

  CommentsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream comments for a post
  Stream<List<Comment>> watchComments(String hubId, String postId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.hub(hubId))
        .doc('feed')
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromJson({...doc.data(), 'commentId': doc.id}))
            .toList());
  }

  /// Create a comment
  Future<String> createComment(
    String hubId,
    String postId,
    String authorId,
    String text,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final docRef = _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc();

      await docRef.set({
        'authorId': authorId,
        'text': text,
        'likes': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update comments count on post
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .update({
        'commentsCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create comment: $e');
    }
  }

  /// Like a comment
  Future<void> likeComment(
    String hubId,
    String postId,
    String commentId,
    String userId,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to like comment: $e');
    }
  }

  /// Unlike a comment
  Future<void> unlikeComment(
    String hubId,
    String postId,
    String commentId,
    String userId,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to unlike comment: $e');
    }
  }
}
```

### 4.2 Follow Repository - דוגמה מלאה

```dart
// lib/data/follow_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';

class FollowRepository {
  final FirebaseFirestore _firestore;

  FollowRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Follow a user
  Future<void> follow(String followerId, String followingId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    if (followerId == followingId) {
      throw Exception('Cannot follow yourself');
    }

    try {
      final batch = _firestore.batch();

      // Add to following
      batch.set(
        _firestore
            .collection(FirestorePaths.user(followerId))
            .doc('following')
            .collection('users')
            .doc(followingId),
        {
          'createdAt': FieldValue.serverTimestamp(),
          'notificationEnabled': true,
        },
      );

      // Add to followers
      batch.set(
        _firestore
            .collection(FirestorePaths.user(followingId))
            .doc('followers')
            .collection('users')
            .doc(followerId),
        {
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Update counts
      batch.update(
        _firestore.collection(FirestorePaths.user(followerId)).doc('stats'),
        {
          'followingCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      batch.update(
        _firestore.collection(FirestorePaths.user(followingId)).doc('stats'),
        {
          'followersCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      // Create notification
      await _createFollowNotification(followerId, followingId);
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  /// Unfollow a user
  Future<void> unfollow(String followerId, String followingId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final batch = _firestore.batch();

      // Remove from following
      batch.delete(
        _firestore
            .collection(FirestorePaths.user(followerId))
            .doc('following')
            .collection('users')
            .doc(followingId),
      );

      // Remove from followers
      batch.delete(
        _firestore
            .collection(FirestorePaths.user(followingId))
            .doc('followers')
            .collection('users')
            .doc(followerId),
      );

      // Update counts
      batch.update(
        _firestore.collection(FirestorePaths.user(followerId)).doc('stats'),
        {
          'followingCount': FieldValue.increment(-1),
        },
        SetOptions(merge: true),
      );

      batch.update(
        _firestore.collection(FirestorePaths.user(followingId)).doc('stats'),
        {
          'followersCount': FieldValue.increment(-1),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  /// Check if user is following another user
  Stream<bool> watchIsFollowing(String followerId, String followingId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(false);
    }

    return _firestore
        .collection(FirestorePaths.user(followerId))
        .doc('following')
        .collection('users')
        .doc(followingId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Stream following list
  Stream<List<User>> watchFollowing(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.user(userId))
        .doc('following')
        .collection('users')
        .snapshots()
        .asyncMap((snapshot) async {
          final userIds = snapshot.docs.map((doc) => doc.id).toList();
          if (userIds.isEmpty) return [];

          final usersRepo = UsersRepository(_firestore);
          return await usersRepo.getUsers(userIds);
        });
  }

  /// Stream followers list
  Stream<List<User>> watchFollowers(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.user(userId))
        .doc('followers')
        .collection('users')
        .snapshots()
        .asyncMap((snapshot) async {
          final userIds = snapshot.docs.map((doc) => doc.id).toList();
          if (userIds.isEmpty) return [];

          final usersRepo = UsersRepository(_firestore);
          return await usersRepo.getUsers(userIds);
        });
  }

  /// Stream following count
  Stream<int> watchFollowingCount(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(0);
    }

    return _firestore
        .collection(FirestorePaths.user(userId))
        .doc('following')
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream followers count
  Stream<int> watchFollowersCount(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(0);
    }

    return _firestore
        .collection(FirestorePaths.user(userId))
        .doc('followers')
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> _createFollowNotification(String followerId, String followingId) async {
    final usersRepo = UsersRepository(_firestore);
    final follower = await usersRepo.getUser(followerId);
    final notificationsRepo = NotificationsRepository(_firestore);

    await notificationsRepo.createNotification(
      Notification(
        notificationId: '',
        userId: followingId,
        type: 'follow',
        title: 'עוקב חדש!',
        body: '${follower?.name ?? 'מישהו'} התחיל לעקוב אחריך',
        data: {
          'followerId': followerId,
        },
        createdAt: DateTime.now(),
      ),
    );
  }
}
```

### 4.3 Gamification Service - דוגמה מלאה

```dart
// lib/services/gamification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:kickabout/models/models.dart';

class GamificationService {
  final FirebaseFirestore _firestore;

  GamificationService(this._firestore);

  /// Calculate points for a game result
  static int calculateGamePoints({
    required bool won,
    required int goals,
    required int assists,
    required int saves,
    required bool isMVP,
    required double averageRating,
  }) {
    int points = 0;

    // Base participation
    points += 10;

    // Win bonus
    if (won) points += 20;

    // Performance bonuses
    points += (goals * 5);
    points += (assists * 3);
    points += (saves * 2);

    // MVP bonus
    if (isMVP) points += 15;

    // Rating bonus
    if (averageRating >= 8.0) points += 10;
    if (averageRating >= 9.0) points += 5; // Additional bonus

    return points;
  }

  /// Calculate level from total points
  static int calculateLevel(int totalPoints) {
    if (totalPoints <= 0) return 1;
    return math.sqrt(totalPoints / 100).floor() + 1;
  }

  /// Calculate points needed for next level
  static int pointsForNextLevel(int currentLevel) {
    return (currentLevel * 100) * (currentLevel * 100);
  }

  /// Update user gamification after game
  Future<void> updateGamification({
    required String userId,
    required int pointsEarned,
    required bool won,
    required int goals,
    required int assists,
    required int saves,
  }) async {
    try {
      final gamificationRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('gamification')
          .doc('stats');

      final currentData = await gamificationRef.get();
      final currentPoints = currentData.data()?['points'] ?? 0;
      final currentGames = currentData.data()?['stats']['gamesPlayed'] ?? 0;
      final currentWins = currentData.data()?['stats']['gamesWon'] ?? 0;
      final currentGoals = currentData.data()?['stats']['goals'] ?? 0;
      final currentAssists = currentData.data()?['stats']['assists'] ?? 0;
      final currentSaves = currentData.data()?['stats']['saves'] ?? 0;

      final newPoints = currentPoints + pointsEarned;
      final newLevel = calculateLevel(newPoints);

      await gamificationRef.set({
        'points': newPoints,
        'level': newLevel,
        'stats': {
          'gamesPlayed': currentGames + 1,
          'gamesWon': currentWins + (won ? 1 : 0),
          'goals': currentGoals + goals,
          'assists': currentAssists + assists,
          'saves': currentSaves + saves,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Check for level up
      if (newLevel > (currentData.data()?['level'] ?? 1)) {
        await _awardLevelUpBadge(userId, newLevel);
      }

      // Check for achievement badges
      await _checkAndAwardBadges(userId, newPoints, currentGames + 1, goals);
    } catch (e) {
      throw Exception('Failed to update gamification: $e');
    }
  }

  /// Check and award badges
  Future<void> _checkAndAwardBadges(
    String userId,
    int totalPoints,
    int gamesPlayed,
    int goals,
  ) async {
    final badgesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('gamification')
        .doc('badges');

    final currentBadges = (await badgesRef.get()).data()?['badges'] ?? [];

    final badgesToAward = <String>[];

    // Game count badges
    if (gamesPlayed >= 1 && !currentBadges.contains('first_game')) {
      badgesToAward.add('first_game');
    }
    if (gamesPlayed >= 10 && !currentBadges.contains('ten_games')) {
      badgesToAward.add('ten_games');
    }
    if (gamesPlayed >= 50 && !currentBadges.contains('fifty_games')) {
      badgesToAward.add('fifty_games');
    }
    if (gamesPlayed >= 100 && !currentBadges.contains('hundred_games')) {
      badgesToAward.add('hundred_games');
    }

    // Goal badges
    if (goals >= 1 && !currentBadges.contains('first_goal')) {
      badgesToAward.add('first_goal');
    }
    if (goals >= 3 && !currentBadges.contains('hat_trick')) {
      badgesToAward.add('hat_trick');
    }

    if (badgesToAward.isNotEmpty) {
      await badgesRef.set({
        'badges': FieldValue.arrayUnion(badgesToAward),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create notifications for new badges
      for (final badge in badgesToAward) {
        await _createBadgeNotification(userId, badge);
      }
    }
  }

  Future<void> _awardLevelUpBadge(String userId, int level) async {
    // Create level up notification
    // ...
  }

  Future<void> _createBadgeNotification(String userId, String badge) async {
    // Create badge notification
    // ...
  }
}
```

---

## שלב 5: שיקולי ביצועים ומדרגיות

### 5.1 אופטימיזציה של Firestore Queries

**בעיות נפוצות:**
1. **Too many reads** - queries לא יעילים
2. **Missing indexes** - queries מורכבים דורשים indexes
3. **Large documents** - documents גדולים מדי

**פתרונות:**
1. **Denormalization:**
   ```dart
   // Instead of querying comments count every time
   // Store it on the post document
   /hubs/{hubId}/feed/posts/{postId}
     - commentsCount: number // denormalized
   ```

2. **Composite Indexes:**
   ```javascript
   // Create composite index for leaderboard queries
   // Collection: users
   // Fields: gamification.points (Descending), createdAt (Ascending)
   ```

3. **Pagination:**
   ```dart
   // Use limit() and startAfter() for pagination
   query.limit(20).startAfter(lastDocument);
   ```

### 5.2 Caching Strategy

**מה לקאש:**
1. **User profiles** - קאש מקומי
2. **Hub lists** - קאש עם TTL
3. **Leaderboards** - עדכון כל שעה

**Implementation:**
```dart
class CacheService {
  final SharedPreferences _prefs;
  
  Future<void> cacheUser(User user) async {
    await _prefs.setString('user_${user.uid}', jsonEncode(user.toJson()));
  }
  
  Future<User?> getCachedUser(String uid) async {
    final data = _prefs.getString('user_$uid');
    if (data == null) return null;
    return User.fromJson(jsonDecode(data));
  }
}
```

### 5.3 Image Optimization

**מה לעשות:**
1. **Compress images** לפני העלאה
2. **Use thumbnails** לרשימות
3. **Lazy loading** בתמונות

**Implementation:**
```dart
import 'package:image/image.dart' as img;

Future<Uint8List> compressImage(Uint8List imageData) async {
  final image = img.decodeImage(imageData);
  if (image == null) return imageData;
  
  final resized = img.copyResize(image, width: 800);
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}
```

---

## שלב 6: אבטחה ופרטיות

### 6.1 Firestore Security Rules

**עדכן את ה-security rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Following/Followers
      match /following/users/{followingId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /followers/users/{followerId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Gamification
      match /gamification/{doc} {
        allow read: if request.auth != null;
        allow write: if false; // Only server-side updates
      }
    }
    
    // Hubs
    match /hubs/{hubId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.createdBy == request.auth.uid;
      
      // Feed
      match /feed/posts/{postId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
        allow update, delete: if request.auth != null && 
          resource.data.authorId == request.auth.uid;
        
        // Comments
        match /comments/{commentId} {
          allow read: if request.auth != null;
          allow create: if request.auth != null;
          allow update, delete: if request.auth != null && 
            resource.data.authorId == request.auth.uid;
        }
      }
      
      // Chat
      match /chat/messages/{messageId} {
        allow read: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/hubs/$(hubId)).data.memberIds;
        allow create: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/hubs/$(hubId)).data.memberIds;
      }
    }
    
    // Private Messages
    match /private_messages/{conversationId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      allow create: if request.auth != null;
      
      match /messages/{messageId} {
        allow read: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/private_messages/$(conversationId)).data.participants;
        allow create: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/private_messages/$(conversationId)).data.participants;
      }
    }
    
    // Notifications
    match /notifications/{userId}/items/{notifId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Only server-side
    }
  }
}
```

### 6.2 Privacy Settings

**הוסף Privacy Settings ל-User model:**

```dart
@freezed
class PrivacySettings with _$PrivacySettings {
  const factory PrivacySettings({
    @Default(true) bool showLocation,
    @Default(true) bool showPhoneNumber,
    @Default(true) bool allowMessages,
    @Default(true) bool showInLeaderboard,
    @Default(true) bool showInDiscover,
    @Default(true) bool showInFeed,
  }) = _PrivacySettings;
}
```

---

## שלב 7: תכנית יישום מדורגת

### שבוע 1-2: Comments & Follow System
- [ ] יצירת `Comment` model
- [ ] יצירת `CommentsRepository`
- [ ] עדכון `FeedScreen` עם תגובות
- [ ] יצירת `PostDetailScreen`
- [ ] יצירת `FollowRepository`
- [ ] עדכון `PlayerProfileScreen` עם כפתור Follow
- [ ] יצירת `FollowingScreen` ו-`FollowersScreen`

### שבוע 3-4: Push Notifications
- [ ] הוספת `firebase_messaging` dependency
- [ ] יצירת `PushNotificationService`
- [ ] הגדרת FCM ב-Firebase Console
- [ ] יצירת Firebase Function ל-push notifications
- [ ] Integration עם `NotificationsRepository`
- [ ] Deep linking מה-notifications

### שבוע 5-6: Gamification Foundation
- [ ] יצירת `GamificationService`
- [ ] עדכון `User` model עם gamification fields
- [ ] יצירת `GamificationRepository`
- [ ] Integration עם game completion flow
- [ ] עדכון `PlayerProfileScreen` עם points & level

### שבוע 7-8: Badges & Achievements
- [ ] יצירת `Badge` model
- [ ] יצירת `BadgeService`
- [ ] יצירת `AchievementsScreen`
- [ ] Integration עם game events
- [ ] Notifications ל-badges חדשים

### שבוע 9-10: Leaderboards
- [ ] יצירת `LeaderboardRepository`
- [ ] יצירת `LeaderboardScreen`
- [ ] יצירת composite indexes ב-Firestore
- [ ] Caching strategy ל-leaderboards
- [ ] Integration עם `HomeScreen`

### שבוע 11-12: Game Chat & Private Messages
- [ ] יצירת `GameChatScreen`
- [ ] יצירת `PrivateMessagesRepository`
- [ ] יצירת `MessagesListScreen`
- [ ] יצירת `PrivateChatScreen`
- [ ] Integration עם notifications

---

## הנחיות כלליות ליישום

### 1. שמירה על עקביות
- השתמש ב-Freezed לכל ה-models
- השתמש ב-Riverpod לכל ה-state management
- שמור על מבנה repositories אחיד
- השתמש ב-`AppScaffold` לכל המסכים

### 2. Error Handling
```dart
try {
  // Operation
} catch (e) {
  if (mounted) {
    SnackbarHelper.showError(context, 'שגיאה: $e');
  }
}
```

### 3. Loading States
```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator());
}
```

### 4. Empty States
```dart
if (items.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('אין פריטים'),
      ],
    ),
  );
}
```

### 5. RTL Support
- כל הטקסטים בעברית
- שימוש ב-`Directionality` widget
- בדיקת RTL ב-layouts

---

## סיכום

פרויקט Kickabout הוא בסיס מצוין לרשת חברתית. עם היישום של התכונות המפורטות לעיל, האפליקציה תהפוך לרשת חברתית פעילה ומושכת לשחקני כדורגל שכונתיים.

**עדיפויות:**
1. **Comments** - קריטי לאינטראקציה חברתית
2. **Follow/Unfollow** - בסיס לרשת חברתית
3. **Push Notifications** - מעודד engagement
4. **Gamification** - מעודד שימוש חוזר
5. **Leaderboards** - יוצר תחרותיות

**זמנים משוערים:**
- Comments & Follow: 2 שבועות
- Push Notifications: 2 שבועות
- Gamification: 4 שבועות
- Leaderboards: 2 שבועות
- Game Chat & Messages: 2 שבועות

**סה"כ: 12 שבועות (3 חודשים)**

---

*פרומפט זה נוצר על בסיס ניתוח מעמיק של הקוד הקיים ב-https://github.com/sassongal/Kickabout*

