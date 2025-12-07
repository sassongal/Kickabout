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
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      settings: json['settings'] as Map<String, dynamic>? ??
          const {
            'showManagerContactInfo': true,
            'allowJoinRequests': true,
            'allowModeratorsToCreateGames': false
          },
      permissions: json['permissions'] as Map<String, dynamic>? ?? const {},
      location: const NullableGeoPointConverter().fromJson(json['location']),
      geohash: json['geohash'] as String?,
      radius: (json['radius'] as num?)?.toDouble(),
      venueIds: (json['venueIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      mainVenueId: json['mainVenueId'] as String?,
      primaryVenueId: json['primaryVenueId'] as String?,
      primaryVenueLocation: const NullableGeoPointConverter()
          .fromJson(json['primaryVenueLocation']),
      profileImageUrl: json['profileImageUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      hubRules: json['hubRules'] as String?,
      region: json['region'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? false,
      paymentLink: json['paymentLink'] as String?,
      gameCount: (json['gameCount'] as num?)?.toInt(),
      lastActivity: _$JsonConverterFromJson<Object, DateTime>(
          json['lastActivity'], const TimestampConverter().fromJson),
      activityScore: (json['activityScore'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$$HubImplToJson(_$HubImpl instance) => <String, dynamic>{
      'hubId': instance.hubId,
      'name': instance.name,
      'description': instance.description,
      'createdBy': instance.createdBy,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'memberCount': instance.memberCount,
      'settings': instance.settings,
      'permissions': instance.permissions,
      'location': const NullableGeoPointConverter().toJson(instance.location),
      'geohash': instance.geohash,
      'radius': instance.radius,
      'venueIds': instance.venueIds,
      'mainVenueId': instance.mainVenueId,
      'primaryVenueId': instance.primaryVenueId,
      'primaryVenueLocation': const NullableGeoPointConverter()
          .toJson(instance.primaryVenueLocation),
      'profileImageUrl': instance.profileImageUrl,
      'logoUrl': instance.logoUrl,
      'hubRules': instance.hubRules,
      'region': instance.region,
      'isPrivate': instance.isPrivate,
      'paymentLink': instance.paymentLink,
      'gameCount': instance.gameCount,
      'lastActivity': _$JsonConverterToJson<Object, DateTime>(
          instance.lastActivity, const TimestampConverter().toJson),
      'activityScore': instance.activityScore,
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
