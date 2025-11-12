import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/models/enums/game_status.dart';
import 'package:kickabout/models/converters/timestamp_converter.dart';
import 'package:kickabout/models/converters/geopoint_converter.dart';

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
    String? location, // Legacy text location (kept for backward compatibility)
    @GeoPointConverter() GeoPoint? locationPoint, // New geographic location
    String? geohash,
    String? venueId, // Reference to venue
    @Default(2) int teamCount, // 2, 3, or 4
    @GameStatusConverter() @Default(GameStatus.teamSelection) GameStatus status,
    @Default([]) List<String> photoUrls, // URLs of game photos
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    // Recurring game fields
    @Default(false) bool isRecurring, // Is this a recurring game?
    String? parentGameId, // ID of the original recurring game (for child games)
    String? recurrencePattern, // 'weekly', 'biweekly', 'monthly'
    @TimestampConverter() DateTime? recurrenceEndDate, // When to stop creating recurring games
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
