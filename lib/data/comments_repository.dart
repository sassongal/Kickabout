import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';

/// Repository for Comments operations
class CommentsRepository {
  final FirebaseFirestore _firestore;

  CommentsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream comments for a post
  Stream<List<Comment>> watchComments(String hubId, String postId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.hub(hubId))
        .doc('feed')
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromJson({...doc.data(), 'commentId': doc.id}))
            .toList());
  }

  /// Create a comment
  Future<String> createComment(
    String hubId,
    String postId,
    String authorId,
    String text,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final docRef = _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc();

      await docRef.set({
        'postId': postId,
        'hubId': hubId,
        'authorId': authorId,
        'text': text,
        'likes': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update comments count on post
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .update({
        'commentsCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create comment: $e');
    }
  }

  /// Like a comment
  Future<void> likeComment(
    String hubId,
    String postId,
    String commentId,
    String userId,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to like comment: $e');
    }
  }

  /// Unlike a comment
  Future<void> unlikeComment(
    String hubId,
    String postId,
    String commentId,
    String userId,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to unlike comment: $e');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(
    String hubId,
    String postId,
    String commentId,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Update comments count on post
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .update({
        'commentsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }
}

