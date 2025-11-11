import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickabout/models/enums/game_status.dart';
import 'package:kickabout/models/converters/timestamp_converter.dart';

part 'game.freezed.dart';
part 'game.g.dart';

/// Game model matching Firestore schema: /games/{gameId}
@freezed
class Game with _$Game {
  const factory Game({
    required String gameId,
    required String createdBy,
    required String hubId,
    @TimestampConverter() required DateTime gameDate,
    String? location,
    @Default(2) int teamCount, // 2, 3, or 4
    @GameStatusConverter() @Default(GameStatus.teamSelection) GameStatus status,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _Game;

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
}

/// Firestore converter for Game
class GameConverter implements JsonConverter<Game, Map<String, dynamic>> {
  const GameConverter();

  @override
  Game fromJson(Map<String, dynamic> json) => Game.fromJson(json);

  @override
  Map<String, dynamic> toJson(Game object) => object.toJson();
}

/// GameStatus converter for Firestore
class GameStatusConverter implements JsonConverter<GameStatus, String> {
  const GameStatusConverter();

  @override
  GameStatus fromJson(String json) => GameStatus.fromFirestore(json);

  @override
  String toJson(GameStatus object) => object.toFirestore();
}
