// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hub.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HubImpl _$$HubImplFromJson(Map<String, dynamic> json) => _$HubImpl(
      hubId: json['hubId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      memberIds: (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      settings: json['settings'] as Map<String, dynamic>? ??
          const {'ratingMode': 'basic'},
      roles: (json['roles'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      location: const GeoPointConverter().fromJson(json['location']),
      geohash: json['geohash'] as String?,
      radius: (json['radius'] as num?)?.toDouble(),
      venueIds: (json['venueIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$HubImplToJson(_$HubImpl instance) => <String, dynamic>{
      'hubId': instance.hubId,
      'name': instance.name,
      'description': instance.description,
      'createdBy': instance.createdBy,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'memberIds': instance.memberIds,
      'settings': instance.settings,
      'roles': instance.roles,
      'location': const GeoPointConverter().toJson(instance.location),
      'geohash': instance.geohash,
      'radius': instance.radius,
      'venueIds': instance.venueIds,
    };
