// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GamificationImpl _$$GamificationImplFromJson(Map<String, dynamic> json) =>
    _$GamificationImpl(
      userId: json['userId'] as String,
      points: (json['points'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      achievements: json['achievements'] as Map<String, dynamic>? ?? const {},
      stats: (json['stats'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {
            'gamesPlayed': 0,
            'gamesWon': 0,
            'goals': 0,
            'assists': 0,
            'saves': 0
          },
      updatedAt: _$JsonConverterFromJson<Object, DateTime>(
          json['updatedAt'], const TimestampConverter().fromJson),
    );

Map<String, dynamic> _$$GamificationImplToJson(_$GamificationImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'points': instance.points,
      'level': instance.level,
      'badges': instance.badges,
      'achievements': instance.achievements,
      'stats': instance.stats,
      'updatedAt': _$JsonConverterToJson<Object, DateTime>(
          instance.updatedAt, const TimestampConverter().toJson),
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
