// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_past_game_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LogPastGameDetails _$LogPastGameDetailsFromJson(Map<String, dynamic> json) {
  return _LogPastGameDetails.fromJson(json);
}

/// @nodoc
mixin _$LogPastGameDetails {
  String get hubId => throw _privateConstructorUsedError;
  DateTime get gameDate => throw _privateConstructorUsedError;
  String? get venueId => throw _privateConstructorUsedError;
  String? get eventId =>
      throw _privateConstructorUsedError; // Link to hub event (optional)
  int get teamAScore => throw _privateConstructorUsedError;
  int get teamBScore => throw _privateConstructorUsedError;
  List<String> get playerIds =>
      throw _privateConstructorUsedError; // Players who participated
  List<Team> get teams =>
      throw _privateConstructorUsedError; // Teams with player assignments
  bool get showInCommunityFeed =>
      throw _privateConstructorUsedError; // Show this game in the community activity feed
  List<String> get goalScorerIds =>
      throw _privateConstructorUsedError; // IDs of players who scored (optional)
  List<String> get goalScorerNames =>
      throw _privateConstructorUsedError; // Names of goal scorers (optional, denormalized)
  String? get mvpPlayerId =>
      throw _privateConstructorUsedError; // MVP player ID (optional)
  String? get mvpPlayerName =>
      throw _privateConstructorUsedError; // MVP player name (optional, denormalized)
  String? get venueName => throw _privateConstructorUsedError;

  /// Serializes this LogPastGameDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LogPastGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LogPastGameDetailsCopyWith<LogPastGameDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LogPastGameDetailsCopyWith<$Res> {
  factory $LogPastGameDetailsCopyWith(
          LogPastGameDetails value, $Res Function(LogPastGameDetails) then) =
      _$LogPastGameDetailsCopyWithImpl<$Res, LogPastGameDetails>;
  @useResult
  $Res call(
      {String hubId,
      DateTime gameDate,
      String? venueId,
      String? eventId,
      int teamAScore,
      int teamBScore,
      List<String> playerIds,
      List<Team> teams,
      bool showInCommunityFeed,
      List<String> goalScorerIds,
      List<String> goalScorerNames,
      String? mvpPlayerId,
      String? mvpPlayerName,
      String? venueName});
}

/// @nodoc
class _$LogPastGameDetailsCopyWithImpl<$Res, $Val extends LogPastGameDetails>
    implements $LogPastGameDetailsCopyWith<$Res> {
  _$LogPastGameDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LogPastGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hubId = null,
    Object? gameDate = null,
    Object? venueId = freezed,
    Object? eventId = freezed,
    Object? teamAScore = null,
    Object? teamBScore = null,
    Object? playerIds = null,
    Object? teams = null,
    Object? showInCommunityFeed = null,
    Object? goalScorerIds = null,
    Object? goalScorerNames = null,
    Object? mvpPlayerId = freezed,
    Object? mvpPlayerName = freezed,
    Object? venueName = freezed,
  }) {
    return _then(_value.copyWith(
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      gameDate: null == gameDate
          ? _value.gameDate
          : gameDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      venueId: freezed == venueId
          ? _value.venueId
          : venueId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventId: freezed == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      teamAScore: null == teamAScore
          ? _value.teamAScore
          : teamAScore // ignore: cast_nullable_to_non_nullable
              as int,
      teamBScore: null == teamBScore
          ? _value.teamBScore
          : teamBScore // ignore: cast_nullable_to_non_nullable
              as int,
      playerIds: null == playerIds
          ? _value.playerIds
          : playerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      teams: null == teams
          ? _value.teams
          : teams // ignore: cast_nullable_to_non_nullable
              as List<Team>,
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
abstract class _$$LogPastGameDetailsImplCopyWith<$Res>
    implements $LogPastGameDetailsCopyWith<$Res> {
  factory _$$LogPastGameDetailsImplCopyWith(_$LogPastGameDetailsImpl value,
          $Res Function(_$LogPastGameDetailsImpl) then) =
      __$$LogPastGameDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String hubId,
      DateTime gameDate,
      String? venueId,
      String? eventId,
      int teamAScore,
      int teamBScore,
      List<String> playerIds,
      List<Team> teams,
      bool showInCommunityFeed,
      List<String> goalScorerIds,
      List<String> goalScorerNames,
      String? mvpPlayerId,
      String? mvpPlayerName,
      String? venueName});
}

/// @nodoc
class __$$LogPastGameDetailsImplCopyWithImpl<$Res>
    extends _$LogPastGameDetailsCopyWithImpl<$Res, _$LogPastGameDetailsImpl>
    implements _$$LogPastGameDetailsImplCopyWith<$Res> {
  __$$LogPastGameDetailsImplCopyWithImpl(_$LogPastGameDetailsImpl _value,
      $Res Function(_$LogPastGameDetailsImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogPastGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hubId = null,
    Object? gameDate = null,
    Object? venueId = freezed,
    Object? eventId = freezed,
    Object? teamAScore = null,
    Object? teamBScore = null,
    Object? playerIds = null,
    Object? teams = null,
    Object? showInCommunityFeed = null,
    Object? goalScorerIds = null,
    Object? goalScorerNames = null,
    Object? mvpPlayerId = freezed,
    Object? mvpPlayerName = freezed,
    Object? venueName = freezed,
  }) {
    return _then(_$LogPastGameDetailsImpl(
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      gameDate: null == gameDate
          ? _value.gameDate
          : gameDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      venueId: freezed == venueId
          ? _value.venueId
          : venueId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventId: freezed == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      teamAScore: null == teamAScore
          ? _value.teamAScore
          : teamAScore // ignore: cast_nullable_to_non_nullable
              as int,
      teamBScore: null == teamBScore
          ? _value.teamBScore
          : teamBScore // ignore: cast_nullable_to_non_nullable
              as int,
      playerIds: null == playerIds
          ? _value._playerIds
          : playerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      teams: null == teams
          ? _value._teams
          : teams // ignore: cast_nullable_to_non_nullable
              as List<Team>,
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
class _$LogPastGameDetailsImpl implements _LogPastGameDetails {
  const _$LogPastGameDetailsImpl(
      {required this.hubId,
      required this.gameDate,
      this.venueId,
      this.eventId,
      required this.teamAScore,
      required this.teamBScore,
      required final List<String> playerIds,
      required final List<Team> teams,
      this.showInCommunityFeed = false,
      final List<String> goalScorerIds = const [],
      final List<String> goalScorerNames = const [],
      this.mvpPlayerId,
      this.mvpPlayerName,
      this.venueName})
      : _playerIds = playerIds,
        _teams = teams,
        _goalScorerIds = goalScorerIds,
        _goalScorerNames = goalScorerNames;

  factory _$LogPastGameDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$LogPastGameDetailsImplFromJson(json);

  @override
  final String hubId;
  @override
  final DateTime gameDate;
  @override
  final String? venueId;
  @override
  final String? eventId;
// Link to hub event (optional)
  @override
  final int teamAScore;
  @override
  final int teamBScore;
  final List<String> _playerIds;
  @override
  List<String> get playerIds {
    if (_playerIds is EqualUnmodifiableListView) return _playerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playerIds);
  }

// Players who participated
  final List<Team> _teams;
// Players who participated
  @override
  List<Team> get teams {
    if (_teams is EqualUnmodifiableListView) return _teams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_teams);
  }

// Teams with player assignments
  @override
  @JsonKey()
  final bool showInCommunityFeed;
// Show this game in the community activity feed
  final List<String> _goalScorerIds;
// Show this game in the community activity feed
  @override
  @JsonKey()
  List<String> get goalScorerIds {
    if (_goalScorerIds is EqualUnmodifiableListView) return _goalScorerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_goalScorerIds);
  }

// IDs of players who scored (optional)
  final List<String> _goalScorerNames;
// IDs of players who scored (optional)
  @override
  @JsonKey()
  List<String> get goalScorerNames {
    if (_goalScorerNames is EqualUnmodifiableListView) return _goalScorerNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_goalScorerNames);
  }

// Names of goal scorers (optional, denormalized)
  @override
  final String? mvpPlayerId;
// MVP player ID (optional)
  @override
  final String? mvpPlayerName;
// MVP player name (optional, denormalized)
  @override
  final String? venueName;

  @override
  String toString() {
    return 'LogPastGameDetails(hubId: $hubId, gameDate: $gameDate, venueId: $venueId, eventId: $eventId, teamAScore: $teamAScore, teamBScore: $teamBScore, playerIds: $playerIds, teams: $teams, showInCommunityFeed: $showInCommunityFeed, goalScorerIds: $goalScorerIds, goalScorerNames: $goalScorerNames, mvpPlayerId: $mvpPlayerId, mvpPlayerName: $mvpPlayerName, venueName: $venueName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LogPastGameDetailsImpl &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.gameDate, gameDate) ||
                other.gameDate == gameDate) &&
            (identical(other.venueId, venueId) || other.venueId == venueId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.teamAScore, teamAScore) ||
                other.teamAScore == teamAScore) &&
            (identical(other.teamBScore, teamBScore) ||
                other.teamBScore == teamBScore) &&
            const DeepCollectionEquality()
                .equals(other._playerIds, _playerIds) &&
            const DeepCollectionEquality().equals(other._teams, _teams) &&
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
  int get hashCode => Object.hash(
      runtimeType,
      hubId,
      gameDate,
      venueId,
      eventId,
      teamAScore,
      teamBScore,
      const DeepCollectionEquality().hash(_playerIds),
      const DeepCollectionEquality().hash(_teams),
      showInCommunityFeed,
      const DeepCollectionEquality().hash(_goalScorerIds),
      const DeepCollectionEquality().hash(_goalScorerNames),
      mvpPlayerId,
      mvpPlayerName,
      venueName);

  /// Create a copy of LogPastGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LogPastGameDetailsImplCopyWith<_$LogPastGameDetailsImpl> get copyWith =>
      __$$LogPastGameDetailsImplCopyWithImpl<_$LogPastGameDetailsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LogPastGameDetailsImplToJson(
      this,
    );
  }
}

abstract class _LogPastGameDetails implements LogPastGameDetails {
  const factory _LogPastGameDetails(
      {required final String hubId,
      required final DateTime gameDate,
      final String? venueId,
      final String? eventId,
      required final int teamAScore,
      required final int teamBScore,
      required final List<String> playerIds,
      required final List<Team> teams,
      final bool showInCommunityFeed,
      final List<String> goalScorerIds,
      final List<String> goalScorerNames,
      final String? mvpPlayerId,
      final String? mvpPlayerName,
      final String? venueName}) = _$LogPastGameDetailsImpl;

  factory _LogPastGameDetails.fromJson(Map<String, dynamic> json) =
      _$LogPastGameDetailsImpl.fromJson;

  @override
  String get hubId;
  @override
  DateTime get gameDate;
  @override
  String? get venueId;
  @override
  String? get eventId; // Link to hub event (optional)
  @override
  int get teamAScore;
  @override
  int get teamBScore;
  @override
  List<String> get playerIds; // Players who participated
  @override
  List<Team> get teams; // Teams with player assignments
  @override
  bool get showInCommunityFeed; // Show this game in the community activity feed
  @override
  List<String> get goalScorerIds; // IDs of players who scored (optional)
  @override
  List<String>
      get goalScorerNames; // Names of goal scorers (optional, denormalized)
  @override
  String? get mvpPlayerId; // MVP player ID (optional)
  @override
  String? get mvpPlayerName; // MVP player name (optional, denormalized)
  @override
  String? get venueName;

  /// Create a copy of LogPastGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LogPastGameDetailsImplCopyWith<_$LogPastGameDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
