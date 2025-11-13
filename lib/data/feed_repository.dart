import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';

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
        .collection('hubs')
        .doc(hubId)
        .collection('feed')
        .doc('posts')
        .collection('items')
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
          .collection('hubs')
          .doc(post.hubId)
          .collection('feed')
          .doc('posts')
          .collection('items')
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
          .collection('hubs')
          .doc(hubId)
          .collection('feed')
          .doc('posts')
          .collection('items')
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
          .collection('hubs')
          .doc(hubId)
          .collection('feed')
          .doc('posts')
          .collection('items')
          .doc(postId)
          .update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  /// Watch a single post
  Stream<FeedPost?> watchPost(String hubId, String postId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .collection('hubs')
        .doc(hubId)
        .collection('feed')
        .doc('posts')
        .collection('items')
        .doc(postId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return FeedPost.fromJson({...snapshot.data()!, 'postId': snapshot.id});
    });
  }

  /// Get a single post (non-streaming)
  Future<FeedPost?> getPost(String hubId, String postId) async {
    if (!Env.isFirebaseAvailable) {
      return null;
    }

    try {
      final doc = await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('feed')
          .doc('posts')
          .collection('items')
          .doc(postId)
          .get();

      if (!doc.exists) return null;
      return FeedPost.fromJson({...doc.data()!, 'postId': doc.id});
    } catch (e) {
      return null;
    }
  }

  /// Delete post
  Future<void> deletePost(String hubId, String postId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('feed')
          .doc('posts')
          .collection('items')
          .doc(postId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }
}

