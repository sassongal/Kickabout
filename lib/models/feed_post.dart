import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickabout/models/converters/timestamp_converter.dart';

part 'feed_post.freezed.dart';
part 'feed_post.g.dart';

/// Feed post model matching Firestore schema: /hubs/{hubId}/feed/{postId}
@freezed
class FeedPost with _$FeedPost {
  const factory FeedPost({
    required String postId,
    required String hubId,
    required String authorId,
    required String type, // 'game' | 'achievement' | 'rating' | 'post'
    String? content,
    String? gameId,
    String? achievementId,
    @Default([]) List<String> likes,
    @Default(0) int commentsCount,
    @Default([]) List<String> photoUrls, // URLs of photos/videos in the post
    @TimestampConverter() required DateTime createdAt,
  }) = _FeedPost;

  factory FeedPost.fromJson(Map<String, dynamic> json) => _$FeedPostFromJson(json);
}

