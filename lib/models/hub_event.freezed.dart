// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hub_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HubEvent _$HubEventFromJson(Map<String, dynamic> json) {
  return _HubEvent.fromJson(json);
}

/// @nodoc
mixin _$HubEvent {
  String get eventId => throw _privateConstructorUsedError;
  String get hubId => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get eventDate => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;
  List<String> get registeredPlayerIds =>
      throw _privateConstructorUsedError; // Players who registered
  String get status =>
      throw _privateConstructorUsedError; // upcoming, ongoing, completed, cancelled
  String? get location => throw _privateConstructorUsedError;
  @NullableGeoPointConverter()
  GeoPoint? get locationPoint => throw _privateConstructorUsedError;
  String? get geohash => throw _privateConstructorUsedError;
  int get teamCount =>
      throw _privateConstructorUsedError; // Number of teams (default: 3)
  String? get gameType =>
      throw _privateConstructorUsedError; // 3v3, 4v4, 5v5, 6v6, 7v7, 8v8, 9v9, 10v10, 11v11
  int? get durationMinutes =>
      throw _privateConstructorUsedError; // Game duration in minutes (default: 12)
  int get maxParticipants =>
      throw _privateConstructorUsedError; // Maximum number of participants (default: 15, required)
  bool get notifyMembers =>
      throw _privateConstructorUsedError; // Send notification to all hub members when event is created
  bool get showInCommunityFeed =>
      throw _privateConstructorUsedError; // Show this event in the community activity feed
// Teams planned for this event (manager-only, saved when using TeamMaker)
  List<Team> get teams =>
      throw _privateConstructorUsedError; // Teams planned for this event (manager-only)
// Multi-match session support
  List<MatchResult> get matches =>
      throw _privateConstructorUsedError; // List of individual match outcomes within this event
  Map<String, int> get aggregateWins =>
      throw _privateConstructorUsedError; // Summary: {'Blue': 6, 'Red': 4, 'Green': 2}
// Reference to Game if event was converted to game
  String? get gameId => throw _privateConstructorUsedError;

  /// Serializes this HubEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HubEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HubEventCopyWith<HubEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HubEventCopyWith<$Res> {
  factory $HubEventCopyWith(HubEvent value, $Res Function(HubEvent) then) =
      _$HubEventCopyWithImpl<$Res, HubEvent>;
  @useResult
  $Res call(
      {String eventId,
      String hubId,
      String createdBy,
      String title,
      String? description,
      @TimestampConverter() DateTime eventDate,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt,
      List<String> registeredPlayerIds,
      String status,
      String? location,
      @NullableGeoPointConverter() GeoPoint? locationPoint,
      String? geohash,
      int teamCount,
      String? gameType,
      int? durationMinutes,
      int maxParticipants,
      bool notifyMembers,
      bool showInCommunityFeed,
      List<Team> teams,
      List<MatchResult> matches,
      Map<String, int> aggregateWins,
      String? gameId});
}

/// @nodoc
class _$HubEventCopyWithImpl<$Res, $Val extends HubEvent>
    implements $HubEventCopyWith<$Res> {
  _$HubEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HubEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? hubId = null,
    Object? createdBy = null,
    Object? title = null,
    Object? description = freezed,
    Object? eventDate = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? registeredPlayerIds = null,
    Object? status = null,
    Object? location = freezed,
    Object? locationPoint = freezed,
    Object? geohash = freezed,
    Object? teamCount = null,
    Object? gameType = freezed,
    Object? durationMinutes = freezed,
    Object? maxParticipants = null,
    Object? notifyMembers = null,
    Object? showInCommunityFeed = null,
    Object? teams = null,
    Object? matches = null,
    Object? aggregateWins = null,
    Object? gameId = freezed,
  }) {
    return _then(_value.copyWith(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      registeredPlayerIds: null == registeredPlayerIds
          ? _value.registeredPlayerIds
          : registeredPlayerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
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
      teamCount: null == teamCount
          ? _value.teamCount
          : teamCount // ignore: cast_nullable_to_non_nullable
              as int,
      gameType: freezed == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMinutes: freezed == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      maxParticipants: null == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      notifyMembers: null == notifyMembers
          ? _value.notifyMembers
          : notifyMembers // ignore: cast_nullable_to_non_nullable
              as bool,
      showInCommunityFeed: null == showInCommunityFeed
          ? _value.showInCommunityFeed
          : showInCommunityFeed // ignore: cast_nullable_to_non_nullable
              as bool,
      teams: null == teams
          ? _value.teams
          : teams // ignore: cast_nullable_to_non_nullable
              as List<Team>,
      matches: null == matches
          ? _value.matches
          : matches // ignore: cast_nullable_to_non_nullable
              as List<MatchResult>,
      aggregateWins: null == aggregateWins
          ? _value.aggregateWins
          : aggregateWins // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      gameId: freezed == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HubEventImplCopyWith<$Res>
    implements $HubEventCopyWith<$Res> {
  factory _$$HubEventImplCopyWith(
          _$HubEventImpl value, $Res Function(_$HubEventImpl) then) =
      __$$HubEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String eventId,
      String hubId,
      String createdBy,
      String title,
      String? description,
      @TimestampConverter() DateTime eventDate,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt,
      List<String> registeredPlayerIds,
      String status,
      String? location,
      @NullableGeoPointConverter() GeoPoint? locationPoint,
      String? geohash,
      int teamCount,
      String? gameType,
      int? durationMinutes,
      int maxParticipants,
      bool notifyMembers,
      bool showInCommunityFeed,
      List<Team> teams,
      List<MatchResult> matches,
      Map<String, int> aggregateWins,
      String? gameId});
}

/// @nodoc
class __$$HubEventImplCopyWithImpl<$Res>
    extends _$HubEventCopyWithImpl<$Res, _$HubEventImpl>
    implements _$$HubEventImplCopyWith<$Res> {
  __$$HubEventImplCopyWithImpl(
      _$HubEventImpl _value, $Res Function(_$HubEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of HubEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? hubId = null,
    Object? createdBy = null,
    Object? title = null,
    Object? description = freezed,
    Object? eventDate = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? registeredPlayerIds = null,
    Object? status = null,
    Object? location = freezed,
    Object? locationPoint = freezed,
    Object? geohash = freezed,
    Object? teamCount = null,
    Object? gameType = freezed,
    Object? durationMinutes = freezed,
    Object? maxParticipants = null,
    Object? notifyMembers = null,
    Object? showInCommunityFeed = null,
    Object? teams = null,
    Object? matches = null,
    Object? aggregateWins = null,
    Object? gameId = freezed,
  }) {
    return _then(_$HubEventImpl(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      registeredPlayerIds: null == registeredPlayerIds
          ? _value._registeredPlayerIds
          : registeredPlayerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
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
      teamCount: null == teamCount
          ? _value.teamCount
          : teamCount // ignore: cast_nullable_to_non_nullable
              as int,
      gameType: freezed == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMinutes: freezed == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      maxParticipants: null == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      notifyMembers: null == notifyMembers
          ? _value.notifyMembers
          : notifyMembers // ignore: cast_nullable_to_non_nullable
              as bool,
      showInCommunityFeed: null == showInCommunityFeed
          ? _value.showInCommunityFeed
          : showInCommunityFeed // ignore: cast_nullable_to_non_nullable
              as bool,
      teams: null == teams
          ? _value._teams
          : teams // ignore: cast_nullable_to_non_nullable
              as List<Team>,
      matches: null == matches
          ? _value._matches
          : matches // ignore: cast_nullable_to_non_nullable
              as List<MatchResult>,
      aggregateWins: null == aggregateWins
          ? _value._aggregateWins
          : aggregateWins // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      gameId: freezed == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HubEventImpl implements _HubEvent {
  const _$HubEventImpl(
      {required this.eventId,
      required this.hubId,
      required this.createdBy,
      required this.title,
      this.description,
      @TimestampConverter() required this.eventDate,
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() required this.updatedAt,
      final List<String> registeredPlayerIds = const [],
      this.status = 'upcoming',
      this.location,
      @NullableGeoPointConverter() this.locationPoint,
      this.geohash,
      this.teamCount = 3,
      this.gameType,
      this.durationMinutes,
      this.maxParticipants = 15,
      this.notifyMembers = false,
      this.showInCommunityFeed = false,
      final List<Team> teams = const [],
      final List<MatchResult> matches = const [],
      final Map<String, int> aggregateWins = const {},
      this.gameId})
      : _registeredPlayerIds = registeredPlayerIds,
        _teams = teams,
        _matches = matches,
        _aggregateWins = aggregateWins;

  factory _$HubEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$HubEventImplFromJson(json);

  @override
  final String eventId;
  @override
  final String hubId;
  @override
  final String createdBy;
  @override
  final String title;
  @override
  final String? description;
  @override
  @TimestampConverter()
  final DateTime eventDate;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;
  final List<String> _registeredPlayerIds;
  @override
  @JsonKey()
  List<String> get registeredPlayerIds {
    if (_registeredPlayerIds is EqualUnmodifiableListView)
      return _registeredPlayerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_registeredPlayerIds);
  }

// Players who registered
  @override
  @JsonKey()
  final String status;
// upcoming, ongoing, completed, cancelled
  @override
  final String? location;
  @override
  @NullableGeoPointConverter()
  final GeoPoint? locationPoint;
  @override
  final String? geohash;
  @override
  @JsonKey()
  final int teamCount;
// Number of teams (default: 3)
  @override
  final String? gameType;
// 3v3, 4v4, 5v5, 6v6, 7v7, 8v8, 9v9, 10v10, 11v11
  @override
  final int? durationMinutes;
// Game duration in minutes (default: 12)
  @override
  @JsonKey()
  final int maxParticipants;
// Maximum number of participants (default: 15, required)
  @override
  @JsonKey()
  final bool notifyMembers;
// Send notification to all hub members when event is created
  @override
  @JsonKey()
  final bool showInCommunityFeed;
// Show this event in the community activity feed
// Teams planned for this event (manager-only, saved when using TeamMaker)
  final List<Team> _teams;
// Show this event in the community activity feed
// Teams planned for this event (manager-only, saved when using TeamMaker)
  @override
  @JsonKey()
  List<Team> get teams {
    if (_teams is EqualUnmodifiableListView) return _teams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_teams);
  }

// Teams planned for this event (manager-only)
// Multi-match session support
  final List<MatchResult> _matches;
// Teams planned for this event (manager-only)
// Multi-match session support
  @override
  @JsonKey()
  List<MatchResult> get matches {
    if (_matches is EqualUnmodifiableListView) return _matches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_matches);
  }

// List of individual match outcomes within this event
  final Map<String, int> _aggregateWins;
// List of individual match outcomes within this event
  @override
  @JsonKey()
  Map<String, int> get aggregateWins {
    if (_aggregateWins is EqualUnmodifiableMapView) return _aggregateWins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_aggregateWins);
  }

// Summary: {'Blue': 6, 'Red': 4, 'Green': 2}
// Reference to Game if event was converted to game
  @override
  final String? gameId;

  @override
  String toString() {
    return 'HubEvent(eventId: $eventId, hubId: $hubId, createdBy: $createdBy, title: $title, description: $description, eventDate: $eventDate, createdAt: $createdAt, updatedAt: $updatedAt, registeredPlayerIds: $registeredPlayerIds, status: $status, location: $location, locationPoint: $locationPoint, geohash: $geohash, teamCount: $teamCount, gameType: $gameType, durationMinutes: $durationMinutes, maxParticipants: $maxParticipants, notifyMembers: $notifyMembers, showInCommunityFeed: $showInCommunityFeed, teams: $teams, matches: $matches, aggregateWins: $aggregateWins, gameId: $gameId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HubEventImpl &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.eventDate, eventDate) ||
                other.eventDate == eventDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality()
                .equals(other._registeredPlayerIds, _registeredPlayerIds) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.locationPoint, locationPoint) ||
                other.locationPoint == locationPoint) &&
            (identical(other.geohash, geohash) || other.geohash == geohash) &&
            (identical(other.teamCount, teamCount) ||
                other.teamCount == teamCount) &&
            (identical(other.gameType, gameType) ||
                other.gameType == gameType) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.maxParticipants, maxParticipants) ||
                other.maxParticipants == maxParticipants) &&
            (identical(other.notifyMembers, notifyMembers) ||
                other.notifyMembers == notifyMembers) &&
            (identical(other.showInCommunityFeed, showInCommunityFeed) ||
                other.showInCommunityFeed == showInCommunityFeed) &&
            const DeepCollectionEquality().equals(other._teams, _teams) &&
            const DeepCollectionEquality().equals(other._matches, _matches) &&
            const DeepCollectionEquality()
                .equals(other._aggregateWins, _aggregateWins) &&
            (identical(other.gameId, gameId) || other.gameId == gameId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        eventId,
        hubId,
        createdBy,
        title,
        description,
        eventDate,
        createdAt,
        updatedAt,
        const DeepCollectionEquality().hash(_registeredPlayerIds),
        status,
        location,
        locationPoint,
        geohash,
        teamCount,
        gameType,
        durationMinutes,
        maxParticipants,
        notifyMembers,
        showInCommunityFeed,
        const DeepCollectionEquality().hash(_teams),
        const DeepCollectionEquality().hash(_matches),
        const DeepCollectionEquality().hash(_aggregateWins),
        gameId
      ]);

  /// Create a copy of HubEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HubEventImplCopyWith<_$HubEventImpl> get copyWith =>
      __$$HubEventImplCopyWithImpl<_$HubEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HubEventImplToJson(
      this,
    );
  }
}

abstract class _HubEvent implements HubEvent {
  const factory _HubEvent(
      {required final String eventId,
      required final String hubId,
      required final String createdBy,
      required final String title,
      final String? description,
      @TimestampConverter() required final DateTime eventDate,
      @TimestampConverter() required final DateTime createdAt,
      @TimestampConverter() required final DateTime updatedAt,
      final List<String> registeredPlayerIds,
      final String status,
      final String? location,
      @NullableGeoPointConverter() final GeoPoint? locationPoint,
      final String? geohash,
      final int teamCount,
      final String? gameType,
      final int? durationMinutes,
      final int maxParticipants,
      final bool notifyMembers,
      final bool showInCommunityFeed,
      final List<Team> teams,
      final List<MatchResult> matches,
      final Map<String, int> aggregateWins,
      final String? gameId}) = _$HubEventImpl;

  factory _HubEvent.fromJson(Map<String, dynamic> json) =
      _$HubEventImpl.fromJson;

  @override
  String get eventId;
  @override
  String get hubId;
  @override
  String get createdBy;
  @override
  String get title;
  @override
  String? get description;
  @override
  @TimestampConverter()
  DateTime get eventDate;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;
  @override
  List<String> get registeredPlayerIds; // Players who registered
  @override
  String get status; // upcoming, ongoing, completed, cancelled
  @override
  String? get location;
  @override
  @NullableGeoPointConverter()
  GeoPoint? get locationPoint;
  @override
  String? get geohash;
  @override
  int get teamCount; // Number of teams (default: 3)
  @override
  String? get gameType; // 3v3, 4v4, 5v5, 6v6, 7v7, 8v8, 9v9, 10v10, 11v11
  @override
  int? get durationMinutes; // Game duration in minutes (default: 12)
  @override
  int get maxParticipants; // Maximum number of participants (default: 15, required)
  @override
  bool
      get notifyMembers; // Send notification to all hub members when event is created
  @override
  bool
      get showInCommunityFeed; // Show this event in the community activity feed
// Teams planned for this event (manager-only, saved when using TeamMaker)
  @override
  List<Team> get teams; // Teams planned for this event (manager-only)
// Multi-match session support
  @override
  List<MatchResult>
      get matches; // List of individual match outcomes within this event
  @override
  Map<String, int>
      get aggregateWins; // Summary: {'Blue': 6, 'Red': 4, 'Green': 2}
// Reference to Game if event was converted to game
  @override
  String? get gameId;

  /// Create a copy of HubEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HubEventImplCopyWith<_$HubEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
