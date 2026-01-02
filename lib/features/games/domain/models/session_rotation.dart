import 'package:kattrick/shared/domain/models/team.dart';
import 'package:kattrick/features/games/domain/models/rotation_state.dart';
import 'package:kattrick/shared/domain/models/match_result.dart';

/// SessionRotationLogic - Pure logic for managing team rotation in Winner Stays format
/// Supports 2-8 teams with winner-stays-on rotation
class SessionRotationLogic {
  /// Create initial rotation state from teams
  ///
  /// For 2 teams: No rotation (always same matchup)
  /// For 3+ teams: First 2 teams play, rest wait in queue
  ///
  /// Throws ArgumentError if fewer than 2 teams provided
  static RotationState createInitialState(List<Team> teams) {
    if (teams.length < 2) {
      throw ArgumentError('Need at least 2 teams for a session');
    }

    // For 2-team sessions, no waiting queue
    if (teams.length == 2) {
      return RotationState(
        teamAColor: teams[0].color ?? teams[0].name,
        teamBColor: teams[1].color ?? teams[1].name,
        waitingTeamColors: [],
        currentMatchNumber: 1,
      );
    }

    // For 3+ teams, create waiting queue with teams[2] onwards
    final waitingQueue =
        teams.skip(2).map((team) => team.color ?? team.name).toList();

    return RotationState(
      teamAColor: teams[0].color ?? teams[0].name,
      teamBColor: teams[1].color ?? teams[1].name,
      waitingTeamColors: waitingQueue,
      currentMatchNumber: 1,
    );
  }

  /// Check if a team has won too many times in a row (Streak Breaker rule)
  ///
  /// Returns true if the team should be forced to rotate,
  /// false if it's OK to stay.
  ///
  /// Streak Breaker Rule: If a team wins 3 matches in a row,
  /// force them to rotate to keep the game fair and fun.
  static bool shouldForceStreakRotation(
    RotationState current,
    String teamColor,
  ) {
    final currentStreak = current.teamWinStreaks[teamColor] ?? 0;
    // If team just won their 3rd consecutive match, force rotation
    return currentStreak + 1 >= 3;
  }

  /// Calculate next rotation after a match completes
  ///
  /// Rules:
  /// - Winner stays on field
  /// - Loser rotates to end of waiting queue
  /// - Next team from queue enters as challenger
  /// - **NEW: Streak Breaker** - If winner has 3 consecutive wins, force rotation
  /// - For ties: manager must select which team stays (via managerSelectedStayingTeam)
  /// - For 2-team sessions: no rotation (same teams continue)
  ///
  /// Returns updated RotationState for the next match
  ///
  /// Throws ArgumentError if match is a tie and no staying team selected
  static RotationState calculateNextRotation({
    required RotationState current,
    required MatchResult completedMatch,
    String? managerSelectedStayingTeam,
  }) {
    // Handle 2-team case: no rotation, just increment match number
    if (current.waitingTeamColors.isEmpty) {
      return current.copyWith(
        currentMatchNumber: current.currentMatchNumber + 1,
      );
    }

    // Determine which team stays on field
    final String stayingTeam;
    final String rotatingTeam;

    if (completedMatch.scoreA > completedMatch.scoreB) {
      // Team A wins, stays
      stayingTeam = current.teamAColor;
      rotatingTeam = current.teamBColor;
    } else if (completedMatch.scoreB > completedMatch.scoreA) {
      // Team B wins, stays
      stayingTeam = current.teamBColor;
      rotatingTeam = current.teamAColor;
    } else {
      // Tie: manager must select which team stays
      if (managerSelectedStayingTeam == null) {
        throw ArgumentError(
          'Manager must select which team stays when match ends in a tie',
        );
      }

      // Validate manager selection is one of the playing teams
      if (managerSelectedStayingTeam != current.teamAColor &&
          managerSelectedStayingTeam != current.teamBColor) {
        throw ArgumentError(
          'Manager must select one of the playing teams: '
          '${current.teamAColor} or ${current.teamBColor}',
        );
      }

      stayingTeam = managerSelectedStayingTeam;
      rotatingTeam = (stayingTeam == current.teamAColor)
          ? current.teamBColor
          : current.teamAColor;
    }

    // Winner stays, loser rotates - pure "Winner Stays" logic
    // Streak Breaker removed per user request (teams can stay indefinitely)
    final String finalStayingTeam;
    final String finalRotatingTeam;

    if (true) {
      // Normal: winner stays, loser rotates
      finalStayingTeam = stayingTeam;
      finalRotatingTeam = rotatingTeam;
    }

    // Pop next team from front of queue
    final nextTeam = current.waitingTeamColors.first;

    // Add rotating team to end of queue
    final updatedQueue = [
      ...current.waitingTeamColors.skip(1),
      finalRotatingTeam,
    ];

    // Updated strokes logic
    final updatedStreaks = Map<String, int>.from(current.teamWinStreaks);

    // If there was a winner (not a tie/manager selection that resulted in same state)
    if (finalStayingTeam == stayingTeam) {
      // stayingTeam won (or was chosen to stay)
      updatedStreaks[finalStayingTeam] =
          (updatedStreaks[finalStayingTeam] ?? 0) + 1;
      // Reset rotating team's streak
      updatedStreaks[finalRotatingTeam] = 0;
    }

    // Reset new team's streak (they're entering fresh)
    updatedStreaks[nextTeam] = 0;

    return RotationState(
      teamAColor: finalStayingTeam,
      teamBColor: nextTeam,
      waitingTeamColors: updatedQueue,
      currentMatchNumber: current.currentMatchNumber + 1,
      teamWinStreaks: updatedStreaks,
    );
  }

  /// Get the team color identifier for a team
  /// Prefers color over name for consistency
  static String getTeamIdentifier(Team team) {
    return team.color ?? team.name;
  }

  /// Check if a rotation state is valid
  /// All team colors should be unique
  static bool isValidRotation(RotationState rotation, List<Team> allTeams) {
    final allColors = {
      rotation.teamAColor,
      rotation.teamBColor,
      ...rotation.waitingTeamColors,
    };

    // Should have same number of unique colors as teams
    if (allColors.length != allTeams.length) {
      return false;
    }

    // All colors should match team identifiers
    final teamIdentifiers = allTeams.map(getTeamIdentifier).toSet();
    return allColors.difference(teamIdentifiers).isEmpty;
  }
}
