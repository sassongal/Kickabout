import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/features/games/data/repositories/session_repository.dart';
import 'package:kattrick/features/games/data/repositories/match_approval_repository.dart';
import 'package:kattrick/shared/domain/models/match_result.dart';
import 'package:kattrick/features/games/domain/models/game.dart';
import 'package:kattrick/utils/stopwatch_utility.dart';

part 'session_controller.freezed.dart';

/// SessionState - UI state for active game session
@freezed
class SessionState with _$SessionState {
  const factory SessionState({
    /// Current scores for teams in active match
    /// Key: team color, Value: score
    @Default({}) Map<String, int> currentScores,

    /// Whether a match is being submitted
    @Default(false) bool isSubmitting,

    /// Match that ended in a tie, awaiting manager selection
    MatchResult? pendingTieMatch,

    /// Team color selected by manager for tie resolution
    String? managerSelectedStayingTeam,

    /// Whether to show tie selection dialog
    @Default(false) bool showTieDialog,

    /// Error message if any
    String? errorMessage,
  }) = _SessionState;
}

/// SessionController - Manages UI state for game sessions
///
/// Handles:
/// - Current match scoring
/// - Match submission
/// - Tie resolution
/// - Stopwatch integration
class SessionController extends StateNotifier<SessionState> {
  final String gameId;
  final SessionRepository _sessionRepo;
  final MatchApprovalRepository _matchApprovalRepo;
  final StopwatchUtility stopwatch;

  SessionController({
    required this.gameId,
    required SessionRepository sessionRepo,
    required MatchApprovalRepository matchApprovalRepo,
    required this.stopwatch,
  })  : _sessionRepo = sessionRepo,
        _matchApprovalRepo = matchApprovalRepo,
        super(const SessionState());

  /// Increment score for a team
  void incrementScore(String teamColor) {
    final currentScore = state.currentScores[teamColor] ?? 0;
    state = state.copyWith(
      currentScores: {
        ...state.currentScores,
        teamColor: currentScore + 1,
      },
    );
  }

  /// Decrement score for a team (with minimum of 0)
  void decrementScore(String teamColor) {
    final currentScore = state.currentScores[teamColor] ?? 0;
    if (currentScore > 0) {
      state = state.copyWith(
        currentScores: {
          ...state.currentScores,
          teamColor: currentScore - 1,
        },
      );
    }
  }

  /// Reset scores for new match
  void resetScores(String teamAColor, String teamBColor) {
    state = state.copyWith(
      currentScores: {
        teamAColor: 0,
        teamBColor: 0,
      },
      pendingTieMatch: null,
      managerSelectedStayingTeam: null,
      showTieDialog: false,
      errorMessage: null,
    );
  }

  /// Finish current match
  ///
  /// If match is a tie and user is manager, shows tie selection dialog.
  /// If match has a winner or moderator submits, creates match result.
  Future<void> finishMatch({
    required Game game,
    required String currentUserId,
    required bool isManager,
    required bool isModerator,
    bool asModeratorRequest = false,
  }) async {
    if (state.isSubmitting) return;

    // Validate rotation state exists
    if (game.session.currentRotation == null) {
      state = state.copyWith(
        errorMessage: 'אין מצב רוטציה פעיל. התחל את המשחק תחילה.',
      );
      return;
    }

    final rotation = game.session.currentRotation!;
    final teamAColor = rotation.teamAColor;
    final teamBColor = rotation.teamBColor;

    final scoreA = state.currentScores[teamAColor] ?? 0;
    final scoreB = state.currentScores[teamBColor] ?? 0;

    // Check if tie
    final isTie = scoreA == scoreB;

    // If tie and manager, show selection dialog
    if (isTie && isManager && !asModeratorRequest) {
      final matchId = _matchApprovalRepo.generateMatchId();
      final tieMatch = MatchResult(
        matchId: matchId,
        teamAColor: teamAColor,
        teamBColor: teamBColor,
        scoreA: scoreA,
        scoreB: scoreB,
        createdAt: DateTime.now(),
        loggedBy: currentUserId,
      );

      state = state.copyWith(
        pendingTieMatch: tieMatch,
        showTieDialog: true,
      );
      return;
    }

    // Submit match
    await _submitMatch(
      game: game,
      teamAColor: teamAColor,
      teamBColor: teamBColor,
      scoreA: scoreA,
      scoreB: scoreB,
      currentUserId: currentUserId,
      isManager: isManager,
      asModeratorRequest: asModeratorRequest,
    );
  }

  /// Select which team stays after a tie (manager only)
  Future<void> selectStayingTeam(
    String teamColor,
    Game game,
    String currentUserId,
  ) async {
    if (state.pendingTieMatch == null) return;

    state = state.copyWith(
      managerSelectedStayingTeam: teamColor,
      showTieDialog: false,
    );

    // Submit the tied match
    await _submitMatch(
      game: game,
      teamAColor: state.pendingTieMatch!.teamAColor,
      teamBColor: state.pendingTieMatch!.teamBColor,
      scoreA: state.pendingTieMatch!.scoreA,
      scoreB: state.pendingTieMatch!.scoreB,
      currentUserId: currentUserId,
      isManager: true,
      asModeratorRequest: false,
      managerSelectedStayingTeam: teamColor,
    );
  }

  /// Internal: Submit match result
  Future<void> _submitMatch({
    required Game game,
    required String teamAColor,
    required String teamBColor,
    required int scoreA,
    required int scoreB,
    required String currentUserId,
    required bool isManager,
    required bool asModeratorRequest,
    String? managerSelectedStayingTeam,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      // Create match result
      final matchId = _matchApprovalRepo.generateMatchId();
      final match = MatchResult(
        matchId: matchId,
        teamAColor: teamAColor,
        teamBColor: teamBColor,
        scoreA: scoreA,
        scoreB: scoreB,
        createdAt: DateTime.now(),
        loggedBy: currentUserId,
        approvalStatus: asModeratorRequest
            ? MatchApprovalStatus.pending
            : MatchApprovalStatus.approved,
      );

      // Submit match
      if (asModeratorRequest) {
        // Moderator submission - requires approval
        await _matchApprovalRepo.submitMatchResult(
          gameId,
          match,
          submitterId: currentUserId,
          requiresApproval: true,
        );
      } else {
        // Manager submission - approved immediately
        await _sessionRepo.addMatchToSession(gameId, match, currentUserId);

        // If tie with manager selection, update rotation
        if (scoreA == scoreB && managerSelectedStayingTeam != null) {
          await _sessionRepo.updateRotationAfterTie(
            gameId,
            match,
            managerSelectedStayingTeam,
            currentUserId,
          );
        }
      }

      // Stop stopwatch
      stopwatch.stop();

      // Reset scores for next match
      state = state.copyWith(
        currentScores: {},
        pendingTieMatch: null,
        managerSelectedStayingTeam: null,
        isSubmitting: false,
      );
    } catch (e) {
      debugPrint('❌ Failed to submit match: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'שגיאה בשמירת התוצאה: ${e.toString()}',
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Cancel tie selection
  void cancelTieSelection() {
    state = state.copyWith(
      showTieDialog: false,
      pendingTieMatch: null,
      managerSelectedStayingTeam: null,
    );
  }
}

/// Provider for SessionController
///
/// Family provider keyed by gameId for multiple simultaneous sessions
final sessionControllerProvider = StateNotifierProvider.family
    .autoDispose<SessionController, SessionState, String>(
  (ref, gameId) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final matchApprovalRepo = ref.watch(matchApprovalRepositoryProvider);
    final stopwatch = StopwatchUtility();

    final controller = SessionController(
      gameId: gameId,
      sessionRepo: sessionRepo,
      matchApprovalRepo: matchApprovalRepo,
      stopwatch: stopwatch,
    );

    // Cleanup stopwatch on dispose
    ref.onDispose(() {
      stopwatch.dispose();
    });

    return controller;
  },
);
