// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geographic_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GeographicPointImpl _$$GeographicPointImplFromJson(
        Map<String, dynamic> json) =>
    _$GeographicPointImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$$GeographicPointImplToJson(
        _$GeographicPointImpl instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
