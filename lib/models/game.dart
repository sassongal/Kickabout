import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/enums/game_status.dart';
import 'package:kattrick/models/enums/game_visibility.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';
import 'package:kattrick/models/converters/geopoint_converter.dart';
import 'package:kattrick/models/team.dart';
import 'package:kattrick/models/match_result.dart';

part 'game.freezed.dart';
part 'game.g.dart';

/// Game model matching Firestore schema: /games/{gameId}
/// Denormalized fields: createdByName, createdByPhotoUrl, hubName for efficient display
@freezed
class Game with _$Game {
  const factory Game({
    required String gameId,
    required String createdBy,
    required String hubId,
    // Event reference - Game should always be created from an Event (legacy games may not have this)
    String? eventId, // ID of the event this game belongs to (required for new games, optional for legacy)
    @TimestampConverter() required DateTime gameDate,
    String? location, // Legacy text location (kept for backward compatibility)
    @NullableGeoPointConverter() GeoPoint? locationPoint, // New geographic location
    String? geohash,
    String? venueId, // Reference to venue (not denormalized - use venueId to fetch)
    @Default(2) int teamCount, // 2, 3, or 4
    @GameStatusConverter() @Default(GameStatus.teamSelection) GameStatus status,
    @GameVisibilityConverter() @Default(GameVisibility.private) GameVisibility visibility, // private, public, or recruiting
    @Default([]) List<String> photoUrls, // URLs of game photos
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    // Recurring game fields
    @Default(false) bool isRecurring, // Is this a recurring game?
    String? parentGameId, // ID of the original recurring game (for child games)
    String? recurrencePattern, // 'weekly', 'biweekly', 'monthly'
    @NullableTimestampConverter() DateTime? recurrenceEndDate, // When to stop creating recurring games
    // Denormalized fields for efficient display (no need to fetch user/hub)
    String? createdByName, // Denormalized from users/{createdBy}.name
    String? createdByPhotoUrl, // Denormalized from users/{createdBy}.photoUrl
    String? hubName, // Denormalized from hubs/{hubId}.name (optional, for feed posts)
    // Teams and scores
    @Default([]) List<Team> teams, // List of teams created in TeamMaker
    // Legacy single-match scores (deprecated - use matches list for session mode)
    // These fields are kept for backward compatibility with old games
    // ignore: invalid_annotation_target
    @JsonKey(name: 'teamAScore') int? legacyTeamAScore, // Legacy: Score for team A - use matches for session mode
    // ignore: invalid_annotation_target
    @JsonKey(name: 'teamBScore') int? legacyTeamBScore, // Legacy: Score for team B - use matches for session mode
    // Multi-match session support (for Events converted to Games)
    @Default([]) List<MatchResult> matches, // List of individual match outcomes within this session
    @Default({}) Map<String, int> aggregateWins, // Summary: {'Blue': 6, 'Red': 4, 'Green': 2}
    // Game rules
    int? durationInMinutes, // Duration of the game in minutes
    String? gameEndCondition, // Condition for game end (e.g., "first to 5 goals", "time limit")
    String? region, // אזור: צפון, מרכז, דרום, ירושלים (מועתק מה-Hub)
    // Community feed
    @Default(false) bool showInCommunityFeed, // Show this game in the community activity feed
    // Denormalized fields for community feed (optimization)
    @Default([]) List<String> goalScorerIds, // IDs of players who scored (denormalized from events)
    @Default([]) List<String> goalScorerNames, // Names of goal scorers (denormalized for quick display)
    String? mvpPlayerId, // MVP player ID (denormalized from events)
    String? mvpPlayerName, // MVP player name (denormalized for quick display)
    String? venueName, // Venue name (denormalized from venue or event.location)
    // Denormalized fields for signups (optimization - avoids N+1 queries)
    @Default([]) List<String> confirmedPlayerIds, // IDs of confirmed players (denormalized from signups)
    @Default(0) int confirmedPlayerCount, // Count of confirmed players (denormalized)
    @Default(false) bool isFull, // Is the game full? (denormalized - calculated from confirmedPlayerCount >= maxParticipants)
    int? maxParticipants, // Maximum number of participants (for games created from events)
    // Attendance confirmation settings
    @Default(true) bool enableAttendanceReminder, // Organizer can choose to send 2h reminders
    bool? reminderSent2Hours, // Whether reminder was already sent (set by Cloud Function)
    DateTime? reminderSent2HoursAt, // When reminder was sent
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
// ignore_for_file: invalid_annotation_target
