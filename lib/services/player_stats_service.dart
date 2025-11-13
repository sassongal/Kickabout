import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kickadoor/models/player_stats.dart';

class PlayerStatsService {
  static const String _playerStatsKey = 'player_stats';
  
  Future<List<PlayerStats>> getAllPlayerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_playerStatsKey);
    
    if (statsJson == null) {
      // Return sample stats for demo
      return _getSamplePlayerStats();
    }
    
    final statsList = jsonDecode(statsJson) as List;
    return statsList.map((json) => PlayerStats.fromJson(json)).toList();
  }
  
  Future<List<PlayerStats>> getPlayerStats(String playerId) async {
    final allStats = await getAllPlayerStats();
    return allStats.where((stats) => stats.playerId == playerId).toList();
  }
  
  Future<PlayerStats?> getLatestPlayerStats(String playerId) async {
    final playerStats = await getPlayerStats(playerId);
    if (playerStats.isEmpty) return null;
    
    // Sort by game date (most recent first)
    playerStats.sort((a, b) {
      final aDate = a.gameDate ?? DateTime.now();
      final bDate = b.gameDate ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    
    return playerStats.first;
  }
  
  Future<void> savePlayerStats(List<PlayerStats> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = jsonEncode(stats.map((s) => s.toJson()).toList());
    await prefs.setString(_playerStatsKey, statsJson);
  }
  
  Future<void> addPlayerStats(PlayerStats stats) async {
    final allStats = await getAllPlayerStats();
    allStats.add(stats);
    await savePlayerStats(allStats);
  }
  
  Future<void> updatePlayerStats(PlayerStats updatedStats) async {
    final allStats = await getAllPlayerStats();
    final index = allStats.indexWhere((s) => 
        s.playerId == updatedStats.playerId && s.gameId == updatedStats.gameId);
    
    if (index != -1) {
      allStats[index] = updatedStats;
      await savePlayerStats(allStats);
    }
  }
  
  Future<Map<String, double>> getLeagueAverages() async {
    final allStats = await getAllPlayerStats();
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
  
  List<PlayerStats> _getSamplePlayerStats() {
    final random = Random(42); // Fixed seed for consistent demo data
    final now = DateTime.now();
    final players = ['1', '2', '3', '4', '5', '6'];
    final gameIds = ['game_1', 'game_2', 'game_3', 'game_4', 'game_5'];
    
    final stats = <PlayerStats>[];
    
    // Generate stats for each player across multiple games
    for (final playerId in players) {
      for (int gameIndex = 0; gameIndex < gameIds.length; gameIndex++) {
        final gameId = gameIds[gameIndex];
        final gameDate = now.subtract(Duration(days: gameIndex * 7 + random.nextInt(3)));
        
        // Create realistic stats based on player ID and position
        final playerStats = _generateRealisticStats(playerId, gameId, gameDate, random);
        stats.add(playerStats);
      }
    }
    
    return stats;
  }
  
  PlayerStats _generateRealisticStats(String playerId, String gameId, DateTime gameDate, Random random) {
    // Base stats influenced by player type
    final Map<String, List<double>> playerProfiles = {
      '1': [6.5, 7.0, 8.5, 8.0, 7.5, 7.0, 7.5, 6.8], // Alex - Forward
      '2': [7.0, 8.5, 7.0, 7.5, 7.0, 8.0, 8.5, 8.2], // Maria - Midfielder
      '3': [8.5, 7.0, 5.5, 6.0, 8.0, 7.5, 8.0, 7.8], // David - Defender
      '4': [8.0, 6.5, 4.0, 5.0, 8.5, 7.5, 7.0, 8.0], // Emma - Goalkeeper
      '5': [5.0, 6.0, 8.0, 9.0, 7.0, 6.0, 6.5, 6.2], // Carlos - Forward
      '6': [6.5, 8.0, 6.5, 7.0, 6.5, 7.5, 8.0, 7.5], // Sarah - Midfielder
    };
    
    final baseStats = playerProfiles[playerId] ?? List.filled(8, 6.0);
    
    // Add some random variation (±1.5 points)
    final variableStats = baseStats.map((base) {
      final variation = (random.nextDouble() - 0.5) * 3.0;
      return (base + variation).clamp(1.0, 10.0);
    }).toList();
    
    return PlayerStats(
      playerId: playerId,
      gameId: gameId,
      defense: variableStats[0],
      passing: variableStats[1],
      shooting: variableStats[2],
      dribbling: variableStats[3],
      physical: variableStats[4],
      leadership: variableStats[5],
      teamPlay: variableStats[6],
      consistency: variableStats[7],
      gameDate: gameDate,
      isVerified: random.nextBool(),
    );
  }
}