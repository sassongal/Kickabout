import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/firestore_paths.dart';

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

  /// Stream leaderboard from gamification/stats collection
  /// 
  /// Queries the gamification/stats subcollection across all users,
  /// sorted by points in descending order
  Stream<List<LeaderboardEntry>> streamLeaderboard({
    LeaderboardType type = LeaderboardType.points,
    String? hubId,
    TimePeriod period = TimePeriod.allTime,
    int limit = 100,
  }) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    try {
      // We need to query users first, then get their gamification stats
      // Since Firestore doesn't support cross-collection queries directly,
      // we'll use a composite approach:
      // 1. Get all users (optionally filtered by hub)
      // 2. For each user, get their gamification stats
      // 3. Sort and limit
      
      // For now, we'll use a simpler approach: query users and then
      // watch their gamification stats in parallel
      // This is not ideal for large datasets, but works for MVP
      
      Query query = _firestore.collection(FirestorePaths.users());
      
      // Filter by hub if specified
      if (hubId != null) {
        query = query.where('hubIds', arrayContains: hubId);
      }
      
      // Order by a field that exists on User (we'll sort by gamification later)
      query = query.limit(limit * 2); // Get more users to account for filtering
      
      return query.snapshots().asyncMap((snapshot) async {
        final entries = <LeaderboardEntry>[];
        
        for (int i = 0; i < snapshot.docs.length; i++) {
          final doc = snapshot.docs[i];
          final data = doc.data() as Map<String, dynamic>;
          final user = User.fromJson({...data, 'uid': doc.id});
          
          // Get gamification stats
          final gamification = await _getGamification(user.uid);
          if (gamification == null) continue;
          
          int score;
          switch (type) {
            case LeaderboardType.points:
              score = gamification.points;
              break;
            case LeaderboardType.gamesPlayed:
              score = gamification.stats['gamesPlayed'] ?? 0;
              break;
            case LeaderboardType.goals:
              score = gamification.stats['goals'] ?? 0;
              break;
            case LeaderboardType.assists:
              score = gamification.stats['assists'] ?? 0;
              break;
            case LeaderboardType.rating:
              score = (user.currentRankScore * 10).round();
              break;
            case LeaderboardType.winRate:
              final gamesPlayed = gamification.stats['gamesPlayed'] ?? 0;
              if (gamesPlayed == 0) {
                score = 0;
              } else {
                final gamesWon = gamification.stats['gamesWon'] ?? 0;
                score = ((gamesWon / gamesPlayed) * 100).round();
              }
              break;
          }
          
          entries.add(LeaderboardEntry(
            userId: user.uid,
            userName: user.name,
            userPhotoUrl: user.photoUrl,
            score: score,
            rank: 0, // Will be set after sorting
          ));
        }
        
        // Sort by score (descending)
        entries.sort((a, b) => b.score.compareTo(a.score));
        
        // Set ranks and limit
        for (int i = 0; i < entries.length && i < limit; i++) {
          entries[i] = LeaderboardEntry(
            userId: entries[i].userId,
            userName: entries[i].userName,
            userPhotoUrl: entries[i].userPhotoUrl,
            score: entries[i].score,
            rank: i + 1,
          );
        }
        
        return entries.take(limit).toList();
      });
    } catch (e) {
      debugPrint('Failed to stream leaderboard: $e');
      return Stream.value([]);
    }
  }
}

