import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/models/match_result.dart';

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
  }) = _GameSession;

  factory GameSession.fromJson(Map<String, dynamic> json) =>
      _$GameSessionFromJson(json);
}
