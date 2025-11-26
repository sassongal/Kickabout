import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/models/models.dart';

/// Create dummy players for testing
/// This is a development utility - run once to populate test data
class DummyPlayersCreator {
  final FirebaseFirestore _firestore;
  final String hubId;
  final String managerId;

  DummyPlayersCreator({
    required this.hubId,
    required this.managerId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates 10 dummy players with varied stats
  Future<List<String>> createDummyPlayers() async {
    final playerIds = <String>[];

    final dummyPlayers = [
      {
        'displayName': 'יוני הכוכב',
        'firstName': 'יוני',
        'lastName': 'כהן',
        'email': 'yoni@test.com',
        'position': 'Attacker',
        'rating': 8.5,
      },
      {
        'displayName': 'דוד השוער',
        'firstName': 'דוד',
        'lastName': 'לוי',
        'email': 'david@test.com',
        'position': 'Goalkeeper',
        'rating': 7.8,
      },
      {
        'displayName': 'משה המגן',
        'firstName': 'משה',
        'lastName': 'אברהם',
        'email': 'moshe@test.com',
        'position': 'Defender',
        'rating': 7.2,
      },
      {
        'displayName': 'אלי הקשר',
        'firstName': 'אלי',
        'lastName': 'ישראל',
        'email': 'eli@test.com',
        'position': 'Midfielder',
        'rating': 8.0,
      },
      {
        'displayName': 'רון התוקף',
        'firstName': 'רון',
        'lastName': 'דוד',
        'email': 'ron@test.com',
        'position': 'Attacker',
        'rating': 7.5,
      },
      {
        'displayName': 'גיא המהיר',
        'firstName': 'גיא',
        'lastName': 'שמעון',
        'email': 'guy@test.com',
        'position': 'Midfielder',
        'rating': 6.8,
      },
      {
        'displayName': 'אורי הבטוח',
        'firstName': 'אורי',
        'lastName': 'רובן',
        'email': 'uri@test.com',
        'position': 'Defender',
        'rating': 7.0,
      },
      {
        'displayName': 'נועם הטכני',
        'firstName': 'נועם',
        'lastName': 'גולן',
        'email': 'noam@test.com',
        'position': 'Midfielder',
        'rating': 8.2,
      },
      {
        'displayName': 'עומר הפצצה',
        'firstName': 'עומר',
        'lastName': 'בן דוד',
        'email': 'omer@test.com',
        'position': 'Attacker',
        'rating': 9.0,
      },
      {
        'displayName': 'תומר הקיר',
        'firstName': 'תומר',
        'lastName': 'מזרחי',
        'email': 'tomer@test.com',
        'position': 'Defender',
        'rating': 6.5,
      },
    ];

    print('Creating ${dummyPlayers.length} dummy players...');

    for (var i = 0; i < dummyPlayers.length; i++) {
      final playerData = dummyPlayers[i];

      // Create user document
      final userId = 'dummy_player_$i';
      playerIds.add(userId);

      final user = User(
        uid: userId,
        name: '${playerData['firstName']} ${playerData['lastName']}',
        email: playerData['email'] as String,
        displayName: playerData['displayName'] as String,
        firstName: playerData['firstName'] as String,
        lastName: playerData['lastName'] as String,
        preferredPosition: playerData['position'] as String,
        hubIds: [hubId],
        createdAt: DateTime.now(),
        currentRankScore: playerData['rating'] as double,
      );

      await _firestore.collection('users').doc(userId).set(user.toJson());
      print(
          '✓ Created player: ${playerData['displayName']} (${playerData['rating']})');
    }

    // Update hub with manager ratings
    final managerRatings = <String, double>{};
    for (var i = 0; i < dummyPlayers.length; i++) {
      managerRatings['dummy_player_$i'] = dummyPlayers[i]['rating'] as double;
    }

    await _firestore.collection('hubs').doc(hubId).update({
      'memberIds': FieldValue.arrayUnion(playerIds),
      'managerRatings': managerRatings,
    });

    print('\n✅ Successfully created ${playerIds.length} dummy players!');
    print('Manager ratings updated in hub.');

    return playerIds;
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
  Future<void> setupDummyPlayersForEvent(String eventId) async {
    final playerIds = await createDummyPlayers();
    await registerPlayersToEvent(eventId, playerIds);
    print(
        '\n🎉 Setup complete! You can now use team maker with these players.');
  }
}
