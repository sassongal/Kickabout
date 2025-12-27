import 'package:kattrick/features/games/domain/models/game.dart';

/// Enum representing the winner of a session
enum SessionWinner {
  teamA,
  teamB,
  draw,
}

/// Extension to get display name for SessionWinner
extension SessionWinnerExtension on SessionWinner {
  String get displayName {
    switch (this) {
      case SessionWinner.teamA:
        return 'Team A';
      case SessionWinner.teamB:
        return 'Team B';
      case SessionWinner.draw:
        return 'Draw';
    }
  }
}

/// Statistics for a player across all matches in a session
class PlayerSessionStats {
  final String playerId;
  int goals;
  int assists;

  PlayerSessionStats({
    required this.playerId,
    this.goals = 0,
    this.assists = 0,
  });
}

/// Statistics for a team across all matches in a session
class TeamSessionStats {
  final String teamColor; // Team identifier (color name)
  int wins;
  int draws;
  int losses;
  int goalsFor;
  int goalsAgainst;

  TeamSessionStats({
    required this.teamColor,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  /// Calculate points: Win = 3, Draw = 1
  int get points => (wins * 3) + draws;

  /// Calculate goal difference
  int get goalDifference => goalsFor - goalsAgainst;
}

/// Service for calculating session results and statistics
class SessionLogic {
  /// Calculate the winner of a session based on matches
  /// Returns TeamA, TeamB, or Draw
  /// Logic: Points (Win=3, Draw=1) -> Goal Difference -> Goals For
  static SessionWinner? calculateSessionWinner(Game game) {
    if (game.session.matches.isEmpty) {
      // No matches played yet - return null
      return null;
    }

    // If only 2 teams, use simple TeamA/TeamB logic
    if (game.teams.length == 2) {
      return _calculateTwoTeamWinner(game);
    }

    // For 3+ teams, calculate based on aggregateWins if available
    if (game.session.aggregateWins.isNotEmpty) {
      return _calculateMultiTeamWinner(game);
    }

    // Fallback: calculate from matches
    return _calculateFromMatches(game);
  }

  /// Calculate winner for 2-team session
  static SessionWinner _calculateTwoTeamWinner(Game game) {
    final teamA = game.teams.isNotEmpty ? game.teams[0] : null;
    final teamB = game.teams.length > 1 ? game.teams[1] : null;

    if (teamA == null || teamB == null) {
      return SessionWinner.draw;
    }

    final teamAStats = _calculateTeamStats(game, teamA.color ?? 'TeamA');
    final teamBStats = _calculateTeamStats(game, teamB.color ?? 'TeamB');

    // Compare points
    if (teamAStats.points > teamBStats.points) {
      return SessionWinner.teamA;
    } else if (teamBStats.points > teamAStats.points) {
      return SessionWinner.teamB;
    }

    // Points equal - check goal difference
    if (teamAStats.goalDifference > teamBStats.goalDifference) {
      return SessionWinner.teamA;
    } else if (teamBStats.goalDifference > teamAStats.goalDifference) {
      return SessionWinner.teamB;
    }

    // Goal difference equal - check goals for
    if (teamAStats.goalsFor > teamBStats.goalsFor) {
      return SessionWinner.teamA;
    } else if (teamBStats.goalsFor > teamAStats.goalsFor) {
      return SessionWinner.teamB;
    }

    // Everything equal - draw
    return SessionWinner.draw;
  }

  /// Calculate winner for multi-team session (3+ teams)
  static SessionWinner? _calculateMultiTeamWinner(Game game) {
    if (game.teams.isEmpty) {
      return null;
    }

    // Find team with most wins
    String? winnerColor;
    int maxWins = 0;
    bool isTie = false;

    for (final entry in game.session.aggregateWins.entries) {
      if (entry.value > maxWins) {
        maxWins = entry.value;
        winnerColor = entry.key;
        isTie = false;
      } else if (entry.value == maxWins && winnerColor != null) {
        isTie = true;
      }
    }

    if (isTie || winnerColor == null) {
      return SessionWinner.draw;
    }

    // Map winner color to TeamA/TeamB (for 2-team compatibility)
    // For multi-team, we might need a different return type
    // For now, return TeamA if first team wins, TeamB otherwise
    final firstTeamColor = game.teams.first.color ?? '';
    if (winnerColor == firstTeamColor) {
      return SessionWinner.teamA;
    } else if (game.teams.length > 1) {
      return SessionWinner.teamB;
    }

    return SessionWinner.draw;
  }

  /// Calculate winner from matches list (fallback)
  static SessionWinner _calculateFromMatches(Game game) {
    if (game.session.matches.isEmpty || game.teams.length < 2) {
      return SessionWinner.draw;
    }

    final teamA = game.teams[0];
    final teamB = game.teams.length > 1 ? game.teams[1] : null;

    if (teamB == null) {
      return SessionWinner.draw;
    }

    final teamAStats = _calculateTeamStats(game, teamA.color ?? 'TeamA');
    final teamBStats = _calculateTeamStats(game, teamB.color ?? 'TeamB');

    // Compare points
    if (teamAStats.points > teamBStats.points) {
      return SessionWinner.teamA;
    } else if (teamBStats.points > teamAStats.points) {
      return SessionWinner.teamB;
    }

    // Points equal - check goal difference
    if (teamAStats.goalDifference > teamBStats.goalDifference) {
      return SessionWinner.teamA;
    } else if (teamBStats.goalDifference > teamAStats.goalDifference) {
      return SessionWinner.teamB;
    }

    return SessionWinner.draw;
  }

  /// Calculate statistics for a specific team across all matches
  static TeamSessionStats _calculateTeamStats(Game game, String teamColor) {
    final stats = TeamSessionStats(teamColor: teamColor);

    for (final match in game.session.matches) {
      final isTeamA = match.teamAColor == teamColor;
      final isTeamB = match.teamBColor == teamColor;

      if (!isTeamA && !isTeamB) {
        continue; // This team didn't play in this match
      }

      final teamScore = isTeamA ? match.scoreA : match.scoreB;
      final opponentScore = isTeamA ? match.scoreB : match.scoreA;

      stats.goalsFor += teamScore;
      stats.goalsAgainst += opponentScore;

      if (teamScore > opponentScore) {
        stats.wins++;
      } else if (teamScore == opponentScore) {
        stats.draws++;
      } else {
        stats.losses++;
      }
    }

    return stats;
  }

  /// Get statistics for all teams in a session
  static Map<String, TeamSessionStats> getAllTeamStats(Game game) {
    final Map<String, TeamSessionStats> statsMap = {};

    for (final team in game.teams) {
      final color = team.color ?? team.teamId;
      statsMap[color] = _calculateTeamStats(game, color);
    }

    return statsMap;
  }

  /// Calculate aggregated player statistics across all matches in a session
  /// Returns a map of playerId -> PlayerSessionStats
  static Map<String, PlayerSessionStats> calculateAggregatedPlayerStats(
    Game game,
  ) {
    final Map<String, PlayerSessionStats> playerStats = {};

    for (final match in game.session.matches) {
      // Count goals
      for (final scorerId in match.scorerIds) {
        playerStats.putIfAbsent(
          scorerId,
          () => PlayerSessionStats(playerId: scorerId),
        );
        playerStats[scorerId]!.goals++;
      }

      // Count assists
      for (final assistId in match.assistIds) {
        playerStats.putIfAbsent(
          assistId,
          () => PlayerSessionStats(playerId: assistId),
        );
        playerStats[assistId]!.assists++;
      }
    }

    return playerStats;
  }

  /// Get the Session MVP (player with most goals, then assists)
  static String? getSessionMVP(Game game) {
    final playerStats = calculateAggregatedPlayerStats(game);

    if (playerStats.isEmpty) {
      return null;
    }

    // Sort by goals (desc), then assists (desc)
    final sortedPlayers = playerStats.values.toList()
      ..sort((a, b) {
        if (a.goals != b.goals) {
          return b.goals.compareTo(a.goals);
        }
        return b.assists.compareTo(a.assists);
      });

    return sortedPlayers.first.playerId;
  }

  /// Get series score display string (e.g., "Team A: 2 Wins | Team B: 1 Win")
  static String getSeriesScoreDisplay(Game game) {
    if (game.session.matches.isEmpty) {
      return 'No matches played yet';
    }

    if (game.teams.length < 2) {
      return 'Insufficient teams';
    }

    final teamA = game.teams[0];
    final teamB = game.teams.length > 1 ? game.teams[1] : null;

    if (teamB == null) {
      return 'Insufficient teams';
    }

    final teamAStats = _calculateTeamStats(game, teamA.color ?? 'TeamA');
    final teamBStats = _calculateTeamStats(game, teamB.color ?? 'TeamB');

    final teamAName =
        teamA.name.isNotEmpty ? teamA.name : (teamA.color ?? 'Team A');
    final teamBName =
        teamB.name.isNotEmpty ? teamB.name : (teamB.color ?? 'Team B');

    return '$teamAName: ${teamAStats.wins} Wins | $teamBName: ${teamBStats.wins} Wins';
  }

  /// Check if a game is in session mode (has matches or is designed for multi-match)
  static bool isSessionMode(Game game) {
    // If it has matches, it's definitely a session
    if (game.session.matches.isNotEmpty) {
      return true;
    }

    // If it has aggregateWins, it's a session
    if (game.session.aggregateWins.isNotEmpty) {
      return true;
    }

    // If teams have colors assigned, it's likely a session
    if (game.teams
        .any((team) => team.color != null && team.color!.isNotEmpty)) {
      return true;
    }

    return false;
  }
}
