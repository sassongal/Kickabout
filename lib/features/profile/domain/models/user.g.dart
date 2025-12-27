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
      birthDate:
          const TimestampConverter().fromJson(json['birthDate'] as Object),
      favoriteTeamId: json['favoriteTeamId'] as String?,
      favoriteProTeamId: json['favoriteProTeamId'] as String?,
      facebookProfileUrl: json['facebookProfileUrl'] as String?,
      instagramProfileUrl: json['instagramProfileUrl'] as String?,
      showSocialLinks: json['showSocialLinks'] as bool? ?? false,
      availabilityStatus: json['availabilityStatus'] as String? ?? 'available',
      isActive: json['isActive'] as bool? ?? true,
      isFictitious: json['isFictitious'] as bool? ?? false,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      hubIds: (json['hubIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentRankScore: (json['currentRankScore'] as num?)?.toDouble() ?? 5.0,
      preferredPosition: json['preferredPosition'] as String? ?? 'Midfielder',
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      totalParticipations: (json['totalParticipations'] as num?)?.toInt() ?? 0,
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      location: const NullableGeographicPointFirestoreConverter()
          .fromJson(json['location']),
      geohash: json['geohash'] as String?,
      region: json['region'] as String?,
      userLocation: json['userLocation'] == null
          ? null
          : UserLocation.fromJson(json['userLocation'] as Map<String, dynamic>),
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
            'hideRatings': false,
            'allowHubInvites': true
          },
      privacy: json['privacy'] == null
          ? null
          : PrivacySettings.fromJson(json['privacy'] as Map<String, dynamic>),
      notificationPreferences:
          (json['notificationPreferences'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, e as bool),
              ) ??
              const {
                'game_reminder': true,
                'message': true,
                'like': true,
                'comment': true,
                'signup': true,
                'new_follower': true,
                'hub_chat': true,
                'new_comment': true,
                'new_game': true
              },
      notifications: json['notifications'] == null
          ? null
          : NotificationPreferences.fromJson(
              json['notifications'] as Map<String, dynamic>),
      blockedUserIds: (json['blockedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
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
      'birthDate': const TimestampConverter().toJson(instance.birthDate),
      'favoriteTeamId': instance.favoriteTeamId,
      'favoriteProTeamId': instance.favoriteProTeamId,
      'facebookProfileUrl': instance.facebookProfileUrl,
      'instagramProfileUrl': instance.instagramProfileUrl,
      'showSocialLinks': instance.showSocialLinks,
      'availabilityStatus': instance.availabilityStatus,
      'isActive': instance.isActive,
      'isFictitious': instance.isFictitious,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'hubIds': instance.hubIds,
      'currentRankScore': instance.currentRankScore,
      'preferredPosition': instance.preferredPosition,
      'heightCm': instance.heightCm,
      'weightKg': instance.weightKg,
      'totalParticipations': instance.totalParticipations,
      'gamesPlayed': instance.gamesPlayed,
      'location': const NullableGeographicPointFirestoreConverter()
          .toJson(instance.location),
      'geohash': instance.geohash,
      'region': instance.region,
      'userLocation': instance.userLocation,
      'isProfileComplete': instance.isProfileComplete,
      'followerCount': instance.followerCount,
      'wins': instance.wins,
      'losses': instance.losses,
      'draws': instance.draws,
      'goals': instance.goals,
      'assists': instance.assists,
      'privacySettings': instance.privacySettings,
      'privacy': instance.privacy,
      'notificationPreferences': instance.notificationPreferences,
      'notifications': instance.notifications,
      'blockedUserIds': instance.blockedUserIds,
    };
