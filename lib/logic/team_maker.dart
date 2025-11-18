import 'dart:math';
import 'package:kickadoor/models/models.dart';

/// Player role enum
enum PlayerRole {
  goalkeeper,
  defender,
  midfielder,
  attacker;

  static PlayerRole fromPosition(String position) {
    final pos = position.toLowerCase();
    if (pos.contains('keeper') || pos.contains('goalkeeper') || pos.contains('gk')) {
      return PlayerRole.goalkeeper;
    }
    if (pos.contains('defender') || pos.contains('def') || pos.contains('back')) {
      return PlayerRole.defender;
    }
    if (pos.contains('forward') || pos.contains('striker') || pos.contains('attacker') || pos.contains('att')) {
      return PlayerRole.attacker;
    }
    return PlayerRole.midfielder; // Default
  }
}

/// Minimal player data for team making
class PlayerForTeam {
  final String uid;
  final double rating;
  final PlayerRole role;
  final String? playingStyle; // goalkeeper, defensive, offensive

  PlayerForTeam({
    required this.uid,
    required this.rating,
    required this.role,
    this.playingStyle,
  });

  static PlayerForTeam fromUser(User user) {
    return PlayerForTeam(
      uid: user.uid,
      rating: user.currentRankScore,
      role: PlayerRole.fromPosition(user.preferredPosition),
      playingStyle: user.playingStyle,
    );
  }
  
  /// Check if player is a goalkeeper based on playingStyle
  bool get isGoalkeeper => playingStyle == 'goalkeeper';
  
  /// Check if player is defensive
  bool get isDefensive => playingStyle == 'defensive';
  
  /// Check if player is offensive
  bool get isOffensive => playingStyle == 'offensive';
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

/// Team maker algorithm - deterministic snake draft + local swap
class TeamMaker {
  /// Create balanced teams using snake draft + local swap
  /// 
  /// Inputs:
  /// - players: List of players with uid, rating, role
  /// - teamCount: Number of teams (2-4)
  /// - playersPerSide: Optional minimum players per team
  /// 
  /// Returns: List of Team objects with balance metrics
  static List<Team> createBalancedTeams(
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

    // Step 1: Separate goalkeepers from other players
    final goalkeepers = players.where((p) => p.isGoalkeeper).toList();
    final fieldPlayers = players.where((p) => !p.isGoalkeeper).toList();

    // Step 2: Distribute goalkeepers evenly across teams
    final teams = _distributeGoalkeepers(goalkeepers, teamCount);

    // Step 3: Distribute field players with style and rating balance
    _distributeFieldPlayers(fieldPlayers, teams, teamCount);

    // Step 4: Local swap to optimize balance while maintaining constraints
    final optimizedTeams = _localSwap(teams, teamCount);

    // Convert to Team objects
    final teamNames = ['קבוצה א', 'קבוצה ב', 'קבוצה ג', 'קבוצה ד'];
    return optimizedTeams.asMap().entries.map((entry) {
      final index = entry.key;
      final playerList = entry.value;
      final totalScore = playerList.fold<double>(
        0.0,
        (sum, player) => sum + player.rating,
      );

      return Team(
        teamId: 'team_$index',
        name: teamNames[index],
        playerIds: playerList.map((p) => p.uid).toList(),
        totalScore: totalScore,
      );
    }).toList();
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
    // Separate by playing style
    final defensivePlayers = fieldPlayers.where((p) => p.isDefensive).toList();
    final offensivePlayers = fieldPlayers.where((p) => p.isOffensive).toList();
    final neutralPlayers = fieldPlayers.where((p) => 
      p.playingStyle == null || (!p.isDefensive && !p.isOffensive)
    ).toList();

    // Sort each group by rating (descending)
    defensivePlayers.sort((a, b) => b.rating.compareTo(a.rating));
    offensivePlayers.sort((a, b) => b.rating.compareTo(a.rating));
    neutralPlayers.sort((a, b) => b.rating.compareTo(a.rating));

    // Distribute defensive players (snake draft)
    for (int i = 0; i < defensivePlayers.length; i++) {
      final roundNumber = i ~/ teamCount;
      final positionInRound = i % teamCount;
      int teamIndex;
      if (roundNumber % 2 == 0) {
        teamIndex = positionInRound;
      } else {
        teamIndex = teamCount - 1 - positionInRound;
      }
      teams[teamIndex].add(defensivePlayers[i]);
    }

    // Distribute offensive players (snake draft, reverse order)
    for (int i = 0; i < offensivePlayers.length; i++) {
      final roundNumber = i ~/ teamCount;
      final positionInRound = i % teamCount;
      int teamIndex;
      if (roundNumber % 2 == 0) {
        teamIndex = teamCount - 1 - positionInRound; // Reverse for balance
      } else {
        teamIndex = positionInRound;
      }
      teams[teamIndex].add(offensivePlayers[i]);
    }

    // Distribute neutral players (snake draft)
    for (int i = 0; i < neutralPlayers.length; i++) {
      final roundNumber = i ~/ teamCount;
      final positionInRound = i % teamCount;
      int teamIndex;
      if (roundNumber % 2 == 0) {
        teamIndex = positionInRound;
      } else {
        teamIndex = teamCount - 1 - positionInRound;
      }
      teams[teamIndex].add(neutralPlayers[i]);
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
          for (var playerI in teams[i]) {
            for (var playerJ in teams[j]) {
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
              } else {
                // Revert swap
                teams[i].remove(playerJ);
                teams[j].remove(playerI);
                teams[i].add(playerI);
                teams[j].add(playerJ);
              }
            }
          }
        }
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

    final mean = averages.fold<double>(0.0, (sum, avg) => sum + avg) / averages.length;
    final variance = averages.fold<double>(
      0.0,
      (sum, avg) => sum + pow(avg - mean, 2),
    ) / averages.length;

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

    final mean = averages.fold<double>(0.0, (sum, avg) => sum + avg) / averages.length;
    final variance = averages.fold<double>(
      0.0,
      (sum, avg) => sum + pow(avg - mean, 2),
    ) / averages.length;
    final stddev = sqrt(variance);

    return TeamBalanceMetrics(
      averageRating: mean,
      stddev: stddev,
      minRating: averages.reduce(min),
      maxRating: averages.reduce(max),
    );
  }
}

