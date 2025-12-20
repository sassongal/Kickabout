// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameSessionImpl _$$GameSessionImplFromJson(Map<String, dynamic> json) =>
    _$GameSessionImpl(
      matches: (json['matches'] as List<dynamic>?)
              ?.map((e) => MatchResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      aggregateWins: (json['aggregateWins'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      legacyTeamAScore: (json['legacyTeamAScore'] as num?)?.toInt(),
      legacyTeamBScore: (json['legacyTeamBScore'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$GameSessionImplToJson(_$GameSessionImpl instance) =>
    <String, dynamic>{
      'matches': instance.matches,
      'aggregateWins': instance.aggregateWins,
      'legacyTeamAScore': instance.legacyTeamAScore,
      'legacyTeamBScore': instance.legacyTeamBScore,
    };
