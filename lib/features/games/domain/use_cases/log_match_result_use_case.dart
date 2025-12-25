import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/core/providers/auth_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_match_result_use_case.g.dart';

/// Parameters for logging a match result
class LogMatchResultParams {
  final String hubId;
  final String eventId;
  final String teamAColor;
  final String teamBColor;
  final int scoreA;
  final int scoreB;
  final HubEvent currentEvent;

  const LogMatchResultParams({
    required this.hubId,
    required this.eventId,
    required this.teamAColor,
    required this.teamBColor,
    required this.scoreA,
    required this.scoreB,
    required this.currentEvent,
  });
}

/// Use case for logging a match result in session mode
/// Extracts business logic from log_game_screen.dart _logMatchResult()
@riverpod
class LogMatchResultUseCase extends _$LogMatchResultUseCase {
  @override
  FutureOr<void> build() async {
    // Use case doesn't need initial state
  }

  /// Logs a match result and updates the event with aggregate wins
  Future<void> execute(LogMatchResultParams params) async {
    // Validate event has teams
    if (params.currentEvent.teams.isEmpty) {
      throw Exception('אין קבוצות מוגדרות לאירוע');
    }

    final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
    final firestore = FirebaseFirestore.instance;
    final currentUserId = ref.read(currentUserIdProvider);

    if (currentUserId == null) {
      throw Exception('משתמש לא מחובר');
    }

    // Determine winner
    String? winnerColor;
    if (params.scoreA > params.scoreB) {
      winnerColor = params.teamAColor;
    } else if (params.scoreB > params.scoreA) {
      winnerColor = params.teamBColor;
    }

    // Create match result
    final matchId = firestore.collection('temp').doc().id;
    final matchResult = MatchResult(
      matchId: matchId,
      teamAColor: params.teamAColor,
      teamBColor: params.teamBColor,
      scoreA: params.scoreA,
      scoreB: params.scoreB,
      createdAt: DateTime.now(),
      loggedBy: currentUserId,
    );

    // Update aggregate wins
    final currentWins = Map<String, int>.from(params.currentEvent.aggregateWins);
    if (winnerColor != null) {
      currentWins[winnerColor] = (currentWins[winnerColor] ?? 0) + 1;
    }

    // Add match to list
    final updatedMatches = List<MatchResult>.from(params.currentEvent.matches)
      ..add(matchResult);

    // Update event
    await hubEventsRepo.updateHubEvent(
      params.hubId,
      params.eventId,
      {
        'matches': updatedMatches.map((m) => m.toJson()).toList(),
        'aggregateWins': currentWins,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }
}

