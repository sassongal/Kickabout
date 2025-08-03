import 'package:kickabout/models/player_stats.dart';

enum GameStatus { teamSelection, teamsFormed, inProgress, completed, statsInput }

class Game {
  final String id;
  final DateTime gameDate;
  final List<String> playerIds;
  final Map<String, Team> teams;
  final GameStatus status;
  final List<PlayerStats> gameStats;

  Game({
    required this.id,
    required this.gameDate,
    required this.playerIds,
    this.teams = const {},
    this.status = GameStatus.teamSelection,
    this.gameStats = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'gameDate': gameDate.toIso8601String(),
    'playerIds': playerIds,
    'teams': teams.map((key, value) => MapEntry(key, value.toJson())),
    'status': status.name,
    'gameStats': gameStats.map((e) => e.toJson()).toList(),
  };

  factory Game.fromJson(Map<String, dynamic> json) => Game(
    id: json['id'],
    gameDate: DateTime.parse(json['gameDate']),
    playerIds: List<String>.from(json['playerIds']),
    teams: (json['teams'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, Team.fromJson(value))
    ) ?? {},
    status: GameStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => GameStatus.teamSelection,
    ),
    gameStats: (json['gameStats'] as List?)
        ?.map((e) => PlayerStats.fromJson(e))
        .toList() ?? [],
  );

  Game copyWith({
    List<String>? playerIds,
    Map<String, Team>? teams,
    GameStatus? status,
    List<PlayerStats>? gameStats,
  }) => Game(
    id: id,
    gameDate: gameDate,
    playerIds: playerIds ?? this.playerIds,
    teams: teams ?? this.teams,
    status: status ?? this.status,
    gameStats: gameStats ?? this.gameStats,
  );
}

class Team {
  final List<String> playerIds;
  final double totalScore;
  final String name;

  Team({
    required this.playerIds,
    this.totalScore = 0.0,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'playerIds': playerIds,
    'totalScore': totalScore,
    'name': name,
  };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    playerIds: List<String>.from(json['playerIds']),
    totalScore: json['totalScore']?.toDouble() ?? 0.0,
    name: json['name'],
  );
}