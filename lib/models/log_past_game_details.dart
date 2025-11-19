import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickadoor/models/team.dart';

part 'log_past_game_details.freezed.dart';
part 'log_past_game_details.g.dart';

/// Details for logging a past game retroactively
@freezed
class LogPastGameDetails with _$LogPastGameDetails {
  const factory LogPastGameDetails({
    required String hubId,
    required DateTime gameDate,
    String? venueId,
    String? eventId, // Link to hub event (optional)
    required int teamAScore,
    required int teamBScore,
    required List<String> playerIds, // Players who participated
    required List<Team> teams, // Teams with player assignments
    @Default(false) bool showInCommunityFeed, // Show this game in the community activity feed
    @Default([]) List<String> goalScorerIds, // IDs of players who scored (optional)
    @Default([]) List<String> goalScorerNames, // Names of goal scorers (optional, denormalized)
    String? mvpPlayerId, // MVP player ID (optional)
    String? mvpPlayerName, // MVP player name (optional, denormalized)
    String? venueName, // Venue name (optional, denormalized)
  }) = _LogPastGameDetails;

  factory LogPastGameDetails.fromJson(Map<String, dynamic> json) =>
      _$LogPastGameDetailsFromJson(json);
}

