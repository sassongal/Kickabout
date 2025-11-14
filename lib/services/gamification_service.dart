import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/config/env.dart';

/// Service for gamification calculations and updates
class GamificationService {
  final FirebaseFirestore _firestore;

  GamificationService(this._firestore);

  /// Calculate points for a game result
  static int calculateGamePoints({
    required bool won,
    required int goals,
    required int assists,
    required int saves,
    required bool isMVP,
    required double averageRating,
  }) {
    int points = 0;

    // Base participation
    points += 10;

    // Win bonus
    if (won) points += 20;

    // Performance bonuses
    points += (goals * 5);
    points += (assists * 3);
    points += (saves * 2);

    // MVP bonus
    if (isMVP) points += 15;

    // Rating bonus
    if (averageRating >= 8.0) points += 10;
    if (averageRating >= 9.0) points += 5; // Additional bonus

    return points;
  }

  /// Calculate level from total points
  static int calculateLevel(int totalPoints) {
    if (totalPoints <= 0) return 1;
    return math.sqrt(totalPoints / 100).floor() + 1;
  }

  /// Calculate points needed for next level
  static int pointsForNextLevel(int currentLevel) {
    return (currentLevel * 100) * (currentLevel * 100);
  }

  /// Get gamification for a user
  Future<Gamification?> getGamification(String userId) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('gamification')
          .doc('stats')
          .get();

      if (!doc.exists) {
        // Create default gamification
        final defaultGamification = Gamification(userId: userId);
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('gamification')
            .doc('stats')
            .set(defaultGamification.toJson());
        return defaultGamification;
      }

      return Gamification.fromJson({...doc.data()!, 'userId': userId});
    } catch (e) {
      return null;
    }
  }

  /// Stream gamification for a user
  Stream<Gamification?> watchGamification(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('gamification')
        .doc('stats')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return Gamification(userId: userId);
      }
      return Gamification.fromJson({...snapshot.data()!, 'userId': userId});
    });
  }

  /// Update user gamification after game
  Future<void> updateGamification({
    required String userId,
    required int pointsEarned,
    required bool won,
    required int goals,
    required int assists,
    required int saves,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final currentGamification = await getGamification(userId);
      if (currentGamification == null) {
        throw Exception('Failed to get current gamification');
      }

      final newPoints = currentGamification.points + pointsEarned;
      final newLevel = calculateLevel(newPoints);
      final oldLevel = currentGamification.level;

      final newStats = {
        'gamesPlayed': (currentGamification.stats['gamesPlayed'] ?? 0) + 1,
        'gamesWon': (currentGamification.stats['gamesWon'] ?? 0) + (won ? 1 : 0),
        'goals': (currentGamification.stats['goals'] ?? 0) + goals,
        'assists': (currentGamification.stats['assists'] ?? 0) + assists,
        'saves': (currentGamification.stats['saves'] ?? 0) + saves,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('gamification')
          .doc('stats')
          .set({
        'userId': userId,
        'points': newPoints,
        'level': newLevel,
        'badges': currentGamification.badges,
        'achievements': currentGamification.achievements,
        'stats': newStats,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Check for level up
      if (newLevel > oldLevel) {
        await _awardLevelUpNotification(userId, newLevel);
      }

      // Check for achievement badges
      await _checkAndAwardBadges(
        userId,
        newPoints,
        newStats['gamesPlayed']!,
        newStats['goals']!,
      );
    } catch (e) {
      throw Exception('Failed to update gamification: $e');
    }
  }

  /// Check and award badges
  Future<void> _checkAndAwardBadges(
    String userId,
    int totalPoints,
    int gamesPlayed,
    int goals,
  ) async {
    if (!Env.isFirebaseAvailable) return;

    try {
      final currentGamification = await getGamification(userId);
      if (currentGamification == null) return;

      final currentBadges = currentGamification.badges;
      final badgesToAward = <String>[];

      // Game count badges
      if (gamesPlayed >= 1 && !currentBadges.contains(BadgeType.firstGame.name)) {
        badgesToAward.add(BadgeType.firstGame.name);
      }
      if (gamesPlayed >= 10 && !currentBadges.contains(BadgeType.tenGames.name)) {
        badgesToAward.add(BadgeType.tenGames.name);
      }
      if (gamesPlayed >= 50 && !currentBadges.contains(BadgeType.fiftyGames.name)) {
        badgesToAward.add(BadgeType.fiftyGames.name);
      }
      if (gamesPlayed >= 100 && !currentBadges.contains(BadgeType.hundredGames.name)) {
        badgesToAward.add(BadgeType.hundredGames.name);
      }

      // Goal badges
      if (goals >= 1 && !currentBadges.contains(BadgeType.firstGoal.name)) {
        badgesToAward.add(BadgeType.firstGoal.name);
      }
      if (goals >= 3 && !currentBadges.contains(BadgeType.hatTrick.name)) {
        badgesToAward.add(BadgeType.hatTrick.name);
      }

      if (badgesToAward.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('gamification')
            .doc('stats')
            .update({
          'badges': FieldValue.arrayUnion(badgesToAward),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create notifications for new badges
        for (final badge in badgesToAward) {
          await _createBadgeNotification(userId, badge);
        }
      }
    } catch (e) {
      debugPrint('Failed to check and award badges: $e');
    }
  }

  Future<void> _awardLevelUpNotification(String userId, int level) async {
    // This will be handled by NotificationsRepository
    // Placeholder for now
  }

  Future<void> _createBadgeNotification(String userId, String badge) async {
    // This will be handled by NotificationsRepository
    // Placeholder for now
  }
}

