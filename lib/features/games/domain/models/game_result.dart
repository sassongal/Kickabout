import 'package:flutter/foundation.dart';

@immutable
class GameResult {
  const GameResult({
    required this.teamAScore,
    required this.teamBScore,
    required this.playerIds,
    this.goalScorerIds = const {},
    this.assistPlayerIds = const {},
    this.mvpPlayerId,
  });

  final int teamAScore;
  final int teamBScore;
  final List<String> playerIds;
  final Map<String, int> goalScorerIds;
  final Map<String, int> assistPlayerIds;
  final String? mvpPlayerId;

  Map<String, dynamic> toJson() {
    return {
      'teamAScore': teamAScore,
      'teamBScore': teamBScore,
      'playerIds': playerIds,
      'goalScorerIds': goalScorerIds,
      'assistPlayerIds': assistPlayerIds,
      'mvpPlayerId': mvpPlayerId,
    };
  }
}
