import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';

/// Repository for Game Signup operations
class SignupsRepository {
  final FirebaseFirestore _firestore;

  SignupsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get signup by game ID and user ID
  Future<GameSignup?> getSignup(String gameId, String uid) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final doc = await _firestore
          .doc(FirestorePaths.gameSignup(gameId, uid))
          .get();
      if (!doc.exists) return null;
      return GameSignup.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get signup: $e');
    }
  }

  /// Stream signup by game ID and user ID
  Stream<GameSignup?> watchSignup(String gameId, String uid) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .doc(FirestorePaths.gameSignup(gameId, uid))
        .snapshots()
        .map((doc) => doc.exists ? GameSignup.fromJson(doc.data()!) : null);
  }

  /// Set signup (create or update)
  Future<void> setSignup(
    String gameId,
    String uid,
    SignupStatus status,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final signup = GameSignup(
        playerId: uid,
        signedUpAt: DateTime.now(),
        status: status,
      );
      
      await _firestore
          .doc(FirestorePaths.gameSignup(gameId, uid))
          .set(signup.toJson());
    } catch (e) {
      throw Exception('Failed to set signup: $e');
    }
  }

  /// Remove signup
  Future<void> removeSignup(String gameId, String uid) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.gameSignup(gameId, uid)).delete();
    } catch (e) {
      throw Exception('Failed to remove signup: $e');
    }
  }

  /// Stream all signups for a game
  Stream<List<GameSignup>> watchSignups(String gameId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.gameSignups(gameId))
        .orderBy('signedUpAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameSignup.fromJson(doc.data()))
            .toList());
  }

  /// Get all signups for a game (non-streaming)
  Future<List<GameSignup>> getSignups(String gameId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.gameSignups(gameId))
          .orderBy('signedUpAt', descending: false)
          .get();
      
      return snapshot.docs
          .map((doc) => GameSignup.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get signups: $e');
    }
  }

  /// Stream signups by status
  Stream<List<GameSignup>> watchSignupsByStatus(
    String gameId,
    SignupStatus status,
  ) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.gameSignups(gameId))
        .where('status', isEqualTo: status.toFirestore())
        .orderBy('signedUpAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameSignup.fromJson(doc.data()))
            .toList());
  }

  /// Check if user is signed up
  Future<bool> isSignedUp(String gameId, String uid) async {
    if (!Env.isFirebaseAvailable) return false;

    try {
      final signup = await getSignup(gameId, uid);
      return signup != null;
    } catch (e) {
      return false;
    }
  }
}

