// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_denormalized_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameDenormalizedDataImpl _$$GameDenormalizedDataImplFromJson(
        Map<String, dynamic> json) =>
    _$GameDenormalizedDataImpl(
      createdByName: json['createdByName'] as String?,
      createdByPhotoUrl: json['createdByPhotoUrl'] as String?,
      hubName: json['hubName'] as String?,
      venueName: json['venueName'] as String?,
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
      confirmedPlayerIds: (json['confirmedPlayerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      confirmedPlayerCount:
          (json['confirmedPlayerCount'] as num?)?.toInt() ?? 0,
      isFull: json['isFull'] as bool? ?? false,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$GameDenormalizedDataImplToJson(
        _$GameDenormalizedDataImpl instance) =>
    <String, dynamic>{
      'createdByName': instance.createdByName,
      'createdByPhotoUrl': instance.createdByPhotoUrl,
      'hubName': instance.hubName,
      'venueName': instance.venueName,
      'goalScorerIds': instance.goalScorerIds,
      'goalScorerNames': instance.goalScorerNames,
      'mvpPlayerId': instance.mvpPlayerId,
      'mvpPlayerName': instance.mvpPlayerName,
      'confirmedPlayerIds': instance.confirmedPlayerIds,
      'confirmedPlayerCount': instance.confirmedPlayerCount,
      'isFull': instance.isFull,
      'maxParticipants': instance.maxParticipants,
    };
