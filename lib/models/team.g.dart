// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeamImpl _$$TeamImplFromJson(Map<String, dynamic> json) => _$TeamImpl(
      teamId: json['teamId'] as String,
      name: json['name'] as String,
      playerIds: (json['playerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String?,
      colorValue: (json['colorValue'] as num?)?.toInt(),
      wins: (json['wins'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$TeamImplToJson(_$TeamImpl instance) =>
    <String, dynamic>{
      'teamId': instance.teamId,
      'name': instance.name,
      'playerIds': instance.playerIds,
      'totalScore': instance.totalScore,
      'color': instance.color,
      'colorValue': instance.colorValue,
      'wins': instance.wins,
    };
