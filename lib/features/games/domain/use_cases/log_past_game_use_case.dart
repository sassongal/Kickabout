import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/core/providers/auth_providers.dart';
import 'package:kattrick/models/log_past_game_details.dart';
import 'package:kattrick/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_past_game_use_case.g.dart';

/// Parameters for logging a past game
class LogPastGameParams {
  final String hubId;
  final DateTime gameDate;
  final String? venueId;
  final String? eventId;
  final int teamAScore;
  final int teamBScore;
  final List<String> playerIds;
  final List<Team> teams;
  final bool showInCommunityFeed;
  final String? region;
  final String? city;

  const LogPastGameParams({
    required this.hubId,
    required this.gameDate,
    this.venueId,
    this.eventId,
    required this.teamAScore,
    required this.teamBScore,
    required this.playerIds,
    required this.teams,
    required this.showInCommunityFeed,
    this.region,
    this.city,
  });
}

/// Use case for logging a past game retroactively
/// Extracts business logic from log_past_game_screen.dart
@riverpod
class LogPastGameUseCase extends _$LogPastGameUseCase {
  @override
  FutureOr<void> build() async {
    // Use case doesn't need initial state
  }

  /// Validates and logs a past game
  Future<void> execute(LogPastGameParams params) async {
    // Validate: at least 4 players required
    if (params.playerIds.length < 4) {
      throw Exception('נא לבחור לפחות 4 שחקנים');
    }

    // Validate: all players must be in teams
    if (params.teams.isEmpty || 
        params.teams.any((team) => team.playerIds.isEmpty)) {
      throw Exception('נא לחלק את כל השחקנים לקבוצות');
    }

    // Validate: scores must be non-negative
    if (params.teamAScore < 0 || params.teamBScore < 0) {
      throw Exception('התוצאות חייבות להיות חיוביות');
    }

    final finalizationService = ref.read(gameFinalizationServiceProvider);
    final currentUserId = ref.read(currentUserIdProvider);

    if (currentUserId == null) {
      throw Exception('משתמש לא מחובר');
    }

    // Create LogPastGameDetails
    final details = LogPastGameDetails(
      hubId: params.hubId,
      gameDate: params.gameDate,
      venueId: params.venueId,
      eventId: params.eventId,
      teamAScore: params.teamAScore,
      teamBScore: params.teamBScore,
      playerIds: params.playerIds,
      teams: params.teams,
      showInCommunityFeed: params.showInCommunityFeed,
      region: params.region,
      city: params.city,
    );

    // Log the past game
    await finalizationService.logPastGame(details, currentUserId);
  }
}

