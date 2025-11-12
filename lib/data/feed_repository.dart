import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';

/// Repository for Feed operations
class FeedRepository {
  final FirebaseFirestore _firestore;

  FeedRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream feed posts for a hub
  Stream<List<FeedPost>> watchFeed(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.hub(hubId))
        .doc('feed')
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedPost.fromJson({...doc.data(), 'postId': doc.id}))
            .toList());
  }

  /// Create feed post
  Future<String> createPost(FeedPost post) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final data = post.toJson();
      data.remove('postId');

      final docRef = _firestore
          .collection(FirestorePaths.hub(post.hubId))
          .doc('feed')
          .collection('posts')
          .doc();

      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Like a post
  Future<void> likePost(String hubId, String postId, String userId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  /// Unlike a post
  Future<void> unlikePost(String hubId, String postId, String userId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  /// Delete post
  Future<void> deletePost(String hubId, String postId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection(FirestorePaths.hub(hubId))
          .doc('feed')
          .collection('posts')
          .doc(postId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }
}

