// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'targeting_criteria.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TargetingCriteriaImpl _$$TargetingCriteriaImplFromJson(
        Map<String, dynamic> json) =>
    _$TargetingCriteriaImpl(
      minAge: (json['minAge'] as num?)?.toInt(),
      maxAge: (json['maxAge'] as num?)?.toInt(),
      gender: $enumDecodeNullable(_$PlayerGenderEnumMap, json['gender']) ??
          PlayerGender.any,
      vibe: $enumDecodeNullable(_$GameVibeEnumMap, json['vibe']) ??
          GameVibe.casual,
    );

Map<String, dynamic> _$$TargetingCriteriaImplToJson(
        _$TargetingCriteriaImpl instance) =>
    <String, dynamic>{
      'minAge': instance.minAge,
      'maxAge': instance.maxAge,
      'gender': _$PlayerGenderEnumMap[instance.gender]!,
      'vibe': _$GameVibeEnumMap[instance.vibe]!,
    };

const _$PlayerGenderEnumMap = {
  PlayerGender.male: 'male',
  PlayerGender.female: 'female',
  PlayerGender.any: 'any',
};

const _$GameVibeEnumMap = {
  GameVibe.competitive: 'competitive',
  GameVibe.casual: 'casual',
};
