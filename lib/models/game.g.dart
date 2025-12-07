// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameImpl _$$GameImplFromJson(Map<String, dynamic> json) => _$GameImpl(
      gameId: json['gameId'] as String,
      createdBy: json['createdBy'] as String,
      hubId: json['hubId'] as String?,
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
      targetingCriteria: json['targetingCriteria'] == null
          ? null
          : TargetingCriteria.fromJson(
              json['targetingCriteria'] as Map<String, dynamic>),
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      minPlayersToPlay: (json['minPlayersToPlay'] as num?)?.toInt() ?? 10,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt(),
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
      recurrenceEndDate: const NullableTimestampConverter()
          .fromJson(json['recurrenceEndDate']),
      teams: (json['teams'] as List<dynamic>?)
              ?.map((e) => Team.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      durationInMinutes: (json['durationInMinutes'] as num?)?.toInt(),
      gameEndCondition: json['gameEndCondition'] as String?,
      region: json['region'] as String?,
      showInCommunityFeed: json['showInCommunityFeed'] as bool? ?? false,
      enableAttendanceReminder:
          json['enableAttendanceReminder'] as bool? ?? true,
      reminderSent2Hours: json['reminderSent2Hours'] as bool?,
      reminderSent2HoursAt: json['reminderSent2HoursAt'] == null
          ? null
          : DateTime.parse(json['reminderSent2HoursAt'] as String),
      denormalized: json['denormalized'] == null
          ? const GameDenormalizedData()
          : GameDenormalizedData.fromJson(
              json['denormalized'] as Map<String, dynamic>),
      session: json['session'] == null
          ? const GameSession()
          : GameSession.fromJson(json['session'] as Map<String, dynamic>),
      audit: json['audit'] == null
          ? const GameAudit()
          : GameAudit.fromJson(json['audit'] as Map<String, dynamic>),
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
      'targetingCriteria': instance.targetingCriteria,
      'requiresApproval': instance.requiresApproval,
      'minPlayersToPlay': instance.minPlayersToPlay,
      'maxPlayers': instance.maxPlayers,
      'photoUrls': instance.photoUrls,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'isRecurring': instance.isRecurring,
      'parentGameId': instance.parentGameId,
      'recurrencePattern': instance.recurrencePattern,
      'recurrenceEndDate':
          const NullableTimestampConverter().toJson(instance.recurrenceEndDate),
      'teams': instance.teams,
      'durationInMinutes': instance.durationInMinutes,
      'gameEndCondition': instance.gameEndCondition,
      'region': instance.region,
      'showInCommunityFeed': instance.showInCommunityFeed,
      'enableAttendanceReminder': instance.enableAttendanceReminder,
      'reminderSent2Hours': instance.reminderSent2Hours,
      'reminderSent2HoursAt': instance.reminderSent2HoursAt?.toIso8601String(),
      'denormalized': instance.denormalized,
      'session': instance.session,
      'audit': instance.audit,
    };
