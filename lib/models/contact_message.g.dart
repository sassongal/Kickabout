// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContactMessageImpl _$$ContactMessageImplFromJson(Map<String, dynamic> json) =>
    _$ContactMessageImpl(
      messageId: json['messageId'] as String,
      hubId: json['hubId'] as String,
      senderId: json['senderId'] as String,
      postId: json['postId'] as String,
      message: json['message'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      senderName: json['senderName'] as String?,
      senderPhotoUrl: json['senderPhotoUrl'] as String?,
      senderPhone: json['senderPhone'] as String?,
      postContent: json['postContent'] as String?,
    );

Map<String, dynamic> _$$ContactMessageImplToJson(
        _$ContactMessageImpl instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'hubId': instance.hubId,
      'senderId': instance.senderId,
      'postId': instance.postId,
      'message': instance.message,
      'status': instance.status,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'senderName': instance.senderName,
      'senderPhotoUrl': instance.senderPhotoUrl,
      'senderPhone': instance.senderPhone,
      'postContent': instance.postContent,
    };
