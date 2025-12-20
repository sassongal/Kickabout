// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_audit_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameAuditEventImpl _$$GameAuditEventImplFromJson(Map<String, dynamic> json) =>
    _$GameAuditEventImpl(
      action: json['action'] as String,
      userId: json['userId'] as String,
      timestamp:
          const TimestampConverter().fromJson(json['timestamp'] as Object),
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$$GameAuditEventImplToJson(
        _$GameAuditEventImpl instance) =>
    <String, dynamic>{
      'action': instance.action,
      'userId': instance.userId,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'reason': instance.reason,
    };
