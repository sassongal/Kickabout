// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_past_game_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LogPastGameDetailsImpl _$$LogPastGameDetailsImplFromJson(
        Map<String, dynamic> json) =>
    _$LogPastGameDetailsImpl(
      hubId: json['hubId'] as String,
      gameDate: DateTime.parse(json['gameDate'] as String),
      venueId: json['venueId'] as String?,
      eventId: json['eventId'] as String?,
      teamAScore: (json['teamAScore'] as num).toInt(),
      teamBScore: (json['teamBScore'] as num).toInt(),
      playerIds:
          (json['playerIds'] as List<dynamic>).map((e) => e as String).toList(),
      teams: (json['teams'] as List<dynamic>)
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList(),
      showInCommunityFeed: json['showInCommunityFeed'] as bool? ?? false,
      goalScorerIds: (json['goalScorerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      goalScorerNames: (json['goalScorerNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      mvpPlayerId: json['mvpPlayerId'] as String?,
      mvpPlayerName: json['mvpPlayerName'] as String?,
      venueName: json['venueName'] as String?,
    );

Map<String, dynamic> _$$LogPastGameDetailsImplToJson(
        _$LogPastGameDetailsImpl instance) =>
    <String, dynamic>{
      'hubId': instance.hubId,
      'gameDate': instance.gameDate.toIso8601String(),
      'venueId': instance.venueId,
      'eventId': instance.eventId,
      'teamAScore': instance.teamAScore,
      'teamBScore': instance.teamBScore,
      'playerIds': instance.playerIds,
      'teams': instance.teams,
      'showInCommunityFeed': instance.showInCommunityFeed,
      'goalScorerIds': instance.goalScorerIds,
      'goalScorerNames': instance.goalScorerNames,
      'mvpPlayerId': instance.mvpPlayerId,
      'mvpPlayerName': instance.mvpPlayerName,
      'venueName': instance.venueName,
    };
