import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/features/social/domain/models/contact_message.dart';

/// Repository for managing hub contact messages
///
/// Extracted from HubsRepository to follow Single Responsibility Principle.
/// Handles player-to-manager communication through contact messages.
class HubContactRepository {
  final FirebaseFirestore _firestore;

  HubContactRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream contact messages for Hub Manager
  ///
  /// Returns up to 100 most recent messages, ordered by creation time.
  ///
  /// Extracted from HubsRepository lines 1477-1497
  Stream<List<ContactMessage>> streamContactMessages(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection('hubs')
        .doc(hubId)
        .collection('contactMessages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ContactMessage.fromJson({
          'messageId': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  /// Send contact message from player to Hub Manager
  ///
  /// Denormalizes sender info and post content for quick access.
  ///
  /// Extracted from HubsRepository lines 1500-1559
  Future<void> sendContactMessage({
    required String hubId,
    required String postId,
    required String senderId,
    required String message,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Get sender info for denormalization
      final senderDoc =
          await _firestore.collection('users').doc(senderId).get();
      final senderData = senderDoc.data();

      // Get post info for context
      final postDoc = await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('feed')
          .doc('posts')
          .collection('items')
          .doc(postId)
          .get();

      final postData = postDoc.data();
      final postContent = postData?['content'] as String?;

      // Create contact message
      final messageRef = _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('contactMessages')
          .doc();

      final contactMessage = ContactMessage(
        messageId: messageRef.id,
        hubId: hubId,
        senderId: senderId,
        postId: postId,
        message: message,
        status: 'pending',
        createdAt: DateTime.now(),
        senderName: senderData?['name'],
        senderPhotoUrl: senderData?['photoUrl'],
        senderPhone: senderData?['phoneNumber'],
        postContent: postContent != null && postContent.length > 50
            ? postContent.substring(0, 50)
            : postContent,
      );

      await messageRef.set(contactMessage.toJson());

      debugPrint('Contact message sent from $senderId to hub $hubId');
    } catch (e) {
      debugPrint('Error sending contact message: $e');
      rethrow;
    }
  }

  /// Check if user already sent a message for this post
  ///
  /// Returns existing ContactMessage if found, null otherwise.
  ///
  /// Extracted from HubsRepository lines 1562-1589
  Future<ContactMessage?> checkExistingContactMessage(
    String hubId,
    String senderId,
    String postId,
  ) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final snapshot = await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('contactMessages')
          .where('senderId', isEqualTo: senderId)
          .where('postId', isEqualTo: postId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ContactMessage.fromJson({
        'messageId': snapshot.docs.first.id,
        ...snapshot.docs.first.data(),
      });
    } catch (e) {
      debugPrint('Error checking existing contact message: $e');
      return null;
    }
  }

  /// Update contact message status (for Hub Manager)
  ///
  /// Status values: 'pending' | 'read' | 'replied'
  ///
  /// Extracted from HubsRepository lines 1592-1615
  Future<void> updateContactMessageStatus({
    required String hubId,
    required String messageId,
    required String status,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('contactMessages')
          .doc(messageId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating contact message status: $e');
      rethrow;
    }
  }
}
