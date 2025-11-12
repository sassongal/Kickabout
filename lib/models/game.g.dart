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
    };
