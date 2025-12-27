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
      activeMemberIds: (json['activeMemberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      managerIds: (json['managerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      moderatorIds: (json['moderatorIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      settings: json['settings'] == null
          ? const HubSettings()
          : const HubSettingsConverter()
              .fromJson(json['settings'] as Map<String, dynamic>),
      legacySettings: json['legacySettings'] as Map<String, dynamic>?,
      permissions: json['permissions'] as Map<String, dynamic>? ?? const {},
      location: const NullableGeographicPointFirestoreConverter()
          .fromJson(json['location']),
      geohash: json['geohash'] as String?,
      radius: (json['radius'] as num?)?.toDouble(),
      venueIds: (json['venueIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      mainVenueId: json['mainVenueId'] as String?,
      primaryVenueId: json['primaryVenueId'] as String?,
      primaryVenueLocation: const NullableGeographicPointFirestoreConverter()
          .fromJson(json['primaryVenueLocation']),
      profileImageUrl: json['profileImageUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      hubRules: json['hubRules'] as String?,
      region: json['region'] as String?,
      city: json['city'] as String?,
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
      'activeMemberIds': instance.activeMemberIds,
      'managerIds': instance.managerIds,
      'moderatorIds': instance.moderatorIds,
      'settings': const HubSettingsConverter().toJson(instance.settings),
      'legacySettings': instance.legacySettings,
      'permissions': instance.permissions,
      'location': const NullableGeographicPointFirestoreConverter()
          .toJson(instance.location),
      'geohash': instance.geohash,
      'radius': instance.radius,
      'venueIds': instance.venueIds,
      'mainVenueId': instance.mainVenueId,
      'primaryVenueId': instance.primaryVenueId,
      'primaryVenueLocation': const NullableGeographicPointFirestoreConverter()
          .toJson(instance.primaryVenueLocation),
      'profileImageUrl': instance.profileImageUrl,
      'logoUrl': instance.logoUrl,
      'bannerUrl': instance.bannerUrl,
      'hubRules': instance.hubRules,
      'region': instance.region,
      'city': instance.city,
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
