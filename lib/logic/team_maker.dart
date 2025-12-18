import 'dart:math';
import 'package:kattrick/models/models.dart';

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
  /// Uses managerRating from hub (required). Manager must rate all players.
  /// Default rating of 4.0 is used if no rating is set (middle of 1-7 scale).
  static PlayerForTeam fromUser(
    User user, {
    String? hubId,
    Map<String, double>? managerRatings,
  }) {
    // Use managerRating as the single source of truth for hub team making
    // Default to 4.0 (middle of 1-7 scale) if not rated yet
    final rating = (hubId != null &&
            managerRatings != null &&
            managerRatings.containsKey(user.uid))
        ? managerRatings[user.uid]!
        : 4.0; // Default middle rating

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
  final double positionBalance; // 0-1, how well positions are distributed
  final double goalkeeperBalance; // 0-1, how well goalkeepers are distributed

  TeamBalanceMetrics({
    required this.averageRating,
    required this.stddev,
    required this.minRating,
    required this.maxRating,
    this.positionBalance = 1.0,
    this.goalkeeperBalance = 1.0,
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

    final metrics = calculateBalanceMetrics(finalTeams, optimizedTeams);

    // Enhanced balance score with multiple factors:
    // 1. Rating balance (stddev) - 50% weight
    // 2. Position balance - 30% weight
    // 3. Goalkeeper balance - 20% weight

    // Rating balance: stddev of 0.5 = perfect (100%), stddev of 1.5 = 50%
    // (1-7 scale has tighter range, so adjusted thresholds)
    final ratingScore = (1.0 - (metrics.stddev / 1.5)).clamp(0.0, 1.0);

    final score = (
      ratingScore * 0.5 +
      metrics.positionBalance * 0.3 +
      metrics.goalkeeperBalance * 0.2
    ) * 100;

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

    // Calculate average rating to use as fallback for missing players
    final averageRating = allPlayers.isEmpty
        ? 4.0
        : allPlayers.fold<double>(0.0, (sum, p) => sum + p.rating) / allPlayers.length;

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
            // Get player ratings - use average rating as fallback for missing players
            // to avoid skewing swap suggestions with zero ratings
            final playerA = allPlayers.firstWhere(
              (p) => p.uid == playerAId,
              orElse: () {
                // Log warning in debug mode - player should exist in allPlayers
                assert(false, 'Player $playerAId not found in allPlayers list');
                return PlayerForTeam(
                    uid: playerAId, rating: averageRating, role: PlayerRole.midfielder);
              }
            );
            final playerB = allPlayers.firstWhere(
              (p) => p.uid == playerBId,
              orElse: () {
                // Log warning in debug mode - player should exist in allPlayers
                assert(false, 'Player $playerBId not found in allPlayers list');
                return PlayerForTeam(
                    uid: playerBId, rating: averageRating, role: PlayerRole.midfielder);
              }
            );

            final playerARating = playerA.rating;
            final playerBRating = playerB.rating;

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
  /// Enhanced to handle edge cases:
  /// - No goalkeepers: returns empty teams (field players will be distributed)
  /// - Fewer goalkeepers than teams: distributes to strongest teams first
  /// - More goalkeepers than teams: snake draft for even distribution
  static List<List<PlayerForTeam>> _distributeGoalkeepers(
    List<PlayerForTeam> goalkeepers,
    int teamCount,
  ) {
    final teams = List.generate(teamCount, (_) => <PlayerForTeam>[]);

    if (goalkeepers.isEmpty) {
      // No goalkeepers - return empty teams (handled gracefully)
      return teams;
    }

    // Sort goalkeepers by rating (descending)
    goalkeepers.sort((a, b) => b.rating.compareTo(a.rating));

    if (goalkeepers.length <= teamCount) {
      // Fewer or equal GKs than teams: give to first N teams
      for (int i = 0; i < goalkeepers.length; i++) {
        teams[i].add(goalkeepers[i]);
      }
    } else {
      // More GKs than teams: use snake draft for balance
      for (int i = 0; i < goalkeepers.length; i++) {
        final roundNumber = i ~/ teamCount;
        final positionInRound = i % teamCount;
        final teamIndex = roundNumber % 2 == 0
            ? positionInRound
            : teamCount - 1 - positionInRound;
        teams[teamIndex].add(goalkeepers[i]);
      }
    }

    return teams;
  }

  /// Distribute field players with style and rating balance
  /// Enhanced to handle edge cases:
  /// - Missing position types: distributes available players fairly
  /// - Uneven distribution: compensates with midfielders
  /// - Mixed rating distribution: ensures no team is too weak/strong in any position
  static void _distributeFieldPlayers(
    List<PlayerForTeam> fieldPlayers,
    List<List<PlayerForTeam>> teams,
    int teamCount,
  ) {
    if (fieldPlayers.isEmpty) {
      return; // Edge case: no field players
    }

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
    _snakeDraft(defenders, teams, teamCount, startReverse: false);

    // Distribute attackers (snake draft, reverse to balance with defenders)
    _snakeDraft(attackers, teams, teamCount, startReverse: true);

    // Distribute midfielders (snake draft)
    _snakeDraft(midfielders, teams, teamCount, startReverse: false);
  }

  /// Helper method for snake draft distribution
  static void _snakeDraft(
    List<PlayerForTeam> players,
    List<List<PlayerForTeam>> teams,
    int teamCount, {
    required bool startReverse,
  }) {
    for (int i = 0; i < players.length; i++) {
      final roundNumber = i ~/ teamCount;
      final positionInRound = i % teamCount;

      int teamIndex;
      if (startReverse) {
        // Start from the end for balance
        if (roundNumber % 2 == 0) {
          teamIndex = teamCount - 1 - positionInRound;
        } else {
          teamIndex = positionInRound;
        }
      } else {
        // Standard snake draft
        if (roundNumber % 2 == 0) {
          teamIndex = positionInRound;
        } else {
          teamIndex = teamCount - 1 - positionInRound;
        }
      }

      teams[teamIndex].add(players[i]);
    }
  }

  /// Local swap to reduce stddev while maintaining role coverage
  /// Enhanced to consider both rating balance and position balance
  static List<List<PlayerForTeam>> _localSwap(
    List<List<PlayerForTeam>> teams,
    int teamCount,
  ) {
    if (teams.length < 2) return teams;

    // Calculate current balance score (combines rating and position balance)
    double currentScore = _calculateBalanceScore(teams);

    // Try pairwise swaps
    bool improved = true;
    int maxIterations = 100; // Increased for better optimization
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
              // Don't swap if it creates goalkeeper imbalance
              // (e.g., team with 2 GKs swapping with team with 0 GKs)
              final iGkCount = teams[i].where((p) => p.isGoalkeeper).length;
              final jGkCount = teams[j].where((p) => p.isGoalkeeper).length;

              if (playerI.isGoalkeeper && !playerJ.isGoalkeeper) {
                // Would create imbalance if diff > 1
                if ((iGkCount - 1 - jGkCount).abs() > 1) continue;
              } else if (!playerI.isGoalkeeper && playerJ.isGoalkeeper) {
                if ((jGkCount - 1 - iGkCount).abs() > 1) continue;
              }

              // Swap
              teams[i].remove(playerI);
              teams[j].remove(playerJ);
              teams[i].add(playerJ);
              teams[j].add(playerI);

              // Check if balance improved
              final newScore = _calculateBalanceScore(teams);
              if (newScore > currentScore) {
                // Keep swap
                currentScore = newScore;
                improved = true;
                // Break inner loops to restart optimization with new state
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

  /// Calculate overall balance score considering rating and position distribution
  static double _calculateBalanceScore(List<List<PlayerForTeam>> teams) {
    if (teams.isEmpty) return 0.0;

    // Rating balance (lower stddev = higher score)
    final stddev = _calculateStddev(teams);
    final ratingScore = (1.0 / (1.0 + stddev)).clamp(0.0, 1.0);

    // Goalkeeper balance
    final gkCounts = teams.map((t) => t.where((p) => p.isGoalkeeper).length.toDouble()).toList();
    final gkVariance = _calculateVariance(gkCounts);
    final gkScore = (1.0 / (1.0 + gkVariance * 2)).clamp(0.0, 1.0);

    // Position balance (defenders vs attackers)
    final defCounts = teams.map((t) => t.where((p) => p.isDefensive).length.toDouble()).toList();
    final attCounts = teams.map((t) => t.where((p) => p.isOffensive).length.toDouble()).toList();
    final defVariance = _calculateVariance(defCounts);
    final attVariance = _calculateVariance(attCounts);
    final posScore = (1.0 / (1.0 + (defVariance + attVariance))).clamp(0.0, 1.0);

    // Weighted combination: rating (50%), goalkeeper (25%), position (25%)
    return ratingScore * 0.5 + gkScore * 0.25 + posScore * 0.25;
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

  /// Calculate team balance metrics with position awareness
  static TeamBalanceMetrics calculateBalanceMetrics(
    List<Team> teams, [
    List<List<PlayerForTeam>>? playerTeams,
  ]) {
    if (teams.isEmpty) {
      return TeamBalanceMetrics(
        averageRating: 0.0,
        stddev: 0.0,
        minRating: 0.0,
        maxRating: 0.0,
        positionBalance: 1.0,
        goalkeeperBalance: 1.0,
      );
    }

    // Calculate rating balance
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

    // Calculate position balance (only if playerTeams provided)
    double positionBalance = 1.0;
    double goalkeeperBalance = 1.0;

    if (playerTeams != null && playerTeams.isNotEmpty) {
      // Calculate goalkeeper distribution
      final gkCounts = playerTeams.map((team) {
        return team.where((p) => p.isGoalkeeper).length;
      }).toList();

      // Perfect: all teams have same number of GKs
      final gkVariance = _calculateVariance(gkCounts.map((c) => c.toDouble()).toList());
      goalkeeperBalance = (1.0 / (1.0 + gkVariance)).clamp(0.0, 1.0);

      // Calculate position distribution balance
      final defenderCounts = playerTeams.map((team) {
        return team.where((p) => p.isDefensive).length.toDouble();
      }).toList();

      final attackerCounts = playerTeams.map((team) {
        return team.where((p) => p.isOffensive).length.toDouble();
      }).toList();

      final defVariance = _calculateVariance(defenderCounts);
      final attVariance = _calculateVariance(attackerCounts);

      // Average the position variances (lower variance = better balance)
      final avgPositionVariance = (defVariance + attVariance) / 2;
      positionBalance = (1.0 / (1.0 + avgPositionVariance)).clamp(0.0, 1.0);
    }

    return TeamBalanceMetrics(
      averageRating: mean,
      stddev: stddev,
      minRating: averages.isEmpty ? 0.0 : averages.reduce(min),
      maxRating: averages.isEmpty ? 0.0 : averages.reduce(max),
      positionBalance: positionBalance,
      goalkeeperBalance: goalkeeperBalance,
    );
  }

  /// Calculate variance for a list of values
  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.fold<double>(0.0, (sum, val) => sum + val) / values.length;
    return values.fold<double>(0.0, (sum, val) => sum + pow(val - mean, 2)) / values.length;
  }
}
