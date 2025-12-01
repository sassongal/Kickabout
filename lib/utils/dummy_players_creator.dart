import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/geohash_utils.dart';
import 'package:kattrick/data/hubs_repository.dart';
import 'package:kattrick/services/firestore_paths.dart';

/// Enhanced dummy players creator that respects hub settings
/// Creates variable number of players with realistic data matching hub location, region, age
/// This is a development utility - run once to populate test data
class DummyPlayersCreator {
  final FirebaseFirestore _firestore;
  final HubsRepository _hubsRepo;
  final String hubId;
  final String managerId;
  final Random _random = Random();

  DummyPlayersCreator({
    required this.hubId,
    required this.managerId,
    FirebaseFirestore? firestore,
    HubsRepository? hubsRepo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _hubsRepo = hubsRepo ?? HubsRepository(firestore: firestore);

  // Israeli names pools
  static const List<String> _firstNames = [
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
    'אורן',
    'ירון',
    'רון',
    'גל',
    'דור',
    'לירן',
    'יונתן',
    'אופיר',
    'אלירז',
    'אליאל',
  ];

  static const List<String> _lastNames = [
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
    'גולן',
    'רובין',
    'כץ',
    'ברוך',
    'פישר',
    'וייס',
    'ברגר',
    'שטרן',
    'גרוס',
  ];

  static const List<String> _positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Attacker',
  ];

  static const List<String> _cities = [
    'חיפה',
    'תל אביב',
    'ירושלים',
    'באר שבע',
    'אשדוד',
    'רמת גן',
    'נתניה',
    'בת ים',
    'חולון',
    'ראשון לציון',
    'רחובות',
    'אשקלון',
    'קריית אתא',
    'קריית מוצקין',
    'נשר',
  ];

  static const List<String> _regions = [
    'צפון',
    'מרכז',
    'דרום',
    'ירושלים',
  ];

  /// Creates dummy players with variable count, respecting hub settings
  /// [count] - Number of players to create (default: 10)
  /// Returns list of created player IDs
  Future<List<String>> createDummyPlayers({
    int count = 10,
  }) async {
    // Load hub to get settings
    final hub = await _hubsRepo.getHub(hubId);
    if (hub == null) {
      throw Exception('Hub not found: $hubId');
    }

    final playerIds = <String>[];
    final managerRatings = <String, double>{};

    print('Creating $count dummy players for Hub: ${hub.name}...');
    print('Hub location: ${hub.primaryVenueLocation ?? hub.location}');
    print('Hub region: ${hub.region ?? "לא מוגדר"}');

    // Get hub location for generating nearby coordinates
    GeoPoint? hubLocation = hub.primaryVenueLocation ?? hub.location;

    for (var i = 0; i < count; i++) {
      // Generate random player data
      final firstName = _firstNames[_random.nextInt(_firstNames.length)];
      final lastName = _lastNames[_random.nextInt(_lastNames.length)];
      final position = _positions[_random.nextInt(_positions.length)];

      // Generate rating (5.0 to 9.5)
      final rating = 5.0 + (_random.nextDouble() * 4.5);

      // Generate age (18-45 for realistic distribution)
      final age = 18 + _random.nextInt(28); // 18-45
      final birthDate = DateTime.now().subtract(Duration(days: age * 365));

      // Generate location based on hub location
      GeoPoint? location;
      String? geohash;
      String? city;
      String? region;

      if (hubLocation != null) {
        // Generate location within 10km radius of hub
        location = _generateNearbyLocation(hubLocation);
        geohash = GeohashUtils.encode(location.latitude, location.longitude);
        city = _cities[_random.nextInt(_cities.length)];
        region = hub.region ?? _regions[_random.nextInt(_regions.length)];
      } else {
        city = _cities[_random.nextInt(_cities.length)];
        region = hub.region ?? _regions[_random.nextInt(_regions.length)];
      }

      // Generate unique email
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email =
          '$firstName.${lastName.toLowerCase()}.$timestamp@dummy.test';

      // Generate phone number
      final phoneNumber =
          '05${_random.nextInt(9)}${_random.nextInt(9999999).toString().padLeft(7, '0')}';

      // Generate photo URL (random user photos)
      final photoId = _random.nextInt(99);
      final photoUrl = 'https://randomuser.me/api/portraits/men/$photoId.jpg';

      // Create user document
      final userId = 'dummy_${hubId}_${timestamp}_$i';
      playerIds.add(userId);

      final user = User(
        uid: userId,
        name: '$firstName $lastName',
        email: email,
        displayName: '$firstName $lastName',
        firstName: firstName,
        lastName: lastName,
        preferredPosition: position,
        birthDate: birthDate,
        phoneNumber: phoneNumber,
        city: city,
        region: region,
        location: location,
        geohash: geohash,
        photoUrl: photoUrl,
        hubIds: [hubId],
        createdAt: DateTime.now(),
        currentRankScore: rating,
        isActive: true,
        isProfileComplete: true,
      );

      // Create user document
      await _firestore.doc(FirestorePaths.user(userId)).set(user.toJson());

      // Add to hub using HubsRepository (proper way)
      try {
        await _hubsRepo.addMember(hubId, userId);
      } catch (e) {
        // If already a member, continue
        print('⚠️ Player $userId already a member: $e');
      }

      // Set manager rating
      managerRatings[userId] = rating;

      print(
          '✓ Created player: $firstName $lastName (גיל: $age, דירוג: ${rating.toStringAsFixed(1)}, תפקיד: $position)');
    }

    // Update hub with manager ratings
    if (managerRatings.isNotEmpty) {
      final currentRatings = Map<String, double>.from(hub.managerRatings);
      currentRatings.addAll(managerRatings);

      await _firestore.doc(FirestorePaths.hub(hubId)).update({
        'managerRatings': currentRatings,
      });
    }

    print('\n✅ Successfully created ${playerIds.length} dummy players!');
    print('Manager ratings updated in hub.');

    return playerIds;
  }

  /// Generate a random location within 10km radius of a center point
  GeoPoint _generateNearbyLocation(GeoPoint center) {
    final angle = _random.nextDouble() * 2 * pi;
    final distanceKm = _random.nextDouble() * 10.0; // Up to 10km

    // Convert km to degrees (approximately)
    final latOffset = (distanceKm * cos(angle)) / 111.0;
    final lngOffset =
        (distanceKm * sin(angle)) / (111.0 * cos(center.latitude * pi / 180));

    return GeoPoint(
      center.latitude + latOffset,
      center.longitude + lngOffset,
    );
  }

  /// Register all dummy players to an event
  Future<void> registerPlayersToEvent(
      String eventId, List<String> playerIds) async {
    await _firestore
        .collection('hubs')
        .doc(hubId)
        .collection('events')
        .doc(eventId)
        .update({
      'registeredPlayerIds': FieldValue.arrayUnion(playerIds),
    });

    print('✅ Registered ${playerIds.length} players to event $eventId');
  }

  /// Complete setup: create players and register to event
  /// [playerCount] - Number of players to create (default: 15 for events)
  Future<void> setupDummyPlayersForEvent(
    String eventId, {
    int playerCount = 15,
  }) async {
    final playerIds = await createDummyPlayers(count: playerCount);
    await registerPlayersToEvent(eventId, playerIds);
    print(
        '\n🎉 Setup complete! Created $playerCount players and registered them to event $eventId');
    print('You can now use team maker with these players.');
  }

  /// Create players and register to event in one call (convenience method)
  /// [playerCount] - Number of players to create (default: 15)
  Future<List<String>> createAndRegisterToEvent(
    String eventId, {
    int playerCount = 15,
  }) async {
    final playerIds = await createDummyPlayers(count: playerCount);
    await registerPlayersToEvent(eventId, playerIds);
    return playerIds;
  }
}
