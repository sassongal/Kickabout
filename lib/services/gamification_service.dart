import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/config/env.dart';

/// Service for gamification - simplified to participation tracking only
/// No points, no levels, just milestone badges and stats
/// All updates are handled by Cloud Function onGameCompleted
class GamificationService {
  final FirebaseFirestore _firestore;

  GamificationService(this._firestore);

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

  /// DEPRECATED: updateGamification is now handled by Cloud Function onGameCompleted
  /// This method is kept for backward compatibility but should not be used
  /// All gamification updates happen server-side when a game is marked as completed
  @Deprecated('Use Cloud Function onGameCompleted instead')
  Future<void> updateGamification({
    required String userId,
    required int pointsEarned,
    required bool won,
    required int goals,
    required int assists,
    required int saves,
  }) async {
    debugPrint('⚠️ updateGamification is deprecated. Gamification is now handled by Cloud Function.');
    // No-op - gamification is handled by Cloud Function
  }

  /// Check and award milestone badges (simplified - only game count milestones)
  /// This is called by Cloud Function, not by client code
  /// Badges are awarded based on gamesPlayed count only (1st, 10th, 50th, 100th game)
  static List<String> checkMilestoneBadges(int gamesPlayed, List<String> currentBadges) {
    final badgesToAward = <String>[];

    // Game count milestone badges only
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

    // Goal badges (optional - for display only, no points)
    // These are tracked but don't affect ranking
    // Note: Goal tracking is handled separately in Cloud Function

    return badgesToAward;
  }

}

