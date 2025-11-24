// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MatchResultImpl _$$MatchResultImplFromJson(Map<String, dynamic> json) =>
    _$MatchResultImpl(
      matchId: json['matchId'] as String,
      teamAColor: json['teamAColor'] as String,
      teamBColor: json['teamBColor'] as String,
      scoreA: (json['scoreA'] as num).toInt(),
      scoreB: (json['scoreB'] as num).toInt(),
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      loggedBy: json['loggedBy'] as String?,
    );

Map<String, dynamic> _$$MatchResultImplToJson(_$MatchResultImpl instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'teamAColor': instance.teamAColor,
      'teamBColor': instance.teamBColor,
      'scoreA': instance.scoreA,
      'scoreB': instance.scoreB,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'loggedBy': instance.loggedBy,
    };
