// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserLocationImpl _$$UserLocationImplFromJson(Map<String, dynamic> json) =>
    _$UserLocationImpl(
      location: const NullableGeographicPointFirestoreConverter()
          .fromJson(json['location']),
      geohash: json['geohash'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
    );

Map<String, dynamic> _$$UserLocationImplToJson(_$UserLocationImpl instance) =>
    <String, dynamic>{
      'location': const NullableGeographicPointFirestoreConverter()
          .toJson(instance.location),
      'geohash': instance.geohash,
      'city': instance.city,
      'region': instance.region,
    };
