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
  List<Team> get teams => throw _privateConstructorUsedError;

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
      List<Team> teams});
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
      List<Team> teams});
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
      required final List<Team> teams})
      : _playerIds = playerIds,
        _teams = teams;

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

  @override
  String toString() {
    return 'LogPastGameDetails(hubId: $hubId, gameDate: $gameDate, venueId: $venueId, eventId: $eventId, teamAScore: $teamAScore, teamBScore: $teamBScore, playerIds: $playerIds, teams: $teams)';
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
            const DeepCollectionEquality().equals(other._teams, _teams));
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
      const DeepCollectionEquality().hash(_teams));

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
      required final List<Team> teams}) = _$LogPastGameDetailsImpl;

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
  List<Team> get teams;

  /// Create a copy of LogPastGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LogPastGameDetailsImplCopyWith<_$LogPastGameDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
