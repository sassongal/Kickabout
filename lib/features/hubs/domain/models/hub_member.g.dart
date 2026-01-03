// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hub_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HubMemberImpl _$$HubMemberImplFromJson(Map<String, dynamic> json) =>
    _$HubMemberImpl(
      hubId: json['hubId'] as String,
      userId: json['userId'] as String,
      joinedAt: const TimestampConverter().fromJson(json['joinedAt'] as Object),
      role: $enumDecodeNullable(_$HubMemberRoleEnumMap, json['role']) ??
          HubMemberRole.member,
      status: $enumDecodeNullable(_$HubMemberStatusEnumMap, json['status']) ??
          HubMemberStatus.active,
      veteranSince: _$JsonConverterFromJson<Object, DateTime>(
          json['veteranSince'], const TimestampConverter().fromJson),
      managerRating: (json['managerRating'] as num?)?.toDouble() ?? 0.0,
      totalMvps: (json['totalMvps'] as num?)?.toInt() ?? 0,
      lastActiveAt: _$JsonConverterFromJson<Object, DateTime>(
          json['lastActiveAt'], const TimestampConverter().fromJson),
      updatedAt: _$JsonConverterFromJson<Object, DateTime>(
          json['updatedAt'], const TimestampConverter().fromJson),
      updatedBy: json['updatedBy'] as String?,
      statusReason: json['statusReason'] as String?,
    );

Map<String, dynamic> _$$HubMemberImplToJson(_$HubMemberImpl instance) =>
    <String, dynamic>{
      'hubId': instance.hubId,
      'userId': instance.userId,
      'joinedAt': const TimestampConverter().toJson(instance.joinedAt),
      'role': _$HubMemberRoleEnumMap[instance.role]!,
      'status': _$HubMemberStatusEnumMap[instance.status]!,
      'veteranSince': _$JsonConverterToJson<Object, DateTime>(
          instance.veteranSince, const TimestampConverter().toJson),
      'managerRating': instance.managerRating,
      'totalMvps': instance.totalMvps,
      'lastActiveAt': _$JsonConverterToJson<Object, DateTime>(
          instance.lastActiveAt, const TimestampConverter().toJson),
      'updatedAt': _$JsonConverterToJson<Object, DateTime>(
          instance.updatedAt, const TimestampConverter().toJson),
      'updatedBy': instance.updatedBy,
      'statusReason': instance.statusReason,
    };

const _$HubMemberRoleEnumMap = {
  HubMemberRole.manager: 'manager',
  HubMemberRole.moderator: 'moderator',
  HubMemberRole.veteran: 'veteran',
  HubMemberRole.member: 'member',
};

const _$HubMemberStatusEnumMap = {
  HubMemberStatus.active: 'active',
  HubMemberStatus.left: 'left',
  HubMemberStatus.banned: 'banned',
  HubMemberStatus.archived: 'archived',
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
