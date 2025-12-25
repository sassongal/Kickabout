import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'submit_game_use_case.g.dart';

/// Parameters for submitting a game
class SubmitGameParams {
  final String eventId;
  final String hubId;
  final int teamAScore;
  final int teamBScore;
  final List<String> presentPlayerIds;
  final List<String>? goalScorerIds;
  final String? mvpPlayerId;
  final bool isSessionMode;
  final Map<String, int>? aggregateWins;
  final List<MatchResult>? matches;

  const SubmitGameParams({
    required this.eventId,
    required this.hubId,
    required this.teamAScore,
    required this.teamBScore,
    required this.presentPlayerIds,
    this.goalScorerIds,
    this.mvpPlayerId,
    this.isSessionMode = false,
    this.aggregateWins,
    this.matches,
  });
}

/// Use case for submitting a game from an event
/// Extracts business logic from log_game_screen.dart
@riverpod
class SubmitGameUseCase extends _$SubmitGameUseCase {
  @override
  FutureOr<String> build() async {
    throw UnimplementedError('Use execute() method');
  }

  /// Validates and submits a game
  /// Returns the created game ID
  Future<String> execute(SubmitGameParams params) async {
    // Validate: at least one team must have players
    if (params.presentPlayerIds.isEmpty) {
      throw Exception('יש לבחור לפחות שחקן אחד נוכח');
    }

    final gamesRepo = ref.read(gamesRepositoryProvider);
    final finalizationService = ref.read(gameFinalizationServiceProvider);

    // Filter goal scorers to only include present players
    final goalScorerIds = params.goalScorerIds
            ?.where((id) => params.presentPlayerIds.contains(id))
            .toList() ??
        [];

    // Filter MVP to only include present players
    final mvpPlayerId = params.mvpPlayerId != null &&
            params.presentPlayerIds.contains(params.mvpPlayerId)
        ? params.mvpPlayerId
        : null;

    // Convert event to game
    if (params.isSessionMode) {
      // For Session Mode, create game first then update with session data
      final gameId = await finalizationService.convertEventToGame(
        eventId: params.eventId,
        hubId: params.hubId,
        teamAScore: params.teamAScore,
        teamBScore: params.teamBScore,
        presentPlayerIds: params.presentPlayerIds,
        goalScorerIds: goalScorerIds.isNotEmpty ? goalScorerIds : null,
        mvpPlayerId: mvpPlayerId,
      );

      // Update game with session data
      if (params.aggregateWins != null || params.matches != null) {
        final updateData = <String, dynamic>{};
        if (params.aggregateWins != null) {
          updateData['aggregateWins'] = params.aggregateWins;
        }
        if (params.matches != null) {
          updateData['matches'] = params.matches!.map((m) => m.toJson()).toList();
        }
        await gamesRepo.updateGame(gameId, updateData);
      }

      return gameId;
    } else {
      // Single Game Mode - normal flow
      final gameId = await finalizationService.convertEventToGame(
        eventId: params.eventId,
        hubId: params.hubId,
        teamAScore: params.teamAScore,
        teamBScore: params.teamBScore,
        presentPlayerIds: params.presentPlayerIds,
        goalScorerIds: goalScorerIds.isNotEmpty ? goalScorerIds : null,
        mvpPlayerId: mvpPlayerId,
      );
      return gameId;
    }
  }
}

