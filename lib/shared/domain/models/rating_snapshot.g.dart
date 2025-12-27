// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RatingSnapshotImpl _$$RatingSnapshotImplFromJson(Map<String, dynamic> json) =>
    _$RatingSnapshotImpl(
      ratingId: json['ratingId'] as String,
      gameId: json['gameId'] as String,
      playerId: json['playerId'] as String,
      basicScore: (json['basicScore'] as num?)?.toDouble(),
      defense: (json['defense'] as num?)?.toDouble() ?? 5.0,
      passing: (json['passing'] as num?)?.toDouble() ?? 5.0,
      shooting: (json['shooting'] as num?)?.toDouble() ?? 5.0,
      dribbling: (json['dribbling'] as num?)?.toDouble() ?? 5.0,
      physical: (json['physical'] as num?)?.toDouble() ?? 5.0,
      leadership: (json['leadership'] as num?)?.toDouble() ?? 5.0,
      teamPlay: (json['teamPlay'] as num?)?.toDouble() ?? 5.0,
      consistency: (json['consistency'] as num?)?.toDouble() ?? 5.0,
      submittedBy: json['submittedBy'] as String,
      submittedAt:
          const TimestampConverter().fromJson(json['submittedAt'] as Object),
      isVerified: json['isVerified'] as bool? ?? false,
    );

Map<String, dynamic> _$$RatingSnapshotImplToJson(
        _$RatingSnapshotImpl instance) =>
    <String, dynamic>{
      'ratingId': instance.ratingId,
      'gameId': instance.gameId,
      'playerId': instance.playerId,
      'basicScore': instance.basicScore,
      'defense': instance.defense,
      'passing': instance.passing,
      'shooting': instance.shooting,
      'dribbling': instance.dribbling,
      'physical': instance.physical,
      'leadership': instance.leadership,
      'teamPlay': instance.teamPlay,
      'consistency': instance.consistency,
      'submittedBy': instance.submittedBy,
      'submittedAt': const TimestampConverter().toJson(instance.submittedAt),
      'isVerified': instance.isVerified,
    };
