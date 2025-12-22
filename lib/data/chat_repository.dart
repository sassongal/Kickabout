import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';

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
        .collection('chatMessages')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return ChatMessage.fromJson({...data, 'messageId': doc.id});
            })
            .toList());
  }

  /// Alias for watchMessages (for consistency)
  Stream<List<ChatMessage>> getHubChatStream(String hubId) {
    return watchMessages(hubId);
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

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('chatMessages')
          .doc();

      final messageId = docRef.id;
      
      final data = {
        'messageId': messageId, // Include messageId in data (required by Firestore rules)
        'hubId': hubId,
        'authorId': currentUid,
        'text': text.trim(),
        'readBy': [currentUid],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);

      // Send notification to other members
      // This will be handled by the caller using push integration service

      return messageId;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Alias for sendMessage (for consistency)
  Future<String> sendHubMessage(String hubId, ChatMessage message) async {
    return sendMessage(
      hubId,
      message.authorId,
      message.text,
    );
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
          .collection('chatMessages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  /// Stream messages for a game
  /// 
  /// Reads from games/{gameId}/chatMessages collection
  /// Note: Game chat messages use 'senderId' (not 'authorId'), so we map it to authorId for the model
  Stream<List<ChatMessage>> watchGameMessages(String gameId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('chatMessages')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          // Game chat uses senderId, but ChatMessage model expects authorId
          // Map senderId to authorId for compatibility
          final mappedData = Map<String, dynamic>.from(data);
          if (mappedData.containsKey('senderId') && !mappedData.containsKey('authorId')) {
            mappedData['authorId'] = mappedData['senderId'];
          }
          // Game chat doesn't have hubId, set empty string (model requires it but won't be used)
          if (!mappedData.containsKey('hubId')) {
            mappedData['hubId'] = '';
          }
          // Game chat doesn't have readBy array
          if (!mappedData.containsKey('readBy')) {
            mappedData['readBy'] = [];
          }
          return ChatMessage.fromJson({...mappedData, 'messageId': doc.id});
        }).toList());
  }

  /// Send message to game chat
  /// 
  /// Writes to games/{gameId}/chatMessages collection
  /// Note: Game chat messages use 'senderId' (not 'authorId') per Firestore rules
  Future<String> sendGameMessage(
    String gameId,
    String senderId,
    String text,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      throw Exception('User not authenticated');
    }

    if (senderId != currentUid) {
      debugPrint('sendGameMessage: ignoring mismatched senderId, using auth uid');
    }

    try {
      final data = {
        'gameId': gameId,
        'senderId': currentUid, // Game chat uses senderId per Firestore rules
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = _firestore
          .collection('games')
          .doc(gameId)
          .collection('chatMessages')
          .doc();

      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send game message: $e');
    }
  }

  /// Alias for watchGameMessages (for consistency)
  Stream<List<ChatMessage>> getGameChatStream(String gameId) {
    return watchGameMessages(gameId);
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
          .collection('chatMessages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}
