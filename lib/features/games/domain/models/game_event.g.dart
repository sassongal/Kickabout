// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameEventImpl _$$GameEventImplFromJson(Map<String, dynamic> json) =>
    _$GameEventImpl(
      eventId: json['eventId'] as String,
      type: const EventTypeConverter().fromJson(json['type'] as String),
      playerId: json['playerId'] as String,
      timestamp:
          const TimestampConverter().fromJson(json['timestamp'] as Object),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$GameEventImplToJson(_$GameEventImpl instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'type': const EventTypeConverter().toJson(instance.type),
      'playerId': instance.playerId,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'metadata': instance.metadata,
    };
