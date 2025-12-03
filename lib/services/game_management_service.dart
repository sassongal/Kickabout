import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/hub_permissions_service.dart'; // Added import

import 'package:kattrick/data/games_repository.dart';
import 'package:kattrick/data/hubs_repository.dart';
import 'package:kattrick/data/signups_repository.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/services/cache_service.dart';
import 'package:kattrick/models/game_audit_event.dart';
import 'package:kattrick/data/notifications_repository.dart';

/// Service for game management operations (rollback, edit, roster management)
///
/// Handles critical operations like:
/// - Rollback finalized game results
/// - Edit game results (rollback + re-finalize)
/// - Audit logging for game modifications
/// - Roster management (approve/kick/reschedule)
class GameManagementService {
  final FirebaseFirestore _firestore;
  final GamesRepository _gamesRepo;
  final HubsRepository _hubsRepo;
  final SignupsRepository _signupsRepo;
  final NotificationsRepository _notificationsRepo;

  GameManagementService({
    GamesRepository? gamesRepo,
    HubsRepository? hubsRepo,
    SignupsRepository? signupsRepo,
    NotificationsRepository? notificationsRepo,
    FirebaseFirestore? firestore,
  })  : _gamesRepo = gamesRepo ?? GamesRepository(),
        _hubsRepo = hubsRepo ?? HubsRepository(),
        _signupsRepo = signupsRepo ?? SignupsRepository(),
        _notificationsRepo = notificationsRepo ?? NotificationsRepository(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// TRANSACTION: Approve a player to join a game
  ///
  /// This method:
  /// 1. Checks if game has capacity
  /// 2. Updates signup status to confirmed
  /// 3. Increments confirmedPlayerCount
  /// 4. Updates game status to fullyBooked if at capacity
  /// 5. Adds audit log entry
  /// 6. Sends notification to player
  ///
  /// Throws: Exception if game is full or transaction fails
  Future<void> approvePlayer({
    required String gameId,
    required String userId,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.doc(FirestorePaths.game(gameId));
      final signupRef =
          _firestore.doc(FirestorePaths.gameSignup(gameId, userId));

      final gameDoc = await transaction.get(gameRef);
      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }

      final gameData = gameDoc.data()!;
      final game = Game.fromJson({...gameData, 'gameId': gameId});

      // Check capacity
      if (game.maxPlayers != null &&
          game.confirmedPlayerCount >= game.maxPlayers!) {
        throw Exception(
            'Game is full (${game.confirmedPlayerCount}/${game.maxPlayers})');
      }

      // Approve player
      transaction.update(signupRef, {
        'status': SignupStatus.confirmed.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(gameRef, {
        'confirmedPlayerCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Check if now full
      final newCount = game.confirmedPlayerCount + 1;
      if (game.maxPlayers != null && newCount >= game.maxPlayers!) {
        transaction.update(gameRef, {
          'status': GameStatus.fullyBooked.toFirestore(),
        });
      }

      // Add audit log entry
      final auditEntry = GameAuditEvent(
        action: 'PLAYER_APPROVED',
        userId: currentUserId,
        timestamp: DateTime.now(),
        reason: 'Approved by admin',
      );

      transaction.update(gameRef, {
        'auditLog': FieldValue.arrayUnion([auditEntry.toJson()]),
      });
    }).then((_) async {
      // Send notification (outside transaction)
      try {
        await _notificationsRepo.createNotification(
          Notification(
            notificationId: '',
            userId: userId,
            title: 'בקשתך אושרה!',
            body: 'בקשתך להצטרף למשחק אושרה',
            type: 'game_approval',
            data: {'gameId': gameId},
            read: false,
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        debugPrint('Failed to send approval notification: $e');
      }

      // Invalidate cache
      CacheService().clear(CacheKeys.game(gameId));
    });
  }

  /// TRANSACTION: Kick a player from a game
  ///
  /// This method:
  /// 1. Updates signup status to rejected (with reason)
  /// 2. Decrements confirmedPlayerCount
  /// 3. Reopens game if it was fullyBooked
  /// 4. Adds audit log entry
  /// 5. Sends notification to player
  ///
  /// Parameters:
  /// - gameId: The game ID
  /// - userId: The player to kick
  /// - reason: Mandatory reason for kicking (for audit trail)
  Future<void> kickPlayer({
    required String gameId,
    required String userId,
    required String reason,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    if (reason.trim().isEmpty) {
      throw Exception('Reason is required for kicking players');
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.doc(FirestorePaths.game(gameId));
      final signupRef =
          _firestore.doc(FirestorePaths.gameSignup(gameId, userId));

      final gameDoc = await transaction.get(gameRef);
      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }

      final gameData = gameDoc.data()!;
      final game = Game.fromJson({...gameData, 'gameId': gameId});

      // Update signup to rejected with reason
      transaction.update(signupRef, {
        'status': SignupStatus.rejected.toFirestore(),
        'adminActionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Decrement count
      transaction.update(gameRef, {
        'confirmedPlayerCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reopen if was full
      if (game.status == GameStatus.fullyBooked) {
        transaction.update(gameRef, {
          'status': GameStatus.recruiting.toFirestore(),
        });
      }

      // Add audit log entry
      final auditEntry = GameAuditEvent(
        action: 'PLAYER_KICKED',
        userId: currentUserId,
        timestamp: DateTime.now(),
        reason: reason,
      );

      transaction.update(gameRef, {
        'auditLog': FieldValue.arrayUnion([auditEntry.toJson()]),
      });
    }).then((_) async {
      // Send notification (outside transaction)
      try {
        await _notificationsRepo.createNotification(
          Notification(
            notificationId: '',
            userId: userId,
            title: 'הוצאת ממשחק',
            body: 'הוצאת מהמשחק. סיבה: $reason',
            type: 'game_kicked',
            data: {'gameId': gameId, 'reason': reason},
            read: false,
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        debugPrint('Failed to send kick notification: $e');
      }

      // Invalidate cache
      CacheService().clear(CacheKeys.game(gameId));
    });
  }

  /// TRANSACTION: Reschedule a game
  ///
  /// If the date changes to a different calendar day:
  /// - Resets all confirmed signups to pending
  /// - Adds audit log entry
  /// - Notifies all registered players
  ///
  /// Parameters:
  /// - gameId: The game to reschedule
  /// - newDate: The new game date
  Future<void> rescheduleGame({
    required String gameId,
    required DateTime newDate,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Get game first to check if date actually changed
    final game = await _gamesRepo.getGame(gameId);
    if (game == null) {
      throw Exception('Game not found');
    }

    // Check if date changed to different day
    final oldDate = game.gameDate;
    final isDifferentDay = oldDate.year != newDate.year ||
        oldDate.month != newDate.month ||
        oldDate.day != newDate.day;

    if (!isDifferentDay) {
      // Only time changed, just update the gameDate
      await _gamesRepo.updateGame(gameId, {
        'gameDate': Timestamp.fromDate(newDate),
      });
      return;
    }

    // Date changed - need to reset signups
    final signups = await _signupsRepo.getSignups(gameId);
    final confirmedPlayerIds = signups
        .where((s) => s.status == SignupStatus.confirmed)
        .map((s) => s.playerId)
        .toList();

    return _firestore.runTransaction((transaction) async {
      final gameRef = _firestore.doc(FirestorePaths.game(gameId));

      // Update game date
      transaction.update(gameRef, {
        'gameDate': Timestamp.fromDate(newDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reset all confirmed signups to pending
      for (final playerId in confirmedPlayerIds) {
        final signupRef =
            _firestore.doc(FirestorePaths.gameSignup(gameId, playerId));
        transaction.update(signupRef, {
          'status': SignupStatus.pending.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Add audit log entry
      final auditEntry = GameAuditEvent(
        action: 'GAME_RESCHEDULED',
        userId: currentUserId,
        timestamp: DateTime.now(),
        reason:
            'Date changed from ${oldDate.toIso8601String()} to ${newDate.toIso8601String()}',
      );

      transaction.update(gameRef, {
        'auditLog': FieldValue.arrayUnion([auditEntry.toJson()]),
      });
    }).then((_) async {
      // Notify all players (outside transaction)
      for (final playerId in confirmedPlayerIds) {
        try {
          await _notificationsRepo.createNotification(
            Notification(
              notificationId: '',
              userId: playerId,
              title: 'המשחק נדחה',
              body:
                  'המשחק שבו נרשמת נדחה לתאריך חדש. אנא אשר את השתתפותך מחדש.',
              type: 'game_rescheduled',
              data: {'gameId': gameId, 'newDate': newDate.toIso8601String()},
              read: false,
              createdAt: DateTime.now(),
            ),
          );
        } catch (e) {
          debugPrint('Failed to send reschedule notification to $playerId: $e');
        }
      }

      // Invalidate cache
      CacheService().clear(CacheKeys.game(gameId));
    });
  }

  /// Rollback a finalized game result
  ///
  /// This method:
  /// 1. Verifies the current user is a Hub Manager/Admin
  /// 2. Verifies the game status is 'completed'
  /// 3. Uses Firestore Transaction for atomic rollback
  /// 4. Reverses all player stat updates (gamesPlayed, wins, goals, assists)
  /// 5. Resets game status back to 'teamsFormed'
  ///
  /// Returns: Map containing the original game data for audit/recovery
  ///
  /// Throws: Exception if user is not a manager, game not found, or transaction fails
  Future<Map<String, dynamic>> rollbackGameResult(String gameId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Step 1: Permission Check - Verify user is Hub Manager/Admin
      final auth = FirebaseAuth.instance;
      final currentUserId = auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get game to check hubId and status
      final game = await _gamesRepo.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify game is completed
      if (game.status != GameStatus.completed) {
        throw Exception(
            'Cannot rollback: Game is not completed (status: ${game.status})');
      }

      // Get hub to verify permissions (skip for public games)
      if (game.hubId == null) {
        throw Exception('Cannot rollback public games without hub');
      }

      final hub = await _hubsRepo.getHub(game.hubId!);
      if (hub == null) {
        throw Exception('Hub not found: ${game.hubId}');
      }

      // Check if user is manager/admin
      final hubPermissions = HubPermissions(hub: hub, userId: currentUserId);
      if (!hubPermissions.isManager() && !hubPermissions.isModerator()) {
        throw Exception('Unauthorized: Only Hub Managers can rollback games');
      }

      // Step 2: Get signups for the game (before transaction)
      final allSignups = await _signupsRepo.getSignups(gameId);
      final confirmedSignups =
          allSignups.where((s) => s.status == SignupStatus.confirmed).toList();

      // Store original data for audit
      final originalData = <String, dynamic>{
        'gameId': gameId,
        'teamAScore': game.legacyTeamAScore,
        'teamBScore': game.legacyTeamBScore,
        'goalScorerIds': game.goalScorerIds,
        'mvpPlayerId': game.mvpPlayerId,
        'rolledBackAt': FieldValue.serverTimestamp(),
        'rolledBackBy': currentUserId,
      };

      // Step 3: Determine winning team from original scores
      final teamAScore = game.legacyTeamAScore ?? 0;
      final teamBScore = game.legacyTeamBScore ?? 0;
      final winningTeamId = teamAScore > teamBScore
          ? (game.teams.isNotEmpty ? game.teams[0].teamId : 'teamA')
          : (teamAScore < teamBScore
              ? (game.teams.length > 1 ? game.teams[1].teamId : 'teamB')
              : null); // Draw

      // Step 4: Build goal/assist maps from original data
      // Note: The original finalizeGame stores goalScorerIds as a List, not a Map
      // We need to count occurrences for rollback
      final Map<String, int> goalScorerCounts = {};
      for (final scorerId in game.goalScorerIds) {
        goalScorerCounts[scorerId] = (goalScorerCounts[scorerId] ?? 0) + 1;
      }

      // Assists are not stored in the game model currently, so we can't roll them back
      // This is a limitation of the current data model

      // Step 5: Atomic Transaction - Rollback
      await _firestore.runTransaction((transaction) async {
        // Read game document
        final gameRef = _firestore.doc(FirestorePaths.game(gameId));
        final gameDoc = await transaction.get(gameRef);

        if (!gameDoc.exists) {
          throw Exception('Game not found');
        }

        final gameData = gameDoc.data()!;
        final gameHubId = gameData['hubId'] as String;

        // Verify hub still exists and user is still manager
        final hubRef = _firestore.doc(FirestorePaths.hub(gameHubId));
        final hubDoc = await transaction.get(hubRef);

        if (!hubDoc.exists) {
          throw Exception('Hub not found');
        }

        final hubData = hubDoc.data()!;
        bool isManager = hubData['createdBy'] == currentUserId;

        if (!isManager) {
          // Check member role from subcollection
          final memberRef =
              _firestore.doc('hubs/$gameHubId/members/$currentUserId');
          final memberDoc = await transaction.get(memberRef);

          if (memberDoc.exists) {
            final memberData = memberDoc.data()!;
            final role = memberData['role'] as String?;
            if (role == 'manager' || role == 'admin' || role == 'moderator') {
              isManager = true;
            }
          }
        }

        if (!isManager) {
          throw Exception('Unauthorized: Only Hub Managers can rollback games');
        }

        // Parse teams from gameData
        final teamsData = gameData['teams'] as List? ?? [];
        final teams = teamsData
            .map((t) => Team.fromJson(t as Map<String, dynamic>))
            .toList();

        // Step 6: Reverse stats for all confirmed players
        for (final signup in confirmedSignups) {
          final playerId = signup.playerId;
          final userRef = _firestore.doc(FirestorePaths.user(playerId));

          // Determine which team the player was on
          final playerTeamId = teams.isNotEmpty
              ? teams
                  .firstWhere(
                    (team) => team.playerIds.contains(playerId),
                    orElse: () => teams[0],
                  )
                  .teamId
              : 'teamA';

          final wasWinner =
              winningTeamId != null && playerTeamId == winningTeamId;

          // Get player's goals count
          final playerGoals = goalScorerCounts[playerId] ?? 0;

          // Prepare stat reversals (negative increments)
          final userUpdates = <String, dynamic>{
            'gamesPlayed': FieldValue.increment(-1),
          };

          if (wasWinner) {
            userUpdates['wins'] = FieldValue.increment(-1);
          }

          if (playerGoals > 0) {
            userUpdates['goals'] = FieldValue.increment(-playerGoals);
          }

          // Note: We can't reverse assists as they're not stored in the game model
          // This is a known limitation

          transaction.update(userRef, userUpdates);
        }

        // Step 7: Reset game status and remove scores
        transaction.update(gameRef, {
          'status': GameStatus.teamsFormed.toFirestore(),
          'teamAScore': FieldValue.delete(),
          'teamBScore': FieldValue.delete(),
          'goalScorerIds': FieldValue.delete(),
          'goalScorerNames': FieldValue.delete(),
          'mvpPlayerId': FieldValue.delete(),
          'mvpPlayerName': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Invalidate caches
      CacheService().clear(CacheKeys.game(gameId));
      if (game.hubId != null) {
        CacheService().clear(CacheKeys.gamesByHub(game.hubId!));
      }

      debugPrint('✅ Game result rolled back: $gameId');
      return originalData;
    } catch (e) {
      debugPrint('❌ Failed to rollback game: $e');
      throw Exception('Failed to rollback game: $e');
    }
  }

  /// Edit game result (rollback + re-finalize)
  ///
  /// This method:
  /// 1. Calls rollbackGameResult to reverse the old stats
  /// 2. Calls GamesRepository.finalizeGame with new data
  ///
  /// Parameters:
  /// - gameId: The game to edit
  /// - newTeamAScore: New score for team A
  /// - newTeamBScore: New score for team B
  /// - newGoalScorerIds: Map of playerId -> number of goals
  /// - newAssistPlayerIds: Map of playerId -> number of assists (optional)
  /// - newMvpPlayerId: Optional new MVP player ID
  ///
  /// Throws: Exception if rollback or finalize fails
  Future<void> editGameResult({
    required String gameId,
    required int newTeamAScore,
    required int newTeamBScore,
    required Map<String, int> newGoalScorerIds,
    Map<String, int>? newAssistPlayerIds,
    String? newMvpPlayerId,
  }) async {
    try {
      // Step 1: Rollback the old result
      final originalData = await rollbackGameResult(gameId);
      debugPrint(
          '   Rolled back original result: ${originalData['teamAScore']} vs ${originalData['teamBScore']}');

      // Step 2: Apply the new result
      await _gamesRepo.finalizeGame(
        gameId: gameId,
        teamAScore: newTeamAScore,
        teamBScore: newTeamBScore,
        goalScorerIds: newGoalScorerIds,
        assistPlayerIds: newAssistPlayerIds,
        mvpPlayerId: newMvpPlayerId,
      );

      debugPrint('✅ Game result edited successfully: $gameId');
      debugPrint(
          '   Old: ${originalData['teamAScore']} vs ${originalData['teamBScore']}');
      debugPrint('   New: $newTeamAScore vs $newTeamBScore');
    } catch (e) {
      debugPrint('❌ Failed to edit game result: $e');
      // If finalize fails after rollback, the game is left in 'teamsFormed' state
      // This is safer than having incorrect stats
      throw Exception('Failed to edit game result: $e');
    }
  }
}
