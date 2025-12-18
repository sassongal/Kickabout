import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/utils/geohash_utils.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// סקריפט מקיף לבדיקת איזון קבוצות
/// יוצר: Hub חדש + 15 שחקנים + אירוע אחד עם 3 קבוצות (Winner Stays)
class TeamBalancingTestScript {
  final FirebaseFirestore firestore;
  final Random random = Random();

  TeamBalancingTestScript({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

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
  GeoPoint _randomCoordinateNearHaifa() {
    const double haifaLat = 32.7940;
    const double haifaLng = 34.9896;
    const double radiusKm = 10.0;

    final angle = random.nextDouble() * 2 * pi;
    final distance = random.nextDouble() * radiusKm;

    final latOffset = distance * cos(angle) / 111.0;
    final lngOffset = distance * sin(angle) / 111.0;

    return GeoPoint(
      haifaLat + latOffset,
      haifaLng + lngOffset,
    );
  }

  /// הפונקציה הראשית - יוצרת הכל בבת אחת!
  Future<Map<String, dynamic>> createCompleteTestScenario({
    String? managerEmail,
  }) async {
    debugPrint('🚀 מתחיל יצירת תרחיש מלא לבדיקת איזון קבוצות...\n');

    final batch = firestore.batch();
    final hubLocation = GeoPoint(32.8000, 34.9800); // גן דניאל, חיפה
    final hubGeohash =
        GeohashUtils.encode(hubLocation.latitude, hubLocation.longitude);

    // שלב 1: קבלת/יצירת משתמש מנהל
    debugPrint('📝 שלב 1: זיהוי משתמש מנהל...');
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    String managerId;
    bool isExistingUser = false;

    if (currentUser != null) {
      managerId = currentUser.uid;
      isExistingUser = true;
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
      settings: {
        'ratingMode': 'advanced',
        'allowGuestPlayers': false,
      },
    );

    final hubRef = firestore.doc(FirestorePaths.hub(hubId));
    batch.set(hubRef, hub.toJson());

    // הוספת המנהל כחבר ראשון
    batch.set(
      hubRef.collection('members').doc(managerId),
      {
        'userId': managerId,
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'manager',
        'status': 'active',
      },
    );

    // אם זה משתמש קיים, נעדכן את hubIds שלו
    if (isExistingUser) {
      batch.update(
        firestore.doc(FirestorePaths.user(managerId)),
        {
          'hubIds': FieldValue.arrayUnion([hubId]),
        },
      );
      debugPrint('✅ מעדכן את hubIds של המשתמש הקיים');
    }

    debugPrint('✅ Hub נוצר: $hubId');
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

    // עדכון חבר ה-Hub של המנהל עם דירוג
    batch.set(
      hubRef.collection('members').doc(managerId),
      {
        'managerRating': managerRating,
      },
      SetOptions(merge: true), // מיזוג עם המסמך הקיים
    );
    debugPrint(
        '   ✅ 1/15: אתה (מנהל) - דירוג: ${managerRating.toStringAsFixed(1)}');

    // יצירת 14 שחקנים נוספים
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
        hubIds: [hubId],
        isProfileComplete: true,
      );

      batch.set(firestore.doc(FirestorePaths.user(userId)), user.toJson());
      playerIds.add(userId);

      // הוספת השחקן כחבר ב-Hub
      batch.set(
        hubRef.collection('members').doc(userId),
        {
          'userId': userId,
          'joinedAt': FieldValue.serverTimestamp(),
          'role': 'member',
          'status': 'active',
          'managerRating': ratings[i + 1], // דירוג מנהל
        },
      );

      debugPrint(
          '   ✅ ${i + 2}/15: $fullName - דירוג: ${ratings[i + 1].toStringAsFixed(1)}');
    }

    // שלב 4: יצירת אירוע
    debugPrint('\n📅 שלב 4: יצירת אירוע עם 3 קבוצות...');

    // יצירת ID לאירוע
    final eventsCollectionRef =
        firestore.collection('hubs').doc(hubId).collection('events');
    final eventDocRef = eventsCollectionRef.doc();
    final eventId = eventDocRef.id;

    final eventDate =
        DateTime.now().add(const Duration(hours: 2)); // בעוד שעתיים

    final event = HubEvent(
      eventId: eventId,
      hubId: hubId,
      createdBy: managerId,
      title: 'אירוע בדיקת איזון קבוצות',
      description: 'אירוע מיוחד לבדיקת מערכת איזון הקבוצות - 15 שחקנים מאושרים',
      eventDate: eventDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'upcoming',
      location: 'גן דניאל',
      locationPoint: hubLocation,
      geohash: hubGeohash,
      teamCount: 3, // 3 קבוצות עבור Winner Stays
      maxParticipants: 15,
      registeredPlayerIds: playerIds, // כל 15 השחקנים
      waitingListPlayerIds: [],
    );

    batch.set(eventDocRef, event.toJson());
    debugPrint('✅ אירוע נוצר: $eventId');
    debugPrint(
        '   📅 תאריך: ${eventDate.day}/${eventDate.month}/${eventDate.year} ${eventDate.hour}:${eventDate.minute.toString().padLeft(2, '0')}');
    debugPrint('   🏟️ מיקום: גן דניאל');
    debugPrint('   👥 מספר שחקנים: 15 (3 קבוצות של 5)');

    // שלב 5: רישום כל 15 השחקנים לאירוע (confirmed)
    debugPrint('\n📝 שלב 5: רישום כל 15 השחקנים לאירוע...');
    for (int i = 0; i < playerIds.length; i++) {
      final signup = GameSignup(
        playerId: playerIds[i],
        signedUpAt:
            DateTime.now().subtract(Duration(hours: 15 - i)), // זמנים שונים
        status: SignupStatus.confirmed,
      );

      batch.set(
        firestore.doc(FirestorePaths.gameSignup(eventId, playerIds[i])),
        signup.toJson(),
      );
    }
    debugPrint('✅ כל 15 השחקנים נרשמו לאירוע (אישרו הגעה)');

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
    debugPrint('   📅 Event ID: $eventId');
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
      'eventId': eventId,
      'managerId': managerId,
      'playerIds': playerIds,
      'success': true,
      'message': 'תרחיש נוצר בהצלחה עם Hub $hubId, אירוע $eventId, ו-15 שחקנים',
    };
  }

  /// פונקציה עזר - מחיקת כל הנתונים של התרחיש (לניקיון)
  Future<void> cleanupTestScenario({
    required String hubId,
    required String eventId,
    required List<String> playerIds,
  }) async {
    debugPrint('🧹 מנקה תרחיש בדיקה...');

    final batch = firestore.batch();

    // מחיקת רישומים לאירוע
    for (final playerId in playerIds) {
      batch.delete(firestore.doc(FirestorePaths.gameSignup(eventId, playerId)));
    }

    // מחיקת אירוע
    final eventRef = firestore
        .collection('hubs')
        .doc(hubId)
        .collection('events')
        .doc(eventId);
    batch.delete(eventRef);

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
