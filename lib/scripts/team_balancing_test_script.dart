import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/hubs/domain/models/hub_settings.dart';
import 'package:kattrick/features/hubs/domain/models/hub_event.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/utils/geohash_utils.dart';
import 'package:kattrick/features/hubs/domain/services/hub_creation_service.dart';
import 'package:kattrick/features/hubs/data/repositories/hubs_repository.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Comprehensive script for testing Team Balancing
/// Creates: New Hub + 15 Players + 1 Event (Winner Stays)
///
/// UPDATES:
/// - Uses [HubEvent] instead of [Game]
/// - Generates physical data: Height, Weight, Preferred Foot
/// - Improved cleanup function
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

  /// First names list
  final List<String> firstNames = [
    'Yoav',
    'Dani',
    'Or',
    'Ronen',
    'Amit',
    'Alon',
    'Tomer',
    'Nir',
    'Roi',
    'Itay',
    'Sharon',
    'Oren',
    'Lior',
    'Ran',
    'Gil',
    'Omer',
    'Roy',
    'Mor',
    'Adi',
    'Tal',
    'Idan',
    'Yossi',
    'Moshe',
    'David',
    'Kobi',
    'Shay',
    'Yair',
    'Erez',
    'Guy',
    'Yaniv'
  ];

  /// Last names list
  final List<String> lastNames = [
    'Cohen',
    'Levi',
    'Mizrachi',
    'Dahan',
    'Avraham',
    'Israel',
    'David',
    'Yosef',
    'Moshe',
    'Yaakov',
    'Ben David',
    'Ezra',
    'Shalom',
    'Haim',
    'Eliyahu',
    'Feldman',
    'Golan',
    'Bar',
    'Sason',
    'Gabay'
  ];

  /// Cities near Haifa
  final List<String> cities = [
    'Haifa',
    'Kiryat Ata',
    'Kiryat Bialik',
    'Kiryat Yam',
    'Kiryat Motzkin',
    'Nesher',
  ];

  /// Positions
  final List<String> positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
  ];

  /// Generate height based on position (cm)
  double _generateHeight(String position) {
    switch (position) {
      case 'Goalkeeper':
        return 180.0 + (random.nextDouble() * 15); // 180-195
      case 'Defender':
        return 175.0 + (random.nextDouble() * 15); // 175-190
      case 'Midfielder':
        return 170.0 + (random.nextDouble() * 12); // 170-182
      case 'Forward':
        return 172.0 + (random.nextDouble() * 13); // 172-185
      default:
        return 175.0 + (random.nextDouble() * 10); // 175-185
    }
  }

  /// Generate weight based on height and position (kg)
  double _generateWeight(double height, String position) {
    // Basic BMI calculation for athletic build
    final idealBMI = position == 'Goalkeeper' ? 24.0 : 22.5;
    final heightM = height / 100.0;
    final baseWeight = idealBMI * (heightM * heightM);
    // Add some variation
    return baseWeight + (random.nextDouble() * 8 - 4); // ±4 kg
  }

  /// Generate preferred foot
  String _randomPreferredFoot() {
    final roll = random.nextDouble();
    if (roll < 0.70) return 'right'; // 70% Right
    if (roll < 0.90) return 'left'; // 20% Left
    return 'both'; // 10% Both
  }

  /// Generate random coordinate near Haifa
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

  /// Main function - Creates complete scenario
  Future<Map<String, dynamic>> createCompleteTestScenario({
    String? managerEmail,
  }) async {
    debugPrint('🚀 Starting Team Balancing Scenario Creation...\n');

    final batch = firestore.batch();
    final hubLocation = GeographicPoint(
      latitude: 32.8000,
      longitude: 34.9800,
    ); // Gan Daniel, Haifa
    final hubGeohash =
        GeohashUtils.encode(hubLocation.latitude, hubLocation.longitude);

    // Step 1: Get/Create Manager User
    debugPrint('📝 Step 1: Identifying Manager User...');
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    String managerId =
        currentUser?.uid ?? ''; // Initialize with empty string or current uid
    User? managerUserObj;

    if (currentUser != null) {
      // managerId already set
      // Fetch current user data to update if needed
      final userDoc = await firestore.doc(FirestorePaths.user(managerId)).get();
      if (userDoc.exists) {
        managerUserObj = User.fromJson({...userDoc.data()!, 'uid': managerId});
        debugPrint(
            '✅ Logged in user: ${currentUser.email} (${currentUser.uid})');
      }
    }

    if (managerUserObj == null) {
      debugPrint(
          '⚠️ No logged in user found or user doc missing. Creating fallback manager...');
      // Fallback: Create new manager user
      managerId = currentUser?.uid ?? firestore.collection('users').doc().id;
      final height = _generateHeight('Midfielder');

      managerUserObj = User(
        uid: managerId,
        name: 'Gal Sasson',
        email: managerEmail ?? 'gal@joya-tech.net',
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
        phoneNumber: '0541234567',
        city: 'Haifa',
        preferredPosition: 'Midfielder',
        createdAt: DateTime.now(),
        // New Physical Data
        heightCm: height,
        weightKg: _generateWeight(height, 'Midfielder'),
        preferredFoot: 'right',
        // Legacy
        currentRankScore: 7.5,
        totalParticipations: 100,
        location: hubLocation,
        geohash: hubGeohash,
        isProfileComplete: true,
      );

      batch.set(
        firestore.doc(FirestorePaths.user(managerId)),
        managerUserObj.toJson(),
      );
      debugPrint('✅ Created new manager user: $managerId');
    } else {
      // Update existing manager with physical data if missing
      Map<String, dynamic> updates = {};
      if (managerUserObj.heightCm == null) {
        final h = _generateHeight(managerUserObj.preferredPosition);
        updates['heightCm'] = h;
        updates['weightKg'] =
            _generateWeight(h, managerUserObj.preferredPosition);
      }
      if (managerUserObj.preferredFoot == null) {
        updates['preferredFoot'] = _randomPreferredFoot();
      }

      if (updates.isNotEmpty) {
        batch.update(firestore.doc(FirestorePaths.user(managerId)), updates);
        debugPrint('✅ Updated manager user with physical data');
      }
    }

    // Step 2: Create Hub
    debugPrint('\n🏟️ Step 2: Creating New Hub...');
    final hubId = firestore.collection('hubs').doc().id;
    final hub = Hub(
      hubId: hubId,
      name: 'Team Balancing Test Hub',
      description: 'Hub for testing algorithm with 15 players (Winner Stays)',
      createdBy: managerId,
      memberCount: 15, // 14 dummies + 1 manager
      region: 'North',
      createdAt: DateTime.now(),
      location: hubLocation,
      geohash: hubGeohash,
      settings: const HubSettings(),
    );

    // Use HubCreationService
    await _hubCreationService.createHub(hub);

    debugPrint('✅ Hub Created: $hubId');

    // Step 3: Create 14 Dummy Players + Manager = 15 Total
    debugPrint('\n👥 Step 3: Creating 14 Dummy Players + You = 15 Total...');
    final playerIds = <String>[];

    // Rating distribution: 3 Weak (4-5), 9 Average (5-7), 3 Strong (7-9)
    final ratings = [
      4.2, 4.5, 4.8, // Low
      5.2, 5.5, 5.8, 6.0, 6.3, 6.5, 6.7, 7.0, 7.2, // Mid
      7.5, 8.0, 8.5, // High
    ];
    ratings.shuffle();

    // Add Manager as first player
    playerIds.add(managerId);
    final managerRating = ratings[0];

    // Update Manager Rating in Hub
    await firestore
        .doc(FirestorePaths.hub(hubId))
        .collection('members')
        .doc(managerId)
        .update({
      'managerRating': managerRating,
    });
    debugPrint(
        '   ✅ 1/15: Manager - Rating: ${managerRating.toStringAsFixed(1)}');

    // Create 14 Dummies
    final userBatch = firestore.batch();
    for (int i = 0; i < 14; i++) {
      final firstName = firstNames[random.nextInt(firstNames.length)];
      final lastName = lastNames[random.nextInt(lastNames.length)];
      final fullName = '$firstName $lastName';
      final position = positions[random.nextInt(positions.length)];

      final photoId = 47 + (i * 3);
      final photoUrl =
          'https://randomuser.me/api/portraits/men/${photoId % 100}.jpg';

      final userId = firestore.collection('users').doc().id;
      final location = _randomCoordinateNearHaifa();
      final geohash =
          GeohashUtils.encode(location.latitude, location.longitude);

      // Calculate Physical Data
      final height = _generateHeight(position);
      final weight = _generateWeight(height, position);
      final pFoot = _randomPreferredFoot();

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
        preferredPosition: position,
        availabilityStatus: 'available',
        createdAt: DateTime.now().subtract(Duration(days: i)),

        // Physical Data
        heightCm: height,
        weightKg: weight,
        preferredFoot: pFoot,

        // Legacy/Other
        currentRankScore: ratings[i + 1],
        totalParticipations: 10 + random.nextInt(40),
        location: location,
        geohash: geohash,
        photoUrl: photoUrl,
        hubIds: [], // Updated by repository
        isProfileComplete: true,
      );

      userBatch.set(firestore.doc(FirestorePaths.user(userId)), user.toJson());
      playerIds.add(userId);

      debugPrint(
          '   ✅ ${i + 2}/15: $fullName ($position, ${height.round()}cm, $pFoot) - Rating: ${ratings[i + 1].toStringAsFixed(1)}');
    }

    // Commit User Creation
    await userBatch.commit();

    // Add Members to Hub with Ratings
    for (int i = 0; i < playerIds.length - 1; i++) {
      // Skip manager (already added via createHub)
      final userId = playerIds[i + 1];
      await _hubsRepository.addMember(hubId, userId);

      // Update managerRating (Fix: ratings index should be i + 1)
      await firestore
          .doc(FirestorePaths.hub(hubId))
          .collection('members')
          .doc(userId)
          .update({
        'managerRating': ratings[i + 1],
      });
    }

    // CRITICAL: Manually sync denormalized arrays on the Hub document
    // This ensures visibility even if Cloud Functions are not running or are slow
    debugPrint('\n🔄 Manually syncing denormalized member arrays...');
    await firestore.doc(FirestorePaths.hub(hubId)).update({
      'activeMemberIds': playerIds,
      'memberIds': playerIds,
      'managerIds': [managerId],
      'moderatorIds': <String>[],
      'memberCount': 15,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('✅ Hub document fully synced (15 members).');

    // Step 4: Create HubEvent (Winner Stays)
    debugPrint('\n📅 Step 4: Creating HubEvent (Winner Stays)...');

    final eventDocRef =
        firestore.collection(FirestorePaths.hubEvents(hubId)).doc();
    final eventId = eventDocRef.id;

    final eventDate = DateTime.now().add(const Duration(hours: 2));

    final event = HubEvent(
      eventId: eventId,
      hubId: hubId,
      createdBy: managerId,
      title: 'Testing: Winner Stays 5v5',
      description: 'Automated test event for team balancing',
      eventDate: eventDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'upcoming',
      location: 'Gan Daniel',
      locationPoint: hubLocation,
      geohash: hubGeohash,
      teamCount: 3, // 3 Teams
      gameType: '5v5',
      maxParticipants: 15,
      // Initially empty signups, added below
    );

    // We can't use batch for subcollection create easily if parent path dynamic,
    // but firestore paths are absolute here.
    batch.set(eventDocRef, event.toJson());

    debugPrint('✅ Event Created: $eventId (via HubEvent)');

    // Step 5: Register all 15 players
    debugPrint(
        '\n📝 Step 5: Registering 15 players via \'signups\' subcollection...');

    for (int i = 0; i < playerIds.length; i++) {
      // Note: In HubEvent, signups are in a subcollection OR in registeredPlayerIds array
      // We should do BOTH for read optimization if the model supports it,
      // but typically we write to subcollection and Cloud Functions sync the array.
      // However, to be safe and immediate, we will update the array in the event document too at end,
      // OR just rely on the subcollection if the app reads from it.
      // Looking at HubEvent model, it has `registeredPlayerIds` list.

      // Let's create the signup document
      final signupRef = eventDocRef.collection('signups').doc(playerIds[i]);

      // Using generic map or specific Signup model?
      // Usually `GameSignup` model is used for `games`, check if `HubEvent` has `HubEventSignup`.
      // For now assuming standard signup structure compatible with GameSignup
      final signupData = {
        'playerId': playerIds[i],
        'signedUpAt': DateTime.now().subtract(Duration(hours: 15 - i)),
        'status': 'confirmed',
        'hubId': hubId,
        'eventId': eventId,
      };

      batch.set(signupRef, signupData);
    }

    // Update the registeredPlayerIds array directly on the event so the UI shows count immediately
    // without waiting for Cloud Functions (if any).
    batch.update(eventDocRef, {'registeredPlayerIds': playerIds});

    debugPrint('✅ All 15 players registered.');

    // Commit Final Batch
    debugPrint('\n💾 Saving all data to Firestore...');
    try {
      await batch.commit();
      debugPrint('✅ All data saved successfully!');
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving data: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }

    // Summary
    debugPrint('\n${'=' * 60}');
    debugPrint('🎉 Scenario Created Successfully!');
    debugPrint('=' * 60);
    debugPrint('   🏟️ Hub ID: $hubId');
    debugPrint('   📅 Event ID: $eventId');
    debugPrint('   👤 Manager ID: $managerId');
    debugPrint('   👥 Players: 15 (inc. physical data)');
    debugPrint('   ✅ Ready for Team Balancing');
    debugPrint('=' * 60);

    return {
      'hubId': hubId,
      'eventId': eventId,
      'managerId': managerId,
      'playerIds': playerIds,
      'success': true,
      'message': 'Scenario created: Hub $hubId, Event $eventId, 15 Players',
    };
  }

  /// Cleanup Function - Robust Deletion
  Future<void> cleanupTestScenario({
    required String hubId,
    required String eventId,
    required List<String> playerIds,
  }) async {
    debugPrint('🧹 Cleaning up test scenario...');

    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid;

      if (currentUserId == null) {
        debugPrint('⚠️ Cannot cleanup: No logged in user (need permissions)');
        return;
      }

      // 1. Check if Hub exists
      final hubDoc = await firestore.doc(FirestorePaths.hub(hubId)).get();
      if (!hubDoc.exists) {
        debugPrint('⚠️ Hub $hubId not found, skipping cleanup');
        return;
      }

      // 2. Use HubsRepository.deleteHub which handles:
      // - Games
      // - Members
      // - Events
      // - The Hub itself
      // - User.hubIds cleaning
      debugPrint('🗑️ Calling HubsRepository.deleteHub...');
      await _hubsRepository.deleteHub(hubId, currentUserId);
      debugPrint('✅ Hub and subcollections deleted.');

      // 3. Delete Dummy Users (SKIP Manager/Real User)
      debugPrint('🗑️ Deleting dummy users...');
      final batch = firestore.batch();
      int deletedCount = 0;

      for (final pid in playerIds) {
        // NEVER delete the current logged in user (you!)
        if (pid == currentUserId) continue;

        batch.delete(firestore.doc(FirestorePaths.user(pid)));
        deletedCount++;
      }

      if (deletedCount > 0) {
        await batch.commit();
        debugPrint('✅ Deleted $deletedCount dummy user accounts.');
      }

      debugPrint('✨ Cleanup Complete!');
    } catch (e) {
      debugPrint('❌ Cleanup Failed: $e');
      rethrow;
    }
  }
}
