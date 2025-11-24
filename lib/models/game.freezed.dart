// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Game _$GameFromJson(Map<String, dynamic> json) {
  return _Game.fromJson(json);
}

/// @nodoc
mixin _$Game {
  String get gameId => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  String get hubId =>
      throw _privateConstructorUsedError; // Event reference - Game should always be created from an Event (legacy games may not have this)
  String? get eventId =>
      throw _privateConstructorUsedError; // ID of the event this game belongs to (required for new games, optional for legacy)
  @TimestampConverter()
  DateTime get gameDate => throw _privateConstructorUsedError;
  String? get location =>
      throw _privateConstructorUsedError; // Legacy text location (kept for backward compatibility)
  @NullableGeoPointConverter()
  GeoPoint? get locationPoint =>
      throw _privateConstructorUsedError; // New geographic location
  String? get geohash => throw _privateConstructorUsedError;
  String? get venueId =>
      throw _privateConstructorUsedError; // Reference to venue (not denormalized - use venueId to fetch)
  int get teamCount => throw _privateConstructorUsedError; // 2, 3, or 4
  @GameStatusConverter()
  GameStatus get status => throw _privateConstructorUsedError;
  @GameVisibilityConverter()
  GameVisibility get visibility =>
      throw _privateConstructorUsedError; // private, public, or recruiting
  List<String> get photoUrls =>
      throw _privateConstructorUsedError; // URLs of game photos
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt =>
      throw _privateConstructorUsedError; // Recurring game fields
  bool get isRecurring =>
      throw _privateConstructorUsedError; // Is this a recurring game?
  String? get parentGameId =>
      throw _privateConstructorUsedError; // ID of the original recurring game (for child games)
  String? get recurrencePattern =>
      throw _privateConstructorUsedError; // 'weekly', 'biweekly', 'monthly'
  @TimestampConverter()
  DateTime? get recurrenceEndDate =>
      throw _privateConstructorUsedError; // When to stop creating recurring games
// Denormalized fields for efficient display (no need to fetch user/hub)
  String? get createdByName =>
      throw _privateConstructorUsedError; // Denormalized from users/{createdBy}.name
  String? get createdByPhotoUrl =>
      throw _privateConstructorUsedError; // Denormalized from users/{createdBy}.photoUrl
  String? get hubName =>
      throw _privateConstructorUsedError; // Denormalized from hubs/{hubId}.name (optional, for feed posts)
// Teams and scores
  List<Team> get teams =>
      throw _privateConstructorUsedError; // List of teams created in TeamMaker
// Legacy single-match scores (deprecated - use matches list for session mode)
// These fields are kept for backward compatibility with old games
  @JsonKey(name: 'teamAScore')
  int? get legacyTeamAScore =>
      throw _privateConstructorUsedError; // Legacy: Score for team A - use matches for session mode
  @JsonKey(name: 'teamBScore')
  int? get legacyTeamBScore =>
      throw _privateConstructorUsedError; // Legacy: Score for team B - use matches for session mode
// Multi-match session support (for Events converted to Games)
  List<MatchResult> get matches =>
      throw _privateConstructorUsedError; // List of individual match outcomes within this session
  Map<String, int> get aggregateWins =>
      throw _privateConstructorUsedError; // Summary: {'Blue': 6, 'Red': 4, 'Green': 2}
// Game rules
  int? get durationInMinutes =>
      throw _privateConstructorUsedError; // Duration of the game in minutes
  String? get gameEndCondition =>
      throw _privateConstructorUsedError; // Condition for game end (e.g., "first to 5 goals", "time limit")
  String? get region =>
      throw _privateConstructorUsedError; // אזור: צפון, מרכז, דרום, ירושלים (מועתק מה-Hub)
// Community feed
  bool get showInCommunityFeed =>
      throw _privateConstructorUsedError; // Show this game in the community activity feed
// Denormalized fields for community feed (optimization)
  List<String> get goalScorerIds =>
      throw _privateConstructorUsedError; // IDs of players who scored (denormalized from events)
  List<String> get goalScorerNames =>
      throw _privateConstructorUsedError; // Names of goal scorers (denormalized for quick display)
  String? get mvpPlayerId =>
      throw _privateConstructorUsedError; // MVP player ID (denormalized from events)
  String? get mvpPlayerName =>
      throw _privateConstructorUsedError; // MVP player name (denormalized for quick display)
  String? get venueName =>
      throw _privateConstructorUsedError; // Venue name (denormalized from venue or event.location)
// Denormalized fields for signups (optimization - avoids N+1 queries)
  List<String> get confirmedPlayerIds =>
      throw _privateConstructorUsedError; // IDs of confirmed players (denormalized from signups)
  int get confirmedPlayerCount =>
      throw _privateConstructorUsedError; // Count of confirmed players (denormalized)
  bool get isFull =>
      throw _privateConstructorUsedError; // Is the game full? (denormalized - calculated from confirmedPlayerCount >= maxParticipants)
  int? get maxParticipants => throw _privateConstructorUsedError;

  /// Serializes this Game to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameCopyWith<Game> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameCopyWith<$Res> {
  factory $GameCopyWith(Game value, $Res Function(Game) then) =
      _$GameCopyWithImpl<$Res, Game>;
  @useResult
  $Res call(
      {String gameId,
      String createdBy,
      String hubId,
      String? eventId,
      @TimestampConverter() DateTime gameDate,
      String? location,
      @NullableGeoPointConverter() GeoPoint? locationPoint,
      String? geohash,
      String? venueId,
      int teamCount,
      @GameStatusConverter() GameStatus status,
      @GameVisibilityConverter() GameVisibility visibility,
      List<String> photoUrls,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt,
      bool isRecurring,
      String? parentGameId,
      String? recurrencePattern,
      @TimestampConverter() DateTime? recurrenceEndDate,
      String? createdByName,
      String? createdByPhotoUrl,
      String? hubName,
      List<Team> teams,
      @JsonKey(name: 'teamAScore') int? legacyTeamAScore,
      @JsonKey(name: 'teamBScore') int? legacyTeamBScore,
      List<MatchResult> matches,
      Map<String, int> aggregateWins,
      int? durationInMinutes,
      String? gameEndCondition,
      String? region,
      bool showInCommunityFeed,
      List<String> goalScorerIds,
      List<String> goalScorerNames,
      String? mvpPlayerId,
      String? mvpPlayerName,
      String? venueName,
      List<String> confirmedPlayerIds,
      int confirmedPlayerCount,
      bool isFull,
      int? maxParticipants});
}

/// @nodoc
class _$GameCopyWithImpl<$Res, $Val extends Game>
    implements $GameCopyWith<$Res> {
  _$GameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? createdBy = null,
    Object? hubId = null,
    Object? eventId = freezed,
    Object? gameDate = null,
    Object? location = freezed,
    Object? locationPoint = freezed,
    Object? geohash = freezed,
    Object? venueId = freezed,
    Object? teamCount = null,
    Object? status = null,
    Object? visibility = null,
    Object? photoUrls = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isRecurring = null,
    Object? parentGameId = freezed,
    Object? recurrencePattern = freezed,
    Object? recurrenceEndDate = freezed,
    Object? createdByName = freezed,
    Object? createdByPhotoUrl = freezed,
    Object? hubName = freezed,
    Object? teams = null,
    Object? legacyTeamAScore = freezed,
    Object? legacyTeamBScore = freezed,
    Object? matches = null,
    Object? aggregateWins = null,
    Object? durationInMinutes = freezed,
    Object? gameEndCondition = freezed,
    Object? region = freezed,
    Object? showInCommunityFeed = null,
    Object? goalScorerIds = null,
    Object? goalScorerNames = null,
    Object? mvpPlayerId = freezed,
    Object? mvpPlayerName = freezed,
    Object? venueName = freezed,
    Object? confirmedPlayerIds = null,
    Object? confirmedPlayerCount = null,
    Object? isFull = null,
    Object? maxParticipants = freezed,
  }) {
    return _then(_value.copyWith(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: freezed == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      gameDate: null == gameDate
          ? _value.gameDate
          : gameDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      locationPoint: freezed == locationPoint
          ? _value.locationPoint
          : locationPoint // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
      venueId: freezed == venueId
          ? _value.venueId
          : venueId // ignore: cast_nullable_to_non_nullable
              as String?,
      teamCount: null == teamCount
          ? _value.teamCount
          : teamCount // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GameStatus,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as GameVisibility,
      photoUrls: null == photoUrls
          ? _value.photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      parentGameId: freezed == parentGameId
          ? _value.parentGameId
          : parentGameId // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrencePattern: freezed == recurrencePattern
          ? _value.recurrencePattern
          : recurrencePattern // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceEndDate: freezed == recurrenceEndDate
          ? _value.recurrenceEndDate
          : recurrenceEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdByName: freezed == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdByPhotoUrl: freezed == createdByPhotoUrl
          ? _value.createdByPhotoUrl
          : createdByPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hubName: freezed == hubName
          ? _value.hubName
          : hubName // ignore: cast_nullable_to_non_nullable
              as String?,
      teams: null == teams
          ? _value.teams
          : teams // ignore: cast_nullable_to_non_nullable
              as List<Team>,
      legacyTeamAScore: freezed == legacyTeamAScore
          ? _value.legacyTeamAScore
          : legacyTeamAScore // ignore: cast_nullable_to_non_nullable
              as int?,
      legacyTeamBScore: freezed == legacyTeamBScore
          ? _value.legacyTeamBScore
          : legacyTeamBScore // ignore: cast_nullable_to_non_nullable
              as int?,
      matches: null == matches
          ? _value.matches
          : matches // ignore: cast_nullable_to_non_nullable
              as List<MatchResult>,
      aggregateWins: null == aggregateWins
          ? _value.aggregateWins
          : aggregateWins // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      durationInMinutes: freezed == durationInMinutes
          ? _value.durationInMinutes
          : durationInMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      gameEndCondition: freezed == gameEndCondition
          ? _value.gameEndCondition
          : gameEndCondition // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      showInCommunityFeed: null == showInCommunityFeed
          ? _value.showInCommunityFeed
          : showInCommunityFeed // ignore: cast_nullable_to_non_nullable
              as bool,
      goalScorerIds: null == goalScorerIds
          ? _value.goalScorerIds
          : goalScorerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goalScorerNames: null == goalScorerNames
          ? _value.goalScorerNames
          : goalScorerNames // ignore: cast_nullable_to_non_nullable
              as List<String>,
      mvpPlayerId: freezed == mvpPlayerId
          ? _value.mvpPlayerId
          : mvpPlayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      mvpPlayerName: freezed == mvpPlayerName
          ? _value.mvpPlayerName
          : mvpPlayerName // ignore: cast_nullable_to_non_nullable
              as String?,
      venueName: freezed == venueName
          ? _value.venueName
          : venueName // ignore: cast_nullable_to_non_nullable
              as String?,
      confirmedPlayerIds: null == confirmedPlayerIds
          ? _value.confirmedPlayerIds
          : confirmedPlayerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      confirmedPlayerCount: null == confirmedPlayerCount
          ? _value.confirmedPlayerCount
          : confirmedPlayerCount // ignore: cast_nullable_to_non_nullable
              as int,
      isFull: null == isFull
          ? _value.isFull
          : isFull // ignore: cast_nullable_to_non_nullable
              as bool,
      maxParticipants: freezed == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameImplCopyWith<$Res> implements $GameCopyWith<$Res> {
  factory _$$GameImplCopyWith(
          _$GameImpl value, $Res Function(_$GameImpl) then) =
      __$$GameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String gameId,
      String createdBy,
      String hubId,
      String? eventId,
      @TimestampConverter() DateTime gameDate,
      String? location,
      @NullableGeoPointConverter() GeoPoint? locationPoint,
      String? geohash,
      String? venueId,
      int teamCount,
      @GameStatusConverter() GameStatus status,
      @GameVisibilityConverter() GameVisibility visibility,
      List<String> photoUrls,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt,
      bool isRecurring,
      String? parentGameId,
      String? recurrencePattern,
      @TimestampConverter() DateTime? recurrenceEndDate,
      String? createdByName,
      String? createdByPhotoUrl,
      String? hubName,
      List<Team> teams,
      @JsonKey(name: 'teamAScore') int? legacyTeamAScore,
      @JsonKey(name: 'teamBScore') int? legacyTeamBScore,
      List<MatchResult> matches,
      Map<String, int> aggregateWins,
      int? durationInMinutes,
      String? gameEndCondition,
      String? region,
      bool showInCommunityFeed,
      List<String> goalScorerIds,
      List<String> goalScorerNames,
      String? mvpPlayerId,
      String? mvpPlayerName,
      String? venueName,
      List<String> confirmedPlayerIds,
      int confirmedPlayerCount,
      bool isFull,
      int? maxParticipants});
}

/// @nodoc
class __$$GameImplCopyWithImpl<$Res>
    extends _$GameCopyWithImpl<$Res, _$GameImpl>
    implements _$$GameImplCopyWith<$Res> {
  __$$GameImplCopyWithImpl(_$GameImpl _value, $Res Function(_$GameImpl) _then)
      : super(_value, _then);

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? createdBy = null,
    Object? hubId = null,
    Object? eventId = freezed,
    Object? gameDate = null,
    Object? location = freezed,
    Object? locationPoint = freezed,
    Object? geohash = freezed,
    Object? venueId = freezed,
    Object? teamCount = null,
    Object? status = null,
    Object? visibility = null,
    Object? photoUrls = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isRecurring = null,
    Object? parentGameId = freezed,
    Object? recurrencePattern = freezed,
    Object? recurrenceEndDate = freezed,
    Object? createdByName = freezed,
    Object? createdByPhotoUrl = freezed,
    Object? hubName = freezed,
    Object? teams = null,
    Object? legacyTeamAScore = freezed,
    Object? legacyTeamBScore = freezed,
    Object? matches = null,
    Object? aggregateWins = null,
    Object? durationInMinutes = freezed,
    Object? gameEndCondition = freezed,
    Object? region = freezed,
    Object? showInCommunityFeed = null,
    Object? goalScorerIds = null,
    Object? goalScorerNames = null,
    Object? mvpPlayerId = freezed,
    Object? mvpPlayerName = freezed,
    Object? venueName = freezed,
    Object? confirmedPlayerIds = null,
    Object? confirmedPlayerCount = null,
    Object? isFull = null,
    Object? maxParticipants = freezed,
  }) {
    return _then(_$GameImpl(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: freezed == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      gameDate: null == gameDate
          ? _value.gameDate
          : gameDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      locationPoint: freezed == locationPoint
          ? _value.locationPoint
          : locationPoint // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
      venueId: freezed == venueId
          ? _value.venueId
          : venueId // ignore: cast_nullable_to_non_nullable
              as String?,
      teamCount: null == teamCount
          ? _value.teamCount
          : teamCount // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GameStatus,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as GameVisibility,
      photoUrls: null == photoUrls
          ? _value._photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      parentGameId: freezed == parentGameId
          ? _value.parentGameId
          : parentGameId // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrencePattern: freezed == recurrencePattern
          ? _value.recurrencePattern
          : recurrencePattern // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceEndDate: freezed == recurrenceEndDate
          ? _value.recurrenceEndDate
          : recurrenceEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdByName: freezed == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdByPhotoUrl: freezed == createdByPhotoUrl
          ? _value.createdByPhotoUrl
          : createdByPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hubName: freezed == hubName
          ? _value.hubName
          : hubName // ignore: cast_nullable_to_non_nullable
              as String?,
      teams: null == teams
          ? _value._teams
          : teams // ignore: cast_nullable_to_non_nullable
              as List<Team>,
      legacyTeamAScore: freezed == legacyTeamAScore
          ? _value.legacyTeamAScore
          : legacyTeamAScore // ignore: cast_nullable_to_non_nullable
              as int?,
      legacyTeamBScore: freezed == legacyTeamBScore
          ? _value.legacyTeamBScore
          : legacyTeamBScore // ignore: cast_nullable_to_non_nullable
              as int?,
      matches: null == matches
          ? _value._matches
          : matches // ignore: cast_nullable_to_non_nullable
              as List<MatchResult>,
      aggregateWins: null == aggregateWins
          ? _value._aggregateWins
          : aggregateWins // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      durationInMinutes: freezed == durationInMinutes
          ? _value.durationInMinutes
          : durationInMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      gameEndCondition: freezed == gameEndCondition
          ? _value.gameEndCondition
          : gameEndCondition // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      showInCommunityFeed: null == showInCommunityFeed
          ? _value.showInCommunityFeed
          : showInCommunityFeed // ignore: cast_nullable_to_non_nullable
              as bool,
      goalScorerIds: null == goalScorerIds
          ? _value._goalScorerIds
          : goalScorerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goalScorerNames: null == goalScorerNames
          ? _value._goalScorerNames
          : goalScorerNames // ignore: cast_nullable_to_non_nullable
              as List<String>,
      mvpPlayerId: freezed == mvpPlayerId
          ? _value.mvpPlayerId
          : mvpPlayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      mvpPlayerName: freezed == mvpPlayerName
          ? _value.mvpPlayerName
          : mvpPlayerName // ignore: cast_nullable_to_non_nullable
              as String?,
      venueName: freezed == venueName
          ? _value.venueName
          : venueName // ignore: cast_nullable_to_non_nullable
              as String?,
      confirmedPlayerIds: null == confirmedPlayerIds
          ? _value._confirmedPlayerIds
          : confirmedPlayerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      confirmedPlayerCount: null == confirmedPlayerCount
          ? _value.confirmedPlayerCount
          : confirmedPlayerCount // ignore: cast_nullable_to_non_nullable
              as int,
      isFull: null == isFull
          ? _value.isFull
          : isFull // ignore: cast_nullable_to_non_nullable
              as bool,
      maxParticipants: freezed == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameImpl implements _Game {
  const _$GameImpl(
      {required this.gameId,
      required this.createdBy,
      required this.hubId,
      this.eventId,
      @TimestampConverter() required this.gameDate,
      this.location,
      @NullableGeoPointConverter() this.locationPoint,
      this.geohash,
      this.venueId,
      this.teamCount = 2,
      @GameStatusConverter() this.status = GameStatus.teamSelection,
      @GameVisibilityConverter() this.visibility = GameVisibility.private,
      final List<String> photoUrls = const [],
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() required this.updatedAt,
      this.isRecurring = false,
      this.parentGameId,
      this.recurrencePattern,
      @TimestampConverter() this.recurrenceEndDate,
      this.createdByName,
      this.createdByPhotoUrl,
      this.hubName,
      final List<Team> teams = const [],
      @JsonKey(name: 'teamAScore') this.legacyTeamAScore,
      @JsonKey(name: 'teamBScore') this.legacyTeamBScore,
      final List<MatchResult> matches = const [],
      final Map<String, int> aggregateWins = const {},
      this.durationInMinutes,
      this.gameEndCondition,
      this.region,
      this.showInCommunityFeed = false,
      final List<String> goalScorerIds = const [],
      final List<String> goalScorerNames = const [],
      this.mvpPlayerId,
      this.mvpPlayerName,
      this.venueName,
      final List<String> confirmedPlayerIds = const [],
      this.confirmedPlayerCount = 0,
      this.isFull = false,
      this.maxParticipants})
      : _photoUrls = photoUrls,
        _teams = teams,
        _matches = matches,
        _aggregateWins = aggregateWins,
        _goalScorerIds = goalScorerIds,
        _goalScorerNames = goalScorerNames,
        _confirmedPlayerIds = confirmedPlayerIds;

  factory _$GameImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameImplFromJson(json);

  @override
  final String gameId;
  @override
  final String createdBy;
  @override
  final String hubId;
// Event reference - Game should always be created from an Event (legacy games may not have this)
  @override
  final String? eventId;
// ID of the event this game belongs to (required for new games, optional for legacy)
  @override
  @TimestampConverter()
  final DateTime gameDate;
  @override
  final String? location;
// Legacy text location (kept for backward compatibility)
  @override
  @NullableGeoPointConverter()
  final GeoPoint? locationPoint;
// New geographic location
  @override
  final String? geohash;
  @override
  final String? venueId;
// Reference to venue (not denormalized - use venueId to fetch)
  @override
  @JsonKey()
  final int teamCount;
// 2, 3, or 4
  @override
  @JsonKey()
  @GameStatusConverter()
  final GameStatus status;
  @override
  @JsonKey()
  @GameVisibilityConverter()
  final GameVisibility visibility;
// private, public, or recruiting
  final List<String> _photoUrls;
// private, public, or recruiting
  @override
  @JsonKey()
  List<String> get photoUrls {
    if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoUrls);
  }

// URLs of game photos
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;
// Recurring game fields
  @override
  @JsonKey()
  final bool isRecurring;
// Is this a recurring game?
  @override
  final String? parentGameId;
// ID of the original recurring game (for child games)
  @override
  final String? recurrencePattern;
// 'weekly', 'biweekly', 'monthly'
  @override
  @TimestampConverter()
  final DateTime? recurrenceEndDate;
// When to stop creating recurring games
// Denormalized fields for efficient display (no need to fetch user/hub)
  @override
  final String? createdByName;
// Denormalized from users/{createdBy}.name
  @override
  final String? createdByPhotoUrl;
// Denormalized from users/{createdBy}.photoUrl
  @override
  final String? hubName;
// Denormalized from hubs/{hubId}.name (optional, for feed posts)
// Teams and scores
  final List<Team> _teams;
// Denormalized from hubs/{hubId}.name (optional, for feed posts)
// Teams and scores
  @override
  @JsonKey()
  List<Team> get teams {
    if (_teams is EqualUnmodifiableListView) return _teams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_teams);
  }

// List of teams created in TeamMaker
// Legacy single-match scores (deprecated - use matches list for session mode)
// These fields are kept for backward compatibility with old games
  @override
  @JsonKey(name: 'teamAScore')
  final int? legacyTeamAScore;
// Legacy: Score for team A - use matches for session mode
  @override
  @JsonKey(name: 'teamBScore')
  final int? legacyTeamBScore;
// Legacy: Score for team B - use matches for session mode
// Multi-match session support (for Events converted to Games)
  final List<MatchResult> _matches;
// Legacy: Score for team B - use matches for session mode
// Multi-match session support (for Events converted to Games)
  @override
  @JsonKey()
  List<MatchResult> get matches {
    if (_matches is EqualUnmodifiableListView) return _matches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_matches);
  }

// List of individual match outcomes within this session
  final Map<String, int> _aggregateWins;
// List of individual match outcomes within this session
  @override
  @JsonKey()
  Map<String, int> get aggregateWins {
    if (_aggregateWins is EqualUnmodifiableMapView) return _aggregateWins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_aggregateWins);
  }

// Summary: {'Blue': 6, 'Red': 4, 'Green': 2}
// Game rules
  @override
  final int? durationInMinutes;
// Duration of the game in minutes
  @override
  final String? gameEndCondition;
// Condition for game end (e.g., "first to 5 goals", "time limit")
  @override
  final String? region;
// אזור: צפון, מרכז, דרום, ירושלים (מועתק מה-Hub)
// Community feed
  @override
  @JsonKey()
  final bool showInCommunityFeed;
// Show this game in the community activity feed
// Denormalized fields for community feed (optimization)
  final List<String> _goalScorerIds;
// Show this game in the community activity feed
// Denormalized fields for community feed (optimization)
  @override
  @JsonKey()
  List<String> get goalScorerIds {
    if (_goalScorerIds is EqualUnmodifiableListView) return _goalScorerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_goalScorerIds);
  }

// IDs of players who scored (denormalized from events)
  final List<String> _goalScorerNames;
// IDs of players who scored (denormalized from events)
  @override
  @JsonKey()
  List<String> get goalScorerNames {
    if (_goalScorerNames is EqualUnmodifiableListView) return _goalScorerNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_goalScorerNames);
  }

// Names of goal scorers (denormalized for quick display)
  @override
  final String? mvpPlayerId;
// MVP player ID (denormalized from events)
  @override
  final String? mvpPlayerName;
// MVP player name (denormalized for quick display)
  @override
  final String? venueName;
// Venue name (denormalized from venue or event.location)
// Denormalized fields for signups (optimization - avoids N+1 queries)
  final List<String> _confirmedPlayerIds;
// Venue name (denormalized from venue or event.location)
// Denormalized fields for signups (optimization - avoids N+1 queries)
  @override
  @JsonKey()
  List<String> get confirmedPlayerIds {
    if (_confirmedPlayerIds is EqualUnmodifiableListView)
      return _confirmedPlayerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_confirmedPlayerIds);
  }

// IDs of confirmed players (denormalized from signups)
  @override
  @JsonKey()
  final int confirmedPlayerCount;
// Count of confirmed players (denormalized)
  @override
  @JsonKey()
  final bool isFull;
// Is the game full? (denormalized - calculated from confirmedPlayerCount >= maxParticipants)
  @override
  final int? maxParticipants;

  @override
  String toString() {
    return 'Game(gameId: $gameId, createdBy: $createdBy, hubId: $hubId, eventId: $eventId, gameDate: $gameDate, location: $location, locationPoint: $locationPoint, geohash: $geohash, venueId: $venueId, teamCount: $teamCount, status: $status, visibility: $visibility, photoUrls: $photoUrls, createdAt: $createdAt, updatedAt: $updatedAt, isRecurring: $isRecurring, parentGameId: $parentGameId, recurrencePattern: $recurrencePattern, recurrenceEndDate: $recurrenceEndDate, createdByName: $createdByName, createdByPhotoUrl: $createdByPhotoUrl, hubName: $hubName, teams: $teams, legacyTeamAScore: $legacyTeamAScore, legacyTeamBScore: $legacyTeamBScore, matches: $matches, aggregateWins: $aggregateWins, durationInMinutes: $durationInMinutes, gameEndCondition: $gameEndCondition, region: $region, showInCommunityFeed: $showInCommunityFeed, goalScorerIds: $goalScorerIds, goalScorerNames: $goalScorerNames, mvpPlayerId: $mvpPlayerId, mvpPlayerName: $mvpPlayerName, venueName: $venueName, confirmedPlayerIds: $confirmedPlayerIds, confirmedPlayerCount: $confirmedPlayerCount, isFull: $isFull, maxParticipants: $maxParticipants)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.gameDate, gameDate) ||
                other.gameDate == gameDate) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.locationPoint, locationPoint) ||
                other.locationPoint == locationPoint) &&
            (identical(other.geohash, geohash) || other.geohash == geohash) &&
            (identical(other.venueId, venueId) || other.venueId == venueId) &&
            (identical(other.teamCount, teamCount) ||
                other.teamCount == teamCount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            const DeepCollectionEquality()
                .equals(other._photoUrls, _photoUrls) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isRecurring, isRecurring) ||
                other.isRecurring == isRecurring) &&
            (identical(other.parentGameId, parentGameId) ||
                other.parentGameId == parentGameId) &&
            (identical(other.recurrencePattern, recurrencePattern) ||
                other.recurrencePattern == recurrencePattern) &&
            (identical(other.recurrenceEndDate, recurrenceEndDate) ||
                other.recurrenceEndDate == recurrenceEndDate) &&
            (identical(other.createdByName, createdByName) ||
                other.createdByName == createdByName) &&
            (identical(other.createdByPhotoUrl, createdByPhotoUrl) ||
                other.createdByPhotoUrl == createdByPhotoUrl) &&
            (identical(other.hubName, hubName) || other.hubName == hubName) &&
            const DeepCollectionEquality().equals(other._teams, _teams) &&
            (identical(other.legacyTeamAScore, legacyTeamAScore) ||
                other.legacyTeamAScore == legacyTeamAScore) &&
            (identical(other.legacyTeamBScore, legacyTeamBScore) ||
                other.legacyTeamBScore == legacyTeamBScore) &&
            const DeepCollectionEquality().equals(other._matches, _matches) &&
            const DeepCollectionEquality()
                .equals(other._aggregateWins, _aggregateWins) &&
            (identical(other.durationInMinutes, durationInMinutes) ||
                other.durationInMinutes == durationInMinutes) &&
            (identical(other.gameEndCondition, gameEndCondition) ||
                other.gameEndCondition == gameEndCondition) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.showInCommunityFeed, showInCommunityFeed) ||
                other.showInCommunityFeed == showInCommunityFeed) &&
            const DeepCollectionEquality()
                .equals(other._goalScorerIds, _goalScorerIds) &&
            const DeepCollectionEquality()
                .equals(other._goalScorerNames, _goalScorerNames) &&
            (identical(other.mvpPlayerId, mvpPlayerId) ||
                other.mvpPlayerId == mvpPlayerId) &&
            (identical(other.mvpPlayerName, mvpPlayerName) ||
                other.mvpPlayerName == mvpPlayerName) &&
            (identical(other.venueName, venueName) ||
                other.venueName == venueName) &&
            const DeepCollectionEquality()
                .equals(other._confirmedPlayerIds, _confirmedPlayerIds) &&
            (identical(other.confirmedPlayerCount, confirmedPlayerCount) ||
                other.confirmedPlayerCount == confirmedPlayerCount) &&
            (identical(other.isFull, isFull) || other.isFull == isFull) &&
            (identical(other.maxParticipants, maxParticipants) ||
                other.maxParticipants == maxParticipants));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        gameId,
        createdBy,
        hubId,
        eventId,
        gameDate,
        location,
        locationPoint,
        geohash,
        venueId,
        teamCount,
        status,
        visibility,
        const DeepCollectionEquality().hash(_photoUrls),
        createdAt,
        updatedAt,
        isRecurring,
        parentGameId,
        recurrencePattern,
        recurrenceEndDate,
        createdByName,
        createdByPhotoUrl,
        hubName,
        const DeepCollectionEquality().hash(_teams),
        legacyTeamAScore,
        legacyTeamBScore,
        const DeepCollectionEquality().hash(_matches),
        const DeepCollectionEquality().hash(_aggregateWins),
        durationInMinutes,
        gameEndCondition,
        region,
        showInCommunityFeed,
        const DeepCollectionEquality().hash(_goalScorerIds),
        const DeepCollectionEquality().hash(_goalScorerNames),
        mvpPlayerId,
        mvpPlayerName,
        venueName,
        const DeepCollectionEquality().hash(_confirmedPlayerIds),
        confirmedPlayerCount,
        isFull,
        maxParticipants
      ]);

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameImplCopyWith<_$GameImpl> get copyWith =>
      __$$GameImplCopyWithImpl<_$GameImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameImplToJson(
      this,
    );
  }
}

abstract class _Game implements Game {
  const factory _Game(
      {required final String gameId,
      required final String createdBy,
      required final String hubId,
      final String? eventId,
      @TimestampConverter() required final DateTime gameDate,
      final String? location,
      @NullableGeoPointConverter() final GeoPoint? locationPoint,
      final String? geohash,
      final String? venueId,
      final int teamCount,
      @GameStatusConverter() final GameStatus status,
      @GameVisibilityConverter() final GameVisibility visibility,
      final List<String> photoUrls,
      @TimestampConverter() required final DateTime createdAt,
      @TimestampConverter() required final DateTime updatedAt,
      final bool isRecurring,
      final String? parentGameId,
      final String? recurrencePattern,
      @TimestampConverter() final DateTime? recurrenceEndDate,
      final String? createdByName,
      final String? createdByPhotoUrl,
      final String? hubName,
      final List<Team> teams,
      @JsonKey(name: 'teamAScore') final int? legacyTeamAScore,
      @JsonKey(name: 'teamBScore') final int? legacyTeamBScore,
      final List<MatchResult> matches,
      final Map<String, int> aggregateWins,
      final int? durationInMinutes,
      final String? gameEndCondition,
      final String? region,
      final bool showInCommunityFeed,
      final List<String> goalScorerIds,
      final List<String> goalScorerNames,
      final String? mvpPlayerId,
      final String? mvpPlayerName,
      final String? venueName,
      final List<String> confirmedPlayerIds,
      final int confirmedPlayerCount,
      final bool isFull,
      final int? maxParticipants}) = _$GameImpl;

  factory _Game.fromJson(Map<String, dynamic> json) = _$GameImpl.fromJson;

  @override
  String get gameId;
  @override
  String get createdBy;
  @override
  String
      get hubId; // Event reference - Game should always be created from an Event (legacy games may not have this)
  @override
  String?
      get eventId; // ID of the event this game belongs to (required for new games, optional for legacy)
  @override
  @TimestampConverter()
  DateTime get gameDate;
  @override
  String?
      get location; // Legacy text location (kept for backward compatibility)
  @override
  @NullableGeoPointConverter()
  GeoPoint? get locationPoint; // New geographic location
  @override
  String? get geohash;
  @override
  String?
      get venueId; // Reference to venue (not denormalized - use venueId to fetch)
  @override
  int get teamCount; // 2, 3, or 4
  @override
  @GameStatusConverter()
  GameStatus get status;
  @override
  @GameVisibilityConverter()
  GameVisibility get visibility; // private, public, or recruiting
  @override
  List<String> get photoUrls; // URLs of game photos
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt; // Recurring game fields
  @override
  bool get isRecurring; // Is this a recurring game?
  @override
  String?
      get parentGameId; // ID of the original recurring game (for child games)
  @override
  String? get recurrencePattern; // 'weekly', 'biweekly', 'monthly'
  @override
  @TimestampConverter()
  DateTime? get recurrenceEndDate; // When to stop creating recurring games
// Denormalized fields for efficient display (no need to fetch user/hub)
  @override
  String? get createdByName; // Denormalized from users/{createdBy}.name
  @override
  String? get createdByPhotoUrl; // Denormalized from users/{createdBy}.photoUrl
  @override
  String?
      get hubName; // Denormalized from hubs/{hubId}.name (optional, for feed posts)
// Teams and scores
  @override
  List<Team> get teams; // List of teams created in TeamMaker
// Legacy single-match scores (deprecated - use matches list for session mode)
// These fields are kept for backward compatibility with old games
  @override
  @JsonKey(name: 'teamAScore')
  int?
      get legacyTeamAScore; // Legacy: Score for team A - use matches for session mode
  @override
  @JsonKey(name: 'teamBScore')
  int?
      get legacyTeamBScore; // Legacy: Score for team B - use matches for session mode
// Multi-match session support (for Events converted to Games)
  @override
  List<MatchResult>
      get matches; // List of individual match outcomes within this session
  @override
  Map<String, int>
      get aggregateWins; // Summary: {'Blue': 6, 'Red': 4, 'Green': 2}
// Game rules
  @override
  int? get durationInMinutes; // Duration of the game in minutes
  @override
  String?
      get gameEndCondition; // Condition for game end (e.g., "first to 5 goals", "time limit")
  @override
  String? get region; // אזור: צפון, מרכז, דרום, ירושלים (מועתק מה-Hub)
// Community feed
  @override
  bool get showInCommunityFeed; // Show this game in the community activity feed
// Denormalized fields for community feed (optimization)
  @override
  List<String>
      get goalScorerIds; // IDs of players who scored (denormalized from events)
  @override
  List<String>
      get goalScorerNames; // Names of goal scorers (denormalized for quick display)
  @override
  String? get mvpPlayerId; // MVP player ID (denormalized from events)
  @override
  String? get mvpPlayerName; // MVP player name (denormalized for quick display)
  @override
  String?
      get venueName; // Venue name (denormalized from venue or event.location)
// Denormalized fields for signups (optimization - avoids N+1 queries)
  @override
  List<String>
      get confirmedPlayerIds; // IDs of confirmed players (denormalized from signups)
  @override
  int get confirmedPlayerCount; // Count of confirmed players (denormalized)
  @override
  bool
      get isFull; // Is the game full? (denormalized - calculated from confirmedPlayerCount >= maxParticipants)
  @override
  int? get maxParticipants;

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameImplCopyWith<_$GameImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
