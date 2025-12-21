import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/models/match_result.dart';
import 'package:kattrick/models/rotation_state.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';

part 'game_session.freezed.dart';
part 'game_session.g.dart';

@freezed
class GameSession with _$GameSession {
  const factory GameSession({
    @Default([]) List<MatchResult> matches,
    @Default({}) Map<String, int> aggregateWins,
    // Legacy support fields
    int? legacyTeamAScore,
    int? legacyTeamBScore,

    // Session lifecycle tracking (for Winner Stays format)
    @Default(false) bool isActive,
    @TimestampConverter() DateTime? sessionStartedAt,
    @TimestampConverter() DateTime? sessionEndedAt,
    String? sessionStartedBy, // User ID of manager who started session

    // Rotation queue state (for 2-8 team sessions)
    RotationState? currentRotation,

    // Finalization tracking
    @TimestampConverter() DateTime? finalizedAt,
  }) = _GameSession;

  factory GameSession.fromJson(Map<String, dynamic> json) =>
      _$GameSessionFromJson(json);
}
