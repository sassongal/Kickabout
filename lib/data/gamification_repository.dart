import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';
import 'package:kickabout/services/gamification_service.dart';

/// Repository for Gamification operations
class GamificationRepository {
  final FirebaseFirestore _firestore;
  final GamificationService _service;

  GamificationRepository({
    FirebaseFirestore? firestore,
    GamificationService? service,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _service = service ?? GamificationService(FirebaseFirestore.instance);

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

