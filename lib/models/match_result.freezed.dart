// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MatchResult _$MatchResultFromJson(Map<String, dynamic> json) {
  return _MatchResult.fromJson(json);
}

/// @nodoc
mixin _$MatchResult {
  String get matchId =>
      throw _privateConstructorUsedError; // Unique UUID for this match
  String get teamAColor =>
      throw _privateConstructorUsedError; // Color of first team (e.g., "Blue", "Red")
  String get teamBColor =>
      throw _privateConstructorUsedError; // Color of second team
  int get scoreA => throw _privateConstructorUsedError; // Score for team A
  int get scoreB => throw _privateConstructorUsedError; // Score for team B
  List<String> get scorerIds =>
      throw _privateConstructorUsedError; // User IDs of goal scorers (for team A + B combined)
  List<String> get assistIds =>
      throw _privateConstructorUsedError; // User IDs of assisters (for team A + B combined)
  @TimestampConverter()
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // When this match was logged
  String? get loggedBy =>
      throw _privateConstructorUsedError; // User ID who logged this match (manager)
  int get matchDurationMinutes => throw _privateConstructorUsedError;

  /// Serializes this MatchResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatchResultCopyWith<MatchResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchResultCopyWith<$Res> {
  factory $MatchResultCopyWith(
          MatchResult value, $Res Function(MatchResult) then) =
      _$MatchResultCopyWithImpl<$Res, MatchResult>;
  @useResult
  $Res call(
      {String matchId,
      String teamAColor,
      String teamBColor,
      int scoreA,
      int scoreB,
      List<String> scorerIds,
      List<String> assistIds,
      @TimestampConverter() DateTime createdAt,
      String? loggedBy,
      int matchDurationMinutes});
}

/// @nodoc
class _$MatchResultCopyWithImpl<$Res, $Val extends MatchResult>
    implements $MatchResultCopyWith<$Res> {
  _$MatchResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? matchId = null,
    Object? teamAColor = null,
    Object? teamBColor = null,
    Object? scoreA = null,
    Object? scoreB = null,
    Object? scorerIds = null,
    Object? assistIds = null,
    Object? createdAt = null,
    Object? loggedBy = freezed,
    Object? matchDurationMinutes = null,
  }) {
    return _then(_value.copyWith(
      matchId: null == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String,
      teamAColor: null == teamAColor
          ? _value.teamAColor
          : teamAColor // ignore: cast_nullable_to_non_nullable
              as String,
      teamBColor: null == teamBColor
          ? _value.teamBColor
          : teamBColor // ignore: cast_nullable_to_non_nullable
              as String,
      scoreA: null == scoreA
          ? _value.scoreA
          : scoreA // ignore: cast_nullable_to_non_nullable
              as int,
      scoreB: null == scoreB
          ? _value.scoreB
          : scoreB // ignore: cast_nullable_to_non_nullable
              as int,
      scorerIds: null == scorerIds
          ? _value.scorerIds
          : scorerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      assistIds: null == assistIds
          ? _value.assistIds
          : assistIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      loggedBy: freezed == loggedBy
          ? _value.loggedBy
          : loggedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      matchDurationMinutes: null == matchDurationMinutes
          ? _value.matchDurationMinutes
          : matchDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MatchResultImplCopyWith<$Res>
    implements $MatchResultCopyWith<$Res> {
  factory _$$MatchResultImplCopyWith(
          _$MatchResultImpl value, $Res Function(_$MatchResultImpl) then) =
      __$$MatchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String matchId,
      String teamAColor,
      String teamBColor,
      int scoreA,
      int scoreB,
      List<String> scorerIds,
      List<String> assistIds,
      @TimestampConverter() DateTime createdAt,
      String? loggedBy,
      int matchDurationMinutes});
}

/// @nodoc
class __$$MatchResultImplCopyWithImpl<$Res>
    extends _$MatchResultCopyWithImpl<$Res, _$MatchResultImpl>
    implements _$$MatchResultImplCopyWith<$Res> {
  __$$MatchResultImplCopyWithImpl(
      _$MatchResultImpl _value, $Res Function(_$MatchResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of MatchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? matchId = null,
    Object? teamAColor = null,
    Object? teamBColor = null,
    Object? scoreA = null,
    Object? scoreB = null,
    Object? scorerIds = null,
    Object? assistIds = null,
    Object? createdAt = null,
    Object? loggedBy = freezed,
    Object? matchDurationMinutes = null,
  }) {
    return _then(_$MatchResultImpl(
      matchId: null == matchId
          ? _value.matchId
          : matchId // ignore: cast_nullable_to_non_nullable
              as String,
      teamAColor: null == teamAColor
          ? _value.teamAColor
          : teamAColor // ignore: cast_nullable_to_non_nullable
              as String,
      teamBColor: null == teamBColor
          ? _value.teamBColor
          : teamBColor // ignore: cast_nullable_to_non_nullable
              as String,
      scoreA: null == scoreA
          ? _value.scoreA
          : scoreA // ignore: cast_nullable_to_non_nullable
              as int,
      scoreB: null == scoreB
          ? _value.scoreB
          : scoreB // ignore: cast_nullable_to_non_nullable
              as int,
      scorerIds: null == scorerIds
          ? _value._scorerIds
          : scorerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      assistIds: null == assistIds
          ? _value._assistIds
          : assistIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      loggedBy: freezed == loggedBy
          ? _value.loggedBy
          : loggedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      matchDurationMinutes: null == matchDurationMinutes
          ? _value.matchDurationMinutes
          : matchDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchResultImpl implements _MatchResult {
  const _$MatchResultImpl(
      {required this.matchId,
      required this.teamAColor,
      required this.teamBColor,
      required this.scoreA,
      required this.scoreB,
      final List<String> scorerIds = const [],
      final List<String> assistIds = const [],
      @TimestampConverter() required this.createdAt,
      this.loggedBy,
      this.matchDurationMinutes = 12})
      : _scorerIds = scorerIds,
        _assistIds = assistIds;

  factory _$MatchResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchResultImplFromJson(json);

  @override
  final String matchId;
// Unique UUID for this match
  @override
  final String teamAColor;
// Color of first team (e.g., "Blue", "Red")
  @override
  final String teamBColor;
// Color of second team
  @override
  final int scoreA;
// Score for team A
  @override
  final int scoreB;
// Score for team B
  final List<String> _scorerIds;
// Score for team B
  @override
  @JsonKey()
  List<String> get scorerIds {
    if (_scorerIds is EqualUnmodifiableListView) return _scorerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_scorerIds);
  }

// User IDs of goal scorers (for team A + B combined)
  final List<String> _assistIds;
// User IDs of goal scorers (for team A + B combined)
  @override
  @JsonKey()
  List<String> get assistIds {
    if (_assistIds is EqualUnmodifiableListView) return _assistIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assistIds);
  }

// User IDs of assisters (for team A + B combined)
  @override
  @TimestampConverter()
  final DateTime createdAt;
// When this match was logged
  @override
  final String? loggedBy;
// User ID who logged this match (manager)
  @override
  @JsonKey()
  final int matchDurationMinutes;

  @override
  String toString() {
    return 'MatchResult(matchId: $matchId, teamAColor: $teamAColor, teamBColor: $teamBColor, scoreA: $scoreA, scoreB: $scoreB, scorerIds: $scorerIds, assistIds: $assistIds, createdAt: $createdAt, loggedBy: $loggedBy, matchDurationMinutes: $matchDurationMinutes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchResultImpl &&
            (identical(other.matchId, matchId) || other.matchId == matchId) &&
            (identical(other.teamAColor, teamAColor) ||
                other.teamAColor == teamAColor) &&
            (identical(other.teamBColor, teamBColor) ||
                other.teamBColor == teamBColor) &&
            (identical(other.scoreA, scoreA) || other.scoreA == scoreA) &&
            (identical(other.scoreB, scoreB) || other.scoreB == scoreB) &&
            const DeepCollectionEquality()
                .equals(other._scorerIds, _scorerIds) &&
            const DeepCollectionEquality()
                .equals(other._assistIds, _assistIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.loggedBy, loggedBy) ||
                other.loggedBy == loggedBy) &&
            (identical(other.matchDurationMinutes, matchDurationMinutes) ||
                other.matchDurationMinutes == matchDurationMinutes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      matchId,
      teamAColor,
      teamBColor,
      scoreA,
      scoreB,
      const DeepCollectionEquality().hash(_scorerIds),
      const DeepCollectionEquality().hash(_assistIds),
      createdAt,
      loggedBy,
      matchDurationMinutes);

  /// Create a copy of MatchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchResultImplCopyWith<_$MatchResultImpl> get copyWith =>
      __$$MatchResultImplCopyWithImpl<_$MatchResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchResultImplToJson(
      this,
    );
  }
}

abstract class _MatchResult implements MatchResult {
  const factory _MatchResult(
      {required final String matchId,
      required final String teamAColor,
      required final String teamBColor,
      required final int scoreA,
      required final int scoreB,
      final List<String> scorerIds,
      final List<String> assistIds,
      @TimestampConverter() required final DateTime createdAt,
      final String? loggedBy,
      final int matchDurationMinutes}) = _$MatchResultImpl;

  factory _MatchResult.fromJson(Map<String, dynamic> json) =
      _$MatchResultImpl.fromJson;

  @override
  String get matchId; // Unique UUID for this match
  @override
  String get teamAColor; // Color of first team (e.g., "Blue", "Red")
  @override
  String get teamBColor; // Color of second team
  @override
  int get scoreA; // Score for team A
  @override
  int get scoreB; // Score for team B
  @override
  List<String>
      get scorerIds; // User IDs of goal scorers (for team A + B combined)
  @override
  List<String> get assistIds; // User IDs of assisters (for team A + B combined)
  @override
  @TimestampConverter()
  DateTime get createdAt; // When this match was logged
  @override
  String? get loggedBy; // User ID who logged this match (manager)
  @override
  int get matchDurationMinutes;

  /// Create a copy of MatchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatchResultImplCopyWith<_$MatchResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
