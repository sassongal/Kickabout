import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/games/domain/models/game_audit_event.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/shared/infrastructure/cache/cache_service.dart';
import 'package:kattrick/shared/infrastructure/cache/cache_invalidation_service.dart';
import 'package:kattrick/services/retry_service.dart';
import 'package:kattrick/shared/infrastructure/monitoring/monitoring_service.dart';
import 'package:kattrick/utils/geohash_utils.dart';

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

  /// Create game with signups in a batch operation
  ///
  /// Data-access only - no business validation
  /// Use GameFinalizationService for business logic
  Future<String> createGameWithSignups({
    required Map<String, dynamic> gameData,
    required String gameId,
    required List<String> playerIds,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      // Add game document
      final gameRef = _firestore.doc(FirestorePaths.game(gameId));
      batch.set(gameRef, gameData);

      // Add signups for players
      for (final playerId in playerIds) {
        final signupRef = _firestore.doc(FirestorePaths.gameSignup(gameId, playerId));
        batch.set(signupRef, {
          'playerId': playerId,
          'status': SignupStatus.confirmed.toFirestore(),
          'signedUpAt': now,
        });
      }

      await batch.commit();

      // Invalidate cache
      _cacheInvalidation.onGameCreated(gameId, hubId: gameData['hubId'] as String?);

      return gameId;
    } catch (e) {
      throw Exception('Failed to create game with signups: $e');
    }
  }

  /// Convert event to game in a batch operation
  ///
  /// Data-access only - no business validation
  /// Use GameFinalizationService for business logic
  Future<String> convertEventToGameBatch({
    required String eventId,
    required String hubId,
    required String gameId,
    required Map<String, dynamic> gameData,
    required List<String> presentPlayerIds,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      // 1. Create game document
      final gameRef = _firestore.doc(FirestorePaths.game(gameId));
      batch.set(gameRef, gameData);

      // 2. Create signups for present players
      for (final playerId in presentPlayerIds) {
        final signupRef = _firestore.doc(FirestorePaths.gameSignup(gameId, playerId));
        batch.set(signupRef, {
          'playerId': playerId,
          'status': SignupStatus.confirmed.toFirestore(),
          'signedUpAt': now,
        });
      }

      // 3. Update event: mark as completed and reference the game
      final eventRef = _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId);
      batch.update(eventRef, {
        'status': 'completed',
        'gameId': gameId,
        'updatedAt': now,
      });

      await batch.commit();

      // Invalidate caches
      _cacheInvalidation.onEventConvertedToGame(hubId, eventId, gameId);

      return gameId;
    } catch (e) {
      throw Exception('Failed to convert event to game: $e');
    }
  }

  /// Get event data from Firestore
  ///
  /// Returns event document data and reference
  Future<(Map<String, dynamic> data, String eventId)> getEventData({
    required String eventId,
    required String hubId,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final eventRef = _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId);

      final eventDoc = await eventRef.get();
      if (!eventDoc.exists) {
        throw Exception('Event not found: $eventId');
      }

      return (eventDoc.data()!, eventId);
    } catch (e) {
      throw Exception('Failed to get event data: $e');
    }
  }

  /// Generate new game ID
  String generateGameId() {
    return _firestore.collection(FirestorePaths.games()).doc().id;
  }

  /// Find games nearby using geohash-based queries
  ///
  /// Returns games within the specified radius, sorted by distance.
  /// Only returns games that have a locationPoint set.
  Future<List<Game>> findGamesNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      // Get geohash for the location
      final centerGeohash =
          GeohashUtils.encode(latitude, longitude, precision: 7);
      final neighbors = GeohashUtils.neighbors(centerGeohash);

      // Query games in the geohash area concurrently
      final geohashes = <String>{centerGeohash, ...neighbors};
      final snapshots = await Future.wait(
        geohashes.map(
          (geohash) => _firestore
              .collection(FirestorePaths.games())
              .where('geohash', isGreaterThanOrEqualTo: geohash)
              .where('geohash', isLessThanOrEqualTo: '${geohash}z')
              // Only get upcoming and in-progress games
              .where('status', whereIn: [
                GameStatus.scheduled.name,
                GameStatus.recruiting.name,
                GameStatus.teamSelection.name,
                GameStatus.teamsFormed.name,
                GameStatus.inProgress.name,
              ])
              .limit(20) // Limit per geohash to prevent massive loads
              .get(),
        ),
      );

      final games = <Game>[];
      final distances = <String, double>{};

      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          if (distances.containsKey(doc.id)) continue;

          try {
            final game = Game.fromJson({...doc.data(), 'gameId': doc.id});

            // Skip games without location
            if (game.locationPoint == null) continue;

            final distanceKm = Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  game.locationPoint!.latitude,
                  game.locationPoint!.longitude,
                ) /
                1000; // Convert to km

            if (distanceKm <= radiusKm) {
              distances[doc.id] = distanceKm;
              games.add(game);
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing game ${doc.id}: $e');
            continue;
          }
        }
      }

      // Sort by distance (closest first)
      games.sort((a, b) =>
          distances[a.gameId]!.compareTo(distances[b.gameId]!));

      return games;
    } catch (e) {
      debugPrint('❌ Error in findGamesNearby: $e');
      return [];
    }
  }
}
