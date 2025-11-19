import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/log_past_game_details.dart';
import 'package:kickadoor/services/firestore_paths.dart';
import 'package:kickadoor/services/cache_service.dart';
import 'package:kickadoor/services/retry_service.dart';
import 'package:kickadoor/services/monitoring_service.dart';
import 'package:kickadoor/services/error_handler_service.dart';

/// Repository for Game operations
class GamesRepository {
  final FirebaseFirestore _firestore;

  GamesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
          
          // Invalidate cache
          CacheService().clear(CacheKeys.game(gameId));
          CacheService().clear(CacheKeys.gamesByHub(data['hubId'] as String? ?? ''));
          CacheService().clear(CacheKeys.publicGames());
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

  /// Stream all completed games (for main games screen)
  /// Shows games with scores from all hubs
  Stream<List<Game>> watchCompletedGames({int limit = 50}) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.games())
        .where('status', isEqualTo: 'completed')
        .orderBy('gameDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          // Filter games that have scores
          return snapshot.docs
              .map((doc) => Game.fromJson({...doc.data(), 'gameId': doc.id}))
              .where((game) => game.teamAScore != null && game.teamBScore != null)
              .toList();
        });
  }

  /// Stream all public completed games for community feed
  /// Shows games with showInCommunityFeed = true
  /// Note: We filter by showInCommunityFeed in query, then filter by status/scores in memory
  /// to allow newly created games to appear immediately
  Stream<List<Game>> watchPublicCompletedGames({
    int limit = 100,
    String? hubId,
    String? region,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    try {
      // Start with showInCommunityFeed filter (this is the main filter)
      Query query = _firestore
          .collection(FirestorePaths.games())
          .where('showInCommunityFeed', isEqualTo: true);

      // Apply additional filters (only one more where clause allowed with orderBy)
      // Priority: hubId > region > date filters
      if (hubId != null) {
        query = query.where('hubId', isEqualTo: hubId);
      } else if (region != null) {
        query = query.where('region', isEqualTo: region);
      }

      // Date filters will be applied in memory if both hubId and region are null
      // Otherwise, we'll filter in memory after fetching

      return query
          .orderBy('gameDate', descending: true)
          .limit(limit * 2) // Fetch more to account for in-memory filtering
          .snapshots()
          .map((snapshot) {
            return MonitoringService().trackSyncOperation<List<Game>>(
              'watchPublicCompletedGames',
              () {
                var games = snapshot.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Game.fromJson({...data, 'gameId': doc.id});
                    })
                    .toList();

                // Filter in memory:
                // 1. Only games with scores (completed games) OR status = completed
                games = games.where((game) => 
                    (game.teamAScore != null && game.teamBScore != null) ||
                    game.status == GameStatus.completed
                ).toList();

                // 2. Apply date filters in memory if not already in query
                if (startDate != null) {
                  games = games.where((g) => g.gameDate.isAfter(startDate) || g.gameDate.isAtSameMomentAs(startDate)).toList();
                }
                if (endDate != null) {
                  games = games.where((g) => g.gameDate.isBefore(endDate) || g.gameDate.isAtSameMomentAs(endDate)).toList();
                }
                if (region != null && hubId == null) {
                  games = games.where((g) => g.region == region).toList();
                }

                // Sort again after filtering
                games.sort((a, b) => b.gameDate.compareTo(a.gameDate));

                // Limit to requested amount
                games = games.take(limit).toList();
                
                // Cache the result
                final cacheKey = CacheKeys.publicGames(region: region);
                CacheService().set(cacheKey, games, ttl: CacheService.gamesTtl);
                
                return games;
              },
              metadata: {
                'count': snapshot.docs.length,
                'region': region,
                'hubId': hubId,
              },
            );
          });
    } catch (e) {
      debugPrint('Error in watchPublicCompletedGames: $e');
      ErrorHandlerService().logError(e, reason: 'watchPublicCompletedGames failed');
      return Stream.value([]);
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
  /// Returns games where:
  /// - Status is 'teamSelection' or 'teamsFormed' (pending/confirmed)
  /// - User is signed up (confirmed signup)
  /// - Game date is in the future
  Stream<List<Game>> streamMyUpcomingGames(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    try {
      // Get current time
      final now = DateTime.now();
      
      // Query games with status in ['teamSelection', 'teamsFormed']
      // Note: We can't directly query signups, so we'll:
      // 1. Get all games with pending/confirmed status
      // 2. Filter by checking signups in the app
      // OR use a composite index if needed
      
      // For now, we'll query games and filter by checking signups
      return _firestore
          .collection(FirestorePaths.games())
          .where('status', whereIn: ['teamSelection', 'teamsFormed'])
          .where('gameDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('gameDate', descending: false)
          .limit(20)
          .snapshots()
          .asyncMap((snapshot) async {
            final games = <Game>[];
            
            for (final doc in snapshot.docs) {
              try {
                final game = Game.fromJson({...doc.data(), 'gameId': doc.id});
                
                // Check if user is signed up for this game
                final signupsSnapshot = await _firestore
                    .collection(FirestorePaths.gameSignups(doc.id))
                    .doc(userId)
                    .get();
                
                if (signupsSnapshot.exists) {
                  final signupData = signupsSnapshot.data();
                  if (signupData != null) {
                    final status = signupData['status'] as String?;
                    if (status == 'confirmed') {
                      games.add(game);
                    }
                  }
                }
              } catch (e) {
                debugPrint('Error processing game ${doc.id}: $e');
                // Continue with other games
              }
            }
            
            return games;
          });
    } catch (e) {
      debugPrint('Error in streamMyUpcomingGames: $e');
      return Stream.value([]);
    }
  }

  /// Log a past game retroactively
  /// 
  /// Creates a Game document with status 'completed' immediately,
  /// along with signups for all participating players
  Future<void> logPastGame(LogPastGameDetails details, String currentUserId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {

      final now = FieldValue.serverTimestamp();
      
      // Create game document with denormalized data
      final gameData = {
        'createdBy': currentUserId,
        'hubId': details.hubId,
        'gameDate': Timestamp.fromDate(details.gameDate),
        'venueId': details.venueId,
        'eventId': details.eventId,
        'teamCount': 2,
        'status': GameStatus.completed.toFirestore(),
        'teamAScore': details.teamAScore,
        'teamBScore': details.teamBScore,
        'showInCommunityFeed': details.showInCommunityFeed,
        'goalScorerIds': details.goalScorerIds,
        'goalScorerNames': details.goalScorerNames,
        'mvpPlayerId': details.mvpPlayerId,
        'mvpPlayerName': details.mvpPlayerName,
        'venueName': details.venueName,
        'teams': details.teams.map((team) => team.toJson()).toList(),
        'createdAt': now,
        'updatedAt': now,
        'photoUrls': <String>[],
        'isRecurring': false,
      };

      final gameRef = _firestore.collection(FirestorePaths.games()).doc();
      final gameId = gameRef.id;

      // Create signups for all participating players
      final batch = _firestore.batch();
      
      // Add game document
      batch.set(gameRef, gameData);
      
      // Add signups
      for (final playerId in details.playerIds) {
        final signupRef = _firestore.doc(FirestorePaths.gameSignup(gameId, playerId));
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
}

