import 'dart:math';
import 'package:kickadoor/models/models.dart';

/// Player role enum
enum PlayerRole {
  goalkeeper,
  defender,
  midfielder,
  attacker;

  static PlayerRole fromPosition(String position) {
    return switch (position.toLowerCase()) {
      'keeper' || 'goalkeeper' || 'gk' => PlayerRole.goalkeeper,
      'defender' ||
      'def' ||
      'back' ||
      'cb' ||
      'lb' ||
      'rb' ||
      'rwb' ||
      'lwb' =>
        PlayerRole.defender,
      'forward' ||
      'striker' ||
      'attacker' ||
      'att' ||
      'st' ||
      'cf' ||
      'rw' ||
      'lw' =>
        PlayerRole.attacker,
      _ => PlayerRole.midfielder, // Default (includes cm, cdm, cam, lm, rm)
    };
  }
}

/// Minimal player data for team making
class PlayerForTeam {
  final String uid;
  final double rating;
  final PlayerRole role;

  PlayerForTeam({
    required this.uid,
    required this.rating,
    required this.role,
  });

  /// Create PlayerForTeam from User with manager rating
  ///
  /// Uses managerRating from hub if available, otherwise falls back to currentRankScore
  static PlayerForTeam fromUser(
    User user, {
    String? hubId,
    Map<String, double>? managerRatings,
  }) {
    // Use managerRating if available, otherwise fall back to currentRankScore
    final rating = (hubId != null &&
            managerRatings != null &&
            managerRatings.containsKey(user.uid))
        ? managerRatings[user.uid]!
        : user.currentRankScore; // Fallback for backward compatibility

    return PlayerForTeam(
      uid: user.uid,
      rating: rating,
      role: PlayerRole.fromPosition(user.preferredPosition),
    );
  }

  /// Check if player is a goalkeeper
  bool get isGoalkeeper => role == PlayerRole.goalkeeper;

  /// Check if player is defensive
  bool get isDefensive => role == PlayerRole.defender;

  /// Check if player is offensive
  bool get isOffensive => role == PlayerRole.attacker;
}

/// Team balance metrics
class TeamBalanceMetrics {
  final double averageRating;
  final double stddev;
  final double minRating;
  final double maxRating;

  TeamBalanceMetrics({
    required this.averageRating,
    required this.stddev,
    required this.minRating,
    required this.maxRating,
  });
}

/// Represents a swap suggestion between two teams.
class SwapSuggestion {
  final String teamAId;
  final String teamBId;
  final String playerAId;
  final String playerBId;
  SwapSuggestion(
      {required this.teamAId,
      required this.teamBId,
      required this.playerAId,
      required this.playerBId});
  @override
  String toString() =>
      'Swap $playerAId (Team $teamAId) with $playerBId (Team $teamBId)';
}

/// Result of the team creation process.
class TeamCreationResult {
  final List<Team> teams;
  final double balanceScore;

  TeamCreationResult({required this.teams, required this.balanceScore});
}

/// Team maker algorithm - deterministic snake draft + local swap
class TeamMaker {
  // Static field to hold the last computed balance score (0-100)
  static double lastBalanceScore = 0.0;

  /// Create balanced teams using snake draft + local swap.
  /// Returns a record containing the list of teams and the balance score.
  static TeamCreationResult createBalancedTeams(
    List<PlayerForTeam> players, {
    required int teamCount,
    int? playersPerSide,
  }) {
    if (players.length < teamCount) {
      throw ArgumentError('Not enough players for $teamCount teams');
    }
    if (playersPerSide != null && players.length < teamCount * playersPerSide) {
      throw ArgumentError(
        'Not enough players: need ${teamCount * playersPerSide}, have ${players.length}',
      );
    }

    // Separate goalkeepers and field players
    final goalkeepers = players.where((p) => p.isGoalkeeper).toList();
    final fieldPlayers = players.where((p) => !p.isGoalkeeper).toList();

    // Distribute goalkeepers evenly
    final teams = _distributeGoalkeepers(goalkeepers, teamCount);
    // Distribute field players
    _distributeFieldPlayers(fieldPlayers, teams, teamCount);
    // Optimize via local swaps
    final optimizedTeams = _localSwap(teams, teamCount);

    // Define team colors and names
    const teamColors = ['Red', 'Blue', 'Yellow', 'Green', 'Orange'];

    // Convert to final Team objects
    final finalTeams = optimizedTeams.asMap().entries.map((e) {
      final idx = e.key;
      final playerList = e.value;
      final totalScore = playerList.fold<double>(0.0, (s, p) => s + p.rating);
      final color = idx < teamColors.length ? teamColors[idx] : null;
      final name = color ?? 'Team ${idx + 1}';

      return Team(
        teamId: 'team_$idx',
        name: name,
        color: color,
        playerIds: playerList.map((p) => p.uid).toList(),
        totalScore: totalScore,
      );
    }).toList();

    final metrics = calculateBalanceMetrics(finalTeams);
    // Balance score: 100 for perfect balance (stddev=0), decreases as stddev grows.
    // A stddev of 2.5 is considered ~50% balanced.
    final score = (1.0 - (metrics.stddev / 5.0)).clamp(0.0, 1.0) * 100;
    lastBalanceScore = score;

    return TeamCreationResult(teams: finalTeams, balanceScore: score);
  }

  /// Suggest a team for a new player without reshuffling existing teams.
  static String suggestTeamForNewPlayer(
      PlayerForTeam newPlayer, List<Team> currentTeams) {
    double lowestAvg = double.infinity;
    String suggestedTeamId = '';
    for (final team in currentTeams) {
      final avg = team.playerIds.isEmpty
          ? 0.0
          : team.totalScore / team.playerIds.length;
      if (avg < lowestAvg) {
        lowestAvg = avg;
        suggestedTeamId = team.teamId;
      }
    }
    return suggestedTeamId;
  }

  /// Suggest up to two player swaps that would improve team balance.
  static List<SwapSuggestion> getOptimizationSuggestions(
      List<Team> currentTeams, List<PlayerForTeam> allPlayers) {
    if (currentTeams.length < 2) return [];

    final suggestions = <(SwapSuggestion, double)>[];
    final initialStdDev = calculateBalanceMetrics(currentTeams).stddev;

    // Create a mutable copy of teams with player objects for simulation
    final simTeams = currentTeams.map((t) {
      return {
        'id': t.teamId,
        'players': t.playerIds,
        'totalScore': t.totalScore,
      };
    }).toList();

    // Find all possible swaps
    for (int i = 0; i < simTeams.length; i++) {
      for (int j = i + 1; j < simTeams.length; j++) {
        final teamA = simTeams[i];
        final teamB = simTeams[j];

        final teamAPlayers = teamA['players'] as List<String>;
        final teamBPlayers = teamB['players'] as List<String>;

        for (final playerAId in teamAPlayers) {
          for (final playerBId in teamBPlayers) {
            // Simulate the swap
            final playerARating = allPlayers
                .firstWhere((p) => p.uid == playerAId,
                    orElse: () => PlayerForTeam(
                        uid: playerAId, rating: 0, role: PlayerRole.midfielder))
                .rating;
            final playerBRating = allPlayers
                .firstWhere((p) => p.uid == playerBId,
                    orElse: () => PlayerForTeam(
                        uid: playerBId, rating: 0, role: PlayerRole.midfielder))
                .rating;

            final newTeamAScore =
                (teamA['totalScore'] as double) - playerARating + playerBRating;
            final newTeamBScore =
                (teamB['totalScore'] as double) - playerBRating + playerARating;

            final tempTeams = List<Team>.from(currentTeams);
            // We need to update the scores in the temp teams to calculate the new stddev correctly
            // However, calculateBalanceMetrics uses totalScore from the Team object.
            // Since we can't easily modify the Team object (it's frozen), we'll calculate stddev manually from scores.

            final newScores = tempTeams.map((t) {
              if (t.teamId == teamA['id']) return newTeamAScore;
              if (t.teamId == teamB['id']) return newTeamBScore;
              return t.totalScore;
            }).toList();

            final newStdDev = _calculateStddevForScores(newScores);

            if (newStdDev < initialStdDev) {
              final improvement = initialStdDev - newStdDev;
              suggestions.add((
                SwapSuggestion(
                    teamAId: teamA['id'] as String,
                    teamBId: teamB['id'] as String,
                    playerAId: playerAId,
                    playerBId: playerBId),
                improvement
              ));
            }
          }
        }
      }
    }

    // Sort by best improvement and return top 2
    suggestions.sort((a, b) => b.$2.compareTo(a.$2));
    return suggestions.map((s) => s.$1).take(2).toList();
  }

  /// Distribute goalkeepers evenly across teams
  static List<List<PlayerForTeam>> _distributeGoalkeepers(
    List<PlayerForTeam> goalkeepers,
    int teamCount,
  ) {
    final teams = List.generate(teamCount, (_) => <PlayerForTeam>[]);

    // Sort goalkeepers by rating (descending)
    goalkeepers.sort((a, b) => b.rating.compareTo(a.rating));

    // Round-robin distribution
    for (int i = 0; i < goalkeepers.length; i++) {
      teams[i % teamCount].add(goalkeepers[i]);
    }

    return teams;
  }

  /// Distribute field players with style and rating balance
  static void _distributeFieldPlayers(
    List<PlayerForTeam> fieldPlayers,
    List<List<PlayerForTeam>> teams,
    int teamCount,
  ) {
    // Separate by role
    final defenders = fieldPlayers.where((p) => p.isDefensive).toList();
    final attackers = fieldPlayers.where((p) => p.isOffensive).toList();
    final midfielders =
        fieldPlayers.where((p) => !p.isDefensive && !p.isOffensive).toList();

    // Sort each group by rating (descending)
    defenders.sort((a, b) => b.rating.compareTo(a.rating));
    attackers.sort((a, b) => b.rating.compareTo(a.rating));
    midfielders.sort((a, b) => b.rating.compareTo(a.rating));

    // Distribute defenders (snake draft)
    for (int i = 0; i < defenders.length; i++) {
      final roundNumber = i ~/ teamCount;
      final positionInRound = i % teamCount;
      int teamIndex;
      if (roundNumber % 2 == 0) {
        teamIndex = positionInRound;
      } else {
        teamIndex = teamCount - 1 - positionInRound;
      }
      teams[teamIndex].add(defenders[i]);
    }

    // Distribute attackers (snake draft, reverse order)
    for (int i = 0; i < attackers.length; i++) {
      final roundNumber = i ~/ teamCount;
      final positionInRound = i % teamCount;
      int teamIndex;
      if (roundNumber % 2 == 0) {
        teamIndex = teamCount - 1 - positionInRound; // Reverse for balance
      } else {
        teamIndex = positionInRound;
      }
      teams[teamIndex].add(attackers[i]);
    }

    // Distribute midfielders (snake draft)
    for (int i = 0; i < midfielders.length; i++) {
      final roundNumber = i ~/ teamCount;
      final positionInRound = i % teamCount;
      int teamIndex;
      if (roundNumber % 2 == 0) {
        teamIndex = positionInRound;
      } else {
        teamIndex = teamCount - 1 - positionInRound;
      }
      teams[teamIndex].add(midfielders[i]);
    }
  }

  /// Local swap to reduce stddev while maintaining role coverage
  static List<List<PlayerForTeam>> _localSwap(
    List<List<PlayerForTeam>> teams,
    int teamCount,
  ) {
    if (teams.length < 2) return teams;

    // Calculate current stddev
    double currentStddev = _calculateStddev(teams);

    // Try pairwise swaps
    bool improved = true;
    int maxIterations = 50; // Prevent infinite loops
    int iterations = 0;

    while (improved && iterations < maxIterations) {
      improved = false;
      iterations++;

      for (int i = 0; i < teamCount; i++) {
        for (int j = i + 1; j < teamCount; j++) {
          // Try swapping players between teams i and j
          // Create copies to iterate over safely
          final teamIPlayers = List<PlayerForTeam>.from(teams[i]);
          final teamJPlayers = List<PlayerForTeam>.from(teams[j]);

          for (var playerI in teamIPlayers) {
            for (var playerJ in teamJPlayers) {
              // Swap
              teams[i].remove(playerI);
              teams[j].remove(playerJ);
              teams[i].add(playerJ);
              teams[j].add(playerI);

              // Check if stddev improved
              final newStddev = _calculateStddev(teams);
              if (newStddev < currentStddev) {
                // Keep swap
                currentStddev = newStddev;
                improved = true;
                // Break inner loops to restart optimization with new state
                // (Since lists changed, continuing iteration on old copies might be suboptimal or invalid)
                break;
              } else {
                // Revert swap
                teams[i].remove(playerJ);
                teams[j].remove(playerI);
                teams[i].add(playerI);
                teams[j].add(playerJ);
              }
            }
            if (improved) break;
          }
          if (improved) break;
        }
        if (improved) break;
      }
    }

    return teams;
  }

  /// Calculate standard deviation of team average ratings
  static double _calculateStddev(List<List<PlayerForTeam>> teams) {
    if (teams.isEmpty) return 0.0;

    final averages = teams.map((team) {
      if (team.isEmpty) return 0.0;
      return team.fold<double>(0.0, (sum, p) => sum + p.rating) / team.length;
    }).toList();

    final mean =
        averages.fold<double>(0.0, (sum, avg) => sum + avg) / averages.length;
    final variance = averages.fold<double>(
          0.0,
          (sum, avg) => sum + pow(avg - mean, 2),
        ) /
        averages.length;

    return sqrt(variance);
  }

  /// Helper to calculate stddev from a list of total scores
  static double _calculateStddevForScores(List<double> scores) {
    if (scores.isEmpty) return 0.0;

    final mean =
        scores.fold<double>(0.0, (sum, score) => sum + score) / scores.length;
    final variance = scores
            .map((score) => pow(score - mean, 2))
            .fold<double>(0.0, (sum, val) => sum + val) /
        scores.length;

    return sqrt(variance);
  }

  /// Calculate team balance metrics
  static TeamBalanceMetrics calculateBalanceMetrics(List<Team> teams) {
    if (teams.isEmpty) {
      return TeamBalanceMetrics(
        averageRating: 0.0,
        stddev: 0.0,
        minRating: 0.0,
        maxRating: 0.0,
      );
    }

    final averages = teams.map((team) {
      if (team.playerIds.isEmpty) return 0.0;
      return team.totalScore / team.playerIds.length;
    }).toList();

    final mean =
        averages.fold<double>(0.0, (sum, avg) => sum + avg) / averages.length;
    final variance = averages.fold<double>(
          0.0,
          (sum, avg) => sum + pow(avg - mean, 2),
        ) /
        averages.length;
    final stddev = sqrt(variance);

    return TeamBalanceMetrics(
      averageRating: mean,
      stddev: stddev,
      minRating: averages.reduce(min),
      maxRating: averages.reduce(max),
    );
  }
}
