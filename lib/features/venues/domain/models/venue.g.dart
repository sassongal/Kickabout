// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VenueImpl _$$VenueImplFromJson(Map<String, dynamic> json) => _$VenueImpl(
      venueId: json['venueId'] as String,
      venueNumber: (json['venueNumber'] as num?)?.toInt() ?? 0,
      hubId: json['hubId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      location:
          const GeographicPointFirestoreConverter().fromJson(json['location']),
      address: json['address'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      googlePlaceId: json['googlePlaceId'] as String?,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      surfaceType: json['surfaceType'] as String? ?? 'grass',
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 11,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      updatedAt:
          const TimestampConverter().fromJson(json['updatedAt'] as Object),
      createdBy: json['createdBy'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isMain: json['isMain'] as bool? ?? false,
      hubCount: (json['hubCount'] as num?)?.toInt() ?? 0,
      isPublic: json['isPublic'] as bool? ?? true,
      source: json['source'] as String? ?? 'manual',
      externalId: json['externalId'] as String?,
    );

Map<String, dynamic> _$$VenueImplToJson(_$VenueImpl instance) =>
    <String, dynamic>{
      'venueId': instance.venueId,
      'venueNumber': instance.venueNumber,
      'hubId': instance.hubId,
      'name': instance.name,
      'description': instance.description,
      'location':
          const GeographicPointFirestoreConverter().toJson(instance.location),
      'address': instance.address,
      'city': instance.city,
      'region': instance.region,
      'googlePlaceId': instance.googlePlaceId,
      'amenities': instance.amenities,
      'surfaceType': instance.surfaceType,
      'maxPlayers': instance.maxPlayers,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'createdBy': instance.createdBy,
      'isActive': instance.isActive,
      'isMain': instance.isMain,
      'hubCount': instance.hubCount,
      'isPublic': instance.isPublic,
      'source': instance.source,
      'externalId': instance.externalId,
    };
