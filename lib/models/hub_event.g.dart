// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hub_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HubEventImpl _$$HubEventImplFromJson(Map<String, dynamic> json) =>
    _$HubEventImpl(
      eventId: json['eventId'] as String,
      hubId: json['hubId'] as String,
      createdBy: json['createdBy'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventDate:
          const TimestampConverter().fromJson(json['eventDate'] as Object),
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      updatedAt:
          const TimestampConverter().fromJson(json['updatedAt'] as Object),
      registeredPlayerIds: (json['registeredPlayerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'upcoming',
      isStarted: json['isStarted'] as bool? ?? false,
      startedAt: _$JsonConverterFromJson<Object, DateTime>(
          json['startedAt'], const TimestampConverter().fromJson),
      location: json['location'] as String?,
      locationPoint:
          const NullableGeoPointConverter().fromJson(json['locationPoint']),
      geohash: json['geohash'] as String?,
      venueId: json['venueId'] as String?,
      teamCount: (json['teamCount'] as num?)?.toInt() ?? 3,
      gameType: json['gameType'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 15,
      notifyMembers: json['notifyMembers'] as bool? ?? false,
      showInCommunityFeed: json['showInCommunityFeed'] as bool? ?? false,
      teams: (json['teams'] as List<dynamic>?)
              ?.map((e) => Team.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      matches: (json['matches'] as List<dynamic>?)
              ?.map((e) => MatchResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      aggregateWins: (json['aggregateWins'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      gameId: json['gameId'] as String?,
    );

Map<String, dynamic> _$$HubEventImplToJson(_$HubEventImpl instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'hubId': instance.hubId,
      'createdBy': instance.createdBy,
      'title': instance.title,
      'description': instance.description,
      'eventDate': const TimestampConverter().toJson(instance.eventDate),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'registeredPlayerIds': instance.registeredPlayerIds,
      'status': instance.status,
      'isStarted': instance.isStarted,
      'startedAt': _$JsonConverterToJson<Object, DateTime>(
          instance.startedAt, const TimestampConverter().toJson),
      'location': instance.location,
      'locationPoint':
          const NullableGeoPointConverter().toJson(instance.locationPoint),
      'geohash': instance.geohash,
      'venueId': instance.venueId,
      'teamCount': instance.teamCount,
      'gameType': instance.gameType,
      'durationMinutes': instance.durationMinutes,
      'maxParticipants': instance.maxParticipants,
      'notifyMembers': instance.notifyMembers,
      'showInCommunityFeed': instance.showInCommunityFeed,
      'teams': instance.teams,
      'matches': instance.matches,
      'aggregateWins': instance.aggregateWins,
      'gameId': instance.gameId,
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
