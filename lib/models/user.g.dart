// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      hubIds: (json['hubIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentRankScore: (json['currentRankScore'] as num?)?.toDouble() ?? 5.0,
      preferredPosition: json['preferredPosition'] as String? ?? 'Midfielder',
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'email': instance.email,
      'photoUrl': instance.photoUrl,
      'phoneNumber': instance.phoneNumber,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'hubIds': instance.hubIds,
      'currentRankScore': instance.currentRankScore,
      'preferredPosition': instance.preferredPosition,
    };
