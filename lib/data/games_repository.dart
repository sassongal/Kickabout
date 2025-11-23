import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/log_past_game_details.dart';
import 'package:kickadoor/models/hub_role.dart';
import 'package:kickadoor/services/firestore_paths.dart';
import 'package:kickadoor/services/cache_service.dart';
import 'package:kickadoor/services/retry_service.dart';
import 'package:kickadoor/services/monitoring_service.dart';
import 'package:kickadoor/services/error_handler_service.dart';
import 'package:kickadoor/data/hubs_repository.dart';
import 'package:kickadoor/data/users_repository.dart';
import 'package:kickadoor/data/signups_repository.dart';
import 'package:kickadoor/data/chat_repository.dart';

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
      
      // Invalidate cache
      CacheService().clear(CacheKeys.game(docRef.id));
      if (game.hubId.isNotEmpty) {
        CacheService().clear(CacheKeys.gamesByHub(game.hubId));
      }
      
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
      // Get game to know hubId for cache invalidation
      final gameDoc = await _firestore.doc(FirestorePaths.game(gameId)).get();
      final hubId = gameDoc.data()?['hubId'] as String?;
      
      await _firestore.doc(FirestorePaths.game(gameId)).delete();
      
      // Invalidate cache
      CacheService().clear(CacheKeys.game(gameId));
      if (hubId != null && hubId.isNotEmpty) {
        CacheService().clear(CacheKeys.gamesByHub(hubId));
      }
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
        .where('showInCommunityFeed', isEqualTo: true) // Filter in Firestore, not memory
        .orderBy('gameDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          // Only filter scores in memory (Firestore can't filter on null/not null easily)
          return snapshot.docs
              .map((doc) => Game.fromJson({...doc.data(), 'gameId': doc.id}))
              .where((game) => game.teamAScore != null && game.teamBScore != null)
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
          .where('status', isEqualTo: 'completed'); // Filter in Firestore, not memory

      // Apply additional filters
      if (hubId != null) {
        query = query.where('hubId', isEqualTo: hubId);
      } else if (region != null) {
        query = query.where('region', isEqualTo: region);
      }

      // Date filters - apply in Firestore if possible
      if (startDate != null && hubId == null && region == null) {
        query = query.where('gameDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null && hubId == null && region == null && startDate == null) {
        query = query.where('gameDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Pagination support
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      return query
          .orderBy('gameDate', descending: true)
          .limit(limit) // No need for limit * 2 - filtering is done in Firestore
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

                // Only filter scores in memory (Firestore can't filter on null/not null easily)
                // But most completed games should have scores anyway
                games = games.where((game) => 
                    game.teamAScore != null && game.teamBScore != null
                ).toList();

                // Apply date filters in memory only if they couldn't be applied in query
                if (startDate != null && (hubId != null || region != null)) {
                  games = games.where((g) => g.gameDate.isAfter(startDate) || g.gameDate.isAtSameMomentAs(startDate)).toList();
                }
                if (endDate != null && (hubId != null || region != null || startDate != null)) {
                  games = games.where((g) => g.gameDate.isBefore(endDate) || g.gameDate.isAtSameMomentAs(endDate)).toList();
                }

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
  /// Stream upcoming games for a specific user
  /// Optimized: Uses collection group query to avoid N+1 queries
  /// - User is signed up (confirmed status)
  /// - Game status is 'teamSelection' or 'teamsFormed'
  /// - Game date is in the future
  Stream<List<Game>> streamMyUpcomingGames(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    try {
      final now = DateTime.now();
      
      // OPTIMIZED: Use collection group query to get all signups for this user
      // This avoids N+1 queries (one per game)
      return _firestore
          .collectionGroup('signups')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'confirmed')
          .snapshots()
          .asyncMap((signupsSnapshot) async {
            if (signupsSnapshot.docs.isEmpty) return <Game>[];
            
            // Extract game IDs from signup document paths
            // Path format: games/{gameId}/signups/{userId}
            final gameIds = signupsSnapshot.docs
                .map((doc) {
                  final pathParts = doc.reference.path.split('/');
                  // Path: games/{gameId}/signups/{userId}
                  if (pathParts.length >= 2 && pathParts[0] == 'games') {
                    return pathParts[1];
                  }
                  return null;
                })
                .whereType<String>()
                .toSet();
            
            if (gameIds.isEmpty) return <Game>[];
            
            // Batch query games - Firestore 'in' limit is 10
            final games = <Game>[];
            final gameIdList = gameIds.toList();
            
            for (var i = 0; i < gameIdList.length; i += 10) {
              final batch = gameIdList.skip(i).take(10).toList();
              
              try {
                final gamesSnapshot = await _firestore
                    .collection(FirestorePaths.games())
                    .where(FieldPath.documentId, whereIn: batch)
                    .where('status', whereIn: ['teamSelection', 'teamsFormed'])
                    .where('gameDate', isGreaterThan: Timestamp.fromDate(now))
                    .get();
                
                games.addAll(
                  gamesSnapshot.docs.map((doc) => 
                      Game.fromJson({...doc.data(), 'gameId': doc.id})),
                );
              } catch (e) {
                debugPrint('Error fetching games batch: $e');
                // Continue with next batch
              }
            }
            
            // Sort by game date
            games.sort((a, b) => a.gameDate.compareTo(b.gameDate));
            
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

      // Add gameId to gameData (required by firestore.rules)
      gameData['gameId'] = gameId;

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
        'teamCount': event.teamCount,
        'status': GameStatus.completed.toFirestore(),
        'teamAScore': teamAScore,
        'teamBScore': teamBScore,
        'teams': teams.map((team) => team.toJson()).toList(),
        'durationInMinutes': event.durationMinutes,
        'region': eventData['region'], // Copy from hub if available
        'showInCommunityFeed': event.showInCommunityFeed,
        'goalScorerIds': goalScorerIds ?? [],
        'mvpPlayerId': mvpPlayerId,
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
        final signupRef = _firestore.doc(FirestorePaths.gameSignup(gameId, playerId));
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

      // Invalidate caches
      CacheService().clear(CacheKeys.game(gameId));
      CacheService().clear(CacheKeys.gamesByHub(hubId));
      CacheService().clear(CacheKeys.eventsByHub(hubId));
      CacheService().clear(CacheKeys.event(hubId, eventId));

      debugPrint('✅ Event converted to Game: $gameId (from event $eventId)');
      
      // The onGameCompleted Cloud Function will be triggered automatically
      // when the game status is set to 'completed'
      
      return gameId;
    } catch (e) {
      throw Exception('Failed to convert event to game: $e');
    }
  }

  /// Finalize game - Manager-only operation with atomic transaction
  /// 
  /// This method:
  /// 1. Verifies the current user is a Hub Manager/Admin
  /// 2. Uses Firestore Transaction for atomic updates
  /// 3. Updates game status, scores, and player stats
  /// 4. Does NOT update player rank scores (rank is manual only via managerRatings)
  /// 
  /// Parameters:
  /// - gameId: The game to finalize
  /// - teamAScore: Score for team A
  /// - teamBScore: Score for team B
  /// - goalScorerIds: Map of playerId -> number of goals
  /// - assistPlayerIds: Map of playerId -> number of assists (optional)
  /// - mvpPlayerId: Optional MVP player ID
  /// 
  /// Throws: Exception if user is not a manager or if transaction fails
  Future<void> finalizeGame({
    required String gameId,
    required int teamAScore,
    required int teamBScore,
    required Map<String, int> goalScorerIds, // playerId -> goals count
    Map<String, int>? assistPlayerIds, // playerId -> assists count
    String? mvpPlayerId,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Step 1: Permission Check - Verify user is Hub Manager/Admin
      final auth = FirebaseAuth.instance;
      final currentUserId = auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get game to check hubId
      final game = await getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Get hub to verify permissions
      final hubsRepo = HubsRepository();
      final hub = await hubsRepo.getHub(game.hubId);
      if (hub == null) {
        throw Exception('Hub not found: ${game.hubId}');
      }

      // Check if user is manager/admin
      final hubPermissions = HubPermissions(hub: hub, userId: currentUserId);
      if (!hubPermissions.isManager() && !hubPermissions.isModerator()) {
        throw Exception('Unauthorized: Only Hub Managers can finalize games');
      }

      // Step 2: Get signups for the game (before transaction)
      final signupsRepo = SignupsRepository();
      final allSignups = await signupsRepo.getSignups(gameId);
      final confirmedSignups = allSignups.where((s) => s.status == SignupStatus.confirmed).toList();

      // Step 3: Determine winning team
      final winningTeamId = teamAScore > teamBScore 
          ? (game.teams.isNotEmpty ? game.teams[0].teamId : 'teamA')
          : (teamAScore < teamBScore 
              ? (game.teams.length > 1 ? game.teams[1].teamId : 'teamB')
              : null); // Draw

      // Step 4: Atomic Transaction
      await _firestore.runTransaction((transaction) async {
        // Read game document
        final gameRef = _firestore.doc(FirestorePaths.game(gameId));
        final gameDoc = await transaction.get(gameRef);
        
        if (!gameDoc.exists) {
          throw Exception('Game not found');
        }

        final gameData = gameDoc.data()!;
        final gameHubId = gameData['hubId'] as String;

        // Verify hub still exists and user is still manager
        final hubRef = _firestore.doc(FirestorePaths.hub(gameHubId));
        final hubDoc = await transaction.get(hubRef);
        
        if (!hubDoc.exists) {
          throw Exception('Hub not found');
        }

        final hubData = hubDoc.data()!;
        final isManager = hubData['createdBy'] == currentUserId ||
                         (hubData['roles'] as Map?)?[currentUserId] == 'manager' ||
                         (hubData['roles'] as Map?)?[currentUserId] == 'admin' ||
                         (hubData['roles'] as Map?)?[currentUserId] == 'moderator';
        
        if (!isManager) {
          throw Exception('Unauthorized: Only Hub Managers can finalize games');
        }

        // Update game document
        final gameUpdates = <String, dynamic>{
          'status': GameStatus.completed.toFirestore(),
          'teamAScore': teamAScore,
          'teamBScore': teamBScore,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add goal scorer IDs (names will be fetched outside transaction)
        if (goalScorerIds.isNotEmpty) {
          gameUpdates['goalScorerIds'] = goalScorerIds.keys.toList();
        }

        // Add MVP
        if (mvpPlayerId != null && mvpPlayerId.isNotEmpty) {
          gameUpdates['mvpPlayerId'] = mvpPlayerId;
        }

        transaction.update(gameRef, gameUpdates);

        // Step 5: Update player stats within transaction
        // Parse teams from gameData (they're stored as List<Map>)
        final teamsData = gameData['teams'] as List? ?? [];
        final teams = teamsData.map((t) => Team.fromJson(t as Map<String, dynamic>)).toList();

        for (final signup in confirmedSignups) {
          final playerId = signup.playerId;
          final userRef = _firestore.doc(FirestorePaths.user(playerId));
          
          // Determine which team the player was on
          final playerTeamId = teams.isNotEmpty
              ? teams.firstWhere(
                  (team) => team.playerIds.contains(playerId),
                  orElse: () => teams[0],
                ).teamId
              : 'teamA';

          final isWinner = winningTeamId != null && playerTeamId == winningTeamId;

          // Prepare user updates
          final userUpdates = <String, dynamic>{
            'gamesPlayed': FieldValue.increment(1),
          };

          if (isWinner) {
            userUpdates['wins'] = FieldValue.increment(1);
          }

          // Add goals count
          final playerGoals = goalScorerIds[playerId] ?? 0;
          if (playerGoals > 0) {
            userUpdates['goals'] = FieldValue.increment(playerGoals);
          }

          // Add assists count
          final playerAssists = assistPlayerIds?[playerId] ?? 0;
          if (playerAssists > 0) {
            userUpdates['assists'] = FieldValue.increment(playerAssists);
          }

          transaction.update(userRef, userUpdates);
        }
      });

      // Step 6: Fetch user names for denormalized fields (outside transaction)
      final usersRepo = UsersRepository();
      if (goalScorerIds.isNotEmpty) {
        final goalScorerNames = <String>[];
        for (final playerId in goalScorerIds.keys) {
          try {
            final user = await usersRepo.getUser(playerId);
            if (user != null) {
              final goalsCount = goalScorerIds[playerId] ?? 1;
              if (goalsCount > 1) {
                goalScorerNames.add('${user.name} ($goalsCount)');
              } else {
                goalScorerNames.add(user.name);
              }
            }
          } catch (e) {
            debugPrint('Failed to get user name for $playerId: $e');
          }
        }
        if (goalScorerNames.isNotEmpty) {
          await updateGame(gameId, {'goalScorerNames': goalScorerNames});
        }
      }

      // Add MVP name
      if (mvpPlayerId != null && mvpPlayerId.isNotEmpty) {
        try {
          final mvpUser = await usersRepo.getUser(mvpPlayerId);
          if (mvpUser != null) {
            await updateGame(gameId, {'mvpPlayerName': mvpUser.name});
          }
        } catch (e) {
          debugPrint('Failed to get MVP user name: $e');
        }
      }

      // Invalidate caches
      CacheService().clear(CacheKeys.game(gameId));
      CacheService().clear(CacheKeys.gamesByHub(game.hubId));

      // Step 7: Send automated chat announcement
      try {
        final chatRepo = ChatRepository();
        final mvpName = mvpPlayerId != null 
            ? (await usersRepo.getUser(mvpPlayerId))?.name 
            : null;
        
        final message = StringBuffer();
        message.writeln('Game Finished! 🏁');
        message.writeln('Score: $teamAScore vs $teamBScore');
        if (mvpName != null) {
          message.writeln('MVP: $mvpName 🏆');
        }
        
        // Use current user as author (manager who finalized the game)
        await chatRepo.sendMessage(game.hubId, currentUserId, message.toString());
      } catch (e) {
        // Don't fail game finalization if chat message fails
        debugPrint('⚠️ Failed to send chat announcement: $e');
      }

      debugPrint('✅ Game finalized: $gameId');
    } catch (e) {
      debugPrint('❌ Failed to finalize game: $e');
      throw Exception('Failed to finalize game: $e');
    }
  }

}

