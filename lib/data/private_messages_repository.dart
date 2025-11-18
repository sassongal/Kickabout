import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';

/// Repository for Private Messages operations
class PrivateMessagesRepository {
  final FirebaseFirestore _firestore;

  PrivateMessagesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream conversations for a user
  Stream<List<Conversation>> watchConversations(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection('private_messages')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromJson({...doc.data(), 'conversationId': doc.id}))
            .toList());
  }

  /// Stream messages for a conversation
  Stream<List<PrivateMessage>> watchMessages(String conversationId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection('private_messages')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PrivateMessage.fromJson({...doc.data(), 'messageId': doc.id}))
            .toList());
  }

  /// Create or get conversation between two users
  Future<String> getOrCreateConversation(String userId1, String userId2) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    // Sort user IDs to ensure consistent conversation ID
    final participants = [userId1, userId2]..sort();
    final conversationId = participants.join('_');

    try {
      final doc = await _firestore
          .collection('private_messages')
          .doc(conversationId)
          .get();

      if (!doc.exists) {
        await _firestore
            .collection('private_messages')
            .doc(conversationId)
            .set({
          'participantIds': participants,
          'unreadCount': {
            userId1: 0,
            userId2: 0,
          },
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }

      return conversationId;
    } catch (e) {
      throw Exception('Failed to get or create conversation: $e');
    }
  }

  /// Send a private message
  Future<String> sendMessage(
    String conversationId,
    String senderId,
    String text,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final docRef = _firestore
          .collection('private_messages')
          .doc(conversationId)
          .collection('messages')
          .doc();

      await docRef.set({
        'messageId': docRef.id,
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text.trim(),
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update conversation
      final conversation = await _firestore
          .collection('private_messages')
          .doc(conversationId)
          .get();

      if (conversation.exists) {
        final participantIds = (conversation.data()!['participantIds'] as List)
            .map((e) => e.toString())
            .toList();
        final otherUserId = participantIds.firstWhere((id) => id != senderId);

        await _firestore
            .collection('private_messages')
            .doc(conversationId)
            .update({
          'lastMessage': text.trim(),
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCount.$otherUserId': FieldValue.increment(1),
        });
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId, String userId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Mark all unread messages as read
      final unreadMessages = await _firestore
          .collection('private_messages')
          .doc(conversationId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }

      // Reset unread count
      batch.update(
        _firestore.collection('private_messages').doc(conversationId),
        {'unreadCount.$userId': 0},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }
}

