// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeedPostImpl _$$FeedPostImplFromJson(Map<String, dynamic> json) =>
    _$FeedPostImpl(
      postId: json['postId'] as String,
      hubId: json['hubId'] as String,
      authorId: json['authorId'] as String,
      type: json['type'] as String,
      content: json['content'] as String?,
      gameId: json['gameId'] as String?,
      achievementId: json['achievementId'] as String?,
      likes:
          (json['likes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
    );

Map<String, dynamic> _$$FeedPostImplToJson(_$FeedPostImpl instance) =>
    <String, dynamic>{
      'postId': instance.postId,
      'hubId': instance.hubId,
      'authorId': instance.authorId,
      'type': instance.type,
      'content': instance.content,
      'gameId': instance.gameId,
      'achievementId': instance.achievementId,
      'likes': instance.likes,
      'commentsCount': instance.commentsCount,
      'photoUrls': instance.photoUrls,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
