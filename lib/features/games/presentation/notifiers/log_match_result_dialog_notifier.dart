import 'package:kattrick/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_match_result_dialog_notifier.g.dart';

/// State for log match result dialog
class LogMatchResultDialogState {
  final int currentPage;
  final int teamAScore;
  final int teamBScore;
  final Team? selectedTeamA;
  final Team? selectedTeamB;
  final List<User> teamAPlayers;
  final List<User> teamBPlayers;
  final List<User> winningTeamPlayers;
  final Team? winningTeam;
  final Team? losingTeam;
  final String? mvpPlayerId;
  final Set<String> scorerIds;
  final Set<String> assistIds;

  const LogMatchResultDialogState({
    this.currentPage = 0,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.selectedTeamA,
    this.selectedTeamB,
    this.teamAPlayers = const [],
    this.teamBPlayers = const [],
    this.winningTeamPlayers = const [],
    this.winningTeam,
    this.losingTeam,
    this.mvpPlayerId,
    this.scorerIds = const {},
    this.assistIds = const {},
  });

  LogMatchResultDialogState copyWith({
    int? currentPage,
    int? teamAScore,
    int? teamBScore,
    Team? selectedTeamA,
    Team? selectedTeamB,
    List<User>? teamAPlayers,
    List<User>? teamBPlayers,
    List<User>? winningTeamPlayers,
    Team? winningTeam,
    Team? losingTeam,
    String? mvpPlayerId,
    Set<String>? scorerIds,
    Set<String>? assistIds,
  }) {
    return LogMatchResultDialogState(
      currentPage: currentPage ?? this.currentPage,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      selectedTeamA: selectedTeamA ?? this.selectedTeamA,
      selectedTeamB: selectedTeamB ?? this.selectedTeamB,
      teamAPlayers: teamAPlayers ?? this.teamAPlayers,
      teamBPlayers: teamBPlayers ?? this.teamBPlayers,
      winningTeamPlayers: winningTeamPlayers ?? this.winningTeamPlayers,
      winningTeam: winningTeam ?? this.winningTeam,
      losingTeam: losingTeam ?? this.losingTeam,
      mvpPlayerId: mvpPlayerId ?? this.mvpPlayerId,
      scorerIds: scorerIds ?? this.scorerIds,
      assistIds: assistIds ?? this.assistIds,
    );
  }
}

/// Parameters for creating the notifier
class LogMatchResultDialogParams {
  final HubEvent event;
  final List<User> players;

  const LogMatchResultDialogParams({
    required this.event,
    required this.players,
  });
}

/// Notifier for managing log match result dialog state
@riverpod
class LogMatchResultDialogNotifier extends _$LogMatchResultDialogNotifier {
  @override
  LogMatchResultDialogState build(LogMatchResultDialogParams params) {
    // Initialize with first two teams if available
    Team? selectedTeamA;
    Team? selectedTeamB;
    List<User> teamAPlayers = [];
    List<User> teamBPlayers = [];

    if (params.event.teams.length >= 2) {
      selectedTeamA = params.event.teams[0];
      selectedTeamB = params.event.teams[1];
      
      // Initialize player lists
      teamAPlayers = params.players
          .where((p) => selectedTeamA?.playerIds.contains(p.uid) ?? false)
          .toList();
      teamBPlayers = params.players
          .where((p) => selectedTeamB?.playerIds.contains(p.uid) ?? false)
          .toList();
    }

    return LogMatchResultDialogState(
      selectedTeamA: selectedTeamA,
      selectedTeamB: selectedTeamB,
      teamAPlayers: teamAPlayers,
      teamBPlayers: teamBPlayers,
    );
  }

  /// Update current page
  void setCurrentPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  /// Update team scores
  void setTeamAScore(int score) {
    state = state.copyWith(teamAScore: score);
  }

  void setTeamBScore(int score) {
    state = state.copyWith(teamBScore: score);
  }

  /// Update selected teams
  void setSelectedTeamA(Team? team, List<User> players) {
    state = state.copyWith(
      selectedTeamA: team,
      teamAPlayers: players,
    );
  }

  void setSelectedTeamB(Team? team, List<User> players) {
    state = state.copyWith(
      selectedTeamB: team,
      teamBPlayers: players,
    );
  }

  /// Set winning/losing teams (calculated from scores)
  void setWinningLosingTeams() {
    if (state.selectedTeamA == null || state.selectedTeamB == null) return;

    final isTeamAWinner = state.teamAScore > state.teamBScore;
    final winningTeam = isTeamAWinner ? state.selectedTeamA : state.selectedTeamB;
    final losingTeam = isTeamAWinner ? state.selectedTeamB : state.selectedTeamA;
    final winningTeamPlayers = isTeamAWinner ? state.teamAPlayers : state.teamBPlayers;

    state = state.copyWith(
      winningTeam: winningTeam,
      losingTeam: losingTeam,
      winningTeamPlayers: winningTeamPlayers,
    );
  }

  /// Set MVP player
  void setMvpPlayerId(String? playerId) {
    state = state.copyWith(mvpPlayerId: playerId);
  }

  /// Toggle scorer
  void toggleScorer(String playerId) {
    final updated = Set<String>.from(state.scorerIds);
    if (updated.contains(playerId)) {
      updated.remove(playerId);
    } else {
      updated.add(playerId);
    }
    state = state.copyWith(scorerIds: updated);
  }

  /// Toggle assist
  void toggleAssist(String playerId) {
    final updated = Set<String>.from(state.assistIds);
    if (updated.contains(playerId)) {
      updated.remove(playerId);
    } else {
      updated.add(playerId);
    }
    state = state.copyWith(assistIds: updated);
  }

  /// Validate step 1 (score & teams)
  String? validateStep1() {
    if (state.selectedTeamA == null || state.selectedTeamB == null) {
      return 'Please select both teams.';
    }
    if (state.teamAScore == state.teamBScore) {
      return 'Scores cannot be a draw.';
    }

    final isTeamAWinner = state.teamAScore > state.teamBScore;
    final winnerScore = isTeamAWinner ? state.teamAScore : state.teamBScore;
    final loserScore = isTeamAWinner ? state.teamBScore : state.teamAScore;

    if (winnerScore > 5) {
      return 'Winning team score cannot exceed 5.';
    }
    if (loserScore > 4) {
      return 'Losing team score cannot exceed 4.';
    }

    return null; // Valid
  }

  /// Create MatchResult from current state
  MatchResult createMatchResult(String matchId, String loggedBy) {
    if (state.winningTeam == null || state.losingTeam == null) {
      throw Exception('Winning and losing teams must be set');
    }

    final winningScore = state.winningTeam == state.selectedTeamA
        ? state.teamAScore
        : state.teamBScore;
    final losingScore = state.losingTeam == state.selectedTeamA
        ? state.teamAScore
        : state.teamBScore;

    return MatchResult(
      matchId: matchId,
      teamAColor: state.winningTeam!.color ?? state.winningTeam!.name,
      teamBColor: state.losingTeam!.color ?? state.losingTeam!.name,
      scoreA: winningScore,
      scoreB: losingScore,
      mvpId: state.mvpPlayerId,
      scorerIds: state.scorerIds.toList(),
      assistIds: state.assistIds.toList(),
      createdAt: DateTime.now(),
      loggedBy: loggedBy,
    );
  }
}

