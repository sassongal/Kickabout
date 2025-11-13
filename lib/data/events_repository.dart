import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/firestore_paths.dart';

/// Repository for Game Event operations
class EventsRepository {
  final FirebaseFirestore _firestore;

  EventsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get event by game ID and event ID
  Future<GameEvent?> getEvent(String gameId, String eventId) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final doc = await _firestore
          .doc(FirestorePaths.gameEvent(gameId, eventId))
          .get();
      if (!doc.exists) return null;
      return GameEvent.fromJson({...doc.data()!, 'eventId': eventId});
    } catch (e) {
      throw Exception('Failed to get event: $e');
    }
  }

  /// Stream event by game ID and event ID
  Stream<GameEvent?> watchEvent(String gameId, String eventId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .doc(FirestorePaths.gameEvent(gameId, eventId))
        .snapshots()
        .map((doc) => doc.exists
            ? GameEvent.fromJson({...doc.data()!, 'eventId': eventId})
            : null);
  }

  /// Add event to game
  Future<String> addEvent(String gameId, GameEvent event) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final data = event.toJson();
      data.remove('eventId'); // Remove eventId from data (it's the document ID)
      data['timestamp'] = FieldValue.serverTimestamp();
      
      final docRef = event.eventId.isNotEmpty
          ? _firestore.doc(FirestorePaths.gameEvent(gameId, event.eventId))
          : _firestore.collection(FirestorePaths.gameEvents(gameId)).doc();
      
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add event: $e');
    }
  }

  /// Stream all events for a game
  Stream<List<GameEvent>> watchEvents(String gameId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.gameEvents(gameId))
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameEvent.fromJson({...doc.data(), 'eventId': doc.id}))
            .toList());
  }

  /// Get all events for a game (non-streaming)
  Future<List<GameEvent>> getEvents(String gameId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.gameEvents(gameId))
          .orderBy('timestamp', descending: false)
          .get();
      
      return snapshot.docs
          .map((doc) => GameEvent.fromJson({...doc.data(), 'eventId': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get events: $e');
    }
  }

  /// Stream events by type
  Stream<List<GameEvent>> watchEventsByType(String gameId, EventType type) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.gameEvents(gameId))
        .where('type', isEqualTo: type.toFirestore())
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameEvent.fromJson({...doc.data(), 'eventId': doc.id}))
            .toList());
  }

  /// Stream events by player
  Stream<List<GameEvent>> watchEventsByPlayer(String gameId, String playerId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.gameEvents(gameId))
        .where('playerId', isEqualTo: playerId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameEvent.fromJson({...doc.data(), 'eventId': doc.id}))
            .toList());
  }

  /// Delete event
  Future<void> deleteEvent(String gameId, String eventId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.gameEvent(gameId, eventId)).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }
}

