import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/services/cache_service.dart';
import 'package:kattrick/services/retry_service.dart';
import 'package:kattrick/services/monitoring_service.dart';

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
                data['registeredPlayerIds'] ??= [];
                data['waitingListPlayerIds'] ??= [];
                data['teams'] ??= [];
                data['matches'] ??= [];
                data['aggregateWins'] ??= {};

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

            return HubEvent.fromJson({...doc.data()!, 'eventId': doc.id});
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
}
