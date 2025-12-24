import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/services/cache_service.dart';
import 'package:kattrick/services/retry_service.dart';
import 'package:kattrick/services/monitoring_service.dart';
import 'package:kattrick/logic/team_maker.dart';
import 'package:kattrick/logic/live_match_permissions.dart';

/// Repository for managing Hub events
class HubEventsRepository {
  final FirebaseFirestore _firestore;

  HubEventsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream all events for a hub
  Stream<List<HubEvent>> watchHubEvents(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.hubs())
        .doc(hubId)
        .collection('events')
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                // Ensure hubId is present (it might be missing in subcollection documents)
                if (!data.containsKey('hubId')) {
                  data['hubId'] = hubId;
                }
                // Ensure array fields have default values for old documents
                // Handle null values explicitly - freezed expects non-null for default values
                if (data['registeredPlayerIds'] == null) {
                  data['registeredPlayerIds'] = [];
                }
                if (data['waitingListPlayerIds'] == null) {
                  data['waitingListPlayerIds'] = [];
                }
                if (data['teams'] == null) {
                  data['teams'] = [];
                } else if (data['teams'] is! List) {
                  // Handle case where teams might be stored as something else
                  data['teams'] = [];
                }
                if (data['matches'] == null) {
                  data['matches'] = [];
                } else if (data['matches'] is! List) {
                  data['matches'] = [];
                }
                if (data['aggregateWins'] == null) {
                  data['aggregateWins'] = <String, int>{};
                } else if (data['aggregateWins'] is! Map) {
                  // Handle case where aggregateWins might be stored as something else
                  data['aggregateWins'] = <String, int>{};
                }

                return HubEvent.fromJson({...data, 'eventId': doc.id});
              } catch (e) {
                debugPrint('Error parsing HubEvent ${doc.id}: $e');
                return null;
              }
            })
            .whereType<HubEvent>()
            .toList());
  }

  /// Get all events for a hub (non-streaming) with caching and retry
  Future<List<HubEvent>> getHubEvents(String hubId,
      {bool forceRefresh = false}) async {
    if (!Env.isFirebaseAvailable) return [];

    return MonitoringService().trackOperation(
      'getHubEvents',
      () => CacheService().getOrFetch<List<HubEvent>>(
        CacheKeys.eventsByHub(hubId),
        () => RetryService().execute(
          () async {
            final snapshot = await _firestore
                .collection(FirestorePaths.hubs())
                .doc(hubId)
                .collection('events')
                .orderBy('eventDate', descending: false)
                .get();

            return snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    if (!data.containsKey('hubId')) {
                      data['hubId'] = hubId;
                    }
                    // Ensure array fields have default values for old documents
                    if (data['registeredPlayerIds'] == null) {
                      data['registeredPlayerIds'] = [];
                    }
                    if (data['waitingListPlayerIds'] == null) {
                      data['waitingListPlayerIds'] = [];
                    }
                    if (data['teams'] == null) {
                      data['teams'] = [];
                    } else if (data['teams'] is! List) {
                      data['teams'] = [];
                    }
                    if (data['matches'] == null) {
                      data['matches'] = [];
                    } else if (data['matches'] is! List) {
                      data['matches'] = [];
                    }
                    if (data['aggregateWins'] == null) {
                      data['aggregateWins'] = <String, int>{};
                    } else if (data['aggregateWins'] is! Map) {
                      data['aggregateWins'] = <String, int>{};
                    }
                    return HubEvent.fromJson({...data, 'eventId': doc.id});
                  } catch (e) {
                    debugPrint('Error parsing HubEvent ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<HubEvent>()
                .toList();
          },
          config: RetryConfig.network,
          operationName: 'getHubEvents',
        ),
        ttl: CacheService.eventsTtl,
        forceRefresh: forceRefresh,
      ),
      metadata: {'hubId': hubId},
    );
  }

  /// Create a new hub event
  Future<String> createHubEvent(HubEvent event) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final data = event.toJson();

      // Generate document ID if not provided
      final eventId = event.eventId.isNotEmpty
          ? event.eventId
          : _firestore
              .collection(FirestorePaths.hubs())
              .doc(event.hubId)
              .collection('events')
              .doc()
              .id;

      // Keep eventId in data (required by Firestore rules)
      data['eventId'] = eventId;

      // Create document with specific ID
      await _firestore
          .collection(FirestorePaths.hubs())
          .doc(event.hubId)
          .collection('events')
          .doc(eventId)
          .set(data);

      // Invalidate cache
      CacheService().clear(CacheKeys.eventsByHub(event.hubId));
      CacheService().clear(CacheKeys.event(event.hubId, eventId));

      return eventId;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  /// Get a single hub event by ID with caching and retry
  Future<HubEvent?> getHubEvent(String hubId, String eventId,
      {bool forceRefresh = false}) async {
    if (!Env.isFirebaseAvailable) {
      return null;
    }

    return MonitoringService().trackOperation(
      'getHubEvent',
      () => CacheService().getOrFetch<HubEvent?>(
        CacheKeys.event(hubId, eventId),
        () => RetryService().execute(
          () async {
            final doc = await _firestore
                .collection(FirestorePaths.hubs())
                .doc(hubId)
                .collection('events')
                .doc(eventId)
                .get();

            if (!doc.exists) {
              return null;
            }

            final data = doc.data()!;
            // Ensure array fields have default values for old documents
            if (data['registeredPlayerIds'] == null) {
              data['registeredPlayerIds'] = [];
            }
            if (data['waitingListPlayerIds'] == null) {
              data['waitingListPlayerIds'] = [];
            }
            if (data['teams'] == null) {
              data['teams'] = [];
            } else if (data['teams'] is! List) {
              data['teams'] = [];
            }
            if (data['matches'] == null) {
              data['matches'] = [];
            } else if (data['matches'] is! List) {
              data['matches'] = [];
            }
            if (data['aggregateWins'] == null) {
              data['aggregateWins'] = <String, int>{};
            } else if (data['aggregateWins'] is! Map) {
              data['aggregateWins'] = <String, int>{};
            }

            return HubEvent.fromJson({...data, 'eventId': doc.id});
          },
          config: RetryConfig.network,
          operationName: 'getHubEvent',
        ),
        ttl: CacheService.eventsTtl, // 15 minutes
        forceRefresh: forceRefresh,
      ),
      metadata: {'hubId': hubId, 'eventId': eventId},
    );
  }

  /// Stream a single hub event
  Stream<HubEvent?> watchHubEvent(String hubId, String eventId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .collection(FirestorePaths.hubs())
        .doc(hubId)
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      
      // Ensure array fields have default values for old documents
      if (data['registeredPlayerIds'] == null) {
        data['registeredPlayerIds'] = [];
      }
      if (data['waitingListPlayerIds'] == null) {
        data['waitingListPlayerIds'] = [];
      }
      if (data['teams'] == null) {
        data['teams'] = [];
      } else if (data['teams'] is! List) {
        data['teams'] = [];
      }
      if (data['matches'] == null) {
        data['matches'] = [];
      } else if (data['matches'] is! List) {
        data['matches'] = [];
      }
      if (data['aggregateWins'] == null) {
        data['aggregateWins'] = <String, int>{};
      } else if (data['aggregateWins'] is! Map) {
        data['aggregateWins'] = <String, int>{};
      }
      
      return HubEvent.fromJson({...data, 'eventId': doc.id});
    });
  }

  /// Save teams for an event (for TeamMaker)
  Future<void> saveTeamsForEvent(
      String hubId, String eventId, List<Team> teams) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final eventRef = _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId);

      // Convert teams to JSON
      final teamsJson = teams.map((team) => team.toJson()).toList();

      // Update event with teams
      await eventRef.update({
        'teams': teamsJson,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache
      CacheService().clear(CacheKeys.event(hubId, eventId));
      CacheService().clear(CacheKeys.eventsByHub(hubId));
    } catch (e) {
      throw Exception('Failed to save teams for event: $e');
    }
  }

  /// Save teams and start event (atomic operation)
  /// Validates teams before starting
  Future<void> saveTeamsAndStartEvent(
    String hubId,
    String eventId,
    List<Team> teams,
    int teamCount,
    int minPlayersPerTeam,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    // Validate teams before starting
    final validationErrors = TeamMaker.validateTeamsForGameStart(
      teams,
      teamCount,
      minPlayersPerTeam,
    );

    if (validationErrors.isNotEmpty) {
      throw Exception(validationErrors.join('\n'));
    }

    try {
      final eventRef = _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId);

      // Convert teams to JSON
      final teamsJson = teams.map((team) => team.toJson()).toList();

      // Update event with teams and start it
      await eventRef.update({
        'teams': teamsJson,
        'isStarted': true,
        'status': 'ongoing',
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache
      CacheService().clear(CacheKeys.event(hubId, eventId));
      CacheService().clear(CacheKeys.eventsByHub(hubId));
    } catch (e) {
      throw Exception('Failed to save teams and start event: $e');
    }
  }

  /// Update a hub event
  Future<void> updateHubEvent(
      String hubId, String eventId, Map<String, dynamic> updates) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Convert DateTime to Timestamp if present
      final convertedUpdates = <String, dynamic>{};
      for (final entry in updates.entries) {
        if (entry.value is DateTime) {
          convertedUpdates[entry.key] =
              Timestamp.fromDate(entry.value as DateTime);
        } else {
          convertedUpdates[entry.key] = entry.value;
        }
      }

      await _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId)
          .update({
        ...convertedUpdates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache
      CacheService().clear(CacheKeys.eventsByHub(hubId));
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  /// Delete a hub event
  Future<void> deleteHubEvent(String hubId, String eventId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId)
          .delete();

      // Invalidate cache
      CacheService().clear(CacheKeys.eventsByHub(hubId));
      CacheService().clear(CacheKeys.event(hubId, eventId));
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  /// Alias for backward compatibility
  Future<void> updateEvent(
      String hubId, String eventId, Map<String, dynamic> updates) async {
    return updateHubEvent(hubId, eventId, updates);
  }

  /// Alias for backward compatibility
  Future<void> deleteEvent(String hubId, String eventId) async {
    return deleteHubEvent(hubId, eventId);
  }

  /// Register a player to an event
  /// Returns positive int (registration number) if registered
  /// Returns negative int (waiting list position) if added to waiting list
  Future<int> registerToEvent(
      String hubId, String eventId, String playerId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final eventRef = _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId);

      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(eventRef);
        if (!snapshot.exists) {
          throw Exception('Event not found');
        }

        final data = snapshot.data()!;
        final registered = List<String>.from(data['registeredPlayerIds'] ?? []);
        final waiting = List<String>.from(data['waitingListPlayerIds'] ?? []);
        final maxParticipants = data['maxParticipants'] as int? ?? 15;

        if (registered.contains(playerId)) {
          throw Exception('Already registered to this event');
        }
        if (waiting.contains(playerId)) {
          throw Exception('Already on waiting list');
        }

        if (registered.length < maxParticipants) {
          // Register
          transaction.update(eventRef, {
            'registeredPlayerIds': FieldValue.arrayUnion([playerId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return registered.length + 1;
        } else {
          // Add to waiting list
          transaction.update(eventRef, {
            'waitingListPlayerIds': FieldValue.arrayUnion([playerId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return -(waiting.length + 1);
        }
      });
    } catch (e) {
      throw Exception('Failed to register to event: $e');
    }
  }

  /// Unregister a player from an event
  Future<void> unregisterFromEvent(
      String hubId, String eventId, String playerId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // 🔒 LIVE EVENT LOCK: Check if event is already started
      final eventDoc = await _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId)
          .get();

      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data();
      final isStarted = eventData?['isStarted'] as bool? ?? false;

      if (isStarted) {
        throw Exception(
            'לא ניתן לבטל הרשמה למשחק שכבר התחיל. הקבוצות נקבעו והמשחק בתהליך.');
      }

      await _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId)
          .update({
        'registeredPlayerIds': FieldValue.arrayRemove([playerId]),
        'waitingListPlayerIds': FieldValue.arrayRemove([playerId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache for this event
      CacheService().clear(CacheKeys.event(hubId, eventId));
      CacheService().clear(CacheKeys.eventsByHub(hubId));
    } catch (e) {
      throw Exception('Failed to unregister from event: $e');
    }
  }

  /// Promote a player from waiting list to registered list
  Future<void> promoteFromWaitingList(
      String hubId, String eventId, String playerId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId)
          .update({
        'waitingListPlayerIds': FieldValue.arrayRemove([playerId]),
        'registeredPlayerIds': FieldValue.arrayUnion([playerId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache for this event
      CacheService().clear(CacheKeys.event(hubId, eventId));
      CacheService().clear(CacheKeys.eventsByHub(hubId));
    } catch (e) {
      throw Exception('Failed to promote player: $e');
    }
  }

  /// Stream all public events for community feed
  /// Uses collection group query to get events from all hubs
  /// Note: We filter by showInCommunityFeed in query, then filter by status in memory
  /// to allow newly created events to appear immediately
  Stream<List<HubEvent>> watchPublicEvents({
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
      // OPTIMIZED: Use collection group query with composite index
      // Filter by showInCommunityFeed AND status in Firestore (requires index)
      Query query = _firestore
          .collectionGroup('events')
          .where('showInCommunityFeed', isEqualTo: true)
          .where('status',
              whereIn: ['upcoming', 'ongoing']); // Filter in Firestore

      // Apply additional filters if possible
      if (hubId != null) {
        // For collection group, we'll filter hubId in memory (can't add more where clauses)
        // Alternative: Create a separate publicEvents collection
      }

      return query
          .orderBy('eventDate', descending: false)
          .limit(
              limit) // No need for limit * 2 - filtering is done in Firestore
          .snapshots()
          .map((snapshot) {
        var events = snapshot.docs
            .map((doc) {
              try {
                // Get hubId from document path: hubs/{hubId}/events/{eventId}
                final pathParts = doc.reference.path.split('/');
                final hubIdFromPath =
                    pathParts.length >= 2 ? pathParts[1] : null;

                final docData = doc.data() as Map<String, dynamic>?;
                if (docData == null) return null;

                return HubEvent.fromJson({
                  ...docData,
                  'eventId': doc.id,
                  'hubId': hubIdFromPath ?? '',
                });
              } catch (e) {
                debugPrint('Error parsing event: $e');
                return null;
              }
            })
            .whereType<HubEvent>()
            .toList();

        // Apply filters that can't be done in Firestore (collection group limitations)
        if (hubId != null) {
          events = events.where((e) => e.hubId == hubId).toList();
        }

        if (startDate != null) {
          events = events
              .where((e) =>
                  e.eventDate.isAfter(startDate) ||
                  e.eventDate.isAtSameMomentAs(startDate))
              .toList();
        }

        if (endDate != null) {
          events = events
              .where((e) =>
                  e.eventDate.isBefore(endDate) ||
                  e.eventDate.isAtSameMomentAs(endDate))
              .toList();
        }

        // Sort again after filtering (should already be sorted, but ensure)
        events.sort((a, b) => a.eventDate.compareTo(b.eventDate));

        return events;
      });
    } catch (e) {
      debugPrint('Error in watchPublicEvents: $e');
      return Stream.value([]);
    }
  }

  /// Save live match state (stopwatch, scores, teams)
  /// This persists the current state so it can be restored after app restart
  Future<void> saveLiveState({
    required String hubId,
    required String eventId,
    required DateTime? startTimestamp,
    required bool isRunning,
    required int elapsedOffsetSeconds,
    required int scoreA,
    required int scoreB,
    required String? selectedTeamAId,
    required String? selectedTeamBId,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final liveStateRef = _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId)
          .collection('liveState')
          .doc('current');

      await liveStateRef.set({
        'startTimestamp': startTimestamp != null
            ? Timestamp.fromDate(startTimestamp)
            : null,
        'isRunning': isRunning,
        'elapsedOffsetSeconds': elapsedOffsetSeconds,
        'scoreA': scoreA,
        'scoreB': scoreB,
        'selectedTeamAId': selectedTeamAId,
        'selectedTeamBId': selectedTeamBId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save live state: $e');
    }
  }

  /// Get live match state
  Future<Map<String, dynamic>?> getLiveState(
      String hubId, String eventId) async {
    if (!Env.isFirebaseAvailable) {
      return null;
    }

    try {
      final liveStateDoc = await _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId)
          .collection('liveState')
          .doc('current')
          .get();

      if (!liveStateDoc.exists) {
        return null;
      }

      final data = liveStateDoc.data()!;
      return {
        'startTimestamp': data['startTimestamp'] as Timestamp?,
        'isRunning': data['isRunning'] as bool? ?? false,
        'elapsedOffsetSeconds': data['elapsedOffsetSeconds'] as int? ?? 0,
        'scoreA': data['scoreA'] as int? ?? 0,
        'scoreB': data['scoreB'] as int? ?? 0,
        'selectedTeamAId': data['selectedTeamAId'] as String?,
        'selectedTeamBId': data['selectedTeamBId'] as String?,
      };
    } catch (e) {
      debugPrint('Error getting live state: $e');
      return null;
    }
  }

  /// Stream live match state for real-time updates
  Stream<Map<String, dynamic>?> watchLiveState(
      String hubId, String eventId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .collection(FirestorePaths.hubs())
        .doc(hubId)
        .collection('events')
        .doc(eventId)
        .collection('liveState')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data()!;
      return {
        'startTimestamp': data['startTimestamp'] as Timestamp?,
        'isRunning': data['isRunning'] as bool? ?? false,
        'elapsedOffsetSeconds': data['elapsedOffsetSeconds'] as int? ?? 0,
        'scoreA': data['scoreA'] as int? ?? 0,
        'scoreB': data['scoreB'] as int? ?? 0,
        'selectedTeamAId': data['selectedTeamAId'] as String?,
        'selectedTeamBId': data['selectedTeamBId'] as String?,
      };
    });
  }

  /// Save match result with transaction to prevent race conditions
  /// Also enforces permissions before saving
  Future<void> saveMatchResult({
    required String hubId,
    required String eventId,
    required MatchResult matchResult,
    required String userId,
    required Hub hub,
    required HubEvent event,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    // Permission check - enforce in repository
    if (!LiveMatchPermissions.canLogMatch(
        userId: userId, hub: hub, event: event)) {
      throw Exception('Permission denied: User cannot log matches');
    }

    try {
      final eventRef = _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId);

      // Use transaction to ensure atomic update
      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        if (!eventDoc.exists) {
          throw Exception('Event not found');
        }

        final currentEvent = HubEvent.fromJson({
          ...eventDoc.data()!,
          'eventId': eventDoc.id,
          'hubId': hubId,
        });

        // Add new match to matches array
        final updatedMatches = [...currentEvent.matches, matchResult];

        // Update aggregate wins using FieldValue.increment for atomicity
        final updatedAggregateWins =
            Map<String, int>.from(currentEvent.aggregateWins);
        final winnerColor = matchResult.scoreA > matchResult.scoreB
            ? matchResult.teamAColor
            : (matchResult.scoreB > matchResult.scoreA
                ? matchResult.teamBColor
                : null);
        if (winnerColor != null) {
          // Use increment for atomic update
          updatedAggregateWins[winnerColor] =
              (updatedAggregateWins[winnerColor] ?? 0) + 1;
        }

        // Update event with new match and aggregate wins
        transaction.update(eventRef, {
          'matches': updatedMatches.map((m) => m.toJson()).toList(),
          'aggregateWins': updatedAggregateWins,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Invalidate cache
      CacheService().clear(CacheKeys.event(hubId, eventId));
      CacheService().clear(CacheKeys.eventsByHub(hubId));
    } catch (e) {
      throw Exception('Failed to save match result: $e');
    }
  }

  /// Update an existing match result
  Future<void> updateMatchResult({
    required String hubId,
    required String eventId,
    required String matchId,
    required MatchResult updatedMatch,
    required String userId,
    required Hub hub,
    required HubEvent event,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    // Permission check
    if (!LiveMatchPermissions.canLogMatch(
        userId: userId, hub: hub, event: event)) {
      throw Exception('Permission denied: User cannot edit matches');
    }

    try {
      final eventRef = _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId);

      // Use transaction to ensure atomic update
      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        if (!eventDoc.exists) {
          throw Exception('Event not found');
        }

        final currentEvent = HubEvent.fromJson({
          ...eventDoc.data()!,
          'eventId': eventDoc.id,
          'hubId': hubId,
        });

        // Find and update the match
        final matches = List<MatchResult>.from(currentEvent.matches);
        final matchIndex = matches.indexWhere((m) => m.matchId == matchId);
        if (matchIndex == -1) {
          throw Exception('Match not found: $matchId');
        }

        // Get old match for aggregate wins recalculation
        final oldMatch = matches[matchIndex];
        
        // Update the match
        matches[matchIndex] = updatedMatch;

        // Recalculate aggregate wins
        final updatedAggregateWins = Map<String, int>.from(currentEvent.aggregateWins);
        
        // Remove old win if it existed
        final oldWinnerColor = oldMatch.scoreA > oldMatch.scoreB
            ? oldMatch.teamAColor
            : (oldMatch.scoreB > oldMatch.scoreA ? oldMatch.teamBColor : null);
        if (oldWinnerColor != null && updatedAggregateWins[oldWinnerColor] != null) {
          updatedAggregateWins[oldWinnerColor] = 
              (updatedAggregateWins[oldWinnerColor] ?? 1) - 1;
          if (updatedAggregateWins[oldWinnerColor]! <= 0) {
            updatedAggregateWins.remove(oldWinnerColor);
          }
        }
        
        // Add new win
        final newWinnerColor = updatedMatch.scoreA > updatedMatch.scoreB
            ? updatedMatch.teamAColor
            : (updatedMatch.scoreB > updatedMatch.scoreA
                ? updatedMatch.teamBColor
                : null);
        if (newWinnerColor != null) {
          updatedAggregateWins[newWinnerColor] =
              (updatedAggregateWins[newWinnerColor] ?? 0) + 1;
        }

        // Update event with updated match and recalculated aggregate wins
        transaction.update(eventRef, {
          'matches': matches.map((m) => m.toJson()).toList(),
          'aggregateWins': updatedAggregateWins,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Invalidate cache
      CacheService().clear(CacheKeys.event(hubId, eventId));
      CacheService().clear(CacheKeys.eventsByHub(hubId));
    } catch (e) {
      debugPrint('Error updating match result: $e');
      rethrow;
    }
  }
}
