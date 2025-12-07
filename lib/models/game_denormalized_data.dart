import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_denormalized_data.freezed.dart';
part 'game_denormalized_data.g.dart';

@freezed
class GameDenormalizedData with _$GameDenormalizedData {
  const factory GameDenormalizedData({
    String? createdByName,
    String? createdByPhotoUrl,
    String? hubName,
    String? venueName,
    @Default([]) List<String> goalScorerIds,
    @Default([]) List<String> goalScorerNames,
    String? mvpPlayerId,
    String? mvpPlayerName,
    @Default([]) List<String> confirmedPlayerIds,
    @Default(0) int confirmedPlayerCount,
    @Default(false) bool isFull,
    int? maxParticipants,
  }) = _GameDenormalizedData;

  factory GameDenormalizedData.fromJson(Map<String, dynamic> json) =>
      _$GameDenormalizedDataFromJson(json);
}
