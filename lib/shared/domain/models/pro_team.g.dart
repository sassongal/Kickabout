// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pro_team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProTeamImpl _$$ProTeamImplFromJson(Map<String, dynamic> json) =>
    _$ProTeamImpl(
      teamId: json['teamId'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      league: json['league'] as String,
      logoUrl: json['logoUrl'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$$ProTeamImplToJson(_$ProTeamImpl instance) =>
    <String, dynamic>{
      'teamId': instance.teamId,
      'name': instance.name,
      'nameEn': instance.nameEn,
      'league': instance.league,
      'logoUrl': instance.logoUrl,
      'isActive': instance.isActive,
    };
