// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MatchRecordImpl _$$MatchRecordImplFromJson(Map<String, dynamic> json) =>
    _$MatchRecordImpl(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      hubId: json['hubId'] as String,
      teamAId: json['teamAId'] as String,
      teamBId: json['teamBId'] as String,
      teamAName: json['teamAName'] as String,
      teamBName: json['teamBName'] as String,
      scoreTeamA: (json['scoreTeamA'] as num).toInt(),
      scoreTeamB: (json['scoreTeamB'] as num).toInt(),
      scorers: (json['scorers'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      assists: (json['assists'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      mvpPlayerId: json['mvpPlayerId'] as String?,
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      timestamp:
          const TimestampConverter().fromJson(json['timestamp'] as Object),
      recordedBy: json['recordedBy'] as String,
    );

Map<String, dynamic> _$$MatchRecordImplToJson(_$MatchRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventId': instance.eventId,
      'hubId': instance.hubId,
      'teamAId': instance.teamAId,
      'teamBId': instance.teamBId,
      'teamAName': instance.teamAName,
      'teamBName': instance.teamBName,
      'scoreTeamA': instance.scoreTeamA,
      'scoreTeamB': instance.scoreTeamB,
      'scorers': instance.scorers,
      'assists': instance.assists,
      'mvpPlayerId': instance.mvpPlayerId,
      'durationSeconds': instance.durationSeconds,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'recordedBy': instance.recordedBy,
    };
