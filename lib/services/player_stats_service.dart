import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/player_stats.dart';
import 'package:kattrick/services/firestore_paths.dart';

/// Service for managing player game statistics.
///
/// IMPORTANT: This service manages OBJECTIVE game logs only (goals, assists, MVP).
/// For skill ratings used in team balancing, use HubMember.managerRating instead.
///
/// Stats are stored in Firestore at:
/// /users/{userId}/stats/{gameId}
class PlayerStatsService {
  final FirebaseFirestore _firestore;

  PlayerStatsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all game stats for a player
  Future<List<PlayerStats>> getPlayerStats(String playerId) async {
    try {
      final snapshot = await _firestore
          .doc(FirestorePaths.user(playerId))
          .collection('stats')
          .orderBy('gameDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PlayerStats.fromJson({
                ...doc.data(),
                'playerId': playerId,
                'gameId': doc.id,
              }))
          .toList();
    } catch (e) {
      // Return empty list on error (player may not have stats yet)
      return [];
    }
  }

  /// Get stats for a specific game
  Future<PlayerStats?> getPlayerStatsForGame(
    String playerId,
    String gameId,
  ) async {
    try {
      final doc = await _firestore
          .doc(FirestorePaths.user(playerId))
          .collection('stats')
          .doc(gameId)
          .get();

      if (!doc.exists) return null;

      return PlayerStats.fromJson({
        ...doc.data()!,
        'playerId': playerId,
        'gameId': gameId,
      });
    } catch (e) {
      return null;
    }
  }

  /// Get the most recent game stats for a player
  Future<PlayerStats?> getLatestPlayerStats(String playerId) async {
    try {
      final snapshot = await _firestore
          .doc(FirestorePaths.user(playerId))
          .collection('stats')
          .orderBy('gameDate', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return PlayerStats.fromJson({
        ...doc.data(),
        'playerId': playerId,
        'gameId': doc.id,
      });
    } catch (e) {
      return null;
    }
  }

  /// Save or update player stats for a game
  ///
  /// This should typically be called by Cloud Functions after game completion.
  /// Only Hub Managers should be able to manually log stats via UI.
  Future<void> savePlayerStats(PlayerStats stats) async {
    final data = stats.toJson();
    // Remove playerId and gameId as they're part of the document path
    data.remove('playerId');
    data.remove('gameId');

    await _firestore
        .doc(FirestorePaths.user(stats.playerId))
        .collection('stats')
        .doc(stats.gameId)
        .set(data, SetOptions(merge: true));
  }

  /// Batch save stats for multiple players (e.g., after game completion)
  Future<void> batchSavePlayerStats(List<PlayerStats> statsList) async {
    final batch = _firestore.batch();

    for (final stats in statsList) {
      final data = stats.toJson();
      data.remove('playerId');
      data.remove('gameId');

      final ref = _firestore
          .doc(FirestorePaths.user(stats.playerId))
          .collection('stats')
          .doc(stats.gameId);

      batch.set(ref, data, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Delete stats for a specific game (e.g., when rolling back game result)
  Future<void> deletePlayerStats(String playerId, String gameId) async {
    await _firestore
        .doc(FirestorePaths.user(playerId))
        .collection('stats')
        .doc(gameId)
        .delete();
  }

  /// Get aggregate stats for a player (total goals, assists, MVP count)
  ///
  /// This calculates aggregates from all games in Firestore.
  /// For better performance, consider storing aggregates in a separate document
  /// that's updated by Cloud Functions.
  Future<Map<String, int>> getAggregateStats(String playerId) async {
    final allStats = await getPlayerStats(playerId);

    final totalGoals = allStats.fold<int>(0, (total, stats) => total + stats.goals);
    final totalAssists =
        allStats.fold<int>(0, (total, stats) => total + stats.assists);
    final mvpCount =
        allStats.where((stats) => stats.isMvp).length;
    final gamesPlayed = allStats.length;

    return {
      'totalGoals': totalGoals,
      'totalAssists': totalAssists,
      'mvpCount': mvpCount,
      'gamesPlayed': gamesPlayed,
      'totalContribution': totalGoals + totalAssists,
    };
  }

  /// Stream player stats for real-time updates
  Stream<List<PlayerStats>> streamPlayerStats(String playerId) {
    return _firestore
        .doc(FirestorePaths.user(playerId))
        .collection('stats')
        .orderBy('gameDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PlayerStats.fromJson({
                  ...doc.data(),
                  'playerId': playerId,
                  'gameId': doc.id,
                }))
            .toList());
  }
}
