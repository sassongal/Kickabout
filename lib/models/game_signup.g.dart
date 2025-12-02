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
    );

Map<String, dynamic> _$$GameSignupImplToJson(_$GameSignupImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'signedUpAt': const TimestampConverter().toJson(instance.signedUpAt),
      'status': const SignupStatusConverter().toJson(instance.status),
      'adminActionReason': instance.adminActionReason,
    };
