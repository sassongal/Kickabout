// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hub_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HubSettingsImpl _$$HubSettingsImplFromJson(Map<String, dynamic> json) =>
    _$HubSettingsImpl(
      showManagerContactInfo: json['showManagerContactInfo'] as bool? ?? true,
      allowJoinRequests: json['allowJoinRequests'] as bool? ?? true,
      allowModeratorsToCreateGames:
          json['allowModeratorsToCreateGames'] as bool? ?? false,
      requireResultApproval: json['requireResultApproval'] as bool? ?? false,
      allowMemberInvites: json['allowMemberInvites'] as bool? ?? true,
      enablePolls: json['enablePolls'] as bool? ?? true,
      enableChat: json['enableChat'] as bool? ?? true,
      enableEvents: json['enableEvents'] as bool? ?? true,
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 50,
      veteranGamesThreshold:
          (json['veteranGamesThreshold'] as num?)?.toInt() ?? 10,
    );

Map<String, dynamic> _$$HubSettingsImplToJson(_$HubSettingsImpl instance) =>
    <String, dynamic>{
      'showManagerContactInfo': instance.showManagerContactInfo,
      'allowJoinRequests': instance.allowJoinRequests,
      'allowModeratorsToCreateGames': instance.allowModeratorsToCreateGames,
      'requireResultApproval': instance.requireResultApproval,
      'allowMemberInvites': instance.allowMemberInvites,
      'enablePolls': instance.enablePolls,
      'enableChat': instance.enableChat,
      'enableEvents': instance.enableEvents,
      'maxMembers': instance.maxMembers,
      'veteranGamesThreshold': instance.veteranGamesThreshold,
    };
