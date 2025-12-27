// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameSession _$GameSessionFromJson(Map<String, dynamic> json) {
  return _GameSession.fromJson(json);
}

/// @nodoc
mixin _$GameSession {
  List<MatchResult> get matches => throw _privateConstructorUsedError;
  Map<String, int> get aggregateWins =>
      throw _privateConstructorUsedError; // Legacy support fields
  int? get legacyTeamAScore => throw _privateConstructorUsedError;
  int? get legacyTeamBScore =>
      throw _privateConstructorUsedError; // Session lifecycle tracking (for Winner Stays format)
  bool get isActive => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get sessionStartedAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get sessionEndedAt => throw _privateConstructorUsedError;
  String? get sessionStartedBy =>
      throw _privateConstructorUsedError; // User ID of manager who started session
// Rotation queue state (for 2-8 team sessions)
  RotationState? get currentRotation =>
      throw _privateConstructorUsedError; // Finalization tracking
  @TimestampConverter()
  DateTime? get finalizedAt => throw _privateConstructorUsedError;

  /// Serializes this GameSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameSessionCopyWith<GameSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameSessionCopyWith<$Res> {
  factory $GameSessionCopyWith(
          GameSession value, $Res Function(GameSession) then) =
      _$GameSessionCopyWithImpl<$Res, GameSession>;
  @useResult
  $Res call(
      {List<MatchResult> matches,
      Map<String, int> aggregateWins,
      int? legacyTeamAScore,
      int? legacyTeamBScore,
      bool isActive,
      @TimestampConverter() DateTime? sessionStartedAt,
      @TimestampConverter() DateTime? sessionEndedAt,
      String? sessionStartedBy,
      RotationState? currentRotation,
      @TimestampConverter() DateTime? finalizedAt});

  $RotationStateCopyWith<$Res>? get currentRotation;
}

/// @nodoc
class _$GameSessionCopyWithImpl<$Res, $Val extends GameSession>
    implements $GameSessionCopyWith<$Res> {
  _$GameSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? matches = null,
    Object? aggregateWins = null,
    Object? legacyTeamAScore = freezed,
    Object? legacyTeamBScore = freezed,
    Object? isActive = null,
    Object? sessionStartedAt = freezed,
    Object? sessionEndedAt = freezed,
    Object? sessionStartedBy = freezed,
    Object? currentRotation = freezed,
    Object? finalizedAt = freezed,
  }) {
    return _then(_value.copyWith(
      matches: null == matches
          ? _value.matches
          : matches // ignore: cast_nullable_to_non_nullable
              as List<MatchResult>,
      aggregateWins: null == aggregateWins
          ? _value.aggregateWins
          : aggregateWins // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      legacyTeamAScore: freezed == legacyTeamAScore
          ? _value.legacyTeamAScore
          : legacyTeamAScore // ignore: cast_nullable_to_non_nullable
              as int?,
      legacyTeamBScore: freezed == legacyTeamBScore
          ? _value.legacyTeamBScore
          : legacyTeamBScore // ignore: cast_nullable_to_non_nullable
              as int?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      sessionStartedAt: freezed == sessionStartedAt
          ? _value.sessionStartedAt
          : sessionStartedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sessionEndedAt: freezed == sessionEndedAt
          ? _value.sessionEndedAt
          : sessionEndedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sessionStartedBy: freezed == sessionStartedBy
          ? _value.sessionStartedBy
          : sessionStartedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      currentRotation: freezed == currentRotation
          ? _value.currentRotation
          : currentRotation // ignore: cast_nullable_to_non_nullable
              as RotationState?,
      finalizedAt: freezed == finalizedAt
          ? _value.finalizedAt
          : finalizedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RotationStateCopyWith<$Res>? get currentRotation {
    if (_value.currentRotation == null) {
      return null;
    }

    return $RotationStateCopyWith<$Res>(_value.currentRotation!, (value) {
      return _then(_value.copyWith(currentRotation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameSessionImplCopyWith<$Res>
    implements $GameSessionCopyWith<$Res> {
  factory _$$GameSessionImplCopyWith(
          _$GameSessionImpl value, $Res Function(_$GameSessionImpl) then) =
      __$$GameSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<MatchResult> matches,
      Map<String, int> aggregateWins,
      int? legacyTeamAScore,
      int? legacyTeamBScore,
      bool isActive,
      @TimestampConverter() DateTime? sessionStartedAt,
      @TimestampConverter() DateTime? sessionEndedAt,
      String? sessionStartedBy,
      RotationState? currentRotation,
      @TimestampConverter() DateTime? finalizedAt});

  @override
  $RotationStateCopyWith<$Res>? get currentRotation;
}

/// @nodoc
class __$$GameSessionImplCopyWithImpl<$Res>
    extends _$GameSessionCopyWithImpl<$Res, _$GameSessionImpl>
    implements _$$GameSessionImplCopyWith<$Res> {
  __$$GameSessionImplCopyWithImpl(
      _$GameSessionImpl _value, $Res Function(_$GameSessionImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? matches = null,
    Object? aggregateWins = null,
    Object? legacyTeamAScore = freezed,
    Object? legacyTeamBScore = freezed,
    Object? isActive = null,
    Object? sessionStartedAt = freezed,
    Object? sessionEndedAt = freezed,
    Object? sessionStartedBy = freezed,
    Object? currentRotation = freezed,
    Object? finalizedAt = freezed,
  }) {
    return _then(_$GameSessionImpl(
      matches: null == matches
          ? _value._matches
          : matches // ignore: cast_nullable_to_non_nullable
              as List<MatchResult>,
      aggregateWins: null == aggregateWins
          ? _value._aggregateWins
          : aggregateWins // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      legacyTeamAScore: freezed == legacyTeamAScore
          ? _value.legacyTeamAScore
          : legacyTeamAScore // ignore: cast_nullable_to_non_nullable
              as int?,
      legacyTeamBScore: freezed == legacyTeamBScore
          ? _value.legacyTeamBScore
          : legacyTeamBScore // ignore: cast_nullable_to_non_nullable
              as int?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      sessionStartedAt: freezed == sessionStartedAt
          ? _value.sessionStartedAt
          : sessionStartedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sessionEndedAt: freezed == sessionEndedAt
          ? _value.sessionEndedAt
          : sessionEndedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sessionStartedBy: freezed == sessionStartedBy
          ? _value.sessionStartedBy
          : sessionStartedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      currentRotation: freezed == currentRotation
          ? _value.currentRotation
          : currentRotation // ignore: cast_nullable_to_non_nullable
              as RotationState?,
      finalizedAt: freezed == finalizedAt
          ? _value.finalizedAt
          : finalizedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameSessionImpl implements _GameSession {
  const _$GameSessionImpl(
      {final List<MatchResult> matches = const [],
      final Map<String, int> aggregateWins = const {},
      this.legacyTeamAScore,
      this.legacyTeamBScore,
      this.isActive = false,
      @TimestampConverter() this.sessionStartedAt,
      @TimestampConverter() this.sessionEndedAt,
      this.sessionStartedBy,
      this.currentRotation,
      @TimestampConverter() this.finalizedAt})
      : _matches = matches,
        _aggregateWins = aggregateWins;

  factory _$GameSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameSessionImplFromJson(json);

  final List<MatchResult> _matches;
  @override
  @JsonKey()
  List<MatchResult> get matches {
    if (_matches is EqualUnmodifiableListView) return _matches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_matches);
  }

  final Map<String, int> _aggregateWins;
  @override
  @JsonKey()
  Map<String, int> get aggregateWins {
    if (_aggregateWins is EqualUnmodifiableMapView) return _aggregateWins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_aggregateWins);
  }

// Legacy support fields
  @override
  final int? legacyTeamAScore;
  @override
  final int? legacyTeamBScore;
// Session lifecycle tracking (for Winner Stays format)
  @override
  @JsonKey()
  final bool isActive;
  @override
  @TimestampConverter()
  final DateTime? sessionStartedAt;
  @override
  @TimestampConverter()
  final DateTime? sessionEndedAt;
  @override
  final String? sessionStartedBy;
// User ID of manager who started session
// Rotation queue state (for 2-8 team sessions)
  @override
  final RotationState? currentRotation;
// Finalization tracking
  @override
  @TimestampConverter()
  final DateTime? finalizedAt;

  @override
  String toString() {
    return 'GameSession(matches: $matches, aggregateWins: $aggregateWins, legacyTeamAScore: $legacyTeamAScore, legacyTeamBScore: $legacyTeamBScore, isActive: $isActive, sessionStartedAt: $sessionStartedAt, sessionEndedAt: $sessionEndedAt, sessionStartedBy: $sessionStartedBy, currentRotation: $currentRotation, finalizedAt: $finalizedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameSessionImpl &&
            const DeepCollectionEquality().equals(other._matches, _matches) &&
            const DeepCollectionEquality()
                .equals(other._aggregateWins, _aggregateWins) &&
            (identical(other.legacyTeamAScore, legacyTeamAScore) ||
                other.legacyTeamAScore == legacyTeamAScore) &&
            (identical(other.legacyTeamBScore, legacyTeamBScore) ||
                other.legacyTeamBScore == legacyTeamBScore) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.sessionStartedAt, sessionStartedAt) ||
                other.sessionStartedAt == sessionStartedAt) &&
            (identical(other.sessionEndedAt, sessionEndedAt) ||
                other.sessionEndedAt == sessionEndedAt) &&
            (identical(other.sessionStartedBy, sessionStartedBy) ||
                other.sessionStartedBy == sessionStartedBy) &&
            (identical(other.currentRotation, currentRotation) ||
                other.currentRotation == currentRotation) &&
            (identical(other.finalizedAt, finalizedAt) ||
                other.finalizedAt == finalizedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_matches),
      const DeepCollectionEquality().hash(_aggregateWins),
      legacyTeamAScore,
      legacyTeamBScore,
      isActive,
      sessionStartedAt,
      sessionEndedAt,
      sessionStartedBy,
      currentRotation,
      finalizedAt);

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameSessionImplCopyWith<_$GameSessionImpl> get copyWith =>
      __$$GameSessionImplCopyWithImpl<_$GameSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameSessionImplToJson(
      this,
    );
  }
}

abstract class _GameSession implements GameSession {
  const factory _GameSession(
      {final List<MatchResult> matches,
      final Map<String, int> aggregateWins,
      final int? legacyTeamAScore,
      final int? legacyTeamBScore,
      final bool isActive,
      @TimestampConverter() final DateTime? sessionStartedAt,
      @TimestampConverter() final DateTime? sessionEndedAt,
      final String? sessionStartedBy,
      final RotationState? currentRotation,
      @TimestampConverter() final DateTime? finalizedAt}) = _$GameSessionImpl;

  factory _GameSession.fromJson(Map<String, dynamic> json) =
      _$GameSessionImpl.fromJson;

  @override
  List<MatchResult> get matches;
  @override
  Map<String, int> get aggregateWins; // Legacy support fields
  @override
  int? get legacyTeamAScore;
  @override
  int?
      get legacyTeamBScore; // Session lifecycle tracking (for Winner Stays format)
  @override
  bool get isActive;
  @override
  @TimestampConverter()
  DateTime? get sessionStartedAt;
  @override
  @TimestampConverter()
  DateTime? get sessionEndedAt;
  @override
  String? get sessionStartedBy; // User ID of manager who started session
// Rotation queue state (for 2-8 team sessions)
  @override
  RotationState? get currentRotation; // Finalization tracking
  @override
  @TimestampConverter()
  DateTime? get finalizedAt;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameSessionImplCopyWith<_$GameSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
