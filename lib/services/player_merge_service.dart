import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/games_repository.dart';
import 'package:kattrick/data/users_repository.dart';

import 'package:kattrick/services/firestore_paths.dart';

/// Result of merge validation
class MergeValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<Game> conflictingGames;

  const MergeValidationResult({
    required this.isValid,
    this.errorMessage,
    this.conflictingGames = const [],
  });

  factory MergeValidationResult.success() =>
      const MergeValidationResult(isValid: true);

  factory MergeValidationResult.error(String message,
      {List<Game> conflicts = const []}) {
    return MergeValidationResult(
      isValid: false,
      errorMessage: message,
      conflictingGames: conflicts,
    );
  }
}

/// Service for merging manual players with real users
///
/// Handles the complex process of:
/// - Validating that a merge is possible
/// - Transferring all game history and signups
/// - Updating game references (MVP, goal scorers)
/// - Combining player statistics
/// - Marking the manual player as merged
class PlayerMergeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamesRepository _gamesRepo;
  final UsersRepository _usersRepo;

  PlayerMergeService({
    GamesRepository? gamesRepo,
    UsersRepository? usersRepo,
  })  : _gamesRepo = gamesRepo ?? GamesRepository(),
        _usersRepo = usersRepo ?? UsersRepository();

  /// Validate that a merge operation is possible
  Future<MergeValidationResult> validateMerge({
    required String manualPlayerId,
    required String realUserId,
  }) async {
    try {
      // 1. Check both players exist
      final manualPlayer = await _usersRepo.getUser(manualPlayerId);
      final realUser = await _usersRepo.getUser(realUserId);

      if (manualPlayer == null) {
        return MergeValidationResult.error('שחקן ידני לא נמצא');
      }

      if (realUser == null) {
        return MergeValidationResult.error('משתמש אמיתי לא נמצא');
      }

      // 2. Verify manual player is actually manual
      if (!manualPlayer.email.startsWith('manual_')) {
        return MergeValidationResult.error('השחקן אינו שחקן ידני');
      }

      // 3. Check if manual player was already merged
      final manualPlayerDoc =
          await _firestore.doc(FirestorePaths.user(manualPlayerId)).get();
      if (manualPlayerDoc.data()?['mergedInto'] != null) {
        final mergedInto = manualPlayerDoc.data()!['mergedInto'] as String;
        return MergeValidationResult.error(
            'השחקן כבר מוזג למשתמש: $mergedInto');
      }

      // 4. Get games for both players
      final manualPlayerGames = await _getPlayerGames(manualPlayerId);
      final realUserGames = await _getPlayerGames(realUserId);

      // 5. Check for conflicting games (same game, different players)
      final conflicts = <Game>[];
      for (final manualGame in manualPlayerGames) {
        final hasConflict = realUserGames
            .any((realGame) => realGame.gameId == manualGame.gameId);
        if (hasConflict) {
          conflicts.add(manualGame);
        }
      }

      if (conflicts.isNotEmpty) {
        return MergeValidationResult.error(
          'שני השחקנים משתתפים באותם משחקים (${conflicts.length} משחקים)',
          conflicts: conflicts,
        );
      }

      return MergeValidationResult.success();
    } catch (e) {
      debugPrint('❌ Validation error: $e');
      return MergeValidationResult.error('שגיאה בבדיקת האפשרות למיזוג: $e');
    }
  }

  /// Get all games where a player participated
  Future<List<Game>> _getPlayerGames(String playerId) async {
    try {
      // Query signups collection group for this player
      final signupsQuery = await _firestore
          .collectionGroup('signups')
          .where('playerId', isEqualTo: playerId)
          .get();

      // Get unique game IDs
      final gameIds = signupsQuery.docs
          .map((doc) => doc.reference.parent.parent!.id)
          .toSet()
          .toList();

      // Fetch all games
      final games = <Game>[];
      for (final gameId in gameIds) {
        final game = await _gamesRepo.getGame(gameId);
        if (game != null) {
          games.add(game);
        }
      }

      return games;
    } catch (e) {
      debugPrint('❌ Error getting player games: $e');
      return [];
    }
  }

  /// Merge a manual player into a real user account
  ///
  /// This operation:
  /// 1. Transfers all signups from manual player to real user
  /// 2. Updates game references (MVP, goal scorers, etc.)
  /// 3. Adds manual player stats to real user stats
  /// 4. Marks manual player as merged and inactive
  ///
  /// All operations are performed in batches for atomicity
  Future<void> mergePlayers({
    required String manualPlayerId,
    required String realUserId,
    required String hubId,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Validate merge
      final validation = await validateMerge(
        manualPlayerId: manualPlayerId,
        realUserId: realUserId,
      );

      if (!validation.isValid) {
        throw Exception(validation.errorMessage ?? 'Merge validation failed');
      }

      // Get both players
      final manualPlayer = await _usersRepo.getUser(manualPlayerId);
      final realUser = await _usersRepo.getUser(realUserId);

      if (manualPlayer == null || realUser == null) {
        throw Exception('Players not found');
      }

      debugPrint('🔄 Starting merge: ${manualPlayer.name} -> ${realUser.name}');

      // Use batch writes (transaction has 500 doc limit, batch has 500 too but we can chain)
      final batch = _firestore.batch();
      int operationCount = 0;

      // 1. Transfer signups
      final signupsQuery = await _firestore
          .collectionGroup('signups')
          .where('playerId', isEqualTo: manualPlayerId)
          .get();

      debugPrint('   Transferring ${signupsQuery.docs.length} signups');
      for (final signupDoc in signupsQuery.docs) {
        batch.update(signupDoc.reference, {
          'playerId': realUserId,
          'mergedFrom': manualPlayerId,
          'mergedAt': FieldValue.serverTimestamp(),
        });
        operationCount++;
      }

      // 2. Update games (MVP, goal scorers, team rosters)
      final games = await _getPlayerGames(manualPlayerId);
      debugPrint('   Updating ${games.length} games');

      for (final game in games) {
        final gameRef = _firestore.doc(FirestorePaths.game(game.gameId));
        final updates = <String, dynamic>{};

        // Update MVP
        if (game.mvpPlayerId == manualPlayerId) {
          updates['mvpPlayerId'] = realUserId;
        }

        // Update goal scorers list
        if (game.goalScorerIds.contains(manualPlayerId)) {
          final updatedIds = game.goalScorerIds
              .map((id) => id == manualPlayerId ? realUserId : id)
              .toList();
          updates['goalScorerIds'] = updatedIds;
        }

        // Update team player lists
        if (game.teams.isNotEmpty) {
          final updatedTeams = game.teams.map((team) {
            if (team.playerIds.contains(manualPlayerId)) {
              final updatedPlayerIds = team.playerIds
                  .map((id) => id == manualPlayerId ? realUserId : id)
                  .toList();
              return team.copyWith(playerIds: updatedPlayerIds);
            }
            return team;
          }).toList();

          updates['teams'] = updatedTeams.map((t) => t.toJson()).toList();
        }

        if (updates.isNotEmpty) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
          batch.update(gameRef, updates);
          operationCount++;
        }
      }

      // 3. Transfer stats to real user (additive)
      final realUserRef = _firestore.doc(FirestorePaths.user(realUserId));
      batch.update(realUserRef, {
        'gamesPlayed': FieldValue.increment(manualPlayer.gamesPlayed),
        'wins': FieldValue.increment(manualPlayer.wins),
        'goals': FieldValue.increment(manualPlayer.goals),
        'assists': FieldValue.increment(manualPlayer.assists),
        'totalParticipations':
            FieldValue.increment(manualPlayer.totalParticipations),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      operationCount++;

      // 4. Mark manual player as merged
      final manualPlayerRef =
          _firestore.doc(FirestorePaths.user(manualPlayerId));
      batch.update(manualPlayerRef, {
        'mergedInto': realUserId,
        'mergedAt': FieldValue.serverTimestamp(),
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      operationCount++;

      // Commit the batch
      debugPrint('   Committing $operationCount operations');
      await batch.commit();

      debugPrint('✅ Merge completed successfully');
    } catch (e) {
      debugPrint('❌ Failed to merge players: $e');
      throw Exception('Failed to merge players: $e');
    }
  }
}
