import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kattrick/features/profile/domain/models/player.dart';

class PlayerService {
  static const String _playersKey = 'players';
  
  Future<List<Player>> getPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final playersJson = prefs.getString(_playersKey);
    
    if (playersJson == null) {
      // Return sample players for demo
      return _getSamplePlayers();
    }
    
    final playersList = jsonDecode(playersJson) as List;
    return playersList.map((json) => Player.fromJson(json)).toList();
  }
  
  Future<void> savePlayers(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    final playersJson = jsonEncode(players.map((p) => p.toJson()).toList());
    await prefs.setString(_playersKey, playersJson);
  }
  
  Future<void> addPlayer(Player player) async {
    final players = await getPlayers();
    players.add(player);
    await savePlayers(players);
  }
  
  Future<void> updatePlayer(Player updatedPlayer) async {
    final players = await getPlayers();
    final index = players.indexWhere((p) => p.id == updatedPlayer.id);
    if (index != -1) {
      players[index] = updatedPlayer;
      await savePlayers(players);
    }
  }
  
  Future<void> deletePlayer(String playerId) async {
    final players = await getPlayers();
    players.removeWhere((p) => p.id == playerId);
    await savePlayers(players);
  }
  
  Future<Player?> getPlayer(String playerId) async {
    final players = await getPlayers();
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

  List<Player> _getSamplePlayers() {
    final now = DateTime.now();
    return [
      Player(
        id: '1',
        name: 'Alex Johnson',
        currentRankScore: 7.5,
        attributes: PlayerAttributes(preferredPosition: 'Forward', speed: 8, strength: 6),
        createdAt: now.subtract(const Duration(days: 30)),
        gamesPlayed: 12,
        formFactor: 1.15,
        consistencyMultiplier: 0.98,
        rankingHistory: [
          RankingEntry(date: now.subtract(const Duration(days: 3)), rankScore: 7.8),
          RankingEntry(date: now.subtract(const Duration(days: 7)), rankScore: 7.2),
          RankingEntry(date: now.subtract(const Duration(days: 14)), rankScore: 7.0),
          RankingEntry(date: now.subtract(const Duration(days: 21)), rankScore: 7.1),
        ],
      ),
      Player(
        id: '2',
        name: 'Maria Santos',
        currentRankScore: 8.2,
        attributes: PlayerAttributes(preferredPosition: 'Midfielder', speed: 7, strength: 7),
        createdAt: now.subtract(const Duration(days: 25)),
        gamesPlayed: 15,
        formFactor: 1.08,
        consistencyMultiplier: 1.05,
        rankingHistory: [
          RankingEntry(date: now.subtract(const Duration(days: 3)), rankScore: 8.3),
          RankingEntry(date: now.subtract(const Duration(days: 7)), rankScore: 8.0),
          RankingEntry(date: now.subtract(const Duration(days: 14)), rankScore: 8.4),
          RankingEntry(date: now.subtract(const Duration(days: 21)), rankScore: 8.1),
        ],
      ),
      Player(
        id: '3',
        name: 'David Kim',
        currentRankScore: 6.8,
        attributes: PlayerAttributes(preferredPosition: 'Defender', speed: 5, strength: 9),
        createdAt: now.subtract(const Duration(days: 20)),
        gamesPlayed: 18,
        formFactor: 0.96,
        consistencyMultiplier: 1.08,
        rankingHistory: [
          RankingEntry(date: now.subtract(const Duration(days: 3)), rankScore: 6.7),
          RankingEntry(date: now.subtract(const Duration(days: 7)), rankScore: 6.5),
          RankingEntry(date: now.subtract(const Duration(days: 14)), rankScore: 7.1),
          RankingEntry(date: now.subtract(const Duration(days: 21)), rankScore: 7.0),
        ],
      ),
      Player(
        id: '4',
        name: 'Emma Wilson',
        currentRankScore: 7.9,
        attributes: PlayerAttributes(preferredPosition: 'Goalkeeper', speed: 6, strength: 8),
        createdAt: now.subtract(const Duration(days: 15)),
        gamesPlayed: 10,
        formFactor: 1.02,
        consistencyMultiplier: 1.03,
        rankingHistory: [
          RankingEntry(date: now.subtract(const Duration(days: 3)), rankScore: 8.0),
          RankingEntry(date: now.subtract(const Duration(days: 7)), rankScore: 7.7),
          RankingEntry(date: now.subtract(const Duration(days: 14)), rankScore: 8.1),
          RankingEntry(date: now.subtract(const Duration(days: 21)), rankScore: 7.8),
        ],
      ),
      Player(
        id: '5',
        name: 'Carlos Rodriguez',
        currentRankScore: 6.3,
        attributes: PlayerAttributes(preferredPosition: 'Forward', speed: 9, strength: 5),
        createdAt: now.subtract(const Duration(days: 10)),
        gamesPlayed: 8,
        formFactor: 1.12,
        consistencyMultiplier: 0.94,
        rankingHistory: [
          RankingEntry(date: now.subtract(const Duration(days: 3)), rankScore: 6.8),
          RankingEntry(date: now.subtract(const Duration(days: 7)), rankScore: 6.1),
          RankingEntry(date: now.subtract(const Duration(days: 14)), rankScore: 6.5),
          RankingEntry(date: now.subtract(const Duration(days: 21)), rankScore: 5.9),
        ],
      ),
      Player(
        id: '6',
        name: 'Sarah Chen',
        currentRankScore: 7.1,
        attributes: PlayerAttributes(preferredPosition: 'Midfielder', speed: 7, strength: 6),
        createdAt: now.subtract(const Duration(days: 8)),
        gamesPlayed: 14,
        formFactor: 1.01,
        consistencyMultiplier: 1.02,
        rankingHistory: [
          RankingEntry(date: now.subtract(const Duration(days: 3)), rankScore: 7.2),
          RankingEntry(date: now.subtract(const Duration(days: 7)), rankScore: 7.0),
          RankingEntry(date: now.subtract(const Duration(days: 14)), rankScore: 7.2),
          RankingEntry(date: now.subtract(const Duration(days: 21)), rankScore: 7.0),
        ],
      ),
    ];
  }
}