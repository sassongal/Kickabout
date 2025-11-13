import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';

part 'rating_snapshot.freezed.dart';
part 'rating_snapshot.g.dart';

/// Rating snapshot model matching Firestore schema: /ratings/{uid}/history/{ratingId}
@freezed
class RatingSnapshot with _$RatingSnapshot {
  const factory RatingSnapshot({
    required String ratingId,
    required String gameId,
    required String playerId,
    double? basicScore,
    @Default(5.0) double defense,
    @Default(5.0) double passing,
    @Default(5.0) double shooting,
    @Default(5.0) double dribbling,
    @Default(5.0) double physical,
    @Default(5.0) double leadership,
    @Default(5.0) double teamPlay,
    @Default(5.0) double consistency,
    required String submittedBy,
    @TimestampConverter() required DateTime submittedAt,
    @Default(false) bool isVerified,
  }) = _RatingSnapshot;

  factory RatingSnapshot.fromJson(Map<String, dynamic> json) =>
      _$RatingSnapshotFromJson(json);
}

/// Firestore converter for RatingSnapshot
class RatingSnapshotConverter
    implements JsonConverter<RatingSnapshot, Map<String, dynamic>> {
  const RatingSnapshotConverter();

  @override
  RatingSnapshot fromJson(Map<String, dynamic> json) =>
      RatingSnapshot.fromJson(json);

  @override
  Map<String, dynamic> toJson(RatingSnapshot object) => object.toJson();
}

