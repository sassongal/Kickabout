import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/firestore_paths.dart';

/// Leaderboard entry model
class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int score;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.score,
    required this.rank,
  });
}

/// Leaderboard type enum
enum LeaderboardType {
  points,
  gamesPlayed,
  goals,
  assists,
  rating,
  winRate,
}

/// Time period enum
enum TimePeriod {
  allTime,
  monthly,
  weekly,
}

/// Repository for Leaderboard operations
class LeaderboardRepository {
  final FirebaseFirestore _firestore;

  LeaderboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({
    LeaderboardType type = LeaderboardType.points,
    String? hubId,
    TimePeriod period = TimePeriod.allTime,
    int limit = 100,
  }) async {
    if (!Env.isFirebaseAvailable) {
      return [];
    }

    try {
      Query query = _firestore.collection(FirestorePaths.users());

      // Filter by hub if specified
      if (hubId != null) {
        query = query.where('hubIds', arrayContains: hubId);
      }

      // Order by the appropriate field
      String orderField;
      switch (type) {
        case LeaderboardType.points:
          orderField = 'gamification.points';
          break;
        case LeaderboardType.gamesPlayed:
          orderField = 'gamification.stats.gamesPlayed';
          break;
        case LeaderboardType.goals:
          orderField = 'gamification.stats.goals';
          break;
        case LeaderboardType.assists:
          orderField = 'gamification.stats.assists';
          break;
        case LeaderboardType.rating:
          orderField = 'currentRankScore';
          break;
        case LeaderboardType.winRate:
          // Calculate win rate on the fly
          orderField = 'gamification.stats.gamesWon';
          break;
      }

      query = query.orderBy(orderField, descending: true).limit(limit);

      final snapshot = await query.get();
      final entries = <LeaderboardEntry>[];

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;
        final user = User.fromJson({...data, 'uid': doc.id});

        int score;
        switch (type) {
          case LeaderboardType.points:
            score = await _getPoints(user.uid);
            break;
          case LeaderboardType.gamesPlayed:
            score = await _getGamesPlayed(user.uid);
            break;
          case LeaderboardType.goals:
            score = await _getGoals(user.uid);
            break;
          case LeaderboardType.assists:
            score = await _getAssists(user.uid);
            break;
          case LeaderboardType.rating:
            score = (user.currentRankScore * 10).round();
            break;
          case LeaderboardType.winRate:
            score = await _getWinRate(user.uid);
            break;
        }

        entries.add(LeaderboardEntry(
          userId: user.uid,
          userName: user.name,
          userPhotoUrl: user.photoUrl,
          score: score,
          rank: i + 1,
        ));
      }

      return entries;
    } catch (e) {
      debugPrint('Failed to get leaderboard: $e');
      return [];
    }
  }

  Future<int> _getPoints(String userId) async {
    final gamification = await _getGamification(userId);
    return gamification?.points ?? 0;
  }

  Future<int> _getGamesPlayed(String userId) async {
    final gamification = await _getGamification(userId);
    return gamification?.stats['gamesPlayed'] ?? 0;
  }

  Future<int> _getGoals(String userId) async {
    final gamification = await _getGamification(userId);
    return gamification?.stats['goals'] ?? 0;
  }

  Future<int> _getAssists(String userId) async {
    final gamification = await _getGamification(userId);
    return gamification?.stats['assists'] ?? 0;
  }

  Future<int> _getWinRate(String userId) async {
    final gamification = await _getGamification(userId);
    if (gamification == null) return 0;
    final gamesPlayed = gamification.stats['gamesPlayed'] ?? 0;
    if (gamesPlayed == 0) return 0;
    final gamesWon = gamification.stats['gamesWon'] ?? 0;
    return ((gamesWon / gamesPlayed) * 100).round();
  }

  Future<Gamification?> _getGamification(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('gamification')
          .doc('stats')
          .get();

      if (!doc.exists) return null;
      return Gamification.fromJson({...doc.data()!, 'userId': userId});
    } catch (e) {
      return null;
    }
  }
}

