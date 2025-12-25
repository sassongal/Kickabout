import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/game_audit_event.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/services/cache_service.dart';
import 'package:kattrick/services/cache_invalidation_service.dart';
import 'package:kattrick/services/retry_service.dart';
import 'package:kattrick/services/monitoring_service.dart';

/// Repository for basic Game CRUD operations
/// For complex queries, see GameQueriesRepository
/// For session management, see SessionRepository
/// For match approval, see MatchApprovalRepository
/// For game finalization, see GameFinalizationService
class GamesRepository {
  final FirebaseFirestore _firestore;
  final CacheInvalidationService _cacheInvalidation;

  GamesRepository({
    FirebaseFirestore? firestore,
    CacheInvalidationService? cacheInvalidation,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheInvalidation = cacheInvalidation ?? CacheInvalidationService();

  /// Get game by ID with caching and retry
  Future<Game?> getGame(String gameId, {bool forceRefresh = false}) async {
    if (!Env.isFirebaseAvailable) return null;

    return MonitoringService().trackOperation(
      'getGame',
      () => CacheService().getOrFetch<Game?>(
        CacheKeys.game(gameId),
        () => RetryService().execute(
          () async {
            final doc = await _firestore.doc(FirestorePaths.game(gameId)).get();
            if (!doc.exists) return null;
            return Game.fromJson({...doc.data()!, 'gameId': gameId});
          },
          config: RetryConfig.network,
          operationName: 'getGame',
        ),
        ttl: CacheService.gamesTtl,
        forceRefresh: forceRefresh,
      ),
      metadata: {'gameId': gameId},
    );
  }

  /// Stream game by ID
  Stream<Game?> watchGame(String gameId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore.doc(FirestorePaths.game(gameId)).snapshots().map((doc) =>
        doc.exists ? Game.fromJson({...doc.data()!, 'gameId': doc.id}) : null);
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

      // Invalidate cache using centralized service
      _cacheInvalidation.onGameCreated(docRef.id, hubId: game.hubId);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create game: $e');
    }
  }

  /// Update game with retry and cache invalidation
  Future<void> updateGame(String gameId, Map<String, dynamic> data) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    return MonitoringService().trackOperation(
      'updateGame',
      () => RetryService().execute(
        () async {
          data['updatedAt'] = FieldValue.serverTimestamp();
          await _firestore.doc(FirestorePaths.game(gameId)).update(data);

          // Invalidate cache using centralized service
          _cacheInvalidation.onGameUpdated(
            gameId,
            hubId: data['hubId'] as String?,
            region: data['region'] as String?,
            city: data['city'] as String?,
          );
        },
        config: RetryConfig.network,
        operationName: 'updateGame',
      ),
      metadata: {'gameId': gameId},
    );
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
      // Get game to know hubId for cache invalidation
      final gameDoc = await _firestore.doc(FirestorePaths.game(gameId)).get();
      final hubId = gameDoc.data()?['hubId'] as String?;

      await _firestore.doc(FirestorePaths.game(gameId)).delete();

      // Invalidate cache using centralized service
      _cacheInvalidation.onGameDeleted(gameId, hubId: hubId);
    } catch (e) {
      throw Exception('Failed to delete game: $e');
    }
  }

  /// Get events for a game (goals, assists, etc.)
  Future<List<GameEvent>> getGameEvents(String gameId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.games())
          .doc(gameId)
          .collection('events')
          .get();

      return snapshot.docs
          .map((doc) => GameEvent.fromJson({...doc.data(), 'eventId': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching game events: $e');
      return [];
    }
  }

  /// Get teams for a game
  Future<List<Team>> getGameTeams(String gameId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.games())
          .doc(gameId)
          .collection('teams')
          .get();

      return snapshot.docs
          .map((doc) => Team.fromJson({...doc.data(), 'teamId': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching game teams: $e');
      return [];
    }
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

      final updatedPhotoUrls =
          game.photoUrls.where((url) => url != photoUrl).toList();
      await updateGame(gameId, {'photoUrls': updatedPhotoUrls});
    } catch (e) {
      throw Exception('Failed to remove game photo: $e');
    }
  }

  /// Save teams for a game
  ///
  /// Saves the list of teams to the game document.
  ///
  /// [gameId] - ID of the game
  /// [teams] - List of teams to save
  Future<void> saveTeamsForGame(String gameId, List<Team> teams) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Convert teams to JSON
      final teamsJson = teams.map((team) => team.toJson()).toList();

      await updateGame(gameId, {
        'teams': teamsJson,
      });
    } catch (e) {
      throw Exception('Failed to save teams: $e');
    }
  }

  /// Get DocumentReference for a game (for transactions)
  DocumentReference getGameRef(String gameId) {
    return _firestore.doc(FirestorePaths.game(gameId));
  }

  /// Update game within a transaction
  /// 
  /// This is a helper for services that need to update games in transactions.
  /// The service should handle business logic, this just performs the data update.
  void updateGameInTransaction(
    Transaction transaction,
    String gameId,
    Map<String, dynamic> data,
  ) {
    final gameRef = getGameRef(gameId);
    data['updatedAt'] = FieldValue.serverTimestamp();
    transaction.update(gameRef, data);
  }

  /// Add audit log entry to game within a transaction
  void addAuditLogInTransaction(
    Transaction transaction,
    String gameId,
    GameAuditEvent auditEvent,
  ) {
    final gameRef = getGameRef(gameId);
    transaction.update(gameRef, {
      'audit.auditLog': FieldValue.arrayUnion([auditEvent.toJson()]),
    });
  }
}
