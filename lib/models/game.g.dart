// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameImpl _$$GameImplFromJson(Map<String, dynamic> json) => _$GameImpl(
      gameId: json['gameId'] as String,
      createdBy: json['createdBy'] as String,
      hubId: json['hubId'] as String,
      eventId: json['eventId'] as String?,
      gameDate: const TimestampConverter().fromJson(json['gameDate'] as Object),
      location: json['location'] as String?,
      locationPoint:
          const NullableGeoPointConverter().fromJson(json['locationPoint']),
      geohash: json['geohash'] as String?,
      venueId: json['venueId'] as String?,
      teamCount: (json['teamCount'] as num?)?.toInt() ?? 2,
      status: json['status'] == null
          ? GameStatus.teamSelection
          : const GameStatusConverter().fromJson(json['status'] as String),
      visibility: json['visibility'] == null
          ? GameVisibility.private
          : const GameVisibilityConverter()
              .fromJson(json['visibility'] as String),
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      updatedAt:
          const TimestampConverter().fromJson(json['updatedAt'] as Object),
      isRecurring: json['isRecurring'] as bool? ?? false,
      parentGameId: json['parentGameId'] as String?,
      recurrencePattern: json['recurrencePattern'] as String?,
      recurrenceEndDate: _$JsonConverterFromJson<Object, DateTime>(
          json['recurrenceEndDate'], const TimestampConverter().fromJson),
      createdByName: json['createdByName'] as String?,
      createdByPhotoUrl: json['createdByPhotoUrl'] as String?,
      hubName: json['hubName'] as String?,
      teams: (json['teams'] as List<dynamic>?)
              ?.map((e) => Team.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      legacyTeamAScore: (json['teamAScore'] as num?)?.toInt(),
      legacyTeamBScore: (json['teamBScore'] as num?)?.toInt(),
      matches: (json['matches'] as List<dynamic>?)
              ?.map((e) => MatchResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      aggregateWins: (json['aggregateWins'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      durationInMinutes: (json['durationInMinutes'] as num?)?.toInt(),
      gameEndCondition: json['gameEndCondition'] as String?,
      region: json['region'] as String?,
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
      confirmedPlayerIds: (json['confirmedPlayerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      confirmedPlayerCount:
          (json['confirmedPlayerCount'] as num?)?.toInt() ?? 0,
      isFull: json['isFull'] as bool? ?? false,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$GameImplToJson(_$GameImpl instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'createdBy': instance.createdBy,
      'hubId': instance.hubId,
      'eventId': instance.eventId,
      'gameDate': const TimestampConverter().toJson(instance.gameDate),
      'location': instance.location,
      'locationPoint':
          const NullableGeoPointConverter().toJson(instance.locationPoint),
      'geohash': instance.geohash,
      'venueId': instance.venueId,
      'teamCount': instance.teamCount,
      'status': const GameStatusConverter().toJson(instance.status),
      'visibility': const GameVisibilityConverter().toJson(instance.visibility),
      'photoUrls': instance.photoUrls,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'isRecurring': instance.isRecurring,
      'parentGameId': instance.parentGameId,
      'recurrencePattern': instance.recurrencePattern,
      'recurrenceEndDate': _$JsonConverterToJson<Object, DateTime>(
          instance.recurrenceEndDate, const TimestampConverter().toJson),
      'createdByName': instance.createdByName,
      'createdByPhotoUrl': instance.createdByPhotoUrl,
      'hubName': instance.hubName,
      'teams': instance.teams,
      'teamAScore': instance.legacyTeamAScore,
      'teamBScore': instance.legacyTeamBScore,
      'matches': instance.matches,
      'aggregateWins': instance.aggregateWins,
      'durationInMinutes': instance.durationInMinutes,
      'gameEndCondition': instance.gameEndCondition,
      'region': instance.region,
      'showInCommunityFeed': instance.showInCommunityFeed,
      'goalScorerIds': instance.goalScorerIds,
      'goalScorerNames': instance.goalScorerNames,
      'mvpPlayerId': instance.mvpPlayerId,
      'mvpPlayerName': instance.mvpPlayerName,
      'venueName': instance.venueName,
      'confirmedPlayerIds': instance.confirmedPlayerIds,
      'confirmedPlayerCount': instance.confirmedPlayerCount,
      'isFull': instance.isFull,
      'maxParticipants': instance.maxParticipants,
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
