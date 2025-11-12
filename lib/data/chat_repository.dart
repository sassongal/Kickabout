import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';

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
        .collection(FirestorePaths.hub(hubId))
        .doc('chat')
        .collection('messages')
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
    String text,
  ) async {
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
          .collection(FirestorePaths.hub(hubId))
          .doc('chat')
          .collection('messages')
          .doc();

      await docRef.set(data);
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
          .collection(FirestorePaths.hub(hubId))
          .doc('chat')
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  /// Delete message
  Future<void> deleteMessage(String hubId, String messageId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('chat')
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}

