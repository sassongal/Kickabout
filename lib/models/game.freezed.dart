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
  String get hubId => throw _privateConstructorUsedError;
  String? get eventId =>
      throw _privateConstructorUsedError; // ID of the event this game belongs to (if part of an event)
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
  int? get teamAScore =>
      throw _privateConstructorUsedError; // Score for team A (first team)
  int? get teamBScore =>
      throw _privateConstructorUsedError; // Score for team B (second team)
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
  String? get venueName => throw _privateConstructorUsedError;

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
      int? teamAScore,
      int? teamBScore,
      int? durationInMinutes,
      String? gameEndCondition,
      String? region,
      bool showInCommunityFeed,
      List<String> goalScorerIds,
      List<String> goalScorerNames,
      String? mvpPlayerId,
      String? mvpPlayerName,
      String? venueName});
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
    Object? teamAScore = freezed,
    Object? teamBScore = freezed,
    Object? durationInMinutes = freezed,
    Object? gameEndCondition = freezed,
    Object? region = freezed,
    Object? showInCommunityFeed = null,
    Object? goalScorerIds = null,
    Object? goalScorerNames = null,
    Object? mvpPlayerId = freezed,
    Object? mvpPlayerName = freezed,
    Object? venueName = freezed,
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
      teamAScore: freezed == teamAScore
          ? _value.teamAScore
          : teamAScore // ignore: cast_nullable_to_non_nullable
              as int?,
      teamBScore: freezed == teamBScore
          ? _value.teamBScore
          : teamBScore // ignore: cast_nullable_to_non_nullable
              as int?,
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
      int? teamAScore,
      int? teamBScore,
      int? durationInMinutes,
      String? gameEndCondition,
      String? region,
      bool showInCommunityFeed,
      List<String> goalScorerIds,
      List<String> goalScorerNames,
      String? mvpPlayerId,
      String? mvpPlayerName,
      String? venueName});
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
    Object? teamAScore = freezed,
    Object? teamBScore = freezed,
    Object? durationInMinutes = freezed,
    Object? gameEndCondition = freezed,
    Object? region = freezed,
    Object? showInCommunityFeed = null,
    Object? goalScorerIds = null,
    Object? goalScorerNames = null,
    Object? mvpPlayerId = freezed,
    Object? mvpPlayerName = freezed,
    Object? venueName = freezed,
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
      teamAScore: freezed == teamAScore
          ? _value.teamAScore
          : teamAScore // ignore: cast_nullable_to_non_nullable
              as int?,
      teamBScore: freezed == teamBScore
          ? _value.teamBScore
          : teamBScore // ignore: cast_nullable_to_non_nullable
              as int?,
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
      this.teamAScore,
      this.teamBScore,
      this.durationInMinutes,
      this.gameEndCondition,
      this.region,
      this.showInCommunityFeed = false,
      final List<String> goalScorerIds = const [],
      final List<String> goalScorerNames = const [],
      this.mvpPlayerId,
      this.mvpPlayerName,
      this.venueName})
      : _photoUrls = photoUrls,
        _teams = teams,
        _goalScorerIds = goalScorerIds,
        _goalScorerNames = goalScorerNames;

  factory _$GameImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameImplFromJson(json);

  @override
  final String gameId;
  @override
  final String createdBy;
  @override
  final String hubId;
  @override
  final String? eventId;
// ID of the event this game belongs to (if part of an event)
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
  final List<String> _photoUrls;
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
  @override
  final int? teamAScore;
// Score for team A (first team)
  @override
  final int? teamBScore;
// Score for team B (second team)
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

  @override
  String toString() {
    return 'Game(gameId: $gameId, createdBy: $createdBy, hubId: $hubId, eventId: $eventId, gameDate: $gameDate, location: $location, locationPoint: $locationPoint, geohash: $geohash, venueId: $venueId, teamCount: $teamCount, status: $status, photoUrls: $photoUrls, createdAt: $createdAt, updatedAt: $updatedAt, isRecurring: $isRecurring, parentGameId: $parentGameId, recurrencePattern: $recurrencePattern, recurrenceEndDate: $recurrenceEndDate, createdByName: $createdByName, createdByPhotoUrl: $createdByPhotoUrl, hubName: $hubName, teams: $teams, teamAScore: $teamAScore, teamBScore: $teamBScore, durationInMinutes: $durationInMinutes, gameEndCondition: $gameEndCondition, region: $region, showInCommunityFeed: $showInCommunityFeed, goalScorerIds: $goalScorerIds, goalScorerNames: $goalScorerNames, mvpPlayerId: $mvpPlayerId, mvpPlayerName: $mvpPlayerName, venueName: $venueName)';
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
            (identical(other.teamAScore, teamAScore) ||
                other.teamAScore == teamAScore) &&
            (identical(other.teamBScore, teamBScore) ||
                other.teamBScore == teamBScore) &&
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
                other.venueName == venueName));
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
        teamAScore,
        teamBScore,
        durationInMinutes,
        gameEndCondition,
        region,
        showInCommunityFeed,
        const DeepCollectionEquality().hash(_goalScorerIds),
        const DeepCollectionEquality().hash(_goalScorerNames),
        mvpPlayerId,
        mvpPlayerName,
        venueName
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
      final int? teamAScore,
      final int? teamBScore,
      final int? durationInMinutes,
      final String? gameEndCondition,
      final String? region,
      final bool showInCommunityFeed,
      final List<String> goalScorerIds,
      final List<String> goalScorerNames,
      final String? mvpPlayerId,
      final String? mvpPlayerName,
      final String? venueName}) = _$GameImpl;

  factory _Game.fromJson(Map<String, dynamic> json) = _$GameImpl.fromJson;

  @override
  String get gameId;
  @override
  String get createdBy;
  @override
  String get hubId;
  @override
  String?
      get eventId; // ID of the event this game belongs to (if part of an event)
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
  @override
  int? get teamAScore; // Score for team A (first team)
  @override
  int? get teamBScore; // Score for team B (second team)
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
  String? get venueName;

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameImplCopyWith<_$GameImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
