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
      final data = event.toJson();
      // Remove eventId from data (it's the document ID)
      data.remove('eventId');
      
      final docRef = await _firestore
          .collection(FirestorePaths.hubs())
          .doc(event.hubId)
          .collection('events')
          .add(data);

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
  /// Returns the new registration count after registration
  Future<int> registerToEvent(String hubId, String eventId, String playerId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // First, get the current event to check max participants
      final eventDoc = await _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId)
          .get();
      
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }
      
      final eventData = eventDoc.data()!;
      final currentRegistered = List<String>.from(eventData['registeredPlayerIds'] ?? []);
      final maxParticipants = eventData['maxParticipants'] as int? ?? 15;
      
      // Check if already registered
      if (currentRegistered.contains(playerId)) {
        throw Exception('Already registered to this event');
      }
      
      // Check if event is full
      if (currentRegistered.length >= maxParticipants) {
        throw Exception('Event is full');
      }
      
      // Register the player
      await _firestore
          .collection(FirestorePaths.hubs())
          .doc(hubId)
          .collection('events')
          .doc(eventId)
          .update({
        'registeredPlayerIds': FieldValue.arrayUnion([playerId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Return the new count (current + 1)
      return currentRegistered.length + 1;
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
