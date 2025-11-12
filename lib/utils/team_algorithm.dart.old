import 'dart:math';
import 'package:kickabout/models/player.dart';
import 'package:kickabout/models/game.dart';

class TeamAlgorithm {
  static Map<String, Team> createBalancedTeams(List<Player> players, {int teamCount = 2}) {
    if (players.length < teamCount) {
      throw ArgumentError('Not enough players for $teamCount teams');
    }
    
    // Sort players by rank score in descending order
    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) => b.currentRankScore.compareTo(a.currentRankScore));
    
    // Initialize teams
    final teams = <String, List<Player>>{};
    final teamNames = ['Team A', 'Team B', 'Team C', 'Team D'];
    
    for (int i = 0; i < teamCount; i++) {
      teams[teamNames[i]] = [];
    }
    
    // Snake draft allocation
    for (int i = 0; i < sortedPlayers.length; i++) {
      final roundNumber = i ~/ teamCount;
      final positionInRound = i % teamCount;
      
      String teamKey;
      if (roundNumber % 2 == 0) {
        // Even round: normal order (0, 1, 2, ...)
        teamKey = teamNames[positionInRound];
      } else {
        // Odd round: reverse order (2, 1, 0, ...)
        teamKey = teamNames[teamCount - 1 - positionInRound];
      }
      
      teams[teamKey]!.add(sortedPlayers[i]);
    }
    
    // Convert to Team objects and calculate scores
    final result = <String, Team>{};
    teams.forEach((teamName, playerList) {
      final totalScore = playerList.fold<double>(
        0.0, 
        (sum, player) => sum + player.currentRankScore
      );
      
      result[teamName] = Team(
        name: teamName,
        playerIds: playerList.map((p) => p.id).toList(),
        totalScore: totalScore,
      );
    });
    
    return result;
  }
  
  static bool areTeamsBalanced(Map<String, Team> teams, {double threshold = 0.1}) {
    if (teams.length < 2) return true;
    
    final scores = teams.values.map((t) => t.totalScore).toList();
    final maxScore = scores.reduce(max);
    final minScore = scores.reduce(min);
    final averageScore = scores.reduce((a, b) => a + b) / scores.length;
    
    final maxDifference = max(maxScore - averageScore, averageScore - minScore);
    final thresholdValue = averageScore * threshold;
    
    return maxDifference <= thresholdValue;
  }
  
  static Map<String, double> getTeamBalanceAnalysis(Map<String, Team> teams) {
    if (teams.isEmpty) return {};
    
    final scores = teams.values.map((t) => t.totalScore).toList();
    final maxScore = scores.reduce(max);
    final minScore = scores.reduce(min);
    final averageScore = scores.reduce((a, b) => a + b) / scores.length;
    
    return {
      'maxScore': maxScore,
      'minScore': minScore,
      'averageScore': averageScore,
      'difference': maxScore - minScore,
      'balancePercentage': ((averageScore - (maxScore - minScore) / 2) / averageScore).clamp(0.0, 1.0),
    };
  }
}