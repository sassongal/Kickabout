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
      text: json['text'] as String?,
      gameId: json['gameId'] as String?,
      achievementId: json['achievementId'] as String?,
      likes:
          (json['likes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      hubName: json['hubName'] as String?,
      hubLogoUrl: json['hubLogoUrl'] as String?,
      authorName: json['authorName'] as String?,
      authorPhotoUrl: json['authorPhotoUrl'] as String?,
      entityId: json['entityId'] as String?,
    );

Map<String, dynamic> _$$FeedPostImplToJson(_$FeedPostImpl instance) =>
    <String, dynamic>{
      'postId': instance.postId,
      'hubId': instance.hubId,
      'authorId': instance.authorId,
      'type': instance.type,
      'content': instance.content,
      'text': instance.text,
      'gameId': instance.gameId,
      'achievementId': instance.achievementId,
      'likes': instance.likes,
      'likeCount': instance.likeCount,
      'commentsCount': instance.commentsCount,
      'photoUrls': instance.photoUrls,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'hubName': instance.hubName,
      'hubLogoUrl': instance.hubLogoUrl,
      'authorName': instance.authorName,
      'authorPhotoUrl': instance.authorPhotoUrl,
      'entityId': instance.entityId,
    };
