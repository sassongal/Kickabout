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

  /// Convert to Firestore string format (capitalized, e.g., 'Goalkeeper', 'Defender')
  String toFirestoreString() {
    return switch (this) {
      PlayerRole.goalkeeper => 'Goalkeeper',
      PlayerRole.defender => 'Defender',
      PlayerRole.midfielder => 'Midfielder',
      PlayerRole.attacker => 'Attacker',
    };
  }

  /// Get Hebrew label for UI display
  String get hebrewLabel {
    return switch (this) {
      PlayerRole.goalkeeper => 'שוער',
      PlayerRole.defender => 'הגנה',
      PlayerRole.midfielder => 'קשר',
      PlayerRole.attacker => 'התקפה',
    };
  }

  /// Create from Firestore string (capitalized format)
  static PlayerRole fromFirestoreString(String? value) {
    if (value == null) return PlayerRole.midfielder;
    return fromPosition(value); // Reuse existing logic
  }

  /// Get positions for Profile Wizard (includes all positions)
  static List<PlayerRole> get wizardPositions => [
        PlayerRole.goalkeeper,
        PlayerRole.defender,
        PlayerRole.midfielder,
        PlayerRole.attacker,
      ];
}

/// Minimal player data for team making
class PlayerForTeam {
  final String uid;
  final double rating;
  final PlayerRole role;

  // Physical data (optional)
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final double physicalScore; // Position-aware physical score

  PlayerForTeam({
    required this.uid,
    required this.rating,
    required this.role,
    this.heightCm,
    this.weightKg,
  })  : bmi = _calculateBMI(heightCm, weightKg),
        physicalScore = _calculatePhysicalScore(role, heightCm, weightKg);

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
        : 4.0 +
            (Random().nextDouble() *
                0.1); // Add tiny jitter to prevent identical sorting

    return PlayerForTeam(
      uid: user.uid,
      rating: rating,
      role: PlayerRole.fromPosition(user.preferredPosition),
      heightCm: user.heightCm,
      weightKg: user.weightKg,
    );
  }

  /// Check if player is a goalkeeper
  bool get isGoalkeeper => role == PlayerRole.goalkeeper;

  /// Check if player is defensive
  bool get isDefensive => role == PlayerRole.defender;

  /// Check if player is offensive
  bool get isOffensive => role == PlayerRole.attacker;

  /// Calculate BMI from height and weight
  static double? _calculateBMI(double? height, double? weight) {
    if (height == null || weight == null) return null;
    final heightM = height / 100.0;
    return weight / (heightM * heightM);
  }

  /// Calculate position-aware physical score
  static double _calculatePhysicalScore(
    PlayerRole role,
    double? height,
    double? weight,
  ) {
    // Use defaults if data is missing
    final h = height ?? _getDefaultHeight(role);
    final w = weight ?? _getDefaultWeight(role);
    final bmi = w / ((h / 100.0) * (h / 100.0));

    return switch (role) {
      // Goalkeepers: Height is most important (60%), weight secondary (40%)
      // Ideal: 185cm, 80kg
      PlayerRole.goalkeeper => h * 0.6 + w * 0.4,

      // Defenders: Height and weight equally important (50%-50%)
      // Ideal: 180cm, 78kg
      PlayerRole.defender => h * 0.5 + w * 0.5,

      // Midfielders: Agility matters (lower BMI is better)
      // Ideal: 175cm, 70kg, BMI ~22-24
      PlayerRole.midfielder => () {
          final agilityBonus = (27.0 - bmi).clamp(0.0, 5.0);
          return h * 0.3 + w * 0.3 + agilityBonus * 10;
        }(),

      // Attackers: Mix of agility and height
      // Ideal: 177cm, 72kg, BMI ~23
      PlayerRole.attacker => () {
          final agilityBonus = (26.0 - bmi).clamp(0.0, 5.0);
          return h * 0.4 + w * 0.3 + agilityBonus * 10;
        }(),
    };
  }

  /// Default height by role (cm)
  static double _getDefaultHeight(PlayerRole role) {
    return switch (role) {
      PlayerRole.goalkeeper => 185.0,
      PlayerRole.defender => 180.0,
      PlayerRole.midfielder => 175.0,
      PlayerRole.attacker => 177.0,
    };
  }

  /// Default weight by role (kg)
  static double _getDefaultWeight(PlayerRole role) {
    return switch (role) {
      PlayerRole.goalkeeper => 80.0,
      PlayerRole.defender => 78.0,
      PlayerRole.midfielder => 70.0,
      PlayerRole.attacker => 72.0,
    };
  }
}

/// Team balance metrics
class TeamBalanceMetrics {
  final double averageRating;
  final double stddev;
  final double minRating;
  final double maxRating;
  final double positionBalance; // 0-1, how well positions are distributed
  final double goalkeeperBalance; // 0-1, how well goalkeepers are distributed

  // Physical metrics
  final double physicalBalance; // 0-1, how well physical attributes are balanced
  final double avgHeight; // Average height in cm
  final double avgWeight; // Average weight in kg
  final double avgBMI; // Average BMI
  final int playersWithPhysicalData; // Count of players with height/weight data
  final double physicalDataCoverage; // 0.0-1.0, percentage of players with data

  TeamBalanceMetrics({
    required this.averageRating,
    required this.stddev,
    required this.minRating,
    required this.maxRating,
    this.positionBalance = 1.0,
    this.goalkeeperBalance = 1.0,
    this.physicalBalance = 1.0,
    this.avgHeight = 0.0,
    this.avgWeight = 0.0,
    this.avgBMI = 0.0,
    this.playersWithPhysicalData = 0,
    this.physicalDataCoverage = 0.0,
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
  static const double _weightRating = 0.5;
  static const double _weightPosition = 0.3;
  static const double _weightGoalkeeper = 0.2;

  /// Create balanced teams using snake draft + local swap.
  /// Returns a record containing the list of teams and the balance score.
  static TeamCreationResult createBalancedTeams(
    List<PlayerForTeam> players, {
    required int teamCount,
    int? playersPerSide,
    int? seed,
  }) {
    if (players.length < teamCount) {
      throw ArgumentError('Not enough players for $teamCount teams');
    }
    if (playersPerSide != null && players.length < teamCount * playersPerSide) {
      throw ArgumentError(
        'Not enough players: need ${teamCount * playersPerSide}, have ${players.length}',
      );
    }

    // Derive a deterministic seed when none is provided so the same player set
    // yields repeatable teams (e.g., user reopens the screen)
    final effectiveSeed =
        seed ?? _deriveDeterministicSeed(players, teamCount, playersPerSide);
    final random = Random(effectiveSeed);

    // Separate goalkeepers and field players
    final goalkeepers = players.where((p) => p.isGoalkeeper).toList();
    final fieldPlayers = players.where((p) => !p.isGoalkeeper).toList();

    // Shuffle players to ensure variety between generations with same seed/state
    goalkeepers.shuffle(random);
    fieldPlayers.shuffle(random);

    // Distribute goalkeepers evenly
    final teams = _distributeGoalkeepers(goalkeepers, teamCount);
    // Distribute field players
    _distributeFieldPlayers(fieldPlayers, teams, teamCount, random);
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

    final score = (ratingScore * _weightRating +
            metrics.positionBalance * _weightPosition +
            metrics.goalkeeperBalance * _weightGoalkeeper) *
        100;

    lastBalanceScore = score;

    return TeamCreationResult(teams: finalTeams, balanceScore: score);
  }

  // Build a deterministic seed from player IDs/ratings and input parameters so
  // reshuffles with the same inputs are stable across sessions.
  static int _deriveDeterministicSeed(
    List<PlayerForTeam> players,
    int teamCount,
    int? playersPerSide,
  ) {
    final sorted = [...players]..sort((a, b) => a.uid.compareTo(b.uid));
    int hash = 17;
    for (final p in sorted) {
      for (final codeUnit in p.uid.codeUnits) {
        hash = (hash * 31 + codeUnit) & 0x7fffffff;
      }
      final ratingComponent = (p.rating * 1000).round();
      hash = (hash * 31 + ratingComponent) & 0x7fffffff;
      hash = (hash * 31 + p.role.index) & 0x7fffffff;
    }
    hash = (hash * 31 + teamCount) & 0x7fffffff;
    hash = (hash * 31 + (playersPerSide ?? 0)) & 0x7fffffff;
    return hash;
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
        : allPlayers.fold<double>(0.0, (sum, p) => sum + p.rating) /
            allPlayers.length;

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
            final playerA =
                allPlayers.firstWhere((p) => p.uid == playerAId, orElse: () {
              // Log warning in debug mode - player should exist in allPlayers
              assert(false, 'Player $playerAId not found in allPlayers list');
              return PlayerForTeam(
                  uid: playerAId,
                  rating: averageRating,
                  role: PlayerRole.midfielder);
            });
            final playerB =
                allPlayers.firstWhere((p) => p.uid == playerBId, orElse: () {
              // Log warning in debug mode - player should exist in allPlayers
              assert(false, 'Player $playerBId not found in allPlayers list');
              return PlayerForTeam(
                  uid: playerBId,
                  rating: averageRating,
                  role: PlayerRole.midfielder);
            });

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
    int teamCount, [
    Random? random,
  ]) {
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
  /// Improved to always fill the smallest teams first to ensure strict count balance
  static void _snakeDraft(
    List<PlayerForTeam> players,
    List<List<PlayerForTeam>> teams,
    int teamCount, {
    required bool startReverse,
  }) {
    if (players.isEmpty) return;

    for (int i = 0; i < players.length; i++) {
      // Find the indices of teams with the minimum number of players
      int minSize = teams.map((t) => t.length).reduce(min);
      List<int> candidateIndices = [];
      for (int tIdx = 0; tIdx < teamCount; tIdx++) {
        if (teams[tIdx].length == minSize) {
          candidateIndices.add(tIdx);
        }
      }

      // If all teams are equal size, use snake logic
      if (candidateIndices.length == teamCount) {
        final roundNumber = i ~/ teamCount;
        final positionInRound = i % teamCount;

        int teamIndex;
        if (startReverse) {
          if (roundNumber % 2 == 0) {
            teamIndex = teamCount - 1 - positionInRound;
          } else {
            teamIndex = positionInRound;
          }
        } else {
          if (roundNumber % 2 == 0) {
            teamIndex = positionInRound;
          } else {
            teamIndex = teamCount - 1 - positionInRound;
          }
        }
        teams[teamIndex].add(players[i]);
      } else {
        // Find the "best" team among candidates based on snake order
        final roundNumber = i ~/ teamCount;
        final positionInRound = i % teamCount;

        int targetIndex;
        if (startReverse) {
          if (roundNumber % 2 == 0) {
            targetIndex = teamCount - 1 - positionInRound;
          } else {
            targetIndex = positionInRound;
          }
        } else {
          if (roundNumber % 2 == 0) {
            targetIndex = positionInRound;
          } else {
            targetIndex = teamCount - 1 - positionInRound;
          }
        }

        // Find the candidate closest to targetIndex
        int bestCandidate = candidateIndices.first;
        int minDistance = (bestCandidate - targetIndex).abs();

        for (final cand in candidateIndices) {
          final dist = (cand - targetIndex).abs();
          if (dist < minDistance) {
            minDistance = dist;
            bestCandidate = cand;
          }
        }

        teams[bestCandidate].add(players[i]);
      }
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
    final visitedStates = <String>{_stateSignature(teams)};

    // Try pairwise swaps
    bool improved = true;
    const int maxIterations = 20; // Keep mobile-friendly upper bound
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

              final stateKey = _stateSignature(teams);
              if (visitedStates.contains(stateKey)) {
                // Revert to avoid cycling between identical states
                teams[i].remove(playerJ);
                teams[j].remove(playerI);
                teams[i].add(playerI);
                teams[j].add(playerJ);
                continue;
              }

              // Check if balance improved
              final newScore = _calculateBalanceScore(teams);
              if (newScore > currentScore) {
                // Keep swap
                currentScore = newScore;
                improved = true;
                visitedStates.add(stateKey);
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

  // Signature for the current team composition to detect cycles in swaps
  static String _stateSignature(List<List<PlayerForTeam>> teams) {
    final buffer = StringBuffer();
    for (int t = 0; t < teams.length; t++) {
      final ids = teams[t].map((p) => p.uid).toList()..sort();
      buffer.write(ids.join(','));
      if (t < teams.length - 1) buffer.write('||');
    }
    return buffer.toString();
  }

  /// Calculate physical balance across teams
  static double _calculatePhysicalBalance(List<List<PlayerForTeam>> teams) {
    // Check data coverage
    final allPlayers = teams.expand((t) => t).toList();
    final playersWithData = allPlayers
        .where((p) => p.heightCm != null && p.weightKg != null)
        .length;
    final coverage = allPlayers.isEmpty ? 0.0 : playersWithData / allPlayers.length;

    // If less than 50% have data, reduce impact by returning perfect score
    if (coverage < 0.5) {
      return 1.0;
    }

    // Calculate average physical score for each team
    final teamPhysicalScores = teams.map((team) {
      if (team.isEmpty) return 0.0;
      final avgScore =
          team.fold<double>(0.0, (sum, p) => sum + p.physicalScore) /
              team.length;
      return avgScore;
    }).toList();

    // Calculate variance (lower variance = better balance)
    final variance = _calculateVariance(teamPhysicalScores);
    final crossTeamBalance = (1.0 / (1.0 + variance / 10.0)).clamp(0.0, 1.0);

    // Also check for diversity within each team (not all same height)
    final teamHeightVariances = teams.map((team) {
      final heights =
          team.where((p) => p.heightCm != null).map((p) => p.heightCm!).toList();
      if (heights.length < 2) return 5.0; // Default variance
      final heightTeams = heights.map((h) => [PlayerForTeam(
        uid: '',
        rating: h,
        role: PlayerRole.midfielder,
      )]).toList();
      return _calculateStddev(heightTeams);
    }).toList();

    final avgHeightVar = teamHeightVariances.isEmpty
        ? 5.0
        : teamHeightVariances.reduce((a, b) => a + b) /
            teamHeightVariances.length;

    // Diversity within team is good (but not too much)
    final withinTeamDiversity = (avgHeightVar / 10.0).clamp(0.3, 1.0);

    // Combine: 70% cross-team balance, 30% within-team diversity
    return crossTeamBalance * 0.7 + withinTeamDiversity * 0.3;
  }

  /// Calculate overall balance score considering rating, position, and physical attributes
  static double _calculateBalanceScore(List<List<PlayerForTeam>> teams) {
    if (teams.isEmpty) return 0.0;

    // 1. Rating balance (lower stddev = higher score) - 40%
    final stddev = _calculateStddev(teams);
    final ratingScore = (1.0 / (1.0 + stddev)).clamp(0.0, 1.0);

    // 2. Goalkeeper balance - 15%
    final gkCounts = teams
        .map((t) => t.where((p) => p.isGoalkeeper).length.toDouble())
        .toList();
    final gkVariance = _calculateVariance(gkCounts);
    final gkScore = (1.0 / (1.0 + gkVariance * 2)).clamp(0.0, 1.0);

    // 3. Position balance (defenders vs attackers) - 25%
    final defCounts = teams
        .map((t) => t.where((p) => p.isDefensive).length.toDouble())
        .toList();
    final attCounts = teams
        .map((t) => t.where((p) => p.isOffensive).length.toDouble())
        .toList();
    final defVariance = _calculateVariance(defCounts);
    final attVariance = _calculateVariance(attCounts);
    final posScore =
        (1.0 / (1.0 + (defVariance + attVariance))).clamp(0.0, 1.0);

    // 4. Physical balance - 20%
    final physicalScore = _calculatePhysicalBalance(teams);

    // Weighted combination: rating (40%), position (25%), GK (15%), physical (20%)
    return ratingScore * 0.40 +
        posScore * 0.25 +
        gkScore * 0.15 +
        physicalScore * 0.20;
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

    // Physical metrics
    double physicalBalance = 1.0;
    double avgHeight = 0.0;
    double avgWeight = 0.0;
    double avgBMI = 0.0;
    int playersWithData = 0;
    double coverage = 0.0;

    if (playerTeams != null && playerTeams.isNotEmpty) {
      // Calculate goalkeeper distribution
      final gkCounts = playerTeams.map((team) {
        return team.where((p) => p.isGoalkeeper).length;
      }).toList();

      // Perfect: all teams have same number of GKs
      final gkVariance =
          _calculateVariance(gkCounts.map((c) => c.toDouble()).toList());
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

      // Calculate physical metrics
      final allPlayers = playerTeams.expand((t) => t).toList();
      final playersWithPhysical = allPlayers
          .where((p) => p.heightCm != null && p.weightKg != null)
          .toList();

      playersWithData = playersWithPhysical.length;
      coverage = allPlayers.isEmpty ? 0.0 : playersWithData / allPlayers.length;

      if (playersWithPhysical.isNotEmpty) {
        avgHeight = playersWithPhysical
                .fold<double>(0.0, (sum, p) => sum + p.heightCm!) /
            playersWithData;
        avgWeight = playersWithPhysical
                .fold<double>(0.0, (sum, p) => sum + p.weightKg!) /
            playersWithData;
        avgBMI = playersWithPhysical.fold<double>(0.0, (sum, p) => sum + p.bmi!) /
            playersWithData;

        physicalBalance = _calculatePhysicalBalance(playerTeams);
      }
    }

    return TeamBalanceMetrics(
      averageRating: mean,
      stddev: stddev,
      minRating: averages.isEmpty ? 0.0 : averages.reduce(min),
      maxRating: averages.isEmpty ? 0.0 : averages.reduce(max),
      positionBalance: positionBalance,
      goalkeeperBalance: goalkeeperBalance,
      physicalBalance: physicalBalance,
      avgHeight: avgHeight,
      avgWeight: avgWeight,
      avgBMI: avgBMI,
      playersWithPhysicalData: playersWithData,
      physicalDataCoverage: coverage,
    );
  }

  /// Calculate variance for a list of values
  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean =
        values.fold<double>(0.0, (sum, val) => sum + val) / values.length;
    return values.fold<double>(0.0, (sum, val) => sum + pow(val - mean, 2)) /
        values.length;
  }

  /// Validate teams before starting a game/event
  /// Returns a list of validation errors (empty if valid)
  static List<String> validateTeamsForGameStart(
    List<Team> teams,
    int teamCount,
    int minPlayersPerTeam,
  ) {
    final errors = <String>[];

    // Check if teams exist
    if (teams.isEmpty) {
      errors.add('לא נוצרו כוחות. אנא צור כוחות לפני התחלת המשחק.');
      return errors;
    }

    // Check if we have the correct number of teams
    if (teams.length != teamCount) {
      errors.add(
          'מספר הכוחות ($teamCount) לא תואם למספר הכוחות שנוצרו (${teams.length}).');
    }

    // Check minimum players per team
    for (int i = 0; i < teams.length; i++) {
      final team = teams[i];
      if (team.playerIds.isEmpty) {
        errors.add('כוח ${team.name} ריק. כל כוח חייב לכלול לפחות שחקן אחד.');
      } else if (team.playerIds.length < minPlayersPerTeam) {
        errors.add(
            'כוח ${team.name} כולל רק ${team.playerIds.length} שחקנים. נדרשים לפחות $minPlayersPerTeam שחקנים לכוח.');
      }
    }

    // Check for duplicate players across teams
    final allPlayerIds = <String>[];
    for (final team in teams) {
      for (final playerId in team.playerIds) {
        if (allPlayerIds.contains(playerId)) {
          errors.add('השחקן $playerId מופיע ביותר מכוח אחד.');
        }
        allPlayerIds.add(playerId);
      }
    }

    return errors;
  }
}
