// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MatchRecord _$MatchRecordFromJson(Map<String, dynamic> json) {
  return _MatchRecord.fromJson(json);
}

/// @nodoc
mixin _$MatchRecord {
  String get id => throw _privateConstructorUsedError;
  String get eventId => throw _privateConstructorUsedError;
  String get hubId =>
      throw _privateConstructorUsedError; // Teams involved (Team IDs or Names/Colors)
  String get teamAId => throw _privateConstructorUsedError;
  String get teamBId => throw _privateConstructorUsedError;
  String get teamAName => throw _privateConstructorUsedError;
  String get teamBName => throw _privateConstructorUsedError; // Score
  int get scoreTeamA => throw _privateConstructorUsedError;
  int get scoreTeamB => throw _privateConstructorUsedError; // Stats
  Map<String, int> get scorers =>
      throw _privateConstructorUsedError; // PlayerID -> Goals
  Map<String, int> get assists =>
      throw _privateConstructorUsedError; // PlayerID -> Assists
  String? get mvpPlayerId => throw _privateConstructorUsedError; // Metadata
  int get durationSeconds => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get timestamp => throw _privateConstructorUsedError;
  String get recordedBy => throw _privateConstructorUsedError;

  /// Serializes this MatchRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatchRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatchRecordCopyWith<MatchRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchRecordCopyWith<$Res> {
  factory $MatchRecordCopyWith(
          MatchRecord value, $Res Function(MatchRecord) then) =
      _$MatchRecordCopyWithImpl<$Res, MatchRecord>;
  @useResult
  $Res call(
      {String id,
      String eventId,
      String hubId,
      String teamAId,
      String teamBId,
      String teamAName,
      String teamBName,
      int scoreTeamA,
      int scoreTeamB,
      Map<String, int> scorers,
      Map<String, int> assists,
      String? mvpPlayerId,
      int durationSeconds,
      @TimestampConverter() DateTime timestamp,
      String recordedBy});
}

/// @nodoc
class _$MatchRecordCopyWithImpl<$Res, $Val extends MatchRecord>
    implements $MatchRecordCopyWith<$Res> {
  _$MatchRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatchRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eventId = null,
    Object? hubId = null,
    Object? teamAId = null,
    Object? teamBId = null,
    Object? teamAName = null,
    Object? teamBName = null,
    Object? scoreTeamA = null,
    Object? scoreTeamB = null,
    Object? scorers = null,
    Object? assists = null,
    Object? mvpPlayerId = freezed,
    Object? durationSeconds = null,
    Object? timestamp = null,
    Object? recordedBy = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      teamAId: null == teamAId
          ? _value.teamAId
          : teamAId // ignore: cast_nullable_to_non_nullable
              as String,
      teamBId: null == teamBId
          ? _value.teamBId
          : teamBId // ignore: cast_nullable_to_non_nullable
              as String,
      teamAName: null == teamAName
          ? _value.teamAName
          : teamAName // ignore: cast_nullable_to_non_nullable
              as String,
      teamBName: null == teamBName
          ? _value.teamBName
          : teamBName // ignore: cast_nullable_to_non_nullable
              as String,
      scoreTeamA: null == scoreTeamA
          ? _value.scoreTeamA
          : scoreTeamA // ignore: cast_nullable_to_non_nullable
              as int,
      scoreTeamB: null == scoreTeamB
          ? _value.scoreTeamB
          : scoreTeamB // ignore: cast_nullable_to_non_nullable
              as int,
      scorers: null == scorers
          ? _value.scorers
          : scorers // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      assists: null == assists
          ? _value.assists
          : assists // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      mvpPlayerId: freezed == mvpPlayerId
          ? _value.mvpPlayerId
          : mvpPlayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      durationSeconds: null == durationSeconds
          ? _value.durationSeconds
          : durationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      recordedBy: null == recordedBy
          ? _value.recordedBy
          : recordedBy // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MatchRecordImplCopyWith<$Res>
    implements $MatchRecordCopyWith<$Res> {
  factory _$$MatchRecordImplCopyWith(
          _$MatchRecordImpl value, $Res Function(_$MatchRecordImpl) then) =
      __$$MatchRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String eventId,
      String hubId,
      String teamAId,
      String teamBId,
      String teamAName,
      String teamBName,
      int scoreTeamA,
      int scoreTeamB,
      Map<String, int> scorers,
      Map<String, int> assists,
      String? mvpPlayerId,
      int durationSeconds,
      @TimestampConverter() DateTime timestamp,
      String recordedBy});
}

/// @nodoc
class __$$MatchRecordImplCopyWithImpl<$Res>
    extends _$MatchRecordCopyWithImpl<$Res, _$MatchRecordImpl>
    implements _$$MatchRecordImplCopyWith<$Res> {
  __$$MatchRecordImplCopyWithImpl(
      _$MatchRecordImpl _value, $Res Function(_$MatchRecordImpl) _then)
      : super(_value, _then);

  /// Create a copy of MatchRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eventId = null,
    Object? hubId = null,
    Object? teamAId = null,
    Object? teamBId = null,
    Object? teamAName = null,
    Object? teamBName = null,
    Object? scoreTeamA = null,
    Object? scoreTeamB = null,
    Object? scorers = null,
    Object? assists = null,
    Object? mvpPlayerId = freezed,
    Object? durationSeconds = null,
    Object? timestamp = null,
    Object? recordedBy = null,
  }) {
    return _then(_$MatchRecordImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      teamAId: null == teamAId
          ? _value.teamAId
          : teamAId // ignore: cast_nullable_to_non_nullable
              as String,
      teamBId: null == teamBId
          ? _value.teamBId
          : teamBId // ignore: cast_nullable_to_non_nullable
              as String,
      teamAName: null == teamAName
          ? _value.teamAName
          : teamAName // ignore: cast_nullable_to_non_nullable
              as String,
      teamBName: null == teamBName
          ? _value.teamBName
          : teamBName // ignore: cast_nullable_to_non_nullable
              as String,
      scoreTeamA: null == scoreTeamA
          ? _value.scoreTeamA
          : scoreTeamA // ignore: cast_nullable_to_non_nullable
              as int,
      scoreTeamB: null == scoreTeamB
          ? _value.scoreTeamB
          : scoreTeamB // ignore: cast_nullable_to_non_nullable
              as int,
      scorers: null == scorers
          ? _value._scorers
          : scorers // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      assists: null == assists
          ? _value._assists
          : assists // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      mvpPlayerId: freezed == mvpPlayerId
          ? _value.mvpPlayerId
          : mvpPlayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      durationSeconds: null == durationSeconds
          ? _value.durationSeconds
          : durationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      recordedBy: null == recordedBy
          ? _value.recordedBy
          : recordedBy // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchRecordImpl extends _MatchRecord {
  const _$MatchRecordImpl(
      {required this.id,
      required this.eventId,
      required this.hubId,
      required this.teamAId,
      required this.teamBId,
      required this.teamAName,
      required this.teamBName,
      required this.scoreTeamA,
      required this.scoreTeamB,
      final Map<String, int> scorers = const {},
      final Map<String, int> assists = const {},
      this.mvpPlayerId,
      required this.durationSeconds,
      @TimestampConverter() required this.timestamp,
      required this.recordedBy})
      : _scorers = scorers,
        _assists = assists,
        super._();

  factory _$MatchRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String eventId;
  @override
  final String hubId;
// Teams involved (Team IDs or Names/Colors)
  @override
  final String teamAId;
  @override
  final String teamBId;
  @override
  final String teamAName;
  @override
  final String teamBName;
// Score
  @override
  final int scoreTeamA;
  @override
  final int scoreTeamB;
// Stats
  final Map<String, int> _scorers;
// Stats
  @override
  @JsonKey()
  Map<String, int> get scorers {
    if (_scorers is EqualUnmodifiableMapView) return _scorers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_scorers);
  }

// PlayerID -> Goals
  final Map<String, int> _assists;
// PlayerID -> Goals
  @override
  @JsonKey()
  Map<String, int> get assists {
    if (_assists is EqualUnmodifiableMapView) return _assists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_assists);
  }

// PlayerID -> Assists
  @override
  final String? mvpPlayerId;
// Metadata
  @override
  final int durationSeconds;
  @override
  @TimestampConverter()
  final DateTime timestamp;
  @override
  final String recordedBy;

  @override
  String toString() {
    return 'MatchRecord(id: $id, eventId: $eventId, hubId: $hubId, teamAId: $teamAId, teamBId: $teamBId, teamAName: $teamAName, teamBName: $teamBName, scoreTeamA: $scoreTeamA, scoreTeamB: $scoreTeamB, scorers: $scorers, assists: $assists, mvpPlayerId: $mvpPlayerId, durationSeconds: $durationSeconds, timestamp: $timestamp, recordedBy: $recordedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.teamAId, teamAId) || other.teamAId == teamAId) &&
            (identical(other.teamBId, teamBId) || other.teamBId == teamBId) &&
            (identical(other.teamAName, teamAName) ||
                other.teamAName == teamAName) &&
            (identical(other.teamBName, teamBName) ||
                other.teamBName == teamBName) &&
            (identical(other.scoreTeamA, scoreTeamA) ||
                other.scoreTeamA == scoreTeamA) &&
            (identical(other.scoreTeamB, scoreTeamB) ||
                other.scoreTeamB == scoreTeamB) &&
            const DeepCollectionEquality().equals(other._scorers, _scorers) &&
            const DeepCollectionEquality().equals(other._assists, _assists) &&
            (identical(other.mvpPlayerId, mvpPlayerId) ||
                other.mvpPlayerId == mvpPlayerId) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.recordedBy, recordedBy) ||
                other.recordedBy == recordedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      eventId,
      hubId,
      teamAId,
      teamBId,
      teamAName,
      teamBName,
      scoreTeamA,
      scoreTeamB,
      const DeepCollectionEquality().hash(_scorers),
      const DeepCollectionEquality().hash(_assists),
      mvpPlayerId,
      durationSeconds,
      timestamp,
      recordedBy);

  /// Create a copy of MatchRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchRecordImplCopyWith<_$MatchRecordImpl> get copyWith =>
      __$$MatchRecordImplCopyWithImpl<_$MatchRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchRecordImplToJson(
      this,
    );
  }
}

abstract class _MatchRecord extends MatchRecord {
  const factory _MatchRecord(
      {required final String id,
      required final String eventId,
      required final String hubId,
      required final String teamAId,
      required final String teamBId,
      required final String teamAName,
      required final String teamBName,
      required final int scoreTeamA,
      required final int scoreTeamB,
      final Map<String, int> scorers,
      final Map<String, int> assists,
      final String? mvpPlayerId,
      required final int durationSeconds,
      @TimestampConverter() required final DateTime timestamp,
      required final String recordedBy}) = _$MatchRecordImpl;
  const _MatchRecord._() : super._();

  factory _MatchRecord.fromJson(Map<String, dynamic> json) =
      _$MatchRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get eventId;
  @override
  String get hubId; // Teams involved (Team IDs or Names/Colors)
  @override
  String get teamAId;
  @override
  String get teamBId;
  @override
  String get teamAName;
  @override
  String get teamBName; // Score
  @override
  int get scoreTeamA;
  @override
  int get scoreTeamB; // Stats
  @override
  Map<String, int> get scorers; // PlayerID -> Goals
  @override
  Map<String, int> get assists; // PlayerID -> Assists
  @override
  String? get mvpPlayerId; // Metadata
  @override
  int get durationSeconds;
  @override
  @TimestampConverter()
  DateTime get timestamp;
  @override
  String get recordedBy;

  /// Create a copy of MatchRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatchRecordImplCopyWith<_$MatchRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
