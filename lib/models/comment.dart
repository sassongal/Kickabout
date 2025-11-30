import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

/// Comment model matching Firestore schema: /hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}
/// Denormalized fields: authorName, authorPhotoUrl for efficient display
@freezed
class Comment with _$Comment {
  const factory Comment({
    required String commentId,
    required String postId,
    required String hubId,
    required String authorId,
    required String text,
    @Default([]) List<String> likes,
    @TimestampConverter() required DateTime createdAt,
    // Denormalized fields for efficient display (no need to fetch user)
    String? authorName, // Denormalized from users/{authorId}.name
    String? authorPhotoUrl, // Denormalized from users/{authorId}.photoUrl
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}

