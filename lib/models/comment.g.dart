// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentImpl _$$CommentImplFromJson(Map<String, dynamic> json) =>
    _$CommentImpl(
      commentId: json['commentId'] as String,
      postId: json['postId'] as String,
      hubId: json['hubId'] as String,
      authorId: json['authorId'] as String,
      text: json['text'] as String,
      likes:
          (json['likes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
    );

Map<String, dynamic> _$$CommentImplToJson(_$CommentImpl instance) =>
    <String, dynamic>{
      'commentId': instance.commentId,
      'postId': instance.postId,
      'hubId': instance.hubId,
      'authorId': instance.authorId,
      'text': instance.text,
      'likes': instance.likes,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
