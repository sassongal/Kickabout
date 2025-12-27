// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_signup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameSignupImpl _$$GameSignupImplFromJson(Map<String, dynamic> json) =>
    _$GameSignupImpl(
      playerId: json['playerId'] as String,
      signedUpAt:
          const TimestampConverter().fromJson(json['signedUpAt'] as Object),
      status: json['status'] == null
          ? SignupStatus.pending
          : const SignupStatusConverter().fromJson(json['status'] as String),
      adminActionReason: json['adminActionReason'] as String?,
      gameDate: _$JsonConverterFromJson<Object, DateTime>(
          json['gameDate'], const TimestampConverter().fromJson),
      gameStatus: json['gameStatus'] as String?,
      hubId: json['hubId'] as String?,
      location: json['location'] as String?,
      venueName: json['venueName'] as String?,
    );

Map<String, dynamic> _$$GameSignupImplToJson(_$GameSignupImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'signedUpAt': const TimestampConverter().toJson(instance.signedUpAt),
      'status': const SignupStatusConverter().toJson(instance.status),
      'adminActionReason': instance.adminActionReason,
      'gameDate': _$JsonConverterToJson<Object, DateTime>(
          instance.gameDate, const TimestampConverter().toJson),
      'gameStatus': instance.gameStatus,
      'hubId': instance.hubId,
      'location': instance.location,
      'venueName': instance.venueName,
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
