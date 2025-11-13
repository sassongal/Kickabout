import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

/// Comment model matching Firestore schema: /hubs/{hubId}/feed/posts/{postId}/comments/{commentId}
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
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}

