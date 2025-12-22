import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/game_result.dart';
import 'package:kattrick/services/hub_permissions_service.dart'; // Added import
import 'package:kattrick/models/log_past_game_details.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/services/cache_service.dart';
import 'package:kattrick/services/cache_invalidation_service.dart';
import 'package:kattrick/services/retry_service.dart';
import 'package:kattrick/services/monitoring_service.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/data/hubs_repository.dart';
import 'package:kattrick/utils/geohash_utils.dart';
import 'package:kattrick/logic/session_rotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';

/// Repository for Game operations
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

  /// Stream user's next upcoming match
  Stream<Game?> watchNextMatch(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    final now = DateTime.now();
    return _firestore
        .collection(FirestorePaths.games())
        .where('confirmedPlayerIds', arrayContains: userId)
        .where('gameDate', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('gameDate')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return Game.fromJson({...doc.data(), 'gameId': doc.id});
    });
  }

  /// Stream discovery feed of games (public & hub games nearby)
  ///
  /// OPTIMIZED VERSION - Uses correct geohash precision and neighbor queries
  /// to minimize over-fetching instead of fetching 3x data.
  Stream<List<Game>> watchDiscoveryFeed({
    GeoPoint? userLocation,
    double radiusKm = 10.0,
    int limit = 20,
  }) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    final now = DateTime.now();

    // If no location, just show recent games
    if (userLocation == null) {
      return _firestore
          .collection(FirestorePaths.games())
          .where('gameDate', isGreaterThan: Timestamp.fromDate(now))
          .where('status', whereNotIn: [
            GameStatus.cancelled.toFirestore(),
            GameStatus.archivedNotPlayed.toFirestore(),
            GameStatus.draft.toFirestore(),
          ])
          .orderBy('gameDate')
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Game.fromJson({...doc.data(), 'gameId': doc.id}))
              .toList());
    }

    // OPTIMIZED: Use appropriate precision based on radius
    // precision 5 ≈ 5km, precision 6 ≈ 1.2km, precision 7 ≈ 150m
    final precision = radiusKm <= 1.5 ? 7 : (radiusKm <= 5 ? 6 : 5);

    final centerHash = GeohashUtils.encode(
      userLocation.latitude,
      userLocation.longitude,
      precision: precision,
    );

    // Get neighboring geohashes to cover the area
    final neighbors = GeohashUtils.neighbors(centerHash);
    final hashesToQuery = [centerHash, ...neighbors];

    // Query multiple geohash regions (parallel streams)
    // Use a reduced per-hash limit to avoid 9x over-fetching
    final computedLimit = (limit / 2).ceil();
    final perHashLimit = computedLimit < 1 ? 1 : computedLimit;
    final streams = hashesToQuery.map((hash) {
      return _firestore
          .collection(FirestorePaths.games())
          .where('gameDate', isGreaterThan: Timestamp.fromDate(now))
          .where('status', whereNotIn: [
            GameStatus.cancelled.toFirestore(),
            GameStatus.archivedNotPlayed.toFirestore(),
            GameStatus.draft.toFirestore(),
          ])
          .where('geohash', isGreaterThanOrEqualTo: hash)
          .where('geohash', isLessThan: '$hash~')
          .limit(perHashLimit) // Reduced per-hash limit
          .snapshots();
    }).toList();

    // FIXED: Use RxDart to combine streams reactively instead of polling
    // This eliminates the Stream.periodic anti-pattern and reduces read costs by ~99%
    return Rx.combineLatest(
      streams,
      (List<QuerySnapshot<Map<String, dynamic>>> snapshots) {
        // Combine all results from geohash regions
        var games = snapshots
            .expand((snapshot) => snapshot.docs)
            .map((doc) => Game.fromJson({...doc.data(), 'gameId': doc.id}))
            .toSet() // Remove duplicates across geohashes
            .toList();

        // Filter by actual distance (geohash is approximate)
        games = games.where((game) {
          if (game.locationPoint == null) return false;

          final distanceMeters = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            game.locationPoint!.latitude,
            game.locationPoint!.longitude,
          );
          final distanceKm = distanceMeters / 1000;

          return distanceKm <= radiusKm;
        }).toList();

        // Sort by distance (closest first)
        games.sort((a, b) {
          final distA = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            a.locationPoint!.latitude,
            a.locationPoint!.longitude,
          );
          final distB = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            b.locationPoint!.latitude,
            b.locationPoint!.longitude,
          );
          return distA.compareTo(distB);
        });

        // Limit to requested count
        return games.take(limit).toList();
      },
    );
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

  /// Stream all completed games (for main games screen)
  /// OPTIMIZED: Shows games with scores from all hubs, filtered by showInCommunityFeed
  Stream<List<Game>> watchCompletedGames({int limit = 50}) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    // OPTIMIZED: Filter by showInCommunityFeed AND status in Firestore (requires index)
    return _firestore
        .collection(FirestorePaths.games())
        .where('status', isEqualTo: 'completed')
        .where('showInCommunityFeed',
            isEqualTo: true) // Filter in Firestore, not memory
        .orderBy('gameDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      // Only filter scores in memory (Firestore can't filter on null/not null easily)
      return snapshot.docs
          .map((doc) => Game.fromJson({...doc.data(), 'gameId': doc.id}))
          .where((game) =>
              game.session.legacyTeamAScore != null &&
              game.session.legacyTeamBScore != null)
          .toList();
    });
  }

  /// Stream all public completed games for community feed
  /// OPTIMIZED: Uses Firestore indexes for filtering instead of in-memory filtering
  /// Shows games with showInCommunityFeed = true and status = completed
  Stream<List<Game>> watchPublicCompletedGames({
    int limit = 50, // Reduced from 100, use pagination for more
    String? hubId,
    String? region,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    DocumentSnapshot? startAfter, // Pagination cursor
  }) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    try {
      // OPTIMIZED: Filter by both showInCommunityFeed AND status in Firestore
      // This requires a composite index (already defined in firestore.indexes.json)
      Query query = _firestore
          .collection(FirestorePaths.games())
          .where('showInCommunityFeed', isEqualTo: true)
          .where('status',
              isEqualTo: 'completed'); // Filter in Firestore, not memory

      // Apply additional filters
      if (hubId != null) {
        query = query.where('hubId', isEqualTo: hubId);
      } else {
        if (region != null) {
          query = query.where('region', isEqualTo: region);
        }
        if (city != null) {
          query = query.where('city', isEqualTo: city);
        }
      }

      // Date filters - apply in Firestore if possible
      if (startDate != null &&
          hubId == null &&
          region == null &&
          city == null) {
        query = query.where('gameDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null &&
          hubId == null &&
          region == null &&
          city == null &&
          startDate == null) {
        query = query.where('gameDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Pagination support
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      return query
          .orderBy('gameDate', descending: true)
          .limit(
              limit) // No need for limit * 2 - filtering is done in Firestore
          .snapshots()
          .map((snapshot) {
        return MonitoringService().trackSyncOperation<List<Game>>(
          'watchPublicCompletedGames',
          () {
            var games = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Game.fromJson({...data, 'gameId': doc.id});
            }).toList();

            // Only filter scores in memory (Firestore can't filter on null/not null easily)
            // But most completed games should have scores anyway
            games = games
                .where((game) =>
                    game.session.legacyTeamAScore != null &&
                    game.session.legacyTeamBScore != null)
                .toList();

            // Apply date filters in memory only if they couldn't be applied in query
            if (startDate != null &&
                (hubId != null || region != null || city != null)) {
              games = games
                  .where((g) =>
                      g.gameDate.isAfter(startDate) ||
                      g.gameDate.isAtSameMomentAs(startDate))
                  .toList();
            }
            if (endDate != null &&
                (hubId != null ||
                    region != null ||
                    city != null ||
                    startDate != null)) {
              games = games
                  .where((g) =>
                      g.gameDate.isBefore(endDate) ||
                      g.gameDate.isAtSameMomentAs(endDate))
                  .toList();
            }

            // Cache the result
            final cacheKey = CacheKeys.publicGames(region: region, city: city);
            CacheService().set(cacheKey, games, ttl: CacheService.gamesTtl);

            return games;
          },
          metadata: {
            'count': snapshot.docs.length,
            'region': region,
            'city': city,
            'hubId': hubId,
          },
        );
      });
    } catch (e) {
      debugPrint('Error in watchPublicCompletedGames: $e');
      ErrorHandlerService()
          .logError(e, reason: 'watchPublicCompletedGames failed');
      return Stream.error(e);
    }
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

  /// Get upcoming games for a list of hubs
  Future<List<Game>> getUpcomingGames({
    required List<String> hubIds,
    int limit = 20,
  }) async {
    if (!Env.isFirebaseAvailable) return [];
    if (hubIds.isEmpty) return [];

    try {
      // Split hubIds into batches of 10 (Firestore 'in' query limit)
      final games = <Game>[];
      final now = Timestamp.now();

      for (var i = 0; i < hubIds.length; i += 10) {
        final batch = hubIds.skip(i).take(10).toList();

        final snapshot = await _firestore
            .collection(FirestorePaths.games())
            .where('hubId', whereIn: batch)
            .where('gameDate', isGreaterThan: now)
            .orderBy('gameDate')
            .limit(limit)
            .get();

        games.addAll(snapshot.docs
            .map((doc) => Game.fromJson({...doc.data(), 'gameId': doc.id})));
      }

      // Sort combined results
      games.sort((a, b) => a.gameDate.compareTo(b.gameDate));

      return games.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching upcoming games: $e');
      return [];
    }
  }

  /// Get games by hub (alias for listGamesByHub)
  Future<List<Game>> getGamesByHub(String hubId) async {
    return listGamesByHub(hubId);
  }

  /// Get completed games for a specific player in a specific hub
  /// Used for calculating per-hub stats
  Future<List<Game>> getPlayerGamesInHub(String hubId, String playerId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.games())
          .where('hubId', isEqualTo: hubId)
          .where('confirmedPlayerIds', arrayContains: playerId)
          .where('status', isEqualTo: 'completed')
          .orderBy('gameDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Game.fromJson({...doc.data(), 'gameId': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching player games in hub: $e');
      return [];
    }
  }

  /// Get all completed games for a hub (for Analytics)
  Future<List<Game>> getCompletedGamesForHub(String hubId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.games())
          .where('hubId', isEqualTo: hubId)
          .where('status', isEqualTo: 'completed')
          .orderBy('gameDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Game.fromJson({...doc.data(), 'gameId': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching completed games for hub: $e');
      return [];
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

  /// Stream upcoming games for a user
  ///
  /// OPTIMIZED VERSION - Uses denormalized data in signups to avoid N+1 queries.
  /// Single collection group query instead of 1 + N/10 queries.
  ///
  /// Returns games where:
  /// - User is signed up (confirmed status)
  /// - Game status is 'teamSelection' or 'teamsFormed'
  /// - Game date is in the future
  ///
  /// NOTE: This relies on denormalized game data in GameSignup documents.
  /// Cloud Functions must keep this data in sync when games are updated.
  Stream<List<Game>> streamMyUpcomingGames(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    try {
      final now = DateTime.now();

      // OPTIMIZED: Single query using denormalized data from signups
      // This eliminates the N+1 pattern (was 1 signup query + N/10 game queries)
      return _firestore
          .collectionGroup('signups')
          .where('playerId', isEqualTo: userId)
          .where('status', isEqualTo: 'confirmed')
          .where('gameDate', isGreaterThan: Timestamp.fromDate(now))
          .where('gameStatus', whereIn: ['teamSelection', 'teamsFormed'])
          .orderBy('gameDate')
          .limit(50) // Reasonable limit for upcoming games
          .snapshots()
          .asyncMap((signupsSnapshot) async {
        if (signupsSnapshot.docs.isEmpty) return <Game>[];

        // Extract game IDs and check if denormalized data exists
        final gameIds = <String>[];
        final needsFallback = <String>[];

        for (final doc in signupsSnapshot.docs) {
          final pathParts = doc.reference.path.split('/');
          if (pathParts.length >= 2 && pathParts[0] == 'games') {
            final gameId = pathParts[1];
            final data = doc.data();

            // Check if signup has denormalized data
            if (data['gameDate'] != null && data['gameStatus'] != null) {
              gameIds.add(gameId);
            } else {
              // Fallback: signup doesn't have denormalized data yet
              needsFallback.add(gameId);
            }
          }
        }

        // Fetch full game documents (only needed for denormalized data)
        if (gameIds.isEmpty && needsFallback.isEmpty) return <Game>[];

        final games = <Game>[];

        // Batch query for games (Firestore 'in' limit is 10)
        final allGameIds = [...gameIds, ...needsFallback];
        for (var i = 0; i < allGameIds.length; i += 10) {
          final batch = allGameIds.skip(i).take(10).toList();

          try {
            final gamesSnapshot = await _firestore
                .collection(FirestorePaths.games())
                .where(FieldPath.documentId, whereIn: batch)
                .get();

            games.addAll(
              gamesSnapshot.docs.map(
                  (doc) => Game.fromJson({...doc.data(), 'gameId': doc.id})),
            );
          } catch (e) {
            debugPrint('Error fetching games batch: $e');
            // Continue with next batch
          }
        }

        // Filter by status and date (safety check for fallback cases)
        final filteredGames = games.where((game) {
          return (game.status == GameStatus.teamSelection ||
                  game.status == GameStatus.teamsFormed) &&
              game.gameDate.isAfter(now);
        }).toList();

        // Sort by game date
        filteredGames.sort((a, b) => a.gameDate.compareTo(b.gameDate));

        return filteredGames;
      });
    } catch (e) {
      debugPrint('Error in streamMyUpcomingGames: $e');
      return Stream.error(e);
    }
  }

  /// Log a past game retroactively
  ///
  /// Creates a Game document with status 'completed' immediately,
  /// along with signups for all participating players
  Future<void> logPastGame(
      LogPastGameDetails details, String currentUserId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final now = FieldValue.serverTimestamp();

      // Create game object with nested structure
      final gameId = _firestore.collection(FirestorePaths.games()).doc().id;
      final game = Game(
        gameId: gameId,
        createdBy: currentUserId,
        hubId: details.hubId,
        gameDate: details.gameDate,
        venueId: details.venueId,
        eventId: details.eventId,
        teamCount: 2,
        status: GameStatus.completed,
        showInCommunityFeed: details.showInCommunityFeed,
        region: details.region,
        city: details.city,
        teams: details.teams,
        createdAt: DateTime
            .now(), // approximation, will set server timestamp later if needed, but Game model expects DateTime.
        updatedAt: DateTime.now(),
        denormalized: GameDenormalizedData(
          goalScorerIds: details.goalScorerIds,
          goalScorerNames: details.goalScorerNames,
          mvpPlayerId: details.mvpPlayerId,
          mvpPlayerName: details.mvpPlayerName,
          venueName: details.venueName,
        ),
        session: GameSession(
          legacyTeamAScore: details.teamAScore,
          legacyTeamBScore: details.teamBScore,
        ),
      );

      final gameData = game.toJson();
      // Overwrite timestamps with server timestamp
      gameData['createdAt'] = now;
      gameData['updatedAt'] = now;
      // Game.toJson() already puts gameId in, but let's be safe as we generated it appropriately

      final gameRef = _firestore.collection(FirestorePaths.games()).doc(gameId);

      // Add gameId to gameData (required by firestore.rules)
      // gameData['gameId'] = gameId; // Already in toJson

      // Create signups for all participating players
      final batch = _firestore.batch();

      // Add game document
      batch.set(gameRef, gameData);

      // Add signups
      for (final playerId in details.playerIds) {
        final signupRef =
            _firestore.doc(FirestorePaths.gameSignup(gameId, playerId));
        batch.set(signupRef, {
          'playerId': playerId,
          'status': SignupStatus.confirmed.toFirestore(),
          'signedUpAt': now,
        });
      }

      // Commit all writes
      await batch.commit();

      // The onGameCompleted Cloud Function will be triggered automatically
      // when the game status is set to 'completed'
      debugPrint('✅ Past game logged: $gameId');
    } catch (e) {
      throw Exception('Failed to log past game: $e');
    }
  }

  /// Convert Event to Game - Core flow for logging games
  ///
  /// This is the main method for converting an Event (plan) to a Game (record).
  /// It reads the Event data, creates a Game document with status 'completed',
  /// and updates the Event to reference the new Game.
  ///
  /// The Cloud Function onGameCompleted will automatically update player stats.
  ///
  /// Parameters:
  /// - eventId: The event to convert
  /// - hubId: The hub ID (for Firestore path)
  /// - teamAScore: Score for team A
  /// - teamBScore: Score for team B
  /// - presentPlayerIds: List of player IDs who attended (defaults to all registered)
  /// - goalScorerIds: Optional list of player IDs who scored
  /// - mvpPlayerId: Optional MVP player ID
  ///
  /// Returns: The created Game ID
  Future<String> convertEventToGame({
    required String eventId,
    required String hubId,
    required int teamAScore,
    required int teamBScore,
    required List<String> presentPlayerIds,
    List<String>? goalScorerIds,
    String? mvpPlayerId,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Get event data
      final eventRef = _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId);

      final eventDoc = await eventRef.get();
      if (!eventDoc.exists) {
        throw Exception('Event not found: $eventId');
      }

      final eventData = eventDoc.data()!;
      final event = HubEvent.fromJson({...eventData, 'eventId': eventId});

      // Get teams from event (if they exist)
      final teams = event.teams.isNotEmpty
          ? event.teams
          : <Team>[]; // Teams may not exist if TeamMaker wasn't used

      // Create game document
      final now = FieldValue.serverTimestamp();
      final gameData = {
        'createdBy': event.createdBy,
        'hubId': hubId,
        'eventId': eventId, // Required reference to event
        'gameDate': Timestamp.fromDate(event.eventDate),
        'location': event.location,
        'locationPoint': event.locationPoint,
        'geohash': event.geohash,
        'status': GameStatus.completed.toFirestore(),
        'denormalized': {
          'venueName': event.location,
          'goalScorerIds': goalScorerIds ?? [],
          'mvpPlayerId': mvpPlayerId,
        },
        'session': {
          'legacyTeamAScore': teamAScore,
          'legacyTeamBScore': teamBScore,
        },
        'teamCount': event.teamCount,
        'teams': teams.map((team) => team.toJson()).toList(),
        'durationInMinutes': event.durationMinutes,
        'region': eventData['region'], // Copy from hub if available
        'showInCommunityFeed': event.showInCommunityFeed,
        'createdAt': now,
        'updatedAt': now,
        'photoUrls': <String>[],
        'isRecurring': false,
      };

      final gameRef = _firestore.collection(FirestorePaths.games()).doc();
      final gameId = gameRef.id;

      // Add gameId to gameData (required by firestore.rules)
      gameData['gameId'] = gameId;

      // Create batch for atomic operations
      final batch = _firestore.batch();

      // 1. Create game document
      batch.set(gameRef, gameData);

      // 2. Create signups for present players (status: confirmed)
      for (final playerId in presentPlayerIds) {
        final signupRef =
            _firestore.doc(FirestorePaths.gameSignup(gameId, playerId));
        batch.set(signupRef, {
          'playerId': playerId,
          'status': SignupStatus.confirmed.toFirestore(),
          'signedUpAt': now,
        });
      }

      // 3. Update event: mark as completed and reference the game
      batch.update(eventRef, {
        'status': 'completed',
        'gameId': gameId,
        'updatedAt': now,
      });

      // Commit all writes atomically
      await batch.commit();

      // Invalidate caches using centralized service
      _cacheInvalidation.onEventConvertedToGame(hubId, eventId, gameId);

      debugPrint('✅ Event converted to Game: $gameId (from event $eventId)');

      // The onGameCompleted Cloud Function will be triggered automatically
      // when the game status is set to 'completed'

      return gameId;
    } catch (e) {
      throw Exception('Failed to convert event to game: $e');
    }
  }

  /// Triggers the game finalization flow by setting an intermediate status
  /// and saving the result payload. A Cloud Function will then process the
  /// completion asynchronously.
  Future<void> finalizeGame(String gameId, GameResult result) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // 1. Only update the Game document
    await _firestore.doc(FirestorePaths.game(gameId)).update({
      'status': 'processing_completion', // Intermediate status
      'resultPayload': result.toJson(), // Store the raw input (scores, scorers)
      'finalizedBy': currentUser.uid,
      'finalizedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add a match result to a session (Game with multiple matches)
  ///
  /// OPTIMIZED VERSION - Split into two operations:
  /// 1. Transaction: Add match to game (critical, must be atomic)
  /// 2. Batch: Update player stats (eventual consistency OK)
  ///
  /// This prevents long transactions that can timeout or cause contention.
  Future<void> addMatchToSession(
    String gameId,
    MatchResult match,
    String currentUserId,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Step 1: Verify game exists and user has permission (outside transaction)
      final game = await getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions (outside transaction to reduce contention)
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: currentUserId);
        if (!hubPermissions.isManager && !hubPermissions.isModerator) {
          throw Exception(
              'Unauthorized: Only Hub Managers can add matches to sessions');
        }
      } else {
        // Public game - check if user is creator
        if (game.createdBy != currentUserId) {
          throw Exception(
              'Unauthorized: Only the game creator can add matches to public sessions');
        }
      }

      // Step 2: CRITICAL TRANSACTION - Update game only (fast, < 5 operations)
      await _firestore.runTransaction((transaction) async {
        final gameRef = _firestore.doc(FirestorePaths.game(gameId));
        final gameDoc = await transaction.get(gameRef);

        if (!gameDoc.exists) {
          throw Exception('Game not found');
        }

        // Parse game and calculate updates
        final gameData = gameDoc.data()!;
        final currentGame = Game.fromJson({...gameData, 'gameId': gameId});
        final currentMatches = currentGame.session.matches;

        // Add new match
        final updatedMatches = [...currentMatches, match];
        final matchesJson = updatedMatches.map((m) => m.toJson()).toList();

        // Calculate aggregate wins
        final Map<String, int> aggregateWins = Map<String, int>.from(
          currentGame.session.aggregateWins,
        );

        // Determine winner
        String? winnerColor;
        if (match.scoreA > match.scoreB) {
          winnerColor = match.teamAColor;
        } else if (match.scoreB > match.scoreA) {
          winnerColor = match.teamBColor;
        }

        // Update aggregate wins (only for approved matches)
        if (winnerColor != null &&
            match.approvalStatus == MatchApprovalStatus.approved) {
          aggregateWins[winnerColor] = (aggregateWins[winnerColor] ?? 0) + 1;
        }

        // Calculate next rotation state (if session is active)
        final Map<String, dynamic> updateData = {
          'session.matches': matchesJson,
          'session.aggregateWins': aggregateWins,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Update rotation state for active sessions with approved matches
        if (currentGame.session.isActive &&
            currentGame.session.currentRotation != null &&
            match.approvalStatus == MatchApprovalStatus.approved) {
          try {
            // Calculate next rotation
            // Note: For ties, managerSelectedStayingTeam should be set in the match
            // before calling addMatchToSession (handled by UI layer)
            final nextRotation = SessionRotationLogic.calculateNextRotation(
              current: currentGame.session.currentRotation!,
              completedMatch: match,
              // If tie and no winner selected yet, rotation will throw error
              // This is intentional - UI must handle tie selection first
            );

            updateData['session.currentRotation'] = nextRotation.toJson();
            debugPrint(
                '✅ Rotation updated: ${nextRotation.teamAColor} vs ${nextRotation.teamBColor}');
          } catch (e) {
            // If rotation calculation fails (e.g., tie without selection),
            // still save the match but log the error
            debugPrint('⚠️ Rotation not updated: $e');
            // For ties, UI will need to handle manager selection
            // and update rotation separately
          }
        }

        // Update game document (atomic)
        transaction.update(gameRef, updateData);
      });

      // Step 3: SEPARATE BATCH - Update player stats (eventual consistency OK)
      // This is outside the transaction to avoid long-running transactions
      await _updatePlayerStatsForMatch(match);

      // Step 4: Invalidate caches using centralized service
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint('✅ Match added to session: $gameId, match: ${match.matchId}');
    } catch (e) {
      debugPrint('❌ Failed to add match to session: $e');
      throw Exception('Failed to add match to session: $e');
    }
  }

  /// Helper method: Update player stats using batched writes (eventual consistency)
  ///
  /// This is separated from the critical transaction to avoid long-running transactions.
  /// If this fails, it can be retried independently without affecting the game state.
  Future<void> _updatePlayerStatsForMatch(MatchResult match) async {
    try {
      // Count goals and assists per player
      final Map<String, int> playerGoals = {};
      final Map<String, int> playerAssists = {};

      for (final scorerId in match.scorerIds) {
        playerGoals[scorerId] = (playerGoals[scorerId] ?? 0) + 1;
      }

      for (final assistId in match.assistIds) {
        playerAssists[assistId] = (playerAssists[assistId] ?? 0) + 1;
      }

      // Use batched writes for better performance
      final batch = _firestore.batch();

      // Update each player's stats
      for (final playerId in {...playerGoals.keys, ...playerAssists.keys}) {
        final userRef = _firestore.doc(FirestorePaths.user(playerId));

        final userUpdates = <String, dynamic>{};

        // Add goals count
        final goalsCount = playerGoals[playerId] ?? 0;
        if (goalsCount > 0) {
          userUpdates['goals'] = FieldValue.increment(goalsCount);
        }

        // Add assists count
        final assistsCount = playerAssists[playerId] ?? 0;
        if (assistsCount > 0) {
          userUpdates['assists'] = FieldValue.increment(assistsCount);
        }

        if (userUpdates.isNotEmpty) {
          batch.update(userRef, userUpdates);
        }
      }

      // Commit batch
      await batch.commit();

      debugPrint('✅ Player stats updated for match: ${match.matchId}');
    } catch (e) {
      // Log but don't throw - stats update failure shouldn't block the match
      debugPrint('⚠️ Failed to update player stats for match: $e');
    }
  }

  // =============================================================================
  // SESSION LIFECYCLE METHODS (Winner Stays Format)
  // =============================================================================

  /// Start a session (activates Winner Stays rotation)
  ///
  /// Sets isActive=true and initializes currentRotation state.
  /// Only hub managers or game creator can start sessions.
  Future<void> startSession(String gameId, String managerId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Verify game exists and user has permission
      final game = await getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: managerId);
        if (!hubPermissions.isManager) {
          throw Exception('Unauthorized: Only Hub Managers can start sessions');
        }
      } else {
        // Public game - check if user is creator
        if (game.createdBy != managerId) {
          throw Exception(
              'Unauthorized: Only the game creator can start public sessions');
        }
      }

      // Verify teams exist
      if (game.teams.length < 2) {
        throw Exception(
            'Need at least 2 teams to start a session. Create teams first.');
      }

      // Initialize rotation state using SessionRotationLogic
      final initialRotation =
          SessionRotationLogic.createInitialState(game.teams);

      // Update game document
      await _firestore.doc(FirestorePaths.game(gameId)).update({
        'session.isActive': true,
        'session.sessionStartedAt': FieldValue.serverTimestamp(),
        'session.sessionStartedBy': managerId,
        'session.currentRotation': initialRotation.toJson(),
        'status': 'inProgress', // Update game status
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate caches
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint('✅ Session started: $gameId by $managerId');
    } catch (e) {
      debugPrint('❌ Failed to start session: $e');
      throw Exception('Failed to start session: $e');
    }
  }

  /// End a session
  ///
  /// Sets isActive=false, marks sessionEndedAt.
  /// This will trigger backend processing to finalize stats.
  Future<void> endSession(String gameId, String managerId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Verify game exists and user has permission
      final game = await getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: managerId);
        if (!hubPermissions.isManager) {
          throw Exception('Unauthorized: Only Hub Managers can end sessions');
        }
      } else {
        // Public game - check if user is creator
        if (game.createdBy != managerId) {
          throw Exception(
              'Unauthorized: Only the game creator can end public sessions');
        }
      }

      // Update game document
      await _firestore.doc(FirestorePaths.game(gameId)).update({
        'session.isActive': false,
        'session.sessionEndedAt': FieldValue.serverTimestamp(),
        'session.sessionEndedBy': managerId,
        'status': 'statsInput', // Move to stats input phase
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate caches
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint('✅ Session ended: $gameId by $managerId');
    } catch (e) {
      debugPrint('❌ Failed to end session: $e');
      throw Exception('Failed to end session: $e');
    }
  }

  // =============================================================================
  // MODERATOR APPROVAL WORKFLOW METHODS
  // =============================================================================

  /// Submit a match result with optional moderator approval workflow
  ///
  /// If requiresApproval=true, match is marked as pending and awaits manager approval.
  /// If requiresApproval=false, match is immediately approved.
  Future<void> submitMatchResult(
    String gameId,
    MatchResult match, {
    required String submitterId,
    bool requiresApproval = false,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Set approval status based on workflow
      final matchToSubmit = requiresApproval
          ? match.copyWith(
              approvalStatus: MatchApprovalStatus.pending,
              loggedBy: submitterId,
            )
          : match.copyWith(
              approvalStatus: MatchApprovalStatus.approved,
              loggedBy: submitterId,
              approvedBy: submitterId,
              approvedAt: DateTime.now(),
            );

      // Use existing addMatchToSession logic
      await addMatchToSession(gameId, matchToSubmit, submitterId);

      debugPrint(
          '✅ Match submitted: ${match.matchId}, approval=${requiresApproval ? "pending" : "approved"}');
    } catch (e) {
      debugPrint('❌ Failed to submit match result: $e');
      throw Exception('Failed to submit match result: $e');
    }
  }

  /// Manager approves a pending match
  ///
  /// Updates approvalStatus from pending → approved.
  /// Only hub managers can approve matches.
  Future<void> approveMatch(
    String gameId,
    String matchId,
    String managerId,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Verify game exists and user has permission
      final game = await getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: managerId);
        if (!hubPermissions.isManager) {
          throw Exception(
              'Unauthorized: Only Hub Managers can approve matches');
        }
      } else {
        throw Exception('Only hub sessions support moderator approval');
      }

      // Find and update the match
      await _firestore.runTransaction((transaction) async {
        final gameRef = _firestore.doc(FirestorePaths.game(gameId));
        final gameDoc = await transaction.get(gameRef);

        if (!gameDoc.exists) {
          throw Exception('Game not found');
        }

        final currentGame =
            Game.fromJson({...gameDoc.data()!, 'gameId': gameId});
        final matches = List<MatchResult>.from(currentGame.session.matches);

        // Find the match to approve
        final matchIndex = matches.indexWhere((m) => m.matchId == matchId);
        if (matchIndex == -1) {
          throw Exception('Match not found: $matchId');
        }

        final match = matches[matchIndex];
        if (match.approvalStatus != MatchApprovalStatus.pending) {
          throw Exception('Match is not pending approval');
        }

        // Update match with approval
        matches[matchIndex] = match.copyWith(
          approvalStatus: MatchApprovalStatus.approved,
          approvedBy: managerId,
          approvedAt: DateTime.now(),
        );

        // Update game document
        final matchesJson = matches.map((m) => m.toJson()).toList();
        transaction.update(gameRef, {
          'session.matches': matchesJson,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Invalidate caches
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint('✅ Match approved: $matchId by $managerId');
    } catch (e) {
      debugPrint('❌ Failed to approve match: $e');
      throw Exception('Failed to approve match: $e');
    }
  }

  /// Manager rejects a pending match
  ///
  /// Updates approvalStatus from pending → rejected with reason.
  /// Only hub managers can reject matches.
  Future<void> rejectMatch(
    String gameId,
    String matchId,
    String managerId,
    String reason,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Verify game exists and user has permission
      final game = await getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: managerId);
        if (!hubPermissions.isManager) {
          throw Exception(
              'Unauthorized: Only Hub Managers can reject matches');
        }
      } else {
        throw Exception('Only hub sessions support moderator approval');
      }

      // Find and update the match
      await _firestore.runTransaction((transaction) async {
        final gameRef = _firestore.doc(FirestorePaths.game(gameId));
        final gameDoc = await transaction.get(gameRef);

        if (!gameDoc.exists) {
          throw Exception('Game not found');
        }

        final currentGame =
            Game.fromJson({...gameDoc.data()!, 'gameId': gameId});
        final matches = List<MatchResult>.from(currentGame.session.matches);

        // Find the match to reject
        final matchIndex = matches.indexWhere((m) => m.matchId == matchId);
        if (matchIndex == -1) {
          throw Exception('Match not found: $matchId');
        }

        final match = matches[matchIndex];
        if (match.approvalStatus != MatchApprovalStatus.pending) {
          throw Exception('Match is not pending approval');
        }

        // Update match with rejection
        matches[matchIndex] = match.copyWith(
          approvalStatus: MatchApprovalStatus.rejected,
          approvedBy: managerId,
          approvedAt: DateTime.now(),
          rejectionReason: reason,
        );

        // Update game document
        final matchesJson = matches.map((m) => m.toJson()).toList();
        transaction.update(gameRef, {
          'session.matches': matchesJson,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Invalidate caches
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint('✅ Match rejected: $matchId by $managerId');
    } catch (e) {
      debugPrint('❌ Failed to reject match: $e');
      throw Exception('Failed to reject match: $e');
    }
  }

  /// Stream pending matches awaiting approval
  ///
  /// Returns only matches with approvalStatus=pending
  Stream<List<MatchResult>> watchPendingMatches(String gameId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return watchGame(gameId).map((game) {
      if (game == null) return [];

      return game.session.matches
          .where((match) => match.approvalStatus == MatchApprovalStatus.pending)
          .toList();
    });
  }

  /// Update rotation state after a tie when manager selects staying team
  ///
  /// Used when a match ends in a tie and manager needs to manually
  /// select which team stays on field.
  Future<void> updateRotationAfterTie(
    String gameId,
    MatchResult tiedMatch,
    String stayingTeamColor,
    String managerId,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Verify game exists and user has permission
      final game = await getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: managerId);
        if (!hubPermissions.isManager) {
          throw Exception(
              'Unauthorized: Only Hub Managers can update rotation');
        }
      } else {
        // Public game - check if user is creator
        if (game.createdBy != managerId) {
          throw Exception(
              'Unauthorized: Only the game creator can update rotation');
        }
      }

      // Verify session is active and has rotation state
      if (!game.session.isActive || game.session.currentRotation == null) {
        throw Exception('Session is not active or has no rotation state');
      }

      // Calculate next rotation with manager's selection
      final nextRotation = SessionRotationLogic.calculateNextRotation(
        current: game.session.currentRotation!,
        completedMatch: tiedMatch,
        managerSelectedStayingTeam: stayingTeamColor,
      );

      // Update game document
      await _firestore.doc(FirestorePaths.game(gameId)).update({
        'session.currentRotation': nextRotation.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate caches
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint(
          '✅ Rotation updated after tie: ${nextRotation.teamAColor} vs ${nextRotation.teamBColor}');
    } catch (e) {
      debugPrint('❌ Failed to update rotation after tie: $e');
      throw Exception('Failed to update rotation after tie: $e');
    }
  }
}
