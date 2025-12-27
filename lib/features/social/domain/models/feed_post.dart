import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/shared/infrastructure/firestore/converters/timestamp_firestore_converter.dart';

part 'feed_post.freezed.dart';
part 'feed_post.g.dart';

/// Feed post model matching Firestore schema: /hubs/{hubId}/feed/posts/items/{postId}
/// Denormalized fields: hubName, hubLogoUrl, authorName, authorPhotoUrl for efficient display
@freezed
class FeedPost with _$FeedPost {
  const factory FeedPost({
    required String postId,
    required String hubId,
    required String authorId,
    required String
        type, // 'game' | 'achievement' | 'rating' | 'post' | 'game_created' | 'hub_recruiting' | 'event_completed'
    String? content,
    String? text, // Alternative to content (used by onGameCreated)
    String? gameId,
    String? eventId, // For recruiting posts linked to events
    String? achievementId,
    // Recruiting post fields
    @Default(false) bool isUrgent, // Show "דחוף" badge
    @NullableTimestampConverter()
    DateTime? recruitingUntil, // Deadline for recruiting
    @Default(0) int neededPlayers, // How many players needed
    @Default([]) List<String> likes,
    @Default(0) int likeCount, // Denormalized count for sorting
    @Default(0)
    int commentCount, // Denormalized: Count of comments (Cloud Function writes this)
    // Note: commentsCount is kept for backward compatibility. Prefer using commentCount.
    @Default(0)
    int commentsCount, // Legacy alias - maps to commentCount in Firestore
    @Default([])
    List<String>
        comments, // Legacy: Array of comment IDs (deprecated, use subcollection)
    @Default([]) List<String> photoUrls, // URLs of photos/videos in the post
    @TimestampConverter() required DateTime createdAt,
    // Denormalized fields for efficient display (no need to fetch hub/user)
    String? hubName, // Denormalized from hubs/{hubId}.name
    String? hubLogoUrl, // Denormalized from hubs/{hubId}.logoUrl
    String? authorName, // Denormalized from users/{authorId}.name
    String? authorPhotoUrl, // Denormalized from users/{authorId}.photoUrl
    String? entityId, // ID of related entity (gameId, etc.)
    String? region, // אזור: צפון, מרכז, דרום, ירושלים (לסינון פיד אזורי)
    String? city, // עיר (לתצוגה בפוסטים)
    // Event completion fields (for type: 'event_completed')
    String? winningTeamColor, // Color of winning team
    int? winningTeamWins, // Number of wins for winning team
    String? eventMvpId, // MVP player ID
    String? eventMvpName, // MVP player name (denormalized)
    int? totalMatches, // Total matches played in event
  }) = _FeedPost;

  factory FeedPost.fromJson(Map<String, dynamic> json) =>
      _$FeedPostFromJson(json);
}
