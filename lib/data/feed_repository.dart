import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';

/// Repository for Feed operations
class FeedRepository {
  final FirebaseFirestore _firestore;

  FeedRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream feed posts for a hub (for real-time updates)
  Stream<List<FeedPost>> watchFeed(String hubId, {String? postType}) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('hubs')
        .doc(hubId)
        .collection('feed')
        .doc('posts')
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (postType != null) {
      query = query.where('type', isEqualTo: postType);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => FeedPost.fromJson({...doc.data(), 'postId': doc.id}))
        .toList());
  }

  /// Stream regional feed posts (from feedPosts root collection)
  /// Filters by region and last 24 hours (or last 20 items)
  /// Optimized for bulletin board display
  Stream<List<FeedPost>> streamRegionalFeed(
      {String? region, String? postType}) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    // Calculate 24 hours ago
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    Query<Map<String, dynamic>> query = _firestore.collection('feedPosts');

    // Filter by region if provided (required for composite index)
    if (region != null && region.isNotEmpty) {
      query = query.where('region', isEqualTo: region).where('createdAt',
          isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo));
    } else {
      // If no region, just filter by time
      query = query.where('createdAt',
          isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo));
    }

    if (postType != null) {
      query = query.where('type', isEqualTo: postType);
    }

    // Order by createdAt descending and limit to 20 items
    query = query.orderBy('createdAt', descending: true).limit(20);

    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return FeedPost.fromJson({...data, 'postId': doc.id});
        }).toList());
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
