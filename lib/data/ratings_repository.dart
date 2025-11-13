import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/firestore_paths.dart';
import 'package:kickadoor/data/hubs_repository.dart';

/// Repository for Rating operations
class RatingsRepository {
  final FirebaseFirestore _firestore;
  final HubsRepository _hubsRepo;

  RatingsRepository({
    FirebaseFirestore? firestore,
    HubsRepository? hubsRepo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _hubsRepo = hubsRepo ?? HubsRepository();

  /// Get rating snapshot by ID
  Future<RatingSnapshot?> getRatingSnapshot(String uid, String ratingId) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final doc = await _firestore
          .doc(FirestorePaths.ratingHistory(uid, ratingId))
          .get();
      if (!doc.exists) return null;
      return RatingSnapshot.fromJson({...doc.data()!, 'ratingId': ratingId});
    } catch (e) {
      throw Exception('Failed to get rating snapshot: $e');
    }
  }

  /// Stream rating snapshot by ID
  Stream<RatingSnapshot?> watchRatingSnapshot(String uid, String ratingId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .doc(FirestorePaths.ratingHistory(uid, ratingId))
        .snapshots()
        .map((doc) => doc.exists
            ? RatingSnapshot.fromJson({...doc.data()!, 'ratingId': doc.id})
            : null);
  }

  /// Get rating history for a player
  Future<List<RatingSnapshot>> getRatingHistory(String uid) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.ratingHistories(uid))
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RatingSnapshot.fromJson({...doc.data(), 'ratingId': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get rating history: $e');
    }
  }

  /// Stream rating history for a player
  Stream<List<RatingSnapshot>> watchRatingHistory(String uid) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.ratingHistories(uid))
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RatingSnapshot.fromJson({...doc.data(), 'ratingId': doc.id}))
            .toList());
  }

  /// Add rating snapshot
  Future<String> addRatingSnapshot(String uid, RatingSnapshot snapshot) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final data = snapshot.toJson();
      data.remove('ratingId'); // Remove ratingId from data (it's the document ID)
      data['submittedAt'] = FieldValue.serverTimestamp();

      final docRef = snapshot.ratingId.isNotEmpty
          ? _firestore.doc(FirestorePaths.ratingHistory(uid, snapshot.ratingId))
          : _firestore.collection(FirestorePaths.ratingHistories(uid)).doc();

      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add rating snapshot: $e');
    }
  }

  /// Calculate current rating from history (simple average of last N games)
  /// If hubId is provided, uses that hub's ratingMode setting
  Future<double> getCurrentRating(
    String uid, {
    int lastNGames = 10,
    String? hubId,
  }) async {
    if (!Env.isFirebaseAvailable) return AppConstants.defaultRating;

    try {
      // Get hub settings if hubId is provided
      String? ratingMode;
      if (hubId != null) {
        final hub = await _hubsRepo.getHub(hubId);
        ratingMode = hub?.settings['ratingMode'] as String? ?? 'basic';
      }

      final history = await getRatingHistory(uid);
      if (history.isEmpty) {
        // Return appropriate default based on rating mode
        return ratingMode == 'advanced'
            ? AppConstants.defaultRating
            : AppConstants.defaultBasicRating;
      }

      // Take last N games
      final recentRatings = history.take(lastNGames).toList();
      if (recentRatings.isEmpty) {
        return ratingMode == 'advanced'
            ? AppConstants.defaultRating
            : AppConstants.defaultBasicRating;
      }

      // Calculate average based on rating mode
      double totalRating = 0.0;
      int count = 0;

      for (var snapshot in recentRatings) {
        if (ratingMode == 'basic' && snapshot.basicScore != null) {
          // Use basic score if available and mode is basic
          totalRating += snapshot.basicScore!;
          count += 1;
        } else if (ratingMode != 'basic') {
          // Use advanced 8 categories
          totalRating += snapshot.defense;
          totalRating += snapshot.passing;
          totalRating += snapshot.shooting;
          totalRating += snapshot.dribbling;
          totalRating += snapshot.physical;
          totalRating += snapshot.leadership;
          totalRating += snapshot.teamPlay;
          totalRating += snapshot.consistency;
          count += 8;
        } else if (snapshot.basicScore == null) {
          // Fallback: if basic mode but no basicScore, use advanced calculation
          totalRating += snapshot.defense;
          totalRating += snapshot.passing;
          totalRating += snapshot.shooting;
          totalRating += snapshot.dribbling;
          totalRating += snapshot.physical;
          totalRating += snapshot.leadership;
          totalRating += snapshot.teamPlay;
          totalRating += snapshot.consistency;
          count += 8;
        }
      }

      if (count == 0) {
        return ratingMode == 'advanced'
            ? AppConstants.defaultRating
            : AppConstants.defaultBasicRating;
      }

      return totalRating / count;
    } catch (e) {
      throw Exception('Failed to calculate current rating: $e');
    }
  }

  /// Calculate time-based decay rating (weights recent games more)
  /// If hubId is provided, uses that hub's ratingMode setting
  Future<double> getDecayedRating(
    String uid, {
    int decayDays = 30,
    String? hubId,
  }) async {
    if (!Env.isFirebaseAvailable) return AppConstants.defaultRating;

    try {
      // Get hub settings if hubId is provided
      String? ratingMode;
      if (hubId != null) {
        final hub = await _hubsRepo.getHub(hubId);
        ratingMode = hub?.settings['ratingMode'] as String? ?? 'basic';
      }

      final history = await getRatingHistory(uid);
      if (history.isEmpty) {
        return ratingMode == 'advanced'
            ? AppConstants.defaultRating
            : AppConstants.defaultBasicRating;
      }

      final now = DateTime.now();
      double weightedSum = 0.0;
      double totalWeight = 0.0;

      for (var snapshot in history) {
        final daysAgo = now.difference(snapshot.submittedAt).inDays;
        if (daysAgo > decayDays) continue; // Skip ratings older than decayDays

        // Weight decreases linearly with time
        final weight = 1.0 - (daysAgo / decayDays);
        if (weight <= 0) continue;

        // Calculate average based on rating mode
        double avgRating;
        if (ratingMode == 'basic' && snapshot.basicScore != null) {
          avgRating = snapshot.basicScore!;
        } else if (ratingMode != 'basic') {
          // Average of all 8 categories
          avgRating = (snapshot.defense +
                  snapshot.passing +
                  snapshot.shooting +
                  snapshot.dribbling +
                  snapshot.physical +
                  snapshot.leadership +
                  snapshot.teamPlay +
                  snapshot.consistency) /
              8.0;
        } else {
          // Fallback: if basic mode but no basicScore, use advanced calculation
          avgRating = (snapshot.defense +
                  snapshot.passing +
                  snapshot.shooting +
                  snapshot.dribbling +
                  snapshot.physical +
                  snapshot.leadership +
                  snapshot.teamPlay +
                  snapshot.consistency) /
              8.0;
        }

        weightedSum += avgRating * weight;
        totalWeight += weight;
      }

      if (totalWeight == 0) {
        return ratingMode == 'advanced'
            ? AppConstants.defaultRating
            : AppConstants.defaultBasicRating;
      }

      return weightedSum / totalWeight;
    } catch (e) {
      throw Exception('Failed to calculate decayed rating: $e');
    }
  }

  /// Delete rating snapshot
  Future<void> deleteRatingSnapshot(String uid, String ratingId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.ratingHistory(uid, ratingId)).delete();
    } catch (e) {
      throw Exception('Failed to delete rating snapshot: $e');
    }
  }
}

