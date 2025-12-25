import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/services/cache_invalidation_service.dart';
import 'package:kattrick/data/hubs_repository.dart';
import 'package:kattrick/features/hubs/domain/services/hub_permissions_service.dart';
import 'package:kattrick/features/games/domain/models/session_rotation.dart';
import 'package:kattrick/data/games_repository.dart';

/// Repository for Game Session lifecycle operations
/// Handles Winner Stays format sessions: start, end, add matches, rotation
class SessionRepository {
  final FirebaseFirestore _firestore;
  final CacheInvalidationService _cacheInvalidation;
  final GamesRepository _gamesRepo;

  SessionRepository({
    FirebaseFirestore? firestore,
    CacheInvalidationService? cacheInvalidation,
    GamesRepository? gamesRepo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheInvalidation = cacheInvalidation ?? CacheInvalidationService(),
        _gamesRepo = gamesRepo ?? GamesRepository();

  /// Start a session (activates Winner Stays rotation)
  ///
  /// Sets isActive=true and initializes currentRotation state.
  /// Only hub managers or game creator can start sessions.
  Future<void> startSession(String gameId, String managerId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Verify game exists and user has permission
      final game = await _gamesRepo.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: managerId);
        if (!hubPermissions.isManager) {
          throw Exception('Unauthorized: Only Hub Managers can start sessions');
        }
      } else {
        // Public game - check if user is creator
        if (game.createdBy != managerId) {
          throw Exception(
              'Unauthorized: Only the game creator can start public sessions');
        }
      }

      // Verify teams exist
      if (game.teams.length < 2) {
        throw Exception(
            'Need at least 2 teams to start a session. Create teams first.');
      }

      // Initialize rotation state using SessionRotationLogic
      final initialRotation =
          SessionRotationLogic.createInitialState(game.teams);

      // Update game document
      await _firestore.doc(FirestorePaths.game(gameId)).update({
        'session.isActive': true,
        'session.sessionStartedAt': FieldValue.serverTimestamp(),
        'session.sessionStartedBy': managerId,
        'session.currentRotation': initialRotation.toJson(),
        'status': 'inProgress', // Update game status
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate caches
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint('✅ Session started: $gameId by $managerId');
    } catch (e) {
      debugPrint('❌ Failed to start session: $e');
      throw Exception('Failed to start session: $e');
    }
  }

  /// End a session
  ///
  /// Sets isActive=false, marks sessionEndedAt.
  /// This will trigger backend processing to finalize stats.
  Future<void> endSession(String gameId, String managerId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Verify game exists and user has permission
      final game = await _gamesRepo.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: managerId);
        if (!hubPermissions.isManager) {
          throw Exception('Unauthorized: Only Hub Managers can end sessions');
        }
      } else {
        // Public game - check if user is creator
        if (game.createdBy != managerId) {
          throw Exception(
              'Unauthorized: Only the game creator can end public sessions');
        }
      }

      // Update game document
      await _firestore.doc(FirestorePaths.game(gameId)).update({
        'session.isActive': false,
        'session.sessionEndedAt': FieldValue.serverTimestamp(),
        'session.sessionEndedBy': managerId,
        'status': 'statsInput', // Move to stats input phase
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate caches
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint('✅ Session ended: $gameId by $managerId');
    } catch (e) {
      debugPrint('❌ Failed to end session: $e');
      throw Exception('Failed to end session: $e');
    }
  }

  /// Add a match result to a session (Game with multiple matches)
  ///
  /// OPTIMIZED VERSION - Split into two operations:
  /// 1. Transaction: Add match to game (critical, must be atomic)
  /// 2. Batch: Update player stats (eventual consistency OK)
  ///
  /// This prevents long transactions that can timeout or cause contention.
  Future<void> addMatchToSession(
    String gameId,
    MatchResult match,
    String currentUserId,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Step 1: Verify game exists and user has permission (outside transaction)
      final game = await _gamesRepo.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions (outside transaction to reduce contention)
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: currentUserId);
        if (!hubPermissions.isManager && !hubPermissions.isModerator) {
          throw Exception(
              'Unauthorized: Only Hub Managers can add matches to sessions');
        }
      } else {
        // Public game - check if user is creator
        if (game.createdBy != currentUserId) {
          throw Exception(
              'Unauthorized: Only the game creator can add matches to public sessions');
        }
      }

      // Step 2: CRITICAL TRANSACTION - Update game only (fast, < 5 operations)
      await _firestore.runTransaction((transaction) async {
        final gameRef = _firestore.doc(FirestorePaths.game(gameId));
        final gameDoc = await transaction.get(gameRef);

        if (!gameDoc.exists) {
          throw Exception('Game not found');
        }

        // Parse game and calculate updates
        final gameData = gameDoc.data()!;
        final currentGame = Game.fromJson({...gameData, 'gameId': gameId});
        // Add new match
        final updatedMatches = [...currentGame.session.matches, match];
        final matchesJson = updatedMatches.map((m) => m.toJson()).toList();

        // Determine winner for aggregate wins/rotation
        String? winnerColor;
        if (match.scoreA > match.scoreB) {
          winnerColor = match.teamAColor;
        } else if (match.scoreB > match.scoreA) {
          winnerColor = match.teamBColor;
        }

        final Map<String, dynamic> updateData = {
          'session.matches': matchesJson,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Apply aggregate win increment inside the transaction so retries use fresh state
        if (winnerColor != null &&
            match.approvalStatus == MatchApprovalStatus.approved) {
          updateData['session.aggregateWins.$winnerColor'] =
              FieldValue.increment(1);
        }

        // Update rotation state for active sessions with approved matches using fresh snapshot data
        if (currentGame.session.isActive &&
            currentGame.session.currentRotation != null &&
            match.approvalStatus == MatchApprovalStatus.approved) {
          // Note: For ties, managerSelectedStayingTeam should be set in the match
          // before calling addMatchToSession (handled by UI layer)
          final nextRotation = SessionRotationLogic.calculateNextRotation(
            current: currentGame.session.currentRotation!,
            completedMatch: match,
            // If tie and no winner selected yet, rotation will throw error
            // This is intentional - UI must handle tie selection first
          );

          updateData['session.currentRotation'] = nextRotation.toJson();
          debugPrint(
              '✅ Rotation updated: ${nextRotation.teamAColor} vs ${nextRotation.teamBColor}');
        }

        // Update game document (atomic)
        transaction.update(gameRef, updateData);
      });

      // Step 3: SEPARATE BATCH - Update player stats (eventual consistency OK)
      // This is outside the transaction to avoid long-running transactions
      await _updatePlayerStatsForMatch(match);

      // Step 4: Invalidate caches using centralized service
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint('✅ Match added to session: $gameId, match: ${match.matchId}');
    } catch (e) {
      debugPrint('❌ Failed to add match to session: $e');
      throw Exception('Failed to add match to session: $e');
    }
  }

  /// Helper method: Update player stats using batched writes (eventual consistency)
  ///
  /// This is separated from the critical transaction to avoid long-running transactions.
  /// If this fails, it can be retried independently without affecting the game state.
  Future<void> _updatePlayerStatsForMatch(MatchResult match) async {
    try {
      // Count goals and assists per player
      final Map<String, int> playerGoals = {};
      final Map<String, int> playerAssists = {};

      for (final scorerId in match.scorerIds) {
        playerGoals[scorerId] = (playerGoals[scorerId] ?? 0) + 1;
      }

      for (final assistId in match.assistIds) {
        playerAssists[assistId] = (playerAssists[assistId] ?? 0) + 1;
      }

      // Use batched writes for better performance
      final batch = _firestore.batch();

      // Update each player's stats
      for (final playerId in {...playerGoals.keys, ...playerAssists.keys}) {
        final userRef = _firestore.doc(FirestorePaths.user(playerId));

        final userUpdates = <String, dynamic>{};

        // Add goals count
        final goalsCount = playerGoals[playerId] ?? 0;
        if (goalsCount > 0) {
          userUpdates['goals'] = FieldValue.increment(goalsCount);
        }

        // Add assists count
        final assistsCount = playerAssists[playerId] ?? 0;
        if (assistsCount > 0) {
          userUpdates['assists'] = FieldValue.increment(assistsCount);
        }

        if (userUpdates.isNotEmpty) {
          batch.update(userRef, userUpdates);
        }
      }

      // Commit batch
      await batch.commit();

      debugPrint('✅ Player stats updated for match: ${match.matchId}');
    } catch (e) {
      // Log but don't throw - stats update failure shouldn't block the match
      debugPrint('⚠️ Failed to update player stats for match: $e');
    }
  }

  /// Update rotation state after a tie when manager selects staying team
  ///
  /// Used when a match ends in a tie and manager needs to manually
  /// select which team stays on field.
  Future<void> updateRotationAfterTie(
    String gameId,
    MatchResult tiedMatch,
    String stayingTeamColor,
    String managerId,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Verify game exists and user has permission
      final game = await _gamesRepo.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: managerId);
        if (!hubPermissions.isManager) {
          throw Exception(
              'Unauthorized: Only Hub Managers can update rotation');
        }
      } else {
        // Public game - check if user is creator
        if (game.createdBy != managerId) {
          throw Exception(
              'Unauthorized: Only the game creator can update rotation');
        }
      }

      // Verify session is active and has rotation state
      if (!game.session.isActive || game.session.currentRotation == null) {
        throw Exception('Session is not active or has no rotation state');
      }

      // Calculate next rotation with manager's selection
      final nextRotation = SessionRotationLogic.calculateNextRotation(
        current: game.session.currentRotation!,
        completedMatch: tiedMatch,
        managerSelectedStayingTeam: stayingTeamColor,
      );

      // Update game document
      await _firestore.doc(FirestorePaths.game(gameId)).update({
        'session.currentRotation': nextRotation.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate caches
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint(
          '✅ Rotation updated after tie: ${nextRotation.teamAColor} vs ${nextRotation.teamBColor}');
    } catch (e) {
      debugPrint('❌ Failed to update rotation after tie: $e');
      throw Exception('Failed to update rotation after tie: $e');
    }
  }
}

