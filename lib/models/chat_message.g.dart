// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      messageId: json['messageId'] as String,
      hubId: json['hubId'] as String,
      authorId: json['authorId'] as String,
      text: json['text'] as String,
      readBy: (json['readBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'hubId': instance.hubId,
      'authorId': instance.authorId,
      'text': instance.text,
      'readBy': instance.readBy,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
