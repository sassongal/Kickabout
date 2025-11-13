import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/hub_event.dart';
import 'package:kickadoor/services/firestore_paths.dart';

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
            .map((doc) => HubEvent.fromJson({...doc.data(), 'eventId': doc.id}))
            .toList());
  }

  /// Get all events for a hub (non-streaming)
  Future<List<HubEvent>> getHubEvents(String hubId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .orderBy('eventDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => HubEvent.fromJson({...doc.data(), 'eventId': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Create a new hub event
  Future<String> createHubEvent(HubEvent event) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final docRef = await _firestore
          .collection(FirestorePaths.hubs())
          .doc(event.hubId)
          .collection('events')
          .add(event.toJson());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  /// Update a hub event
  Future<void> updateEvent(String hubId, String eventId, Map<String, dynamic> updates) async {
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
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  /// Delete a hub event
  Future<void> deleteEvent(String hubId, String eventId) async {
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
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  /// Register a player to an event
  Future<void> registerToEvent(String hubId, String eventId, String playerId) async {
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
        'registeredPlayerIds': FieldValue.arrayUnion([playerId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to register to event: $e');
    }
  }

  /// Unregister a player from an event
  Future<void> unregisterFromEvent(String hubId, String eventId, String playerId) async {
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
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to unregister from event: $e');
    }
  }
}
