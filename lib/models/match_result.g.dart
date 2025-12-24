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
      scorerIds: (json['scorerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      assistIds: (json['assistIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      mvpId: json['mvpId'] as String?,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      loggedBy: json['loggedBy'] as String?,
      matchDurationMinutes:
          (json['matchDurationMinutes'] as num?)?.toInt() ?? 12,
      approvalStatus: json['approvalStatus'] == null
          ? MatchApprovalStatus.approved
          : const MatchApprovalStatusConverter()
              .fromJson(json['approvalStatus'] as String),
      approvedBy: json['approvedBy'] as String?,
      approvedAt: _$JsonConverterFromJson<Object, DateTime>(
          json['approvedAt'], const TimestampConverter().fromJson),
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$$MatchResultImplToJson(_$MatchResultImpl instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'teamAColor': instance.teamAColor,
      'teamBColor': instance.teamBColor,
      'scoreA': instance.scoreA,
      'scoreB': instance.scoreB,
      'scorerIds': instance.scorerIds,
      'assistIds': instance.assistIds,
      'mvpId': instance.mvpId,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'loggedBy': instance.loggedBy,
      'matchDurationMinutes': instance.matchDurationMinutes,
      'approvalStatus':
          const MatchApprovalStatusConverter().toJson(instance.approvalStatus),
      'approvedBy': instance.approvedBy,
      'approvedAt': _$JsonConverterToJson<Object, DateTime>(
          instance.approvedAt, const TimestampConverter().toJson),
      'rejectionReason': instance.rejectionReason,
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
