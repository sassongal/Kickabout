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
      isActive: json['isActive'] as bool? ?? false,
      sessionStartedAt: _$JsonConverterFromJson<Object, DateTime>(
          json['sessionStartedAt'], const TimestampConverter().fromJson),
      sessionEndedAt: _$JsonConverterFromJson<Object, DateTime>(
          json['sessionEndedAt'], const TimestampConverter().fromJson),
      sessionStartedBy: json['sessionStartedBy'] as String?,
      currentRotation: json['currentRotation'] == null
          ? null
          : RotationState.fromJson(
              json['currentRotation'] as Map<String, dynamic>),
      finalizedAt: _$JsonConverterFromJson<Object, DateTime>(
          json['finalizedAt'], const TimestampConverter().fromJson),
    );

Map<String, dynamic> _$$GameSessionImplToJson(_$GameSessionImpl instance) =>
    <String, dynamic>{
      'matches': instance.matches,
      'aggregateWins': instance.aggregateWins,
      'legacyTeamAScore': instance.legacyTeamAScore,
      'legacyTeamBScore': instance.legacyTeamBScore,
      'isActive': instance.isActive,
      'sessionStartedAt': _$JsonConverterToJson<Object, DateTime>(
          instance.sessionStartedAt, const TimestampConverter().toJson),
      'sessionEndedAt': _$JsonConverterToJson<Object, DateTime>(
          instance.sessionEndedAt, const TimestampConverter().toJson),
      'sessionStartedBy': instance.sessionStartedBy,
      'currentRotation': instance.currentRotation,
      'finalizedAt': _$JsonConverterToJson<Object, DateTime>(
          instance.finalizedAt, const TimestampConverter().toJson),
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
