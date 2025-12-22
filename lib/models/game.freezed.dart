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
  String? get hubId =>
      throw _privateConstructorUsedError; // Nullable for public pickup games
  String? get eventId =>
      throw _privateConstructorUsedError; // ID of the event this game belongs to (required for new games, optional for legacy)
  @TimestampConverter()
  DateTime get gameDate => throw _privateConstructorUsedError;
  String? get location =>
      throw _privateConstructorUsedError; // Legacy text location
  @NullableGeoPointConverter()
  GeoPoint? get locationPoint =>
      throw _privateConstructorUsedError; // New geographic location
  String? get geohash => throw _privateConstructorUsedError;
  String? get venueId =>
      throw _privateConstructorUsedError; // Reference to venue
  int get teamCount => throw _privateConstructorUsedError; // 2, 3, or 4
  @GameStatusConverter()
  GameStatus get status => throw _privateConstructorUsedError;
  @GameVisibilityConverter()
  GameVisibility get visibility =>
      throw _privateConstructorUsedError; // private, public, or recruiting
  TargetingCriteria? get targetingCriteria =>
      throw _privateConstructorUsedError;
  bool get requiresApproval => throw _privateConstructorUsedError;
  int get minPlayersToPlay => throw _privateConstructorUsedError;
  int? get maxPlayers => throw _privateConstructorUsedError;
  List<String> get photoUrls => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt =>
      throw _privateConstructorUsedError; // Recurring game fields
  bool get isRecurring => throw _privateConstructorUsedError;
  String? get parentGameId => throw _privateConstructorUsedError;
  String? get recurrencePattern => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  DateTime? get recurrenceEndDate =>
      throw _privateConstructorUsedError; // Teams
  List<Team> get teams =>
      throw _privateConstructorUsedError; // Teams created in TeamMaker
// Game rules
  int? get durationInMinutes => throw _privateConstructorUsedError;
  String? get gameEndCondition => throw _privateConstructorUsedError;
  String? get region => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError; // Community feed
  bool get showInCommunityFeed =>
      throw _privateConstructorUsedError; // Attendance
  bool get enableAttendanceReminder => throw _privateConstructorUsedError;
  bool? get reminderSent2Hours => throw _privateConstructorUsedError;
  DateTime? get reminderSent2HoursAt =>
      throw _privateConstructorUsedError; // Sub-models
  GameDenormalizedData get denormalized => throw _privateConstructorUsedError;
  GameSession get session => throw _privateConstructorUsedError;
  GameAudit get audit => throw _privateConstructorUsedError;

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
      String? hubId,
      String? eventId,
      @TimestampConverter() DateTime gameDate,
      String? location,
      @NullableGeoPointConverter() GeoPoint? locationPoint,
      String? geohash,
      String? venueId,
      int teamCount,
      @GameStatusConverter() GameStatus status,
      @GameVisibilityConverter() GameVisibility visibility,
      TargetingCriteria? targetingCriteria,
      bool requiresApproval,
      int minPlayersToPlay,
      int? maxPlayers,
      List<String> photoUrls,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt,
      bool isRecurring,
      String? parentGameId,
      String? recurrencePattern,
      @NullableTimestampConverter() DateTime? recurrenceEndDate,
      List<Team> teams,
      int? durationInMinutes,
      String? gameEndCondition,
      String? region,
      String? city,
      bool showInCommunityFeed,
      bool enableAttendanceReminder,
      bool? reminderSent2Hours,
      DateTime? reminderSent2HoursAt,
      GameDenormalizedData denormalized,
      GameSession session,
      GameAudit audit});

  $TargetingCriteriaCopyWith<$Res>? get targetingCriteria;
  $GameDenormalizedDataCopyWith<$Res> get denormalized;
  $GameSessionCopyWith<$Res> get session;
  $GameAuditCopyWith<$Res> get audit;
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
    Object? hubId = freezed,
    Object? eventId = freezed,
    Object? gameDate = null,
    Object? location = freezed,
    Object? locationPoint = freezed,
    Object? geohash = freezed,
    Object? venueId = freezed,
    Object? teamCount = null,
    Object? status = null,
    Object? visibility = null,
    Object? targetingCriteria = freezed,
    Object? requiresApproval = null,
    Object? minPlayersToPlay = null,
    Object? maxPlayers = freezed,
    Object? photoUrls = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isRecurring = null,
    Object? parentGameId = freezed,
    Object? recurrencePattern = freezed,
    Object? recurrenceEndDate = freezed,
    Object? teams = null,
    Object? durationInMinutes = freezed,
    Object? gameEndCondition = freezed,
    Object? region = freezed,
    Object? city = freezed,
    Object? showInCommunityFeed = null,
    Object? enableAttendanceReminder = null,
    Object? reminderSent2Hours = freezed,
    Object? reminderSent2HoursAt = freezed,
    Object? denormalized = null,
    Object? session = null,
    Object? audit = null,
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
      hubId: freezed == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      targetingCriteria: freezed == targetingCriteria
          ? _value.targetingCriteria
          : targetingCriteria // ignore: cast_nullable_to_non_nullable
              as TargetingCriteria?,
      requiresApproval: null == requiresApproval
          ? _value.requiresApproval
          : requiresApproval // ignore: cast_nullable_to_non_nullable
              as bool,
      minPlayersToPlay: null == minPlayersToPlay
          ? _value.minPlayersToPlay
          : minPlayersToPlay // ignore: cast_nullable_to_non_nullable
              as int,
      maxPlayers: freezed == maxPlayers
          ? _value.maxPlayers
          : maxPlayers // ignore: cast_nullable_to_non_nullable
              as int?,
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
      teams: null == teams
          ? _value.teams
          : teams // ignore: cast_nullable_to_non_nullable
              as List<Team>,
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
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      showInCommunityFeed: null == showInCommunityFeed
          ? _value.showInCommunityFeed
          : showInCommunityFeed // ignore: cast_nullable_to_non_nullable
              as bool,
      enableAttendanceReminder: null == enableAttendanceReminder
          ? _value.enableAttendanceReminder
          : enableAttendanceReminder // ignore: cast_nullable_to_non_nullable
              as bool,
      reminderSent2Hours: freezed == reminderSent2Hours
          ? _value.reminderSent2Hours
          : reminderSent2Hours // ignore: cast_nullable_to_non_nullable
              as bool?,
      reminderSent2HoursAt: freezed == reminderSent2HoursAt
          ? _value.reminderSent2HoursAt
          : reminderSent2HoursAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      denormalized: null == denormalized
          ? _value.denormalized
          : denormalized // ignore: cast_nullable_to_non_nullable
              as GameDenormalizedData,
      session: null == session
          ? _value.session
          : session // ignore: cast_nullable_to_non_nullable
              as GameSession,
      audit: null == audit
          ? _value.audit
          : audit // ignore: cast_nullable_to_non_nullable
              as GameAudit,
    ) as $Val);
  }

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TargetingCriteriaCopyWith<$Res>? get targetingCriteria {
    if (_value.targetingCriteria == null) {
      return null;
    }

    return $TargetingCriteriaCopyWith<$Res>(_value.targetingCriteria!, (value) {
      return _then(_value.copyWith(targetingCriteria: value) as $Val);
    });
  }

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameDenormalizedDataCopyWith<$Res> get denormalized {
    return $GameDenormalizedDataCopyWith<$Res>(_value.denormalized, (value) {
      return _then(_value.copyWith(denormalized: value) as $Val);
    });
  }

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameSessionCopyWith<$Res> get session {
    return $GameSessionCopyWith<$Res>(_value.session, (value) {
      return _then(_value.copyWith(session: value) as $Val);
    });
  }

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameAuditCopyWith<$Res> get audit {
    return $GameAuditCopyWith<$Res>(_value.audit, (value) {
      return _then(_value.copyWith(audit: value) as $Val);
    });
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
      String? hubId,
      String? eventId,
      @TimestampConverter() DateTime gameDate,
      String? location,
      @NullableGeoPointConverter() GeoPoint? locationPoint,
      String? geohash,
      String? venueId,
      int teamCount,
      @GameStatusConverter() GameStatus status,
      @GameVisibilityConverter() GameVisibility visibility,
      TargetingCriteria? targetingCriteria,
      bool requiresApproval,
      int minPlayersToPlay,
      int? maxPlayers,
      List<String> photoUrls,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt,
      bool isRecurring,
      String? parentGameId,
      String? recurrencePattern,
      @NullableTimestampConverter() DateTime? recurrenceEndDate,
      List<Team> teams,
      int? durationInMinutes,
      String? gameEndCondition,
      String? region,
      String? city,
      bool showInCommunityFeed,
      bool enableAttendanceReminder,
      bool? reminderSent2Hours,
      DateTime? reminderSent2HoursAt,
      GameDenormalizedData denormalized,
      GameSession session,
      GameAudit audit});

  @override
  $TargetingCriteriaCopyWith<$Res>? get targetingCriteria;
  @override
  $GameDenormalizedDataCopyWith<$Res> get denormalized;
  @override
  $GameSessionCopyWith<$Res> get session;
  @override
  $GameAuditCopyWith<$Res> get audit;
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
    Object? hubId = freezed,
    Object? eventId = freezed,
    Object? gameDate = null,
    Object? location = freezed,
    Object? locationPoint = freezed,
    Object? geohash = freezed,
    Object? venueId = freezed,
    Object? teamCount = null,
    Object? status = null,
    Object? visibility = null,
    Object? targetingCriteria = freezed,
    Object? requiresApproval = null,
    Object? minPlayersToPlay = null,
    Object? maxPlayers = freezed,
    Object? photoUrls = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isRecurring = null,
    Object? parentGameId = freezed,
    Object? recurrencePattern = freezed,
    Object? recurrenceEndDate = freezed,
    Object? teams = null,
    Object? durationInMinutes = freezed,
    Object? gameEndCondition = freezed,
    Object? region = freezed,
    Object? city = freezed,
    Object? showInCommunityFeed = null,
    Object? enableAttendanceReminder = null,
    Object? reminderSent2Hours = freezed,
    Object? reminderSent2HoursAt = freezed,
    Object? denormalized = null,
    Object? session = null,
    Object? audit = null,
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
      hubId: freezed == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      targetingCriteria: freezed == targetingCriteria
          ? _value.targetingCriteria
          : targetingCriteria // ignore: cast_nullable_to_non_nullable
              as TargetingCriteria?,
      requiresApproval: null == requiresApproval
          ? _value.requiresApproval
          : requiresApproval // ignore: cast_nullable_to_non_nullable
              as bool,
      minPlayersToPlay: null == minPlayersToPlay
          ? _value.minPlayersToPlay
          : minPlayersToPlay // ignore: cast_nullable_to_non_nullable
              as int,
      maxPlayers: freezed == maxPlayers
          ? _value.maxPlayers
          : maxPlayers // ignore: cast_nullable_to_non_nullable
              as int?,
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
      teams: null == teams
          ? _value._teams
          : teams // ignore: cast_nullable_to_non_nullable
              as List<Team>,
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
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      showInCommunityFeed: null == showInCommunityFeed
          ? _value.showInCommunityFeed
          : showInCommunityFeed // ignore: cast_nullable_to_non_nullable
              as bool,
      enableAttendanceReminder: null == enableAttendanceReminder
          ? _value.enableAttendanceReminder
          : enableAttendanceReminder // ignore: cast_nullable_to_non_nullable
              as bool,
      reminderSent2Hours: freezed == reminderSent2Hours
          ? _value.reminderSent2Hours
          : reminderSent2Hours // ignore: cast_nullable_to_non_nullable
              as bool?,
      reminderSent2HoursAt: freezed == reminderSent2HoursAt
          ? _value.reminderSent2HoursAt
          : reminderSent2HoursAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      denormalized: null == denormalized
          ? _value.denormalized
          : denormalized // ignore: cast_nullable_to_non_nullable
              as GameDenormalizedData,
      session: null == session
          ? _value.session
          : session // ignore: cast_nullable_to_non_nullable
              as GameSession,
      audit: null == audit
          ? _value.audit
          : audit // ignore: cast_nullable_to_non_nullable
              as GameAudit,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameImpl extends _Game {
  const _$GameImpl(
      {required this.gameId,
      required this.createdBy,
      this.hubId,
      this.eventId,
      @TimestampConverter() required this.gameDate,
      this.location,
      @NullableGeoPointConverter() this.locationPoint,
      this.geohash,
      this.venueId,
      this.teamCount = 2,
      @GameStatusConverter() this.status = GameStatus.teamSelection,
      @GameVisibilityConverter() this.visibility = GameVisibility.private,
      this.targetingCriteria,
      this.requiresApproval = false,
      this.minPlayersToPlay = 10,
      this.maxPlayers,
      final List<String> photoUrls = const [],
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() required this.updatedAt,
      this.isRecurring = false,
      this.parentGameId,
      this.recurrencePattern,
      @NullableTimestampConverter() this.recurrenceEndDate,
      final List<Team> teams = const [],
      this.durationInMinutes,
      this.gameEndCondition,
      this.region,
      this.city,
      this.showInCommunityFeed = false,
      this.enableAttendanceReminder = true,
      this.reminderSent2Hours,
      this.reminderSent2HoursAt,
      this.denormalized = const GameDenormalizedData(),
      this.session = const GameSession(),
      this.audit = const GameAudit()})
      : _photoUrls = photoUrls,
        _teams = teams,
        super._();

  factory _$GameImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameImplFromJson(json);

  @override
  final String gameId;
  @override
  final String createdBy;
  @override
  final String? hubId;
// Nullable for public pickup games
  @override
  final String? eventId;
// ID of the event this game belongs to (required for new games, optional for legacy)
  @override
  @TimestampConverter()
  final DateTime gameDate;
  @override
  final String? location;
// Legacy text location
  @override
  @NullableGeoPointConverter()
  final GeoPoint? locationPoint;
// New geographic location
  @override
  final String? geohash;
  @override
  final String? venueId;
// Reference to venue
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
  @override
  final TargetingCriteria? targetingCriteria;
  @override
  @JsonKey()
  final bool requiresApproval;
  @override
  @JsonKey()
  final int minPlayersToPlay;
  @override
  final int? maxPlayers;
  final List<String> _photoUrls;
  @override
  @JsonKey()
  List<String> get photoUrls {
    if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoUrls);
  }

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
  @override
  final String? parentGameId;
  @override
  final String? recurrencePattern;
  @override
  @NullableTimestampConverter()
  final DateTime? recurrenceEndDate;
// Teams
  final List<Team> _teams;
// Teams
  @override
  @JsonKey()
  List<Team> get teams {
    if (_teams is EqualUnmodifiableListView) return _teams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_teams);
  }

// Teams created in TeamMaker
// Game rules
  @override
  final int? durationInMinutes;
  @override
  final String? gameEndCondition;
  @override
  final String? region;
  @override
  final String? city;
// Community feed
  @override
  @JsonKey()
  final bool showInCommunityFeed;
// Attendance
  @override
  @JsonKey()
  final bool enableAttendanceReminder;
  @override
  final bool? reminderSent2Hours;
  @override
  final DateTime? reminderSent2HoursAt;
// Sub-models
  @override
  @JsonKey()
  final GameDenormalizedData denormalized;
  @override
  @JsonKey()
  final GameSession session;
  @override
  @JsonKey()
  final GameAudit audit;

  @override
  String toString() {
    return 'Game(gameId: $gameId, createdBy: $createdBy, hubId: $hubId, eventId: $eventId, gameDate: $gameDate, location: $location, locationPoint: $locationPoint, geohash: $geohash, venueId: $venueId, teamCount: $teamCount, status: $status, visibility: $visibility, targetingCriteria: $targetingCriteria, requiresApproval: $requiresApproval, minPlayersToPlay: $minPlayersToPlay, maxPlayers: $maxPlayers, photoUrls: $photoUrls, createdAt: $createdAt, updatedAt: $updatedAt, isRecurring: $isRecurring, parentGameId: $parentGameId, recurrencePattern: $recurrencePattern, recurrenceEndDate: $recurrenceEndDate, teams: $teams, durationInMinutes: $durationInMinutes, gameEndCondition: $gameEndCondition, region: $region, city: $city, showInCommunityFeed: $showInCommunityFeed, enableAttendanceReminder: $enableAttendanceReminder, reminderSent2Hours: $reminderSent2Hours, reminderSent2HoursAt: $reminderSent2HoursAt, denormalized: $denormalized, session: $session, audit: $audit)';
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
            (identical(other.targetingCriteria, targetingCriteria) ||
                other.targetingCriteria == targetingCriteria) &&
            (identical(other.requiresApproval, requiresApproval) ||
                other.requiresApproval == requiresApproval) &&
            (identical(other.minPlayersToPlay, minPlayersToPlay) ||
                other.minPlayersToPlay == minPlayersToPlay) &&
            (identical(other.maxPlayers, maxPlayers) ||
                other.maxPlayers == maxPlayers) &&
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
            const DeepCollectionEquality().equals(other._teams, _teams) &&
            (identical(other.durationInMinutes, durationInMinutes) ||
                other.durationInMinutes == durationInMinutes) &&
            (identical(other.gameEndCondition, gameEndCondition) ||
                other.gameEndCondition == gameEndCondition) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.showInCommunityFeed, showInCommunityFeed) ||
                other.showInCommunityFeed == showInCommunityFeed) &&
            (identical(
                    other.enableAttendanceReminder, enableAttendanceReminder) ||
                other.enableAttendanceReminder == enableAttendanceReminder) &&
            (identical(other.reminderSent2Hours, reminderSent2Hours) ||
                other.reminderSent2Hours == reminderSent2Hours) &&
            (identical(other.reminderSent2HoursAt, reminderSent2HoursAt) ||
                other.reminderSent2HoursAt == reminderSent2HoursAt) &&
            (identical(other.denormalized, denormalized) ||
                other.denormalized == denormalized) &&
            (identical(other.session, session) || other.session == session) &&
            (identical(other.audit, audit) || other.audit == audit));
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
        targetingCriteria,
        requiresApproval,
        minPlayersToPlay,
        maxPlayers,
        const DeepCollectionEquality().hash(_photoUrls),
        createdAt,
        updatedAt,
        isRecurring,
        parentGameId,
        recurrencePattern,
        recurrenceEndDate,
        const DeepCollectionEquality().hash(_teams),
        durationInMinutes,
        gameEndCondition,
        region,
        city,
        showInCommunityFeed,
        enableAttendanceReminder,
        reminderSent2Hours,
        reminderSent2HoursAt,
        denormalized,
        session,
        audit
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

abstract class _Game extends Game {
  const factory _Game(
      {required final String gameId,
      required final String createdBy,
      final String? hubId,
      final String? eventId,
      @TimestampConverter() required final DateTime gameDate,
      final String? location,
      @NullableGeoPointConverter() final GeoPoint? locationPoint,
      final String? geohash,
      final String? venueId,
      final int teamCount,
      @GameStatusConverter() final GameStatus status,
      @GameVisibilityConverter() final GameVisibility visibility,
      final TargetingCriteria? targetingCriteria,
      final bool requiresApproval,
      final int minPlayersToPlay,
      final int? maxPlayers,
      final List<String> photoUrls,
      @TimestampConverter() required final DateTime createdAt,
      @TimestampConverter() required final DateTime updatedAt,
      final bool isRecurring,
      final String? parentGameId,
      final String? recurrencePattern,
      @NullableTimestampConverter() final DateTime? recurrenceEndDate,
      final List<Team> teams,
      final int? durationInMinutes,
      final String? gameEndCondition,
      final String? region,
      final String? city,
      final bool showInCommunityFeed,
      final bool enableAttendanceReminder,
      final bool? reminderSent2Hours,
      final DateTime? reminderSent2HoursAt,
      final GameDenormalizedData denormalized,
      final GameSession session,
      final GameAudit audit}) = _$GameImpl;
  const _Game._() : super._();

  factory _Game.fromJson(Map<String, dynamic> json) = _$GameImpl.fromJson;

  @override
  String get gameId;
  @override
  String get createdBy;
  @override
  String? get hubId; // Nullable for public pickup games
  @override
  String?
      get eventId; // ID of the event this game belongs to (required for new games, optional for legacy)
  @override
  @TimestampConverter()
  DateTime get gameDate;
  @override
  String? get location; // Legacy text location
  @override
  @NullableGeoPointConverter()
  GeoPoint? get locationPoint; // New geographic location
  @override
  String? get geohash;
  @override
  String? get venueId; // Reference to venue
  @override
  int get teamCount; // 2, 3, or 4
  @override
  @GameStatusConverter()
  GameStatus get status;
  @override
  @GameVisibilityConverter()
  GameVisibility get visibility; // private, public, or recruiting
  @override
  TargetingCriteria? get targetingCriteria;
  @override
  bool get requiresApproval;
  @override
  int get minPlayersToPlay;
  @override
  int? get maxPlayers;
  @override
  List<String> get photoUrls;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt; // Recurring game fields
  @override
  bool get isRecurring;
  @override
  String? get parentGameId;
  @override
  String? get recurrencePattern;
  @override
  @NullableTimestampConverter()
  DateTime? get recurrenceEndDate; // Teams
  @override
  List<Team> get teams; // Teams created in TeamMaker
// Game rules
  @override
  int? get durationInMinutes;
  @override
  String? get gameEndCondition;
  @override
  String? get region;
  @override
  String? get city; // Community feed
  @override
  bool get showInCommunityFeed; // Attendance
  @override
  bool get enableAttendanceReminder;
  @override
  bool? get reminderSent2Hours;
  @override
  DateTime? get reminderSent2HoursAt; // Sub-models
  @override
  GameDenormalizedData get denormalized;
  @override
  GameSession get session;
  @override
  GameAudit get audit;

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameImplCopyWith<_$GameImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
