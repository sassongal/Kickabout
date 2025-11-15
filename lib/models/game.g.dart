// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameImpl _$$GameImplFromJson(Map<String, dynamic> json) => _$GameImpl(
      gameId: json['gameId'] as String,
      createdBy: json['createdBy'] as String,
      hubId: json['hubId'] as String,
      gameDate: const TimestampConverter().fromJson(json['gameDate'] as Object),
      location: json['location'] as String?,
      locationPoint: const GeoPointConverter().fromJson(json['locationPoint']),
      geohash: json['geohash'] as String?,
      venueId: json['venueId'] as String?,
      teamCount: (json['teamCount'] as num?)?.toInt() ?? 2,
      status: json['status'] == null
          ? GameStatus.teamSelection
          : const GameStatusConverter().fromJson(json['status'] as String),
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      updatedAt:
          const TimestampConverter().fromJson(json['updatedAt'] as Object),
      isRecurring: json['isRecurring'] as bool? ?? false,
      parentGameId: json['parentGameId'] as String?,
      recurrencePattern: json['recurrencePattern'] as String?,
      recurrenceEndDate: _$JsonConverterFromJson<Object, DateTime>(
          json['recurrenceEndDate'], const TimestampConverter().fromJson),
      createdByName: json['createdByName'] as String?,
      createdByPhotoUrl: json['createdByPhotoUrl'] as String?,
      hubName: json['hubName'] as String?,
    );

Map<String, dynamic> _$$GameImplToJson(_$GameImpl instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'createdBy': instance.createdBy,
      'hubId': instance.hubId,
      'gameDate': const TimestampConverter().toJson(instance.gameDate),
      'location': instance.location,
      'locationPoint': const GeoPointConverter().toJson(instance.locationPoint),
      'geohash': instance.geohash,
      'venueId': instance.venueId,
      'teamCount': instance.teamCount,
      'status': const GameStatusConverter().toJson(instance.status),
      'photoUrls': instance.photoUrls,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'isRecurring': instance.isRecurring,
      'parentGameId': instance.parentGameId,
      'recurrencePattern': instance.recurrencePattern,
      'recurrenceEndDate': _$JsonConverterToJson<Object, DateTime>(
          instance.recurrenceEndDate, const TimestampConverter().toJson),
      'createdByName': instance.createdByName,
      'createdByPhotoUrl': instance.createdByPhotoUrl,
      'hubName': instance.hubName,
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
