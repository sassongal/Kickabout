import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';
import 'package:kickabout/utils/geohash_utils.dart';
import 'dart:math';

/// Script to generate dummy data for Haifa area
/// Run this from a Flutter app or Firebase console
class DummyDataGenerator {
  final FirebaseFirestore firestore;
  final Random random = Random();

  DummyDataGenerator({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  // Haifa area coordinates
  static const double haifaLat = 32.7940;
  static const double haifaLng = 34.9896;
  static const double radiusKm = 15.0; // 15km radius around Haifa

  // Israeli names for players
  final List<String> firstNames = [
    'יואב', 'דני', 'אור', 'רונן', 'עמית', 'אלון', 'תומר', 'ניר', 'רועי', 'איתי',
    'שרון', 'מיכל', 'יעל', 'נועה', 'תמר', 'רותם', 'ליאור', 'מור', 'עדי', 'טל',
  ];

  final List<String> lastNames = [
    'כהן', 'לוי', 'מזרחי', 'דהן', 'אברהם', 'ישראל', 'דוד', 'יוסף', 'משה', 'יעקב',
    'בן דוד', 'עזרא', 'שלום', 'חיים', 'אליהו', 'שמעון', 'רחמים', 'יצחק', 'אהרון', 'שלמה',
  ];

  final List<String> cities = [
    'חיפה', 'קריית אתא', 'קריית ביאליק', 'קריית ים', 'קריית מוצקין',
    'נשר', 'טירת כרמל', 'זכרון יעקב', 'עכו', 'נהריה',
  ];

  final List<String> positions = [
    'Goalkeeper', 'Defender', 'Midfielder', 'Forward',
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
      email: '${firstName.toLowerCase()}.${lastName.toLowerCase()}@kickabout.local',
      phoneNumber: '05${random.nextInt(9)}${random.nextInt(9999999).toString().padLeft(7, '0')}',
      city: city ?? cities[random.nextInt(cities.length)],
      preferredPosition: position ?? positions[random.nextInt(positions.length)],
      availabilityStatus: ['available', 'busy', 'notAvailable'][random.nextInt(3)],
      createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
      currentRankScore: rating ?? (4.0 + random.nextDouble() * 3.0), // 4.0-7.0
      totalParticipations: random.nextInt(50),
      location: location,
      geohash: geohash,
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
    final geohash = GeohashUtils.encode(finalLocation.latitude, finalLocation.longitude);

    final hubNames = [
      'הפועל חיפה', 'מכבי חיפה', 'בית"ר חיפה', 'הפועל קריית אתא',
      'מכבי קריית ביאליק', 'הפועל נשר', 'מכבי טירת כרמל',
      'שחקני הכרמל', 'כדורגל חיפה', 'הכרמל FC',
    ];

    final hubDescriptions = [
      'קבוצת כדורגל שכונתית פעילה',
      'משחקים שבועיים קבועים',
      'קבוצה פתוחה לכל הגילאים',
      'כדורגל חברתי וספורטיבי',
      'קבוצה עם מסורת ארוכה',
    ];

    final finalName = name ?? hubNames[random.nextInt(hubNames.length)];
    final finalDescription = description ?? 
        hubDescriptions[random.nextInt(hubDescriptions.length)];

    // Generate members if not provided
    final finalMemberIds = memberIds ?? [];
    if (finalMemberIds.isEmpty) {
      final count = memberCount ?? (5 + random.nextInt(15)); // 5-20 members
      for (int i = 0; i < count; i++) {
        final userId = await generateUser();
        finalMemberIds.add(userId);
      }
    }

    final hub = Hub(
      hubId: hubId,
      name: finalName,
      description: finalDescription,
      createdBy: finalMemberIds.isNotEmpty 
          ? finalMemberIds[0] 
          : firestore.collection('users').doc().id,
      memberIds: finalMemberIds,
      createdAt: DateTime.now().subtract(Duration(days: random.nextInt(180))),
      location: finalLocation,
      geohash: geohash,
      settings: {
        'ratingMode': ['basic', 'advanced'][random.nextInt(2)],
      },
    );

    await firestore.doc(FirestorePaths.hub(hubId)).set(hub.toJson());

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
      
      print('✅ Created Hub at $fieldName: $hubId');
    }
    
    print('🎉 All real field Hubs created!');
  }

  /// Generate games for a hub
  Future<void> _generateGamesForHub(String hubId, List<String> memberIds, GeoPoint? hubLocation) async {
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
    final selectedPlayers = (memberIds.toList()..shuffle()).take(playerCount).toList();

    final gameLocation = location ?? _randomCoordinateNearHaifa();
    final geohash = GeohashUtils.encode(gameLocation.latitude, gameLocation.longitude);

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
  Future<void> _generateFeedPost(String hubId, String authorId, String? gameId) async {
    final postId = firestore.collection('hubs').doc(hubId).collection('feed').doc('posts').collection('items').doc().id;
    
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
      likes: List.generate(random.nextInt(10), (i) => 'user_$i'), // Dummy user IDs for likes
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
    
    // Create hub first to get hubId
    final hubId = firestore.collection('hubs').doc().id;
    final hubLocation = GeoPoint(32.8000, 34.9800); // גן דניאל area
    final hubGeohash = GeohashUtils.encode(hubLocation.latitude, hubLocation.longitude);
    final hubPhotoUrl = 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&h=600&fit=crop';
    
    // Israeli male names for players (25 male names)
    final playerNames = [
      'יואב כהן', 'דני לוי', 'אור מזרחי', 'רונן דהן', 'עמית אברהם',
      'אלון ישראל', 'תומר דוד', 'ניר יוסף', 'רועי משה', 'איתי יעקב',
      'שרון בן דוד', 'אורן עזרא', 'ליאור שלום', 'רן חיים', 'גיל אליהו',
      'עומר שמעון', 'רוי רחמים', 'מור יצחק', 'עדי אהרון', 'טל שלמה',
      'אורן כהן', 'רן לוי', 'גיל מזרחי', 'עומר דהן', 'רוי אברהם',
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
      final photoIds = [47, 52, 58, 64, 68, 72, 78, 84, 90, 96, 102, 108, 114, 120, 126, 132, 138, 144, 150, 156, 162, 168, 174, 180, 186];
      // Random User API provides real-looking photos of people
      final photoUrl = 'https://randomuser.me/api/portraits/men/${photoIds[i]}.jpg';
      
      final userId = firestore.collection('users').doc().id;
      final location = GeoPoint(
        32.8000 + (i % 5) * 0.01, // Spread around Haifa
        34.9800 + (i % 5) * 0.01,
      );
      final geohash = GeohashUtils.encode(location.latitude, location.longitude);
      
      final user = User(
        uid: userId,
        name: playerNames[i],
        email: '${firstName.toLowerCase()}.${lastName.toLowerCase()}@kickadoor.local',
        phoneNumber: '05${(i % 9) + 1}${(i * 1234567).toString().padLeft(7, '0').substring(0, 7)}',
        city: cities[i % cities.length],
        preferredPosition: positions[i % positions.length],
        availabilityStatus: i % 3 == 0 ? 'available' : (i % 3 == 1 ? 'busy' : 'notAvailable'),
        createdAt: DateTime.now().subtract(Duration(days: 30 + i)),
        currentRankScore: 5.0 + (i % 30) / 10.0, // 5.0-7.9
        totalParticipations: 10 + i * 2,
        location: location,
        geohash: geohash,
        photoUrl: photoUrl, // Add photo URL - real photos of men
        hubIds: i < 18 ? [hubId] : [], // First 18 are in the hub
      );
      
      await firestore.doc(FirestorePaths.user(userId)).set(user.toJson());
      userIds.add(userId);
      print('✅ Created player ${i + 1}/25: ${playerNames[i]}');
    }
    
    // Create "השדים האדומים" Hub with first 18 players
    final hubMemberIds = userIds.take(18).toList();
    
    final hub = Hub(
      hubId: hubId,
      name: 'השדים האדומים',
      description: 'קבוצת כדורגל פעילה וחזקה מחיפה. משחקים קבועים במגרש גן דניאל. קבוצה תחרותית עם מסורת ארוכה.',
      createdBy: hubMemberIds[0],
      memberIds: hubMemberIds,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      location: hubLocation,
      geohash: hubGeohash,
      settings: {
        'ratingMode': 'advanced',
        'photoUrl': hubPhotoUrl, // Add hub photo
      },
    );
    
    await firestore.doc(FirestorePaths.hub(hubId)).set(hub.toJson());
    
    // Generate games for this hub
    await _generateGamesForHub(hubId, hubMemberIds, hubLocation);
    
    print('🎉 Created "השדים האדומים" Hub with ${hubMemberIds.length} players!');
    print('📊 Total players created: 25');
    print('👥 Players in Hub: 18');
    print('👤 Players not in Hub: 7');
  }

  /// Generate all dummy data
  Future<void> generateAll({
    int userCount = 30,
    int hubCount = 5,
  }) async {
    print('🚀 Starting dummy data generation...');
    print('📊 Generating $userCount users and $hubCount hubs...');

    // Generate users first
    final userIds = <String>[];
    for (int i = 0; i < userCount; i++) {
      final userId = await generateUser();
      userIds.add(userId);
      if ((i + 1) % 10 == 0) {
        print('✅ Generated ${i + 1}/$userCount users');
      }
    }

    // Generate hubs with some of the users
    final hubIds = <String>[];
    for (int i = 0; i < hubCount; i++) {
      // Select random users for this hub
      final hubUserIds = (userIds.toList()..shuffle())
          .take(5 + random.nextInt(15))
          .toList();
      
      final hubId = await generateHub(memberIds: hubUserIds);
      hubIds.add(hubId);
      print('✅ Generated hub ${i + 1}/$hubCount: $hubId');
    }

    print('🎉 Dummy data generation complete!');
    print('📈 Generated:');
    print('   - $userCount users');
    print('   - $hubCount hubs');
    print('   - Multiple games per hub');
    print('   - Feed posts');
  }
}

