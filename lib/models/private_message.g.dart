// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'private_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PrivateMessageImpl _$$PrivateMessageImplFromJson(Map<String, dynamic> json) =>
    _$PrivateMessageImpl(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      authorId: json['authorId'] as String,
      text: json['text'] as String,
      read: json['read'] as bool? ?? false,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
    );

Map<String, dynamic> _$$PrivateMessageImplToJson(
        _$PrivateMessageImpl instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'conversationId': instance.conversationId,
      'authorId': instance.authorId,
      'text': instance.text,
      'read': instance.read,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };

_$ConversationImpl _$$ConversationImplFromJson(Map<String, dynamic> json) =>
    _$ConversationImpl(
      conversationId: json['conversationId'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: _$JsonConverterFromJson<Object, DateTime>(
          json['lastMessageAt'], const TimestampConverter().fromJson),
      unreadCount: (json['unreadCount'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
    );

Map<String, dynamic> _$$ConversationImplToJson(_$ConversationImpl instance) =>
    <String, dynamic>{
      'conversationId': instance.conversationId,
      'participants': instance.participants,
      'lastMessage': instance.lastMessage,
      'lastMessageAt': _$JsonConverterToJson<Object, DateTime>(
          instance.lastMessageAt, const TimestampConverter().toJson),
      'unreadCount': instance.unreadCount,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
