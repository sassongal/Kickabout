import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/game_result.dart';
import 'package:kattrick/models/log_past_game_details.dart';
import 'package:kattrick/data/games_repository.dart';

/// Service for Game Finalization logic
/// Handles converting events to games, logging past games, and finalizing games
/// This is domain logic, not just data access
///
/// ARCHITECTURE: Services use Repositories for data access, not Firestore directly
class GameFinalizationService {
  final GamesRepository _gamesRepo;

  GameFinalizationService({
    GamesRepository? gamesRepository,
  })  : _gamesRepo = gamesRepository ?? GamesRepository();

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

      // BUSINESS LOGIC: Generate game ID
      final gameId = _gamesRepo.generateGameId();

      // BUSINESS LOGIC: Create game object with nested structure
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
        createdAt: DateTime.now(),
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

      // DATA ACCESS: Use repository to create game with signups
      await _gamesRepo.createGameWithSignups(
        gameData: gameData,
        gameId: gameId,
        playerIds: details.playerIds,
      );

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
      // DATA ACCESS: Get event data from repository
      final (eventData, _) = await _gamesRepo.getEventData(
        eventId: eventId,
        hubId: hubId,
      );

      // BUSINESS LOGIC: Parse event and prepare game data
      final event = HubEvent.fromJson({...eventData, 'eventId': eventId});

      // Get teams from event (if they exist)
      final teams = event.teams.isNotEmpty
          ? event.teams
          : <Team>[]; // Teams may not exist if TeamMaker wasn't used

      // BUSINESS LOGIC: Generate game ID
      final gameId = _gamesRepo.generateGameId();

      // BUSINESS LOGIC: Create game document data
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
        'gameId': gameId, // Required by firestore.rules
      };

      // DATA ACCESS: Use repository to convert event to game atomically
      await _gamesRepo.convertEventToGameBatch(
        eventId: eventId,
        hubId: hubId,
        gameId: gameId,
        gameData: gameData,
        presentPlayerIds: presentPlayerIds,
      );

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
    // BUSINESS LOGIC: Validate user authentication
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // DATA ACCESS: Update game document via repository
    await _gamesRepo.updateGame(gameId, {
      'status': 'processing_completion', // Intermediate status
      'resultPayload': result.toJson(), // Store the raw input (scores, scorers)
      'finalizedBy': currentUser.uid,
      'finalizedAt': FieldValue.serverTimestamp(),
    });
  }
}

