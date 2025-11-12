import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';

/// Repository for Game operations
class GamesRepository {
  final FirebaseFirestore _firestore;

  GamesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get game by ID
  Future<Game?> getGame(String gameId) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final doc = await _firestore.doc(FirestorePaths.game(gameId)).get();
      if (!doc.exists) return null;
      return Game.fromJson({...doc.data()!, 'gameId': gameId});
    } catch (e) {
      throw Exception('Failed to get game: $e');
    }
  }

  /// Stream game by ID
  Stream<Game?> watchGame(String gameId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .doc(FirestorePaths.game(gameId))
        .snapshots()
        .map((doc) => doc.exists
            ? Game.fromJson({...doc.data()!, 'gameId': doc.id})
            : null);
  }

  /// Create game
  Future<String> createGame(Game game) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final now = FieldValue.serverTimestamp();
      final data = game.toJson();
      data.remove('gameId'); // Remove gameId from data (it's the document ID)
      data['createdAt'] = now;
      data['updatedAt'] = now;
      
      final docRef = game.gameId.isNotEmpty
          ? _firestore.doc(FirestorePaths.game(game.gameId))
          : _firestore.collection(FirestorePaths.games()).doc();
      
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create game: $e');
    }
  }

  /// Update game
  Future<void> updateGame(String gameId, Map<String, dynamic> data) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.doc(FirestorePaths.game(gameId)).update(data);
    } catch (e) {
      throw Exception('Failed to update game: $e');
    }
  }

  /// Update game status
  Future<void> updateGameStatus(String gameId, GameStatus status) async {
    await updateGame(gameId, {'status': status.toFirestore()});
  }

  /// Delete game
  Future<void> deleteGame(String gameId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.game(gameId)).delete();
    } catch (e) {
      throw Exception('Failed to delete game: $e');
    }
  }

  /// Stream games by hub
  Stream<List<Game>> watchGamesByHub(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.games())
        .where('hubId', isEqualTo: hubId)
        .orderBy('gameDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Game.fromJson({...doc.data(), 'gameId': doc.id}))
            .toList());
  }

  /// Stream games by creator
  Stream<List<Game>> watchGamesByCreator(String uid) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.games())
        .where('createdBy', isEqualTo: uid)
        .orderBy('gameDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Game.fromJson({...doc.data(), 'gameId': doc.id}))
            .toList());
  }

  /// List games by hub (non-streaming)
  Future<List<Game>> listGamesByHub(String hubId, {int? limit}) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      var query = _firestore
          .collection(FirestorePaths.games())
          .where('hubId', isEqualTo: hubId)
          .orderBy('gameDate', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Game.fromJson({...doc.data(), 'gameId': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to list games: $e');
    }
  }

  /// Get games by hub (alias for listGamesByHub)
  Future<List<Game>> getGamesByHub(String hubId) async {
    return listGamesByHub(hubId);
  }

  /// Add photo URL to game
  Future<void> addGamePhoto(String gameId, String photoUrl) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final game = await getGame(gameId);
      if (game == null) {
        throw Exception('Game not found');
      }

      final updatedPhotoUrls = [...game.photoUrls, photoUrl];
      await updateGame(gameId, {'photoUrls': updatedPhotoUrls});
    } catch (e) {
      throw Exception('Failed to add game photo: $e');
    }
  }

  /// Remove photo URL from game
  Future<void> removeGamePhoto(String gameId, String photoUrl) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final game = await getGame(gameId);
      if (game == null) {
        throw Exception('Game not found');
      }

      final updatedPhotoUrls = game.photoUrls.where((url) => url != photoUrl).toList();
      await updateGame(gameId, {'photoUrls': updatedPhotoUrls});
    } catch (e) {
      throw Exception('Failed to remove game photo: $e');
    }
  }
}

