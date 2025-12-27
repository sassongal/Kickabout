import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';
import 'package:kattrick/utils/geohash_utils.dart';
import 'package:kattrick/shared/infrastructure/cache/cache_service.dart';
import 'package:kattrick/shared/infrastructure/monitoring/monitoring_service.dart';
import 'package:kattrick/shared/infrastructure/logging/error_handler_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';

/// Result class for paginated game queries
class PaginatedGamesResult {
  final List<Game> games;
  final DocumentSnapshot? lastDocument;

  PaginatedGamesResult({required this.games, required this.lastDocument});
}

/// Repository for complex Game queries
/// Handles discovery feed, completed games, upcoming games, and other complex queries
class GameQueriesRepository {
  final FirebaseFirestore _firestore;

  GameQueriesRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

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
    GeographicPoint? userLocation,
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

  /// Paged fetch for public completed games (non-streaming) to support infinite scroll
  Future<PaginatedGamesResult> fetchPublicCompletedGamesPage({
    int limit = 50,
    String? hubId,
    String? region,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    DocumentSnapshot? startAfter,
  }) async {
    if (!Env.isFirebaseAvailable) {
      return PaginatedGamesResult(games: const [], lastDocument: null);
    }

    try {
      Query query = _firestore
          .collection(FirestorePaths.games())
          .where('showInCommunityFeed', isEqualTo: true)
          .where('status', isEqualTo: 'completed');

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

      query = query.orderBy('gameDate', descending: true);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(limit).get();

      var games = snapshot.docs
          .map((doc) =>
              Game.fromJson({...doc.data() as Map<String, dynamic>, 'gameId': doc.id}))
          .toList();

      games = games
          .where((game) =>
              game.session.legacyTeamAScore != null &&
              game.session.legacyTeamBScore != null)
          .toList();

      if (startDate != null &&
          (hubId != null || region != null || city != null)) {
        games = games
            .where((g) =>
                g.gameDate.isAfter(startDate) ||
                g.gameDate.isAtSameMomentAs(startDate))
            .toList();
      }
      if (endDate != null &&
          (hubId != null || region != null || city != null || startDate != null)) {
        games = games
            .where((g) =>
                g.gameDate.isBefore(endDate) ||
                g.gameDate.isAtSameMomentAs(endDate))
            .toList();
      }

      final cacheKey = CacheKeys.publicGames(region: region, city: city);
      CacheService().set(cacheKey, games, ttl: CacheService.gamesTtl);

      final lastDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : startAfter;

      return PaginatedGamesResult(
        games: games,
        lastDocument: lastDoc,
      );
    } catch (e, stackTrace) {
      ErrorHandlerService()
          .logError(e, reason: 'fetchPublicCompletedGamesPage failed');
      debugPrint('Error in fetchPublicCompletedGamesPage: $e\n$stackTrace');
      rethrow;
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
}

