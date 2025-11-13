import 'dart:math';
import 'package:kickadoor/models/player.dart';
import 'package:kickadoor/models/player_stats.dart';
import 'package:kickadoor/models/game.dart';

class RankingService {
  
  /// Calculate enhanced player ranking with position-specific weights, form, and consistency
  static double calculateEnhancedRanking(
    Player player,
    List<PlayerStats> playerGameStats,
    List<Game> recentGames,
  ) {
    if (playerGameStats.isEmpty) return 5.0;

    // Sort stats by game date (most recent first)
    final sortedStats = List<PlayerStats>.from(playerGameStats)
      ..sort((a, b) {
        final aDate = a.gameDate ?? DateTime.now();
        final bDate = b.gameDate ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

    // Base score calculation with position-specific weighting
    final positionWeightedScores = sortedStats
        .map((stats) => stats.calculatePositionScore(player.attributes.preferredPosition))
        .toList();

    // Apply time decay (recent games weighted more heavily)
    final decayedScores = _applyTimeDecay(positionWeightedScores);
    
    // Calculate form factor (performance trend)
    final formFactor = _calculateFormFactor(positionWeightedScores);
    
    // Calculate consistency multiplier
    final consistencyMultiplier = _calculateConsistencyMultiplier(positionWeightedScores);
    
    // Calculate clutch performance bonus
    final clutchBonus = _calculateClutchBonus(sortedStats, recentGames);
    
    // Base ranking from weighted average
    final baseRanking = decayedScores.isNotEmpty 
        ? decayedScores.reduce((a, b) => a + b) / decayedScores.length
        : 5.0;
    
    // Apply all multipliers and bonuses
    final enhancedRanking = baseRanking * formFactor * consistencyMultiplier + clutchBonus;
    
    // Cap between 1.0 and 10.0
    return enhancedRanking.clamp(1.0, 10.0);
  }
  
  /// Apply time decay to give more weight to recent performances
  static List<double> _applyTimeDecay(List<double> scores) {
    if (scores.isEmpty) return [];
    
    final decayWeights = List.generate(scores.length, (index) {
      // Exponential decay: recent games get full weight, older games get less
      return pow(0.85, index).toDouble();
    });
    
    final weightedScores = <double>[];
    double totalWeight = 0.0;
    
    for (int i = 0; i < scores.length; i++) {
      final weight = decayWeights[i];
      weightedScores.add(scores[i] * weight);
      totalWeight += weight;
    }
    
    // Normalize by total weight
    return weightedScores.map((score) => score / totalWeight * scores.length).toList();
  }
  
  /// Calculate form factor based on recent performance trend
  static double _calculateFormFactor(List<double> scores) {
    if (scores.length < 3) return 1.0;
    
    // Compare last 3 games to previous 3 games
    final recentAverage = scores.take(3).reduce((a, b) => a + b) / 3;
    
    if (scores.length >= 6) {
      final previousAverage = scores.skip(3).take(3).reduce((a, b) => a + b) / 3;
      final improvement = (recentAverage - previousAverage) / previousAverage;
      
      // Form factor ranges from 0.9 to 1.2
      return (1.0 + improvement * 0.3).clamp(0.9, 1.2);
    } else {
      // Compare to overall average
      final overallAverage = scores.reduce((a, b) => a + b) / scores.length;
      final improvement = (recentAverage - overallAverage) / overallAverage;
      
      return (1.0 + improvement * 0.2).clamp(0.95, 1.15);
    }
  }
  
  /// Calculate consistency multiplier based on performance variance
  static double _calculateConsistencyMultiplier(List<double> scores) {
    if (scores.length < 3) return 1.0;
    
    final average = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores
        .map((score) => pow(score - average, 2))
        .reduce((a, b) => a + b) / scores.length;
    final standardDeviation = sqrt(variance);
    
    // Lower standard deviation = higher consistency = higher multiplier
    // Consistency multiplier ranges from 0.95 to 1.1
    final consistencyScore = 1.0 - (standardDeviation / average).clamp(0.0, 0.5);
    return (0.95 + consistencyScore * 0.15).clamp(0.95, 1.1);
  }
  
  /// Calculate clutch performance bonus for important games
  static double _calculateClutchBonus(List<PlayerStats> stats, List<Game> games) {
    // For now, simple implementation - could be enhanced with game importance
    if (stats.isEmpty) return 0.0;
    
    // Count high-performance games (score > 8.0)
    final clutchPerformances = stats.where((s) => s.complexScore > 8.0).length;
    final clutchRate = clutchPerformances / stats.length;
    
    // Bonus ranges from 0.0 to 0.3
    return clutchRate * 0.3;
  }
  
  /// Update player with new calculated values
  static Player updatePlayerWithEnhancedMetrics(
    Player player,
    List<PlayerStats> playerGameStats,
    List<Game> recentGames,
  ) {
    final newRankScore = calculateEnhancedRanking(player, playerGameStats, recentGames);
    
    // Calculate form factor for storage
    final scores = playerGameStats
        .map((stats) => stats.calculatePositionScore(player.attributes.preferredPosition))
        .toList();
    final formFactor = _calculateFormFactor(scores);
    final consistencyMultiplier = _calculateConsistencyMultiplier(scores);
    
    // Update ranking history
    final newRankingHistory = List<RankingEntry>.from(player.rankingHistory);
    newRankingHistory.insert(0, RankingEntry(
      date: DateTime.now(),
      rankScore: newRankScore,
    ));
    
    // Keep only last 20 entries
    if (newRankingHistory.length > 20) {
      newRankingHistory.removeRange(20, newRankingHistory.length);
    }
    
    return player.copyWith(
      currentRankScore: newRankScore,
      rankingHistory: newRankingHistory,
      gamesPlayed: playerGameStats.length,
      formFactor: formFactor,
      consistencyMultiplier: consistencyMultiplier,
    );
  }
  
  /// Get best and worst attributes for a player
  static Map<String, dynamic> getPlayerStrengthsWeaknesses(PlayerStats? latestStats) {
    if (latestStats == null) {
      return {'best': [], 'worst': []};
    }
    
    final attributes = latestStats.attributesList;
    final names = PlayerStats.attributeNames;
    
    final attributeMap = Map.fromIterables(names, attributes);
    final sorted = attributeMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'best': sorted.take(2).map((e) => e.key).toList(),
      'worst': sorted.reversed.take(2).map((e) => e.key).toList(),
    };
  }
  
  /// Calculate league averages for comparison
  static Map<String, double> calculateLeagueAverages(List<PlayerStats> allStats) {
    if (allStats.isEmpty) {
      return Map.fromIterables(
        PlayerStats.attributeNames,
        List.filled(PlayerStats.attributeNames.length, 5.0),
      );
    }
    
    final totals = List.filled(PlayerStats.attributeNames.length, 0.0);
    
    for (final stats in allStats) {
      final attributes = stats.attributesList;
      for (int i = 0; i < attributes.length; i++) {
        totals[i] += attributes[i];
      }
    }
    
    final averages = totals.map((total) => total / allStats.length).toList();
    return Map.fromIterables(PlayerStats.attributeNames, averages);
  }
}