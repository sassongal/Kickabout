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
  int? get legacyTeamBScore => throw _privateConstructorUsedError;

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
      int? legacyTeamBScore});
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
    ) as $Val);
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
      int? legacyTeamBScore});
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
      this.legacyTeamBScore})
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

  @override
  String toString() {
    return 'GameSession(matches: $matches, aggregateWins: $aggregateWins, legacyTeamAScore: $legacyTeamAScore, legacyTeamBScore: $legacyTeamBScore)';
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
                other.legacyTeamBScore == legacyTeamBScore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_matches),
      const DeepCollectionEquality().hash(_aggregateWins),
      legacyTeamAScore,
      legacyTeamBScore);

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
      final int? legacyTeamBScore}) = _$GameSessionImpl;

  factory _GameSession.fromJson(Map<String, dynamic> json) =
      _$GameSessionImpl.fromJson;

  @override
  List<MatchResult> get matches;
  @override
  Map<String, int> get aggregateWins; // Legacy support fields
  @override
  int? get legacyTeamAScore;
  @override
  int? get legacyTeamBScore;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameSessionImplCopyWith<_$GameSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
