import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/game_result.dart';
import 'package:kattrick/models/log_past_game_details.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/services/cache_invalidation_service.dart';

/// Service for Game Finalization logic
/// Handles converting events to games, logging past games, and finalizing games
/// This is domain logic, not just data access
class GameFinalizationService {
  final FirebaseFirestore _firestore;
  final CacheInvalidationService _cacheInvalidation;

  GameFinalizationService({
    FirebaseFirestore? firestore,
    CacheInvalidationService? cacheInvalidation,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheInvalidation = cacheInvalidation ?? CacheInvalidationService();

  /// Log a past game retroactively
  ///
  /// Creates a Game document with status 'completed' immediately,
  /// along with signups for all participating players
  Future<void> logPastGame(
      LogPastGameDetails details, String currentUserId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final now = FieldValue.serverTimestamp();

      // Create game object with nested structure
      final gameId = _firestore.collection(FirestorePaths.games()).doc().id;
      final game = Game(
        gameId: gameId,
        createdBy: currentUserId,
        hubId: details.hubId,
        gameDate: details.gameDate,
        venueId: details.venueId,
        eventId: details.eventId,
        teamCount: 2,
        status: GameStatus.completed,
        showInCommunityFeed: details.showInCommunityFeed,
        region: details.region,
        city: details.city,
        teams: details.teams,
        createdAt: DateTime
            .now(), // approximation, will set server timestamp later if needed, but Game model expects DateTime.
        updatedAt: DateTime.now(),
        denormalized: GameDenormalizedData(
          goalScorerIds: details.goalScorerIds,
          goalScorerNames: details.goalScorerNames,
          mvpPlayerId: details.mvpPlayerId,
          mvpPlayerName: details.mvpPlayerName,
          venueName: details.venueName,
        ),
        session: GameSession(
          legacyTeamAScore: details.teamAScore,
          legacyTeamBScore: details.teamBScore,
        ),
      );

      final gameData = game.toJson();
      // Overwrite timestamps with server timestamp
      gameData['createdAt'] = now;
      gameData['updatedAt'] = now;
      // Game.toJson() already puts gameId in, but let's be safe as we generated it appropriately

      final gameRef = _firestore.collection(FirestorePaths.games()).doc(gameId);

      // Add gameId to gameData (required by firestore.rules)
      // gameData['gameId'] = gameId; // Already in toJson

      // Create signups for all participating players
      final batch = _firestore.batch();

      // Add game document
      batch.set(gameRef, gameData);

      // Add signups
      for (final playerId in details.playerIds) {
        final signupRef =
            _firestore.doc(FirestorePaths.gameSignup(gameId, playerId));
        batch.set(signupRef, {
          'playerId': playerId,
          'status': SignupStatus.confirmed.toFirestore(),
          'signedUpAt': now,
        });
      }

      // Commit all writes
      await batch.commit();

      // The onGameCompleted Cloud Function will be triggered automatically
      // when the game status is set to 'completed'
      debugPrint('✅ Past game logged: $gameId');
    } catch (e) {
      throw Exception('Failed to log past game: $e');
    }
  }

  /// Convert Event to Game - Core flow for logging games
  ///
  /// This is the main method for converting an Event (plan) to a Game (record).
  /// It reads the Event data, creates a Game document with status 'completed',
  /// and updates the Event to reference the new Game.
  ///
  /// The Cloud Function onGameCompleted will automatically update player stats.
  ///
  /// Parameters:
  /// - eventId: The event to convert
  /// - hubId: The hub ID (for Firestore path)
  /// - teamAScore: Score for team A
  /// - teamBScore: Score for team B
  /// - presentPlayerIds: List of player IDs who attended (defaults to all registered)
  /// - goalScorerIds: Optional list of player IDs who scored
  /// - mvpPlayerId: Optional MVP player ID
  ///
  /// Returns: The created Game ID
  Future<String> convertEventToGame({
    required String eventId,
    required String hubId,
    required int teamAScore,
    required int teamBScore,
    required List<String> presentPlayerIds,
    List<String>? goalScorerIds,
    String? mvpPlayerId,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Get event data
      final eventRef = _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId);

      final eventDoc = await eventRef.get();
      if (!eventDoc.exists) {
        throw Exception('Event not found: $eventId');
      }

      final eventData = eventDoc.data()!;
      final event = HubEvent.fromJson({...eventData, 'eventId': eventId});

      // Get teams from event (if they exist)
      final teams = event.teams.isNotEmpty
          ? event.teams
          : <Team>[]; // Teams may not exist if TeamMaker wasn't used

      // Create game document
      final now = FieldValue.serverTimestamp();
      final gameData = {
        'createdBy': event.createdBy,
        'hubId': hubId,
        'eventId': eventId, // Required reference to event
        'gameDate': Timestamp.fromDate(event.eventDate),
        'location': event.location,
        'locationPoint': event.locationPoint,
        'geohash': event.geohash,
        'status': GameStatus.completed.toFirestore(),
        'denormalized': {
          'venueName': event.location,
          'goalScorerIds': goalScorerIds ?? [],
          'mvpPlayerId': mvpPlayerId,
        },
        'session': {
          'legacyTeamAScore': teamAScore,
          'legacyTeamBScore': teamBScore,
        },
        'teamCount': event.teamCount,
        'teams': teams.map((team) => team.toJson()).toList(),
        'durationInMinutes': event.durationMinutes,
        'region': eventData['region'], // Copy from hub if available
        'showInCommunityFeed': event.showInCommunityFeed,
        'createdAt': now,
        'updatedAt': now,
        'photoUrls': <String>[],
        'isRecurring': false,
      };

      final gameRef = _firestore.collection(FirestorePaths.games()).doc();
      final gameId = gameRef.id;

      // Add gameId to gameData (required by firestore.rules)
      gameData['gameId'] = gameId;

      // Create batch for atomic operations
      final batch = _firestore.batch();

      // 1. Create game document
      batch.set(gameRef, gameData);

      // 2. Create signups for present players (status: confirmed)
      for (final playerId in presentPlayerIds) {
        final signupRef =
            _firestore.doc(FirestorePaths.gameSignup(gameId, playerId));
        batch.set(signupRef, {
          'playerId': playerId,
          'status': SignupStatus.confirmed.toFirestore(),
          'signedUpAt': now,
        });
      }

      // 3. Update event: mark as completed and reference the game
      batch.update(eventRef, {
        'status': 'completed',
        'gameId': gameId,
        'updatedAt': now,
      });

      // Commit all writes atomically
      await batch.commit();

      // Invalidate caches using centralized service
      _cacheInvalidation.onEventConvertedToGame(hubId, eventId, gameId);

      debugPrint('✅ Event converted to Game: $gameId (from event $eventId)');

      // The onGameCompleted Cloud Function will be triggered automatically
      // when the game status is set to 'completed'

      return gameId;
    } catch (e) {
      throw Exception('Failed to convert event to game: $e');
    }
  }

  /// Triggers the game finalization flow by setting an intermediate status
  /// and saving the result payload. A Cloud Function will then process the
  /// completion asynchronously.
  Future<void> finalizeGame(String gameId, GameResult result) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // 1. Only update the Game document
    await _firestore.doc(FirestorePaths.game(gameId)).update({
      'status': 'processing_completion', // Intermediate status
      'resultPayload': result.toJson(), // Store the raw input (scores, scorers)
      'finalizedBy': currentUser.uid,
      'finalizedAt': FieldValue.serverTimestamp(),
    });
  }
}

