// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gamification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Gamification _$GamificationFromJson(Map<String, dynamic> json) {
  return _Gamification.fromJson(json);
}

/// @nodoc
mixin _$Gamification {
  String get userId => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  List<String> get badges => throw _privateConstructorUsedError;
  Map<String, dynamic> get achievements => throw _privateConstructorUsedError;
  Map<String, int> get stats => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Gamification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Gamification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GamificationCopyWith<Gamification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GamificationCopyWith<$Res> {
  factory $GamificationCopyWith(
          Gamification value, $Res Function(Gamification) then) =
      _$GamificationCopyWithImpl<$Res, Gamification>;
  @useResult
  $Res call(
      {String userId,
      int points,
      int level,
      List<String> badges,
      Map<String, dynamic> achievements,
      Map<String, int> stats,
      @TimestampConverter() DateTime? updatedAt});
}

/// @nodoc
class _$GamificationCopyWithImpl<$Res, $Val extends Gamification>
    implements $GamificationCopyWith<$Res> {
  _$GamificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Gamification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? points = null,
    Object? level = null,
    Object? badges = null,
    Object? achievements = null,
    Object? stats = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      badges: null == badges
          ? _value.badges
          : badges // ignore: cast_nullable_to_non_nullable
              as List<String>,
      achievements: null == achievements
          ? _value.achievements
          : achievements // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      stats: null == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GamificationImplCopyWith<$Res>
    implements $GamificationCopyWith<$Res> {
  factory _$$GamificationImplCopyWith(
          _$GamificationImpl value, $Res Function(_$GamificationImpl) then) =
      __$$GamificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      int points,
      int level,
      List<String> badges,
      Map<String, dynamic> achievements,
      Map<String, int> stats,
      @TimestampConverter() DateTime? updatedAt});
}

/// @nodoc
class __$$GamificationImplCopyWithImpl<$Res>
    extends _$GamificationCopyWithImpl<$Res, _$GamificationImpl>
    implements _$$GamificationImplCopyWith<$Res> {
  __$$GamificationImplCopyWithImpl(
      _$GamificationImpl _value, $Res Function(_$GamificationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Gamification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? points = null,
    Object? level = null,
    Object? badges = null,
    Object? achievements = null,
    Object? stats = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$GamificationImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      badges: null == badges
          ? _value._badges
          : badges // ignore: cast_nullable_to_non_nullable
              as List<String>,
      achievements: null == achievements
          ? _value._achievements
          : achievements // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      stats: null == stats
          ? _value._stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GamificationImpl implements _Gamification {
  const _$GamificationImpl(
      {required this.userId,
      this.points = 0,
      this.level = 1,
      final List<String> badges = const [],
      final Map<String, dynamic> achievements = const {},
      final Map<String, int> stats = const {
        'gamesPlayed': 0,
        'gamesWon': 0,
        'goals': 0,
        'assists': 0,
        'saves': 0
      },
      @TimestampConverter() this.updatedAt})
      : _badges = badges,
        _achievements = achievements,
        _stats = stats;

  factory _$GamificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$GamificationImplFromJson(json);

  @override
  final String userId;
  @override
  @JsonKey()
  final int points;
  @override
  @JsonKey()
  final int level;
  final List<String> _badges;
  @override
  @JsonKey()
  List<String> get badges {
    if (_badges is EqualUnmodifiableListView) return _badges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_badges);
  }

  final Map<String, dynamic> _achievements;
  @override
  @JsonKey()
  Map<String, dynamic> get achievements {
    if (_achievements is EqualUnmodifiableMapView) return _achievements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_achievements);
  }

  final Map<String, int> _stats;
  @override
  @JsonKey()
  Map<String, int> get stats {
    if (_stats is EqualUnmodifiableMapView) return _stats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stats);
  }

  @override
  @TimestampConverter()
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Gamification(userId: $userId, points: $points, level: $level, badges: $badges, achievements: $achievements, stats: $stats, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GamificationImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality().equals(other._badges, _badges) &&
            const DeepCollectionEquality()
                .equals(other._achievements, _achievements) &&
            const DeepCollectionEquality().equals(other._stats, _stats) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      points,
      level,
      const DeepCollectionEquality().hash(_badges),
      const DeepCollectionEquality().hash(_achievements),
      const DeepCollectionEquality().hash(_stats),
      updatedAt);

  /// Create a copy of Gamification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GamificationImplCopyWith<_$GamificationImpl> get copyWith =>
      __$$GamificationImplCopyWithImpl<_$GamificationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GamificationImplToJson(
      this,
    );
  }
}

abstract class _Gamification implements Gamification {
  const factory _Gamification(
      {required final String userId,
      final int points,
      final int level,
      final List<String> badges,
      final Map<String, dynamic> achievements,
      final Map<String, int> stats,
      @TimestampConverter() final DateTime? updatedAt}) = _$GamificationImpl;

  factory _Gamification.fromJson(Map<String, dynamic> json) =
      _$GamificationImpl.fromJson;

  @override
  String get userId;
  @override
  int get points;
  @override
  int get level;
  @override
  List<String> get badges;
  @override
  Map<String, dynamic> get achievements;
  @override
  Map<String, int> get stats;
  @override
  @TimestampConverter()
  DateTime? get updatedAt;

  /// Create a copy of Gamification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GamificationImplCopyWith<_$GamificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
