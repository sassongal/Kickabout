import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';

/// Result of a paginated feed query
class FeedPageResult {
  final List<FeedPost> posts;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  FeedPageResult({
    required this.posts,
    required this.lastDocument,
    required this.hasMore,
  });
}

/// Repository for Feed operations
class FeedRepository {
  final FirebaseFirestore _firestore;

  FeedRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream feed posts for a hub (for real-time updates)
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

  /// Stream regional feed posts (from feedPosts root collection)
  /// Filters by region if provided
  Stream<List<FeedPost>> streamRegionalFeed({String? region}) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('feedPosts')
        .orderBy('createdAt', descending: true)
        .limit(50);

    // Filter by region if provided
    if (region != null && region.isNotEmpty) {
      query = query.where('region', isEqualTo: region);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return FeedPost.fromJson({...data, 'postId': doc.id});
        })
        .toList());
  }

  /// Get feed posts with pagination
  /// Returns a FeedPageResult containing posts and the last document snapshot
  Future<FeedPageResult> getFeedPosts({
    required String hubId,
    DocumentSnapshot? lastDocumentSnapshot,
    int limit = 15,
  }) async {
    if (!Env.isFirebaseAvailable) {
      return FeedPageResult(posts: [], lastDocument: null, hasMore: false);
    }

    try {
      Query query = _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('feed')
          .doc('posts')
          .collection('items')
          .orderBy('createdAt', descending: true)
          .limit(limit + 1); // Get one extra to check if there's more

      if (lastDocumentSnapshot != null) {
        query = query.startAfterDocument(lastDocumentSnapshot);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > limit;
      
      // Remove the extra document if we got more than limit
      final postsToReturn = hasMore ? docs.take(limit).toList() : docs;
      final lastDoc = postsToReturn.isNotEmpty ? postsToReturn.last : null;

      final posts = postsToReturn
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return FeedPost.fromJson({...data, 'postId': doc.id});
          })
          .toList();

      return FeedPageResult(
        posts: posts,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      debugPrint('Failed to get feed posts: $e');
      return FeedPageResult(posts: [], lastDocument: null, hasMore: false);
    }
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

