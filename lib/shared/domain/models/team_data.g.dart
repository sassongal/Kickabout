// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeamDataImpl _$$TeamDataImplFromJson(Map<String, dynamic> json) =>
    _$TeamDataImpl(
      id: json['id'] as String? ?? '',
      name: json['name'] as String,
      league: json['league'] as String,
      logoUrl: json['logoUrl'] as String,
    );

Map<String, dynamic> _$$TeamDataImplToJson(_$TeamDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'league': instance.league,
      'logoUrl': instance.logoUrl,
    };
