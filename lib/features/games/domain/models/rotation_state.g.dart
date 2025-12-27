// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rotation_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RotationStateImpl _$$RotationStateImplFromJson(Map<String, dynamic> json) =>
    _$RotationStateImpl(
      teamAColor: json['teamAColor'] as String,
      teamBColor: json['teamBColor'] as String,
      waitingTeamColors: (json['waitingTeamColors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentMatchNumber: (json['currentMatchNumber'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$RotationStateImplToJson(_$RotationStateImpl instance) =>
    <String, dynamic>{
      'teamAColor': instance.teamAColor,
      'teamBColor': instance.teamBColor,
      'waitingTeamColors': instance.waitingTeamColors,
      'currentMatchNumber': instance.currentMatchNumber,
    };
