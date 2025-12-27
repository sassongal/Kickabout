import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/gamification/infrastructure/services/gamification_service.dart';

/// Repository for Gamification operations
class GamificationRepository {
  final GamificationService _service;

  GamificationRepository({
    GamificationService? service,
  })  : _service = service ?? GamificationService(FirebaseFirestore.instance);

  /// Stream gamification for a user
  Stream<Gamification?> watchGamification(String userId) {
    return _service.watchGamification(userId);
  }

  /// Get gamification for a user
  Future<Gamification?> getGamification(String userId) async {
    return _service.getGamification(userId);
  }

  /// Update gamification after game
  Future<void> updateGamification({
    required String userId,
    required int pointsEarned,
    required bool won,
    required int goals,
    required int assists,
    required int saves,
  }) async {
    return _service.updateGamification(
      userId: userId,
      pointsEarned: pointsEarned,
      won: won,
      goals: goals,
      assists: assists,
      saves: saves,
    );
  }
}

