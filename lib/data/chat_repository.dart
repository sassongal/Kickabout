import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';

/// Repository for Chat operations
class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream messages for a hub
  Stream<List<ChatMessage>> watchMessages(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection('hubs')
        .doc(hubId)
        .collection('chat')
        .doc('messages')
        .collection('items')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson({...doc.data(), 'messageId': doc.id}))
            .toList());
  }

  /// Send message
  Future<String> sendMessage(
    String hubId,
    String authorId,
    String text, {
    List<String>? memberIds, // For notification
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final data = {
        'hubId': hubId,
        'authorId': authorId,
        'text': text.trim(),
        'readBy': [authorId],
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('chat')
          .doc('messages')
          .collection('items')
          .doc();

      await docRef.set(data);

      // Send notification to other members
      // This will be handled by the caller using push integration service

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Mark message as read
  Future<void> markAsRead(String hubId, String messageId, String userId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('chat')
          .doc('messages')
          .collection('items')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  /// Stream messages for a game
  Stream<List<ChatMessage>> watchGameMessages(String gameId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('chat')
        .doc('messages')
        .collection('items')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson({...doc.data(), 'messageId': doc.id}))
            .toList());
  }

  /// Send message to game chat
  Future<String> sendGameMessage(
    String gameId,
    String authorId,
    String text,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final data = {
        'hubId': gameId, // Using gameId as hubId for compatibility
        'authorId': authorId,
        'text': text.trim(),
        'readBy': [authorId],
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = _firestore
          .collection('games')
          .doc(gameId)
          .collection('chat')
          .doc('messages')
          .collection('items')
          .doc();

      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send game message: $e');
    }
  }

  /// Delete message
  Future<void> deleteMessage(String hubId, String messageId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('chat')
          .doc('messages')
          .collection('items')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}

