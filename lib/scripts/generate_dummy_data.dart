import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/utils/geohash_utils.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Script to generate dummy data for Haifa area
/// Run this from a Flutter app or Firebase console
class DummyDataGenerator {
  final FirebaseFirestore firestore;
  final Random random = Random();

  DummyDataGenerator({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  /// הוספת שחקנים מדומים ל-Hub קיים ספציפי
  Future<void> addPlayersToExistingHub({
    required String hubId,
    int count = 10,
    String? eventId,
  }) async {
    debugPrint('Generating $count players for Hub: $hubId...');

    // בדיקה שה-Hub קיים
    final hubDoc = await firestore.doc(FirestorePaths.hub(hubId)).get();
    if (!hubDoc.exists) {
      throw Exception('Hub with ID $hubId not found!');
    }

    final newMemberIds = <String>[];
    final batch = firestore.batch();

    for (int i = 0; i < count; i++) {
      // 1. יצירת משתמש חדש (ללא כתיבה מיידית כדי שנוכל להוסיף אותו ל-Batch עם ה-hubId)
      final userId = firestore.collection('users').doc().id;
      final firstName = firstNames[random.nextInt(firstNames.length)];
      final lastName = lastNames[random.nextInt(lastNames.length)];

      final location = _randomCoordinateNearHaifa();
      final geohash =
          GeohashUtils.encode(location.latitude, location.longitude);

      // שימוש בתמונה רנדומלית
      final photoId = random.nextInt(99);
      final photoUrl = 'https://randomuser.me/api/portraits/men/$photoId.jpg';

      final user = User(
        uid: userId,
        name: '$firstName $lastName',
        email:
            '${firstName.toLowerCase()}.${lastName.toLowerCase()}.${random.nextInt(999)}@kickabout.local',
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
        phoneNumber:
            '05${random.nextInt(9)}${random.nextInt(9999999).toString().padLeft(7, '0')}',
        city: 'חיפה', // או עיר רנדומלית מהרשימה
        preferredPosition: positions[random.nextInt(positions.length)],
        availabilityStatus: 'available',
        createdAt: DateTime.now(),
        currentRankScore: 4.0 + random.nextDouble() * 2.0,
        totalParticipations: 0,
        location: location,
        geohash: geohash,
        photoUrl: photoUrl,
        hubIds: [hubId], // הוספה ישירה של ה-Hub למשתמש
      );

      // הוספת יצירת המשתמש ל-Batch
      batch.set(firestore.doc(FirestorePaths.user(userId)), user.toJson());
      newMemberIds.add(userId);

      // אם סופק eventId, רשום את השחקן גם לאירוע
      if (eventId != null && eventId.isNotEmpty) {
        final signup = GameSignup(
          playerId: userId,
          status: SignupStatus.confirmed,
          signedUpAt: DateTime.now(),
        );
        batch.set(
          firestore.doc(FirestorePaths.gameSignup(eventId, userId)),
          signup.toJson(),
        );
      }
    }

    // 2. Add members to subcollection and update memberCount (Strategy C)
    final hubRef = firestore.doc(FirestorePaths.hub(hubId));
    for (final memberId in newMemberIds) {
      batch.set(
        hubRef.collection('members').doc(memberId),
        {
          'joinedAt': FieldValue.serverTimestamp(),
          'role': 'member',
        },
      );
    }
    // Increment member count
    batch.update(hubRef, {
      'memberCount': FieldValue.increment(newMemberIds.length),
    });

    await batch.commit();
    debugPrint(
        '✅ Successfully added ${newMemberIds.length} players to Hub $hubId');
    if (eventId != null && eventId.isNotEmpty) {
      debugPrint('✅ And registered them to Event $eventId');
    }
  }

  // Haifa area coordinates
  static const double haifaLat = 32.7940;
  static const double haifaLng = 34.9896;
  static const double radiusKm = 15.0; // 15km radius around Haifa

  // Israeli names for players
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
    'מיכל',
    'יעל',
    'נועה',
    'תמר',
    'רותם',
    'ליאור',
    'מור',
    'עדי',
    'טל',
  ];

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
    'שמעון',
    'רחמים',
    'יצחק',
    'אהרון',
    'שלמה',
  ];

  final List<String> cities = [
    'חיפה',
    'קריית אתא',
    'קריית ביאליק',
    'קריית ים',
    'קריית מוצקין',
    'נשר',
    'טירת כרמל',
    'זכרון יעקב',
    'עכו',
    'נהריה',
  ];

  final List<String> positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
  ];

  final List<String> regions = [
    'צפון',
    'מרכז',
    'דרום',
    'ירושלים',
  ];

  final List<String> playingStyles = [
    'goalkeeper',
    'defensive',
    'offensive',
  ];

  /// Generate a random coordinate near Haifa
  GeoPoint _randomCoordinateNearHaifa() {
    // Generate random offset in km
    final angle = random.nextDouble() * 2 * pi;
    final distance = random.nextDouble() * radiusKm;

    // Convert km to degrees (approximate)
    final latOffset = distance * cos(angle) / 111.0;
    final lngOffset = distance * sin(angle) / 111.0;

    return GeoPoint(
      haifaLat + latOffset,
      haifaLng + lngOffset,
    );
  }

  /// Generate a random user
  Future<String> generateUser({
    String? name,
    String? city,
    String? position,
    double? rating,
  }) async {
    final nameParts = name?.split(' ') ?? [];
    final firstName = nameParts.isNotEmpty
        ? nameParts.first
        : firstNames[random.nextInt(firstNames.length)];
    final lastName = nameParts.length > 1
        ? nameParts.skip(1).join(' ')
        : lastNames[random.nextInt(lastNames.length)];
    final fullName = '$firstName $lastName';

    final userId = firestore.collection('users').doc().id;
    final location = _randomCoordinateNearHaifa();
    final geohash = GeohashUtils.encode(location.latitude, location.longitude);

    final user = User(
      uid: userId,
      name: fullName,
      email:
          '${firstName.toLowerCase()}.${lastName.toLowerCase()}@kickabout.local',
      birthDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      phoneNumber:
          '05${random.nextInt(9)}${random.nextInt(9999999).toString().padLeft(7, '0')}',
      city: city ?? cities[random.nextInt(cities.length)],
      preferredPosition:
          position ?? positions[random.nextInt(positions.length)],
      availabilityStatus: [
        'available',
        'busy',
        'notAvailable'
      ][random.nextInt(3)],
      createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
      currentRankScore: rating ?? (4.0 + random.nextDouble() * 3.0), // 4.0-7.0
      totalParticipations: random.nextInt(50),
      location: location,
      geohash: geohash,
      region: regions[random.nextInt(regions.length)],
    );

    await firestore.doc(FirestorePaths.user(userId)).set(user.toJson());
    return userId;
  }

  // Real football field locations in Haifa
  static const Map<String, Map<String, double>> realFields = {
    'גן דניאל': {
      'lat': 32.8000,
      'lng': 34.9800,
    },
    'ספורטן': {
      'lat': 32.8200,
      'lng': 35.0000,
    },
    'קצף': {
      'lat': 32.8100,
      'lng': 34.9900,
    },
    'מרכז הטניס': {
      'lat': 32.7900,
      'lng': 34.9700,
    },
    'רוממה-ביה"ס': {
      'lat': 32.8050,
      'lng': 34.9850,
    },
  };

  /// Generate a hub with activity
  Future<String> generateHub({
    String? name,
    String? description,
    List<String>? memberIds,
    int? memberCount,
    GeoPoint? location,
  }) async {
    final hubId = firestore.collection('hubs').doc().id;

    // Use provided location or random one
    final finalLocation = location ?? _randomCoordinateNearHaifa();
    final geohash =
        GeohashUtils.encode(finalLocation.latitude, finalLocation.longitude);

    final hubNames = [
      'הפועל חיפה',
      'מכבי חיפה',
      'בית"ר חיפה',
      'הפועל קריית אתא',
      'מכבי קריית ביאליק',
      'הפועל נשר',
      'מכבי טירת כרמל',
      'שחקני הכרמל',
      'כדורגל חיפה',
      'הכרמל FC',
    ];

    final hubDescriptions = [
      'קבוצת כדורגל שכונתית פעילה',
      'משחקים שבועיים קבועים',
      'קבוצה פתוחה לכל הגילאים',
      'כדורגל חברתי וספורטיבי',
      'קבוצה עם מסורת ארוכה',
    ];

    final finalName = name ?? hubNames[random.nextInt(hubNames.length)];
    final finalDescription =
        description ?? hubDescriptions[random.nextInt(hubDescriptions.length)];

    // Generate members if not provided
    final finalMemberIds = memberIds ?? [];
    if (finalMemberIds.isEmpty) {
      final count = memberCount ?? (5 + random.nextInt(15)); // 5-20 members
      for (int i = 0; i < count; i++) {
        final userId = await generateUser();
        finalMemberIds.add(userId);
      }
    }

    // Determine region based on hub name or random
    String? hubRegion;
    if (finalName.contains('חיפה') ||
        finalName.contains('קריית') ||
        finalName.contains('נשר') ||
        finalName.contains('טירת')) {
      hubRegion = 'צפון';
    } else if (finalName.contains('תל אביב') ||
        finalName.contains('רמת גן') ||
        finalName.contains('גבעתיים')) {
      hubRegion = 'מרכז';
    } else if (finalName.contains('באר שבע') ||
        finalName.contains('אשדוד') ||
        finalName.contains('אשקלון')) {
      hubRegion = 'דרום';
    } else if (finalName.contains('ירושלים')) {
      hubRegion = 'ירושלים';
    } else {
      hubRegion = regions[random.nextInt(regions.length)];
    }

    final hub = Hub(
      hubId: hubId,
      name: finalName,
      description: finalDescription,
      createdBy: finalMemberIds.isNotEmpty
          ? finalMemberIds[0]
          : firestore.collection('users').doc().id,
      memberCount: finalMemberIds.length,
      region: hubRegion,
      createdAt: DateTime.now().subtract(Duration(days: random.nextInt(180))),
      location: finalLocation,
      geohash: geohash,
      settings: {
        'ratingMode': ['basic', 'advanced'][random.nextInt(2)],
      },
    );

    final batch = firestore.batch();
    final hubRef = firestore.doc(FirestorePaths.hub(hubId));
    batch.set(hubRef, hub.toJson());

    // Add members to subcollection (Strategy C)
    for (final memberId in finalMemberIds) {
      batch.set(
        hubRef.collection('members').doc(memberId),
        {
          'joinedAt': FieldValue.serverTimestamp(),
          'role': memberId == finalMemberIds[0] ? 'manager' : 'member',
        },
      );
    }

    await batch.commit();

    // Generate some games for this hub
    await _generateGamesForHub(hubId, finalMemberIds, finalLocation);

    return hubId;
  }

  /// Generate hubs at real field locations
  Future<void> generateRealFieldHubs({
    int playersPerHub = 15,
  }) async {
    print('🏟️ Generating Hubs at real field locations...');

    // First generate some users
    final userIds = <String>[];
    for (int i = 0; i < playersPerHub * realFields.length; i++) {
      final userId = await generateUser();
      userIds.add(userId);
    }

    // Shuffle users and distribute them
    userIds.shuffle();
    int userIndex = 0;

    for (final entry in realFields.entries) {
      final fieldName = entry.key;
      final coords = entry.value;
      final location = GeoPoint(coords['lat']!, coords['lng']!);

      // Take users for this hub
      final hubUserIds = userIds.skip(userIndex).take(playersPerHub).toList();
      userIndex += playersPerHub;

      final hubId = await generateHub(
        name: 'Hub $fieldName',
        description: 'קבוצת כדורגל פעילה במגרש $fieldName',
        memberIds: hubUserIds,
        location: location,
      );

      debugPrint('✅ Created Hub at $fieldName: $hubId');
    }

    debugPrint('🎉 All real field Hubs created!');
  }

  /// Generate games for a hub
  Future<void> _generateGamesForHub(
      String hubId, List<String> memberIds, GeoPoint? hubLocation) async {
    if (memberIds.length < 10) return; // Need at least 10 players for games

    // Use hub location if provided, otherwise random
    final gameLocation = hubLocation ?? _randomCoordinateNearHaifa();

    // Generate 2-5 past games
    final pastGamesCount = 2 + random.nextInt(4);
    for (int i = 0; i < pastGamesCount; i++) {
      await _generateGame(
        hubId: hubId,
        memberIds: memberIds,
        isPast: true,
        daysAgo: random.nextInt(30),
        location: gameLocation,
      );
    }

    // Generate 1-3 future games
    final futureGamesCount = 1 + random.nextInt(3);
    for (int i = 0; i < futureGamesCount; i++) {
      await _generateGame(
        hubId: hubId,
        memberIds: memberIds,
        isPast: false,
        daysAhead: random.nextInt(14),
        location: gameLocation,
      );
    }
  }

  /// Generate a single game
  Future<void> _generateGame({
    required String hubId,
    required List<String> memberIds,
    required bool isPast,
    int? daysAgo,
    int? daysAhead,
    GeoPoint? location,
  }) async {
    final gameId = firestore.collection('games').doc().id;
    final gameDate = isPast
        ? DateTime.now().subtract(Duration(days: daysAgo ?? 0))
        : DateTime.now().add(Duration(days: daysAhead ?? 0));

    // Select random players (10-20 players)
    final playerCount = 10 + random.nextInt(11);
    final selectedPlayers =
        (memberIds.toList()..shuffle()).take(playerCount).toList();

    final gameLocation = location ?? _randomCoordinateNearHaifa();
    final geohash =
        GeohashUtils.encode(gameLocation.latitude, gameLocation.longitude);

    final game = Game(
      gameId: gameId,
      hubId: hubId,
      createdBy: memberIds[0],
      gameDate: gameDate,
      locationPoint: gameLocation,
      geohash: geohash,
      teamCount: 2,
      status: isPast ? GameStatus.completed : GameStatus.teamSelection,
      createdAt: gameDate.subtract(const Duration(days: 7)),
      updatedAt: gameDate.subtract(const Duration(days: 7)),
    );

    await firestore.doc(FirestorePaths.game(gameId)).set(game.toJson());

    // Create signups for selected players
    for (final playerId in selectedPlayers) {
      final signup = GameSignup(
        playerId: playerId,
        signedUpAt: gameDate.subtract(const Duration(days: 7)),
        status: SignupStatus.confirmed,
      );
      await firestore
          .doc(FirestorePaths.gameSignup(gameId, playerId))
          .set(signup.toJson());
    }

    // Generate some feed posts about the game
    if (isPast && random.nextDouble() > 0.5) {
      await _generateFeedPost(hubId, memberIds[0], gameId);
    }
  }

  /// Generate a feed post
  Future<void> _generateFeedPost(
      String hubId, String authorId, String? gameId) async {
    final postId = firestore
        .collection('hubs')
        .doc(hubId)
        .collection('feed')
        .doc('posts')
        .collection('items')
        .doc()
        .id;

    final messages = [
      'משחק מעולה היום! תודה לכל מי שהגיע',
      'נהדר לשחק איתכם, עד המשחק הבא!',
      'משחק תחרותי ומהנה, מחכים לפעם הבאה',
      'כיף גדול! תודה על המשחק',
    ];

    final post = FeedPost(
      postId: postId,
      hubId: hubId,
      authorId: authorId,
      type: 'post',
      content: messages[random.nextInt(messages.length)],
      gameId: gameId,
      createdAt: DateTime.now().subtract(Duration(hours: random.nextInt(48))),
      likes: List.generate(
          random.nextInt(10), (i) => 'user_$i'), // Dummy user IDs for likes
    );

    await firestore
        .collection('hubs')
        .doc(hubId)
        .collection('feed')
        .doc('posts')
        .collection('items')
        .doc(postId)
        .set(post.toJson());
  }

  /// Generate 25 players with real photos and "השדים האדומים" Hub
  Future<void> generateRedDevilsHub() async {
    print('👹 Generating "השדים האדומים" Hub with 25 players...');

    final batch = firestore.batch();

    // Create hub first to get hubId
    final hubId = firestore.collection('hubs').doc().id;
    final hubLocation = GeoPoint(32.8000, 34.9800); // גן דניאל area
    final hubGeohash =
        GeohashUtils.encode(hubLocation.latitude, hubLocation.longitude);
    final hubPhotoUrl =
        'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&h=600&fit=crop';

    // Israeli male names for players (25 male names)
    final playerNames = [
      'יואב כהן',
      'דני לוי',
      'אור מזרחי',
      'רונן דהן',
      'עמית אברהם',
      'אלון ישראל',
      'תומר דוד',
      'ניר יוסף',
      'רועי משה',
      'איתי יעקב',
      'שרון בן דוד',
      'אורן עזרא',
      'ליאור שלום',
      'רן חיים',
      'גיל אליהו',
      'עומר שמעון',
      'רוי רחמים',
      'מור יצחק',
      'עדי אהרון',
      'טל שלמה',
      'אורן כהן',
      'רן לוי',
      'גיל מזרחי',
      'עומר דהן',
      'רוי אברהם',
    ];

    final cities = ['חיפה', 'קריית אתא', 'קריית ביאליק', 'קריית ים', 'נשר'];
    final positions = ['Goalkeeper', 'Defender', 'Midfielder', 'Forward'];

    // Generate 25 players with photos
    final userIds = <String>[];
    for (int i = 0; i < 25; i++) {
      final nameParts = playerNames[i].split(' ');
      final firstName = nameParts[0];
      final lastName = nameParts.length > 1 ? nameParts[1] : 'כהן';

      // Use real photos of men (aged 25-50) from Random User API
      // Using different IDs for varied realistic photos
      final photoIds = [
        47,
        52,
        58,
        64,
        68,
        72,
        78,
        84,
        90,
        96,
        102,
        108,
        114,
        120,
        126,
        132,
        138,
        144,
        150,
        156,
        162,
        168,
        174,
        180,
        186
      ];
      // Random User API provides real-looking photos of people
      final photoUrl =
          'https://randomuser.me/api/portraits/men/${photoIds[i]}.jpg';

      final userId = firestore.collection('users').doc().id;
      final location = GeoPoint(
        32.8000 + (i % 5) * 0.01, // Spread around Haifa
        34.9800 + (i % 5) * 0.01,
      );
      final geohash =
          GeohashUtils.encode(location.latitude, location.longitude);

      final user = User(
        uid: userId,
        name: playerNames[i],
        email:
            '${firstName.toLowerCase()}.${lastName.toLowerCase()}@kickadoor.local',
        birthDate:
            DateTime.now().subtract(Duration(days: 365 * (20 + (i % 15)))),
        phoneNumber:
            '05${(i % 9) + 1}${(i * 1234567).toString().padLeft(7, '0').substring(0, 7)}',
        city: cities[i % cities.length],
        preferredPosition: positions[i % positions.length],
        availabilityStatus:
            i % 3 == 0 ? 'available' : (i % 3 == 1 ? 'busy' : 'notAvailable'),
        createdAt: DateTime.now().subtract(Duration(days: 30 + i)),
        currentRankScore: 5.0 + (i % 30) / 10.0, // 5.0-7.9
        totalParticipations: 10 + i * 2,
        location: location,
        geohash: geohash,
        photoUrl: photoUrl, // Add photo URL - real photos of men
        hubIds: i < 18 ? [hubId] : [], // First 18 are in the hub
      );

      batch.set(firestore.doc(FirestorePaths.user(userId)), user.toJson());
      userIds.add(userId);
      print('✅ Added player to batch ${i + 1}/25: ${playerNames[i]}');
    }

    // Create "השדים האדומים" Hub with first 18 players
    final hubMemberIds = userIds.take(18).toList();

    // Add current user if available
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null && !hubMemberIds.contains(currentUser.uid)) {
      hubMemberIds.insert(0, currentUser.uid);
    }

    final hub = Hub(
      hubId: hubId,
      name: 'השדים האדומים',
      description:
          'קבוצת כדורגל פעילה וחזקה מחיפה. משחקים קבועים במגרש גן דניאל. קבוצה תחרותית עם מסורת ארוכה.',
      createdBy: currentUser?.uid ?? hubMemberIds[0],
      memberCount: hubMemberIds.length, // Use memberCount instead of memberIds
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      location: hubLocation,
      geohash: hubGeohash,
      settings: {
        'ratingMode': 'advanced',
        'photoUrl': hubPhotoUrl, // Add hub photo
      },
    );

    final hubRef = firestore.doc(FirestorePaths.hub(hubId));
    batch.set(hubRef, hub.toJson());

    // Add members to subcollection (Strategy C)
    for (final memberId in hubMemberIds) {
      batch.set(
        hubRef.collection('members').doc(memberId),
        {
          'joinedAt': FieldValue.serverTimestamp(),
          'role': memberId == hubMemberIds[0] ? 'manager' : 'member',
        },
      );
    }

    // Commit all users and hub in one batch
    await batch.commit();
    print('✅ Committed batch with 25 users and 1 hub');

    // Generate games for this hub
    await _generateGamesForHub(hubId, hubMemberIds, hubLocation);

    print(
        '🎉 Created "השדים האדומים" Hub with ${hubMemberIds.length} players!');
    print('📊 Total players created: 25');
    print('👥 Players in Hub: 18');
    print('👤 Players not in Hub: 7');
  }

  /// Generate comprehensive dummy data
  /// Creates 20 users, 3 hubs, assigns players, and creates past games with stats
  Future<void> generateComprehensiveData() async {
    // ignore: avoid_print
    print('🚀 Starting comprehensive dummy data generation...');
    print('📊 Generating 20 users, 3 hubs, and game history...');

    // Step 1: Generate 20 users with Israeli names, photos, and playing styles
    print('\n👥 Step 1: Generating 20 users...');
    final userBatch = firestore.batch();
    // Use local batch variable for users
    final batch = userBatch;
    final userIds = <String>[];

    for (int i = 0; i < 20; i++) {
      final firstName = firstNames[random.nextInt(firstNames.length)];
      final lastName = lastNames[random.nextInt(lastNames.length)];
      final fullName = '$firstName $lastName';

      // Use random user photos (men for variety)
      final photoId = 47 + (i * 3); // Vary photo IDs
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
            '${firstName.toLowerCase()}.${lastName.toLowerCase()}@kickadoor.local',
        birthDate: DateTime.now()
            .subtract(Duration(days: 365 * (18 + random.nextInt(15)))),
        phoneNumber:
            '05${random.nextInt(9)}${random.nextInt(9999999).toString().padLeft(7, '0')}',
        city: cities[random.nextInt(cities.length)],
        preferredPosition: positions[random.nextInt(positions.length)],
        availabilityStatus: [
          'available',
          'busy',
          'notAvailable'
        ][random.nextInt(3)],
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
        currentRankScore: 4.0 + random.nextDouble() * 3.0, // 4.0-7.0
        totalParticipations: random.nextInt(50),
        location: location,
        geohash: geohash,
        photoUrl: photoUrl, // Add photo URL
        region: regions[random.nextInt(regions.length)], // Add random region
      );

      batch.set(firestore.doc(FirestorePaths.user(userId)), user.toJson());
      userIds.add(userId);

      if ((i + 1) % 5 == 0) {
        print('✅ Prepared ${i + 1}/20 users for batch');
      }
    }

    await batch.commit();
    print('✅ Committed batch with 20 users');

    // Step 2: Create 3 hubs with names
    print('\n🏟️ Step 2: Creating 3 hubs...');
    final hubNames = [
      'הכוכבים של חיפה',
      'ליגת האלופות תל אביב',
      'השדים האדומים',
    ];
    final hubRegions = [
      'צפון', // חיפה
      'מרכז', // תל אביב
      'צפון', // חיפה (השדים האדומים)
    ];
    final hubDescriptions = [
      'קבוצת כדורגל פעילה וחזקה מחיפה',
      'ליגת אלופות תל אביב - משחקים תחרותיים',
      'קבוצה תחרותית עם מסורת ארוכה',
    ];

    final hubIds = <String>[];
    final hubMemberAssignments = <String, List<String>>{};

    // Distribute users: first hub gets 8, second gets 7, third gets 5
    final hubSizes = [8, 7, 5];
    int userIndex = 0;

    for (int i = 0; i < 3; i++) {
      final hubSize = hubSizes[i];
      final hubMemberIds = userIds.skip(userIndex).take(hubSize).toList();
      userIndex += hubSize;

      // First user in each hub is the manager
      final managerId = hubMemberIds[0];

      final hubLocation = _randomCoordinateNearHaifa();
      final hubGeohash =
          GeohashUtils.encode(hubLocation.latitude, hubLocation.longitude);

      final hubId = firestore.collection('hubs').doc().id;

      // Add current user to the first hub as manager
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      String creatorId = managerId;

      if (i == 0 && currentUser != null) {
        if (!hubMemberIds.contains(currentUser.uid)) {
          hubMemberIds.insert(0, currentUser.uid);
        }
        creatorId = currentUser.uid;
      }

      final hub = Hub(
        hubId: hubId,
        name: hubNames[i],
        description: hubDescriptions[i],
        createdBy: creatorId,
        createdAt: DateTime.now().subtract(Duration(days: 180 + i * 30)),
        location: hubLocation,
        geohash: hubGeohash,
        region: hubRegions[i], // Add region
        memberCount: hubMemberIds.length,
        settings: {
          'ratingMode': ['basic', 'advanced'][random.nextInt(2)],
        },
        // NOTE: roles removed - now stored in members subcollection
      );

      await firestore.doc(FirestorePaths.hub(hubId)).set(hub.toJson());
      // Add members subcollection
      final hubRef = firestore.doc(FirestorePaths.hub(hubId));
      for (final memberId in hubMemberIds) {
        await hubRef.collection('members').doc(memberId).set({
          'joinedAt': FieldValue.serverTimestamp(),
          'role': memberId == managerId ? 'manager' : 'member',
        });
      }
      hubIds.add(hubId);
      hubMemberAssignments[hubId] = hubMemberIds;

      print(
          '✅ Created hub ${i + 1}/3: ${hubNames[i]} (${hubMemberIds.length} members)'); // ignore: avoid_print
    }

    // Step 3: Create game history (5 past games per hub)
    print('\n⚽ Step 3: Creating game history (5 past games per hub)...');

    for (int hubIndex = 0; hubIndex < hubIds.length; hubIndex++) {
      final hubId = hubIds[hubIndex];
      final hubMembers = hubMemberAssignments[hubId]!;

      debugPrint('   Creating games for ${hubNames[hubIndex]}...');

      for (int gameIndex = 0; gameIndex < 5; gameIndex++) {
        // Games in the past: 1 week, 2 weeks, 3 weeks, 4 weeks, 5 weeks ago
        final daysAgo = (gameIndex + 1) * 7;
        final gameDate = DateTime.now().subtract(Duration(days: daysAgo));

        // Select 10-16 players for this game (random from hub members)
        final playerCount = 10 + random.nextInt(7);
        final selectedPlayers =
            (hubMembers.toList()..shuffle()).take(playerCount).toList();

        // Create teams (2 teams)
        final teams = _createBalancedTeams(selectedPlayers, hubMembers);

        // Random scores (e.g., 3-5, 2-4, etc.)
        final teamAScore = 1 + random.nextInt(5);
        final teamBScore = 1 + random.nextInt(5);

        // Create game document
        final gameId = firestore.collection('games').doc().id;
        final gameLocation = _randomCoordinateNearHaifa();
        final gameGeohash =
            GeohashUtils.encode(gameLocation.latitude, gameLocation.longitude);

        // Get hub to copy region
        final hubDoc = await firestore.doc(FirestorePaths.hub(hubId)).get();
        final hubData = hubDoc.data();
        final hubRegion = hubData?['region'] as String?;

        final game = Game(
          gameId: gameId,
          hubId: hubId,
          createdBy: hubMembers[0], // Manager creates the game
          gameDate: gameDate,
          locationPoint: gameLocation,
          geohash: gameGeohash,
          teamCount: 2,
          status: GameStatus.completed,
          createdAt: gameDate.subtract(const Duration(days: 7)),
          updatedAt: gameDate,
          teams: teams,
          session: GameSession(
            legacyTeamAScore: teamAScore,
            legacyTeamBScore: teamBScore,
          ),
          region: hubRegion, // Copy region from hub
        );

        await firestore.doc(FirestorePaths.game(gameId)).set(game.toJson());

        // Create signups for all selected players
        for (final playerId in selectedPlayers) {
          final signup = GameSignup(
            playerId: playerId,
            signedUpAt: gameDate.subtract(const Duration(days: 7)),
            status: SignupStatus.confirmed,
          );
          await firestore
              .doc(FirestorePaths.gameSignup(gameId, playerId))
              .set(signup.toJson());
        }

        // Generate some random game events (goals, assists, saves)
        await _generateGameEvents(
            gameId, selectedPlayers, teams, teamAScore, teamBScore);

        debugPrint(
            '     ✅ Created game ${gameIndex + 1}/5 ($daysAgo days ago, $teamAScore-$teamBScore)');
      }
    }

    debugPrint('\n🎉 Comprehensive dummy data generation complete!');
    debugPrint('📈 Generated:');
    debugPrint('   - 20 users with photos and playing styles');
    debugPrint('   - 3 hubs with assigned members');
    debugPrint('   - 15 past games (5 per hub) with scores and teams');
    debugPrint('   - Game events (goals, assists, saves)');
    debugPrint('   - Signups for all games');
    debugPrint(
        '\n💡 Note: Cloud Function onGameCompleted will automatically calculate');
    debugPrint(
        '   player statistics (points, level, gamesWon, etc.) for completed games.');
  }

  /// Create balanced teams from players
  List<Team> _createBalancedTeams(
      List<String> playerIds, List<String> allHubMembers) {
    // Shuffle players for random distribution
    final shuffled = (playerIds.toList()..shuffle());

    // Split into two teams
    final teamASize = (playerIds.length / 2).ceil();
    final teamAPlayers = shuffled.take(teamASize).toList();
    final teamBPlayers = shuffled.skip(teamASize).toList();

    return [
      Team(
        teamId: 'team_a',
        name: 'קבוצה א',
        playerIds: teamAPlayers,
        totalScore: 0.0, // Will be calculated by Cloud Function
        color: 'red',
      ),
      Team(
        teamId: 'team_b',
        name: 'קבוצה ב',
        playerIds: teamBPlayers,
        totalScore: 0.0,
        color: 'blue',
      ),
    ];
  }

  /// Generate random game events (goals, assists, saves)
  Future<void> _generateGameEvents(
    String gameId,
    List<String> playerIds,
    List<Team> teams,
    int teamAScore,
    int teamBScore,
  ) async {
    final teamAPlayers = teams[0].playerIds;
    final teamBPlayers = teams[1].playerIds;

    // Generate goals for team A
    for (int i = 0; i < teamAScore; i++) {
      final scorer = teamAPlayers[random.nextInt(teamAPlayers.length)];
      final assister = random.nextDouble() > 0.3 // 70% chance of assist
          ? teamAPlayers[random.nextInt(teamAPlayers.length)]
          : null;

      // Goal event
      await firestore.collection('games').doc(gameId).collection('events').add({
        'type': 'goal',
        'playerId': scorer,
        'gameId': gameId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Assist event (if applicable)
      if (assister != null && assister != scorer) {
        await firestore
            .collection('games')
            .doc(gameId)
            .collection('events')
            .add({
          'type': 'assist',
          'playerId': assister,
          'gameId': gameId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Generate goals for team B
    for (int i = 0; i < teamBScore; i++) {
      final scorer = teamBPlayers[random.nextInt(teamBPlayers.length)];
      final assister = random.nextDouble() > 0.3
          ? teamBPlayers[random.nextInt(teamBPlayers.length)]
          : null;

      // Goal event
      await firestore.collection('games').doc(gameId).collection('events').add({
        'type': 'goal',
        'playerId': scorer,
        'gameId': gameId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Assist event (if applicable)
      if (assister != null && assister != scorer) {
        await firestore
            .collection('games')
            .doc(gameId)
            .collection('events')
            .add({
          'type': 'assist',
          'playerId': assister,
          'gameId': gameId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Generate some saves (for goalkeepers)
    final goalkeepers = playerIds.where((id) {
      // In real implementation, check user.playingStyle == 'goalkeeper'
      // For now, randomly select some players as goalkeepers
      return random.nextDouble() > 0.7; // 30% chance
    }).toList();

    for (final goalkeeper in goalkeepers.take(2)) {
      // Max 2 saves per game
      await firestore.collection('games').doc(gameId).collection('events').add({
        'type': 'save',
        'playerId': goalkeeper,
        'gameId': gameId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Generate all dummy data (legacy method - kept for backward compatibility)
  Future<void> generateAll({
    int userCount = 30,
    int hubCount = 5,
  }) async {
    debugPrint('🚀 Starting dummy data generation...');
    debugPrint('📊 Generating $userCount users and $hubCount hubs...');

    // Generate users first
    final userIds = <String>[];
    for (int i = 0; i < userCount; i++) {
      final userId = await generateUser();
      userIds.add(userId);
      if ((i + 1) % 10 == 0) {
        debugPrint('✅ Generated ${i + 1}/$userCount users');
      }
    }

    // Generate hubs with some of the users
    final hubIds = <String>[];
    for (int i = 0; i < hubCount; i++) {
      // Select random users for this hub.
      final hubUserIds =
          (userIds.toList()..shuffle()).take(5 + random.nextInt(15)).toList();

      final hubId = await generateHub(memberIds: hubUserIds);
      hubIds.add(hubId);
      debugPrint('✅ Generated hub ${i + 1}/$hubCount: $hubId');
    }

    debugPrint('🎉 Dummy data generation complete!');
    debugPrint('📈 Generated:');
    debugPrint('   - $userCount users');
    debugPrint('   - $hubCount hubs');
    debugPrint('   - Multiple games per hub');
    debugPrint('   - Feed posts');
  }

  /// Generate Haifa Scenario: 30 Users, 6 Hubs in specific Haifa locations
  /// Each Hub has 5 distinct users (1 Manager, 4 Players)
  Future<void> generateHaifaScenario() async {
    debugPrint('🏗️ Starting Haifa Scenario generation...');

    // Haifa hub locations (specific coordinates)
    final haifaHubs = [
      {
        'name': 'טכניון FC',
        'lat': 32.7788,
        'lng': 35.0224,
        'description': 'קבוצת כדורגל של סטודנטים וסגל הטכניון',
      },
      {
        'name': 'חוף כרמל',
        'lat': 32.7900,
        'lng': 34.9600,
        'description': 'משחקים שבועיים בחוף כרמל',
      },
      {
        'name': 'מרכז הכרמל',
        'lat': 32.8000,
        'lng': 34.9800,
        'description': 'קבוצה פעילה במרכז הכרמל',
      },
      {
        'name': 'נווה שאנן',
        'lat': 32.7800,
        'lng': 35.0000,
        'description': 'כדורגל שכונתי בנווה שאנן',
      },
      {
        'name': 'קריית חיים',
        'lat': 32.8200,
        'lng': 35.0500,
        'description': 'קבוצה מקומית בקריית חיים',
      },
      {
        'name': 'סטלה מאריס',
        'lat': 32.8100,
        'lng': 34.9700,
        'description': 'משחקים בסטלה מאריס',
      },
    ];

    // Generate 30 users with Israeli names
    final israeliFirstNames = [
      'אידן',
      'עומר',
      'רונן',
      'יואב',
      'דני',
      'אור',
      'עמית',
      'אלון',
      'תומר',
      'ניר',
      'רועי',
      'איתי',
      'שרון',
      'מיכל',
      'יעל',
      'נועה',
      'תמר',
      'רותם',
      'ליאור',
      'מור',
      'עדי',
      'טל',
      'אורן',
      'אליאור',
      'אריאל',
      'דור',
      'גיל',
      'יונתן',
      'מתן',
      'נדב',
    ];

    final israeliLastNames = [
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
      'שמעון',
      'רחמים',
      'יצחק',
      'אהרון',
      'שלמה',
    ];

    final ageGroups = AgeGroup.values;
    final allUserIds = <String>[];

    // Generate 30 users
    for (int i = 0; i < 30; i++) {
      final birthDate = DateTime.now()
          .subtract(Duration(days: (365 * (18 + random.nextInt(20))).toInt()));
      final firstName = israeliFirstNames[i % israeliFirstNames.length];
      final lastName =
          israeliLastNames[random.nextInt(israeliLastNames.length)];
      final fullName = '$firstName $lastName';

      final userId = firestore.collection('users').doc().id;
      final location = GeoPoint(
        haifaLat + (random.nextDouble() - 0.5) * 0.1, // ±0.05 degrees (~5km)
        haifaLng + (random.nextDouble() - 0.5) * 0.1,
      );
      final geohash =
          GeohashUtils.encode(location.latitude, location.longitude);

      // final ageGroup = AgeUtils.getAgeGroup(birthDate); // Removed as it's not in the User model yet

      final user = User(
        uid: userId,
        name: fullName,
        firstName: firstName,
        lastName: lastName,
        email:
            '${firstName.toLowerCase()}.${lastName.toLowerCase()}@haifa.local',
        birthDate: birthDate,
        phoneNumber:
            '05${random.nextInt(9)}${random.nextInt(9999999).toString().padLeft(7, '0')}',
        city: 'חיפה',
        preferredPosition: positions[random.nextInt(positions.length)],
        availabilityStatus: 'available',
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
        currentRankScore: 4.0 + random.nextDouble() * 3.0, // 4.0-7.0
        totalParticipations: random.nextInt(50),
        location: location,
        geohash: geohash,
        region: 'צפון',
        // ageGroup: ageGroup, // This field needs to be added to the User model first
        hubIds: [], // Initialize as empty list
      );

      await firestore.doc(FirestorePaths.user(userId)).set({
        ...user.toJson(),
        'isDummy': true, // Flag for cleanup
      });

      allUserIds.add(userId);
      debugPrint('✅ Created user: $fullName ($userId)');
    }

    // Create 6 hubs, assign 5 users to each (1 Manager, 4 Players)
    final hubIds = <String>[];
    int userIndex = 0;

    for (int i = 0; i < haifaHubs.length; i++) {
      final hubData = haifaHubs[i];
      final hubId = firestore.collection('hubs').doc().id;

      // Assign 5 users to this hub
      final hubMemberIds = <String>[];
      final hubRoles = <String, String>{};

      for (int j = 0; j < 5 && userIndex < allUserIds.length; j++) {
        final userId = allUserIds[userIndex];
        hubMemberIds.add(userId);

        // First user is Manager, rest are Players
        if (j == 0) {
          hubRoles[userId] = 'manager';
        } else {
          hubRoles[userId] = 'player';
        }

        userIndex++;
      }

      final hubLocation = GeoPoint(
        (hubData['lat'] as num).toDouble(),
        (hubData['lng'] as num).toDouble(),
      );
      final geohash =
          GeohashUtils.encode(hubLocation.latitude, hubLocation.longitude);

      final hub = Hub(
        hubId: hubId,
        name: hubData['name'] as String,
        description: hubData['description'] as String?,
        createdBy: hubMemberIds.isNotEmpty ? hubMemberIds[0] : allUserIds[0],
        memberCount: hubMemberIds.length,
        region: 'צפון',
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(180))),
        location: hubLocation,
        geohash: geohash,
        settings: {
          'ratingMode': 'basic',
        },
        // NOTE: roles removed - now stored in members subcollection
      );

      await firestore.doc(FirestorePaths.hub(hubId)).set({
        ...hub.toJson(),
        'isDummy': true, // Flag for cleanup
      });

      // Add members subcollection
      final hubRef = firestore.doc(FirestorePaths.hub(hubId));
      for (int idx = 0; idx < hubMemberIds.length; idx++) {
        final memberId = hubMemberIds[idx];
        await hubRef.collection('members').doc(memberId).set({
          'joinedAt': FieldValue.serverTimestamp(),
          'role': idx == 0 ? 'manager' : 'member',
        });
      }

      // Update users' hubIds
      for (final userId in hubMemberIds) {
        await firestore.doc(FirestorePaths.user(userId)).update({
          'hubIds': FieldValue.arrayUnion([hubId]),
        });
      }

      hubIds.add(hubId);
      debugPrint(
          '✅ Created hub: ${hubData['name']} ($hubId) with ${hubMemberIds.length} members');
    }

    debugPrint('🎉 Haifa Scenario completed!');
    debugPrint('   • 30 Users created');
    debugPrint('   • 6 Hubs created');
    debugPrint('   • All flagged with isDummy: true');
  }

  /// Delete all dummy data (Users, Hubs, Games with isDummy: true)
  Future<void> deleteAllDummyData() async {
    debugPrint('🗑️ Starting dummy data cleanup...');
    int totalDeleted = 0;

    // 1. Delete dummy hubs and their subcollections
    final hubsQuery =
        firestore.collection('hubs').where('isDummy', isEqualTo: true);
    final hubsSnapshot = await hubsQuery.get();
    for (final hubDoc in hubsSnapshot.docs) {
      debugPrint('   - Deleting hub: ${hubDoc.id} (${hubDoc.data()['name']})');
      // Delete subcollections first
      totalDeleted += await _deleteCollectionInBatches(
          hubDoc.reference.collection('members'));
      totalDeleted += await _deleteCollectionInBatches(
          hubDoc.reference.collection('events'));
      totalDeleted += await _deleteCollectionInBatches(
          hubDoc.reference.collection('chatMessages'));
      // ... add other subcollections if they exist

      // Delete the hub document itself
      await hubDoc.reference.delete();
      totalDeleted++;
    }
    debugPrint(
        '   - Deleted ${hubsSnapshot.docs.length} hubs and their content.');

    // 2. Delete dummy games and their subcollections
    final gamesQuery =
        firestore.collection('games').where('isDummy', isEqualTo: true);
    final gamesSnapshot = await gamesQuery.get();
    for (final gameDoc in gamesSnapshot.docs) {
      debugPrint('   - Deleting game: ${gameDoc.id}');
      // Delete subcollections
      totalDeleted += await _deleteCollectionInBatches(
          gameDoc.reference.collection('signups'));
      totalDeleted += await _deleteCollectionInBatches(
          gameDoc.reference.collection('events'));
      // ... add other subcollections if they exist

      // Delete the game document
      await gameDoc.reference.delete();
      totalDeleted++;
    }
    debugPrint(
        '   - Deleted ${gamesSnapshot.docs.length} games and their content.');

    // 3. Delete dummy users
    final usersQuery =
        firestore.collection('users').where('isDummy', isEqualTo: true);
    final usersDeleted = await _deleteCollectionInBatches(usersQuery);
    totalDeleted += usersDeleted;
    debugPrint('   - Deleted $usersDeleted users.');

    debugPrint('✅ Deleted a total of $totalDeleted dummy documents.');
  }

  /// Create a scenario for testing team balancing
  /// Creates:
  /// 1. A new Hub
  /// 2. 14 dummy players (plus current user = 15)
  /// 3. An upcoming event
  /// 4. Registers all 15 players to the event
  Future<Map<String, String>> createTeamBalanceScenario() async {
    print('⚖️ Setting up Team Balance Scenario...');

    // 1. Get Current User
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Must be logged in to create scenario');
    }

    final batch = firestore.batch();
    final hubId = firestore.collection('hubs').doc().id;
    final eventId =
        firestore.collection('hubs').doc(hubId).collection('events').doc().id;

    // 2. Create Hub
    final hubName = 'Team Balance Arena ${random.nextInt(100)}';
    final location = _randomCoordinateNearHaifa();
    debugPrint('Creating Hub: $hubName ($hubId)');

    final hub = Hub(
      hubId: hubId,
      name: hubName,
      description: 'Testing arena for team balancing algorithms',
      createdBy: currentUser.uid,
      memberCount: 15,
      location: location,
      geohash: GeohashUtils.encode(location.latitude, location.longitude),
      createdAt: DateTime.now(),
      settings: {'ratingMode': 'advanced'},
    );

    batch.set(firestore.doc(FirestorePaths.hub(hubId)), hub.toJson());

    // 3. Create 14 Dummy Players with varied ratings/positions
    final dummyIds = <String>[];

    // Distribution for 15 players (including user):
    // 2 Goalkeepers, 6 Defenders, 5 Midfielders, 2 Attackers
    // Current user will be one of them

    final positionsToCreate = [
      'Goalkeeper',
      'Goalkeeper',
      'Defender',
      'Defender',
      'Defender',
      'Defender',
      'Defender',
      'Defender',
      'Midfielder',
      'Midfielder',
      'Midfielder',
      'Midfielder',
      'Midfielder',
      'Forward',
      'Forward'
    ];

    // Remove one meaningful position for the current user (assume Midfielder/Attacker)
    positionsToCreate.removeLast();

    for (int i = 0; i < 14; i++) {
      final userId = firestore.collection('users').doc().id;
      final position = positionsToCreate[i % positionsToCreate.length];

      // Ratings between 4.0 and 9.0
      final rating = 4.0 + random.nextDouble() * 5.0;

      final user = User(
        uid: userId,
        name: 'Player ${i + 1} ($position)',
        email: 'dummy${random.nextInt(10000)}@test.com',
        preferredPosition: position,
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
        currentRankScore: rating,
        location: location,
        geohash: GeohashUtils.encode(location.latitude, location.longitude),
        createdAt: DateTime.now(),
        // Important: Tag as dummy for cleanup
        availabilityStatus: 'dummy',
      );

      batch.set(firestore.doc(FirestorePaths.user(userId)), user.toJson());
      dummyIds.add(userId);

      // Add as Hub Member
      batch.set(
        firestore.doc(FirestorePaths.hubMember(hubId, userId)),
        {
          'joinedAt': FieldValue.serverTimestamp(),
          'role': 'member',
          'userId': userId,
          'managerRating': rating, // Set explicit manager rating for team maker
          'status': 'active'
        },
      );
    }

    // Add current user as Hub Member (Manager)
    batch.set(
      firestore.doc(FirestorePaths.hubMember(hubId, currentUser.uid)),
      {
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'manager',
        'userId': currentUser.uid,
        'managerRating': 7.5, // Default rating for manager
        'status': 'active'
      },
    );

    // 4. Create Event
    final eventDate = DateTime.now().add(const Duration(days: 2));
    final event = HubEvent(
      eventId: eventId,
      hubId: hubId,
      createdBy: currentUser.uid,
      title: 'Balancing Test Match',
      eventDate: eventDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      maxParticipants: 15,
      teamCount: 3, // 3 teams of 5
      registeredPlayerIds: [currentUser.uid, ...dummyIds],
      locationPoint: location,
      status: 'upcoming',
    );

    batch.set(
        firestore.doc(FirestorePaths.hubEvent(hubId, eventId)), event.toJson());

    await batch.commit();

    print('✅ Scenario Created!');
    return {
      'hubId': hubId,
      'eventId': eventId,
      'hubName': hubName,
      'eventTitle': event.title,
    };
  }

  /// Helper to delete a collection in batches to avoid memory issues.
  Future<int> _deleteCollectionInBatches(
      Query<Map<String, dynamic>> query) async {
    const int batchSize = 100;
    int deletedCount = 0;

    // Get documents in batches
    QuerySnapshot<Map<String, dynamic>> snapshot;
    do {
      snapshot = await query.limit(batchSize).get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      // Create a new batch for each set of documents
      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        // Recursively delete subcollections if needed
        // For now, we assume subcollections are handled by the main function
        batch.delete(doc.reference);
      }

      try {
        await batch.commit();
        deletedCount += snapshot.docs.length;
        debugPrint(
            '     ...deleted $deletedCount documents from collection...');
      } catch (e) {
        debugPrint('Error during batch delete: $e. Retrying in 1s...');
        await Future.delayed(const Duration(seconds: 1));
        // If a batch fails, we might want to retry or handle it.
        // For simplicity, we'll just log and continue.
      }

      // If we fetched a full batch, there might be more documents.
    } while (snapshot.docs.length == batchSize);

    return deletedCount;
  }
}
