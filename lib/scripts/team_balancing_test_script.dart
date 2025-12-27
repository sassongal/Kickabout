import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/hubs/domain/models/hub_settings.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/utils/geohash_utils.dart';
import 'package:kattrick/features/hubs/domain/services/hub_creation_service.dart';
import 'package:kattrick/features/hubs/data/repositories/hubs_repository.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// סקריפט מקיף לבדיקת איזון קבוצות
/// יוצר: Hub חדש + 15 שחקנים + אירוע אחד עם 3 קבוצות (Winner Stays)
///
/// ARCHITECTURAL NOTE: This script uses domain services instead of direct
/// Firestore manipulation to enforce consistency and business rules.
class TeamBalancingTestScript {
  final FirebaseFirestore firestore;
  final HubCreationService _hubCreationService;
  final HubsRepository _hubsRepository;
  final Random random = Random();

  TeamBalancingTestScript({
    FirebaseFirestore? firestore,
    HubCreationService? hubCreationService,
    HubsRepository? hubsRepository,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        _hubCreationService = hubCreationService ?? HubCreationService(),
        _hubsRepository = hubsRepository ?? HubsRepository();

  /// רשימת שמות פרטיים
  final List<String> firstNames = [
    'יואב',
    'דני',
    'אור',
    'רונן',
    'עמית',
    'אלון',
    'תומר',
    'ניר',
    'רועי',
    'איתי',
    'שרון',
    'אורן',
    'ליאור',
    'רן',
    'גיל',
    'עומר',
    'רוי',
    'מור',
    'עדי',
    'טל',
  ];

  /// רשימת שמות משפחה
  final List<String> lastNames = [
    'כהן',
    'לוי',
    'מזרחי',
    'דהן',
    'אברהם',
    'ישראל',
    'דוד',
    'יוסף',
    'משה',
    'יעקב',
    'בן דוד',
    'עזרא',
    'שלום',
    'חיים',
    'אליהו',
  ];

  /// רשימת עיירות באזור חיפה
  final List<String> cities = [
    'חיפה',
    'קריית אתא',
    'קריית ביאליק',
    'קריית ים',
    'קריית מוצקין',
    'נשר',
  ];

  /// רשימת עמדות
  final List<String> positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
  ];

  /// יצירת קואורדינטה רנדומלית ליד חיפה
  GeographicPoint _randomCoordinateNearHaifa() {
    const double haifaLat = 32.7940;
    const double haifaLng = 34.9896;
    const double radiusKm = 10.0;

    final angle = random.nextDouble() * 2 * pi;
    final distance = random.nextDouble() * radiusKm;

    final latOffset = distance * cos(angle) / 111.0;
    final lngOffset = distance * sin(angle) / 111.0;

    return GeographicPoint(
      latitude: haifaLat + latOffset,
      longitude: haifaLng + lngOffset,
    );
  }

  /// הפונקציה הראשית - יוצרת הכל בבת אחת!
  Future<Map<String, dynamic>> createCompleteTestScenario({
    String? managerEmail,
  }) async {
    debugPrint('🚀 מתחיל יצירת תרחיש מלא לבדיקת איזון קבוצות...\n');

    final batch = firestore.batch();
    final hubLocation = GeographicPoint(
      latitude: 32.8000,
      longitude: 34.9800,
    ); // גן דניאל, חיפה
    final hubGeohash =
        GeohashUtils.encode(hubLocation.latitude, hubLocation.longitude);

    // שלב 1: קבלת/יצירת משתמש מנהל
    debugPrint('📝 שלב 1: זיהוי משתמש מנהל...');
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    String managerId;

    if (currentUser != null) {
      managerId = currentUser.uid;
      debugPrint('✅ משתמש מחובר: ${currentUser.email} (${currentUser.uid})');
    } else {
      // אם אין משתמש מחובר, נוצר אחד
      managerId = firestore.collection('users').doc().id;
      final managerUser = User(
        uid: managerId,
        name: 'גל ששון',
        email: managerEmail ?? 'gal@joya-tech.net',
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
        phoneNumber: '0541234567',
        city: 'חיפה',
        preferredPosition: 'Midfielder',
        createdAt: DateTime.now(),
        currentRankScore: 7.5,
        totalParticipations: 100,
        location: hubLocation,
        geohash: hubGeohash,
        isProfileComplete: true,
      );
      batch.set(
        firestore.doc(FirestorePaths.user(managerId)),
        managerUser.toJson(),
      );
      debugPrint('✅ נוצר משתמש מנהל חדש: $managerEmail ($managerId)');
    }

    // שלב 2: יצירת Hub
    debugPrint('\n🏟️ שלב 2: יצירת Hub חדש...');
    final hubId = firestore.collection('hubs').doc().id;
    final hub = Hub(
      hubId: hubId,
      name: 'Hub בדיקת איזון קבוצות',
      description: 'Hub מיוחד לבדיקת מערכת איזון הקבוצות עם 15 שחקנים',
      createdBy: managerId,
      memberCount: 15, // 14 שחקנים דמה + מנהל = 15 סה"כ
      region: 'צפון',
      createdAt: DateTime.now(),
      location: hubLocation,
      geohash: hubGeohash,
      settings: const HubSettings(),
    );

    // ARCHITECTURAL FIX: Use HubCreationService instead of manual batch writes
    // This ensures proper denormalization and business logic
    await _hubCreationService.createHub(hub);

    debugPrint('✅ Hub נוצר: $hubId (using HubCreationService)');
    debugPrint('   📍 מיקום: גן דניאל, חיפה');
    debugPrint('   👤 מנהל: $managerId');

    // שלב 3: יצירת 14 שחקנים דמה + המנהל = 15 סה"כ
    debugPrint('\n👥 שלב 3: יצירת 14 שחקנים דמה + אתה = 15 סה"כ...');
    final playerIds = <String>[];

    // נוצר פיזור דירוגים: 3 חלשים (4-5), 9 ממוצעים (5-7), 3 חזקים (7-9)
    final ratings = [
      4.2, 4.5, 4.8, // חלשים
      5.2, 5.5, 5.8, 6.0, 6.3, 6.5, 6.7, 7.0, 7.2, // ממוצעים
      7.5, 8.0, 8.5, // חזקים
    ];
    ratings.shuffle(); // ערבוב כדי שלא יהיו לפי סדר

    // הוספת המנהל (אתה) כשחקן ראשון
    playerIds.add(managerId);
    final managerRating = ratings[0]; // דירוג למנהל

    // עדכון דירוג המנהל בחבר ה-Hub
    await firestore
        .doc(FirestorePaths.hub(hubId))
        .collection('members')
        .doc(managerId)
        .update({
      'managerRating': managerRating,
    });
    debugPrint(
        '   ✅ 1/15: אתה (מנהל) - דירוג: ${managerRating.toStringAsFixed(1)}');

    // יצירת 14 שחקנים נוספים
    final userBatch = firestore.batch();
    for (int i = 0; i < 14; i++) {
      final firstName = firstNames[random.nextInt(firstNames.length)];
      final lastName = lastNames[random.nextInt(lastNames.length)];
      final fullName = '$firstName $lastName';

      final photoId = 47 + (i * 3);
      final photoUrl =
          'https://randomuser.me/api/portraits/men/${photoId % 100}.jpg';

      final userId = firestore.collection('users').doc().id;
      final location = _randomCoordinateNearHaifa();
      final geohash =
          GeohashUtils.encode(location.latitude, location.longitude);

      final user = User(
        uid: userId,
        name: fullName,
        email:
            '${firstName.toLowerCase()}.${lastName.toLowerCase()}@kickabout.test',
        birthDate: DateTime.now()
            .subtract(Duration(days: 365 * (20 + random.nextInt(15)))),
        phoneNumber:
            '05${random.nextInt(9)}${(1000000 + random.nextInt(9000000)).toString()}',
        city: cities[random.nextInt(cities.length)],
        preferredPosition: positions[random.nextInt(positions.length)],
        availabilityStatus: 'available',
        createdAt: DateTime.now().subtract(Duration(days: i)),
        currentRankScore: ratings[i + 1], // +1 כי המנהל לקח את ratings[0]
        totalParticipations: 10 + random.nextInt(40),
        location: location,
        geohash: geohash,
        photoUrl: photoUrl,
        hubIds: [], // Will be updated by repository
        isProfileComplete: true,
      );

      userBatch.set(firestore.doc(FirestorePaths.user(userId)), user.toJson());
      playerIds.add(userId);

      debugPrint(
          '   ✅ ${i + 2}/15: $fullName - דירוג: ${ratings[i + 1].toStringAsFixed(1)}');
    }

    // Commit user creation batch
    await userBatch.commit();

    // ARCHITECTURAL FIX: Add members through repository with ratings
    // This ensures proper member document structure and triggers Cloud Functions
    for (int i = 0; i < playerIds.length - 1; i++) {
      // Skip manager (first in list)
      final userId = playerIds[i + 1];
      await _hubsRepository.addMember(hubId, userId);

      // Update managerRating separately (metadata field)
      await firestore
          .doc(FirestorePaths.hub(hubId))
          .collection('members')
          .doc(userId)
          .update({
        'managerRating': ratings[i + 2], // +2 because manager took ratings[0] and we're at i+1
      });
    }

    // שלב 4: יצירת משחק (Game) עם 3 קבוצות
    debugPrint('\n📅 שלב 4: יצירת משחק עם 3 קבוצות...');

    // יצירת ID למשחק
    final gameDocRef = firestore.collection('games').doc();
    final gameId = gameDocRef.id;

    final gameDate =
        DateTime.now().add(const Duration(hours: 2)); // בעוד שעתיים

    final game = Game(
      gameId: gameId,
      hubId: hubId,
      createdBy: managerId,
      gameDate: gameDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: GameStatus.teamSelection,
      location: 'גן דניאל',
      locationPoint: hubLocation,
      geohash: hubGeohash,
      teamCount: 3, // 3 קבוצות עבור Winner Stays
      maxPlayers: 15,
    );

    batch.set(gameDocRef, game.toJson());
    debugPrint('✅ משחק נוצר: $gameId');
    debugPrint(
        '   📅 תאריך: ${gameDate.day}/${gameDate.month}/${gameDate.year} ${gameDate.hour}:${gameDate.minute.toString().padLeft(2, '0')}');
    debugPrint('   🏟️ מיקום: גן דניאל');
    debugPrint('   👥 מספר שחקנים: 15 (3 קבוצות של 5)');

    // שלב 5: רישום כל 15 השחקנים למשחק (confirmed)
    debugPrint('\n📝 שלב 5: רישום כל 15 השחקנים למשחק...');
    for (int i = 0; i < playerIds.length; i++) {
      final signup = GameSignup(
        playerId: playerIds[i],
        signedUpAt:
            DateTime.now().subtract(Duration(hours: 15 - i)), // זמנים שונים
        status: SignupStatus.confirmed,
      );

      batch.set(
        firestore.doc(FirestorePaths.gameSignup(gameId, playerIds[i])),
        signup.toJson(),
      );
    }
    debugPrint('✅ כל 15 השחקנים נרשמו למשחק (אישרו הגעה)');

    // שליחת כל הנתונים לFirestore
    debugPrint('\n💾 שומר את כל הנתונים ל-Firestore...');
    try {
      await batch.commit();
      debugPrint('✅ כל הנתונים נשמרו בהצלחה!');
    } catch (e, stackTrace) {
      debugPrint('❌ שגיאה בשמירת הנתונים: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow; // זרוק מחדש כדי שהUI יראה את השגיאה
    }

    // סיכום
    debugPrint('\n${'=' * 60}');
    debugPrint('🎉 תרחיש נוצר בהצלחה!');
    debugPrint('=' * 60);
    debugPrint('📊 סיכום:');
    debugPrint('   🏟️ Hub ID: $hubId');
    debugPrint('   ⚽ Game ID: $gameId');
    debugPrint('   👤 Manager ID: $managerId');
    debugPrint('   👥 מספר שחקנים: 15');
    debugPrint('   📈 טווח דירוגים: 4.2 - 8.5');
    debugPrint('   ✅ כל השחקנים רשומים ואישרו הגעה');
    debugPrint('=' * 60);
    debugPrint('\n💡 כעת תוכל לבדוק:');
    debugPrint('   1. איזון אוטומטי של קבוצות (Generate Teams)');
    debugPrint('   2. העברת שחקנים בין קבוצות');
    debugPrint('   3. חישוב Balance Score');
    debugPrint('   4. הצעות אופטימיזציה');
    debugPrint('   5. פתיחת סשן Winner Stays');
    debugPrint('=' * 60);

    return {
      'hubId': hubId,
      'gameId': gameId,
      'managerId': managerId,
      'playerIds': playerIds,
      'success': true,
      'message': 'תרחיש נוצר בהצלחה עם Hub $hubId, משחק $gameId, ו-15 שחקנים',
    };
  }

  /// פונקציה עזר - מחיקת כל הנתונים של התרחיש (לניקיון)
  Future<void> cleanupTestScenario({
    required String hubId,
    required String gameId,
    required List<String> playerIds,
  }) async {
    debugPrint('🧹 מנקה תרחיש בדיקה...');

    final batch = firestore.batch();

    // מחיקת רישומים למשחק
    for (final playerId in playerIds) {
      batch.delete(firestore.doc(FirestorePaths.gameSignup(gameId, playerId)));
    }

    // מחיקת משחק
    final gameRef = firestore.collection('games').doc(gameId);
    batch.delete(gameRef);

    // מחיקת חברי Hub
    for (final playerId in playerIds) {
      batch.delete(
        firestore
            .doc(FirestorePaths.hub(hubId))
            .collection('members')
            .doc(playerId),
      );
    }

    // מחיקת Hub
    batch.delete(firestore.doc(FirestorePaths.hub(hubId)));

    // מחיקת שחקנים
    for (final playerId in playerIds) {
      batch.delete(firestore.doc(FirestorePaths.user(playerId)));
    }

    await batch.commit();
    debugPrint('✅ תרחיש נוקה בהצלחה');
  }
}
