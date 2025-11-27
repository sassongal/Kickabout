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
      avatarColor: json['avatarColor'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      city: json['city'] as String?,
      displayName: json['displayName'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      birthDate: _$JsonConverterFromJson<Object, DateTime>(
          json['birthDate'], const TimestampConverter().fromJson),
      favoriteTeamId: json['favoriteTeamId'] as String?,
      facebookProfileUrl: json['facebookProfileUrl'] as String?,
      instagramProfileUrl: json['instagramProfileUrl'] as String?,
      availabilityStatus: json['availabilityStatus'] as String? ?? 'available',
      isActive: json['isActive'] as bool? ?? true,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      hubIds: (json['hubIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentRankScore: (json['currentRankScore'] as num?)?.toDouble() ?? 5.0,
      preferredPosition: json['preferredPosition'] as String? ?? 'Midfielder',
      totalParticipations: (json['totalParticipations'] as num?)?.toInt() ?? 0,
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      location: const NullableGeoPointConverter().fromJson(json['location']),
      geohash: json['geohash'] as String?,
      region: json['region'] as String?,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      privacySettings: (json['privacySettings'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const {
            'hideFromSearch': false,
            'hideEmail': false,
            'hidePhone': false,
            'hideCity': false,
            'hideStats': false,
            'hideRatings': false
          },
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'email': instance.email,
      'photoUrl': instance.photoUrl,
      'avatarColor': instance.avatarColor,
      'phoneNumber': instance.phoneNumber,
      'city': instance.city,
      'displayName': instance.displayName,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'birthDate': _$JsonConverterToJson<Object, DateTime>(
          instance.birthDate, const TimestampConverter().toJson),
      'favoriteTeamId': instance.favoriteTeamId,
      'facebookProfileUrl': instance.facebookProfileUrl,
      'instagramProfileUrl': instance.instagramProfileUrl,
      'availabilityStatus': instance.availabilityStatus,
      'isActive': instance.isActive,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'hubIds': instance.hubIds,
      'currentRankScore': instance.currentRankScore,
      'preferredPosition': instance.preferredPosition,
      'totalParticipations': instance.totalParticipations,
      'gamesPlayed': instance.gamesPlayed,
      'location': const NullableGeoPointConverter().toJson(instance.location),
      'geohash': instance.geohash,
      'region': instance.region,
      'isProfileComplete': instance.isProfileComplete,
      'followerCount': instance.followerCount,
      'wins': instance.wins,
      'losses': instance.losses,
      'draws': instance.draws,
      'goals': instance.goals,
      'assists': instance.assists,
      'privacySettings': instance.privacySettings,
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
