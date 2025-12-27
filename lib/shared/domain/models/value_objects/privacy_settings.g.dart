// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PrivacySettingsImpl _$$PrivacySettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$PrivacySettingsImpl(
      hideFromSearch: json['hideFromSearch'] as bool? ?? false,
      hideEmail: json['hideEmail'] as bool? ?? false,
      hidePhone: json['hidePhone'] as bool? ?? false,
      hideCity: json['hideCity'] as bool? ?? false,
      hideStats: json['hideStats'] as bool? ?? false,
      hideRatings: json['hideRatings'] as bool? ?? false,
      allowHubInvites: json['allowHubInvites'] as bool? ?? true,
    );

Map<String, dynamic> _$$PrivacySettingsImplToJson(
        _$PrivacySettingsImpl instance) =>
    <String, dynamic>{
      'hideFromSearch': instance.hideFromSearch,
      'hideEmail': instance.hideEmail,
      'hidePhone': instance.hidePhone,
      'hideCity': instance.hideCity,
      'hideStats': instance.hideStats,
      'hideRatings': instance.hideRatings,
      'allowHubInvites': instance.allowHubInvites,
    };
