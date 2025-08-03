import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kickabout/models/game.dart';

class GameService {
  static const String _gamesKey = 'games';
  
  Future<List<Game>> getGames() async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = prefs.getString(_gamesKey);
    
    if (gamesJson == null) {
      return [];
    }
    
    final gamesList = jsonDecode(gamesJson) as List;
    return gamesList.map((json) => Game.fromJson(json)).toList();
  }
  
  Future<void> saveGames(List<Game> games) async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = jsonEncode(games.map((g) => g.toJson()).toList());
    await prefs.setString(_gamesKey, gamesJson);
  }
  
  Future<void> saveGame(Game game) async {
    final games = await getGames();
    final index = games.indexWhere((g) => g.id == game.id);
    
    if (index != -1) {
      games[index] = game;
    } else {
      games.add(game);
    }
    
    await saveGames(games);
  }
  
  Future<Game?> getGame(String gameId) async {
    final games = await getGames();
    try {
      return games.firstWhere((g) => g.id == gameId);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> deleteGame(String gameId) async {
    final games = await getGames();
    games.removeWhere((g) => g.id == gameId);
    await saveGames(games);
  }
  
  Future<List<Game>> getRecentGames({int limit = 10}) async {
    final games = await getGames();
    games.sort((a, b) => b.gameDate.compareTo(a.gameDate));
    return games.take(limit).toList();
  }
}