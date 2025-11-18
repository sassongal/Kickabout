// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationImpl _$$NotificationImplFromJson(Map<String, dynamic> json) =>
    _$NotificationImpl(
      notificationId: json['notificationId'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      read: json['read'] as bool? ?? false,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      entityId: json['entityId'] as String?,
      hubId: json['hubId'] as String?,
    );

Map<String, dynamic> _$$NotificationImplToJson(_$NotificationImpl instance) =>
    <String, dynamic>{
      'notificationId': instance.notificationId,
      'userId': instance.userId,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'data': instance.data,
      'read': instance.read,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'entityId': instance.entityId,
      'hubId': instance.hubId,
    };
