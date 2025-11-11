// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rating_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RatingSnapshot _$RatingSnapshotFromJson(Map<String, dynamic> json) {
  return _RatingSnapshot.fromJson(json);
}

/// @nodoc
mixin _$RatingSnapshot {
  String get ratingId => throw _privateConstructorUsedError;
  String get gameId => throw _privateConstructorUsedError;
  String get playerId => throw _privateConstructorUsedError;
  double get defense => throw _privateConstructorUsedError;
  double get passing => throw _privateConstructorUsedError;
  double get shooting => throw _privateConstructorUsedError;
  double get dribbling => throw _privateConstructorUsedError;
  double get physical => throw _privateConstructorUsedError;
  double get leadership => throw _privateConstructorUsedError;
  double get teamPlay => throw _privateConstructorUsedError;
  double get consistency => throw _privateConstructorUsedError;
  String get submittedBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get submittedAt => throw _privateConstructorUsedError;
  bool get isVerified => throw _privateConstructorUsedError;

  /// Serializes this RatingSnapshot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RatingSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RatingSnapshotCopyWith<RatingSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RatingSnapshotCopyWith<$Res> {
  factory $RatingSnapshotCopyWith(
          RatingSnapshot value, $Res Function(RatingSnapshot) then) =
      _$RatingSnapshotCopyWithImpl<$Res, RatingSnapshot>;
  @useResult
  $Res call(
      {String ratingId,
      String gameId,
      String playerId,
      double defense,
      double passing,
      double shooting,
      double dribbling,
      double physical,
      double leadership,
      double teamPlay,
      double consistency,
      String submittedBy,
      @TimestampConverter() DateTime submittedAt,
      bool isVerified});
}

/// @nodoc
class _$RatingSnapshotCopyWithImpl<$Res, $Val extends RatingSnapshot>
    implements $RatingSnapshotCopyWith<$Res> {
  _$RatingSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RatingSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ratingId = null,
    Object? gameId = null,
    Object? playerId = null,
    Object? defense = null,
    Object? passing = null,
    Object? shooting = null,
    Object? dribbling = null,
    Object? physical = null,
    Object? leadership = null,
    Object? teamPlay = null,
    Object? consistency = null,
    Object? submittedBy = null,
    Object? submittedAt = null,
    Object? isVerified = null,
  }) {
    return _then(_value.copyWith(
      ratingId: null == ratingId
          ? _value.ratingId
          : ratingId // ignore: cast_nullable_to_non_nullable
              as String,
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      defense: null == defense
          ? _value.defense
          : defense // ignore: cast_nullable_to_non_nullable
              as double,
      passing: null == passing
          ? _value.passing
          : passing // ignore: cast_nullable_to_non_nullable
              as double,
      shooting: null == shooting
          ? _value.shooting
          : shooting // ignore: cast_nullable_to_non_nullable
              as double,
      dribbling: null == dribbling
          ? _value.dribbling
          : dribbling // ignore: cast_nullable_to_non_nullable
              as double,
      physical: null == physical
          ? _value.physical
          : physical // ignore: cast_nullable_to_non_nullable
              as double,
      leadership: null == leadership
          ? _value.leadership
          : leadership // ignore: cast_nullable_to_non_nullable
              as double,
      teamPlay: null == teamPlay
          ? _value.teamPlay
          : teamPlay // ignore: cast_nullable_to_non_nullable
              as double,
      consistency: null == consistency
          ? _value.consistency
          : consistency // ignore: cast_nullable_to_non_nullable
              as double,
      submittedBy: null == submittedBy
          ? _value.submittedBy
          : submittedBy // ignore: cast_nullable_to_non_nullable
              as String,
      submittedAt: null == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RatingSnapshotImplCopyWith<$Res>
    implements $RatingSnapshotCopyWith<$Res> {
  factory _$$RatingSnapshotImplCopyWith(_$RatingSnapshotImpl value,
          $Res Function(_$RatingSnapshotImpl) then) =
      __$$RatingSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String ratingId,
      String gameId,
      String playerId,
      double defense,
      double passing,
      double shooting,
      double dribbling,
      double physical,
      double leadership,
      double teamPlay,
      double consistency,
      String submittedBy,
      @TimestampConverter() DateTime submittedAt,
      bool isVerified});
}

/// @nodoc
class __$$RatingSnapshotImplCopyWithImpl<$Res>
    extends _$RatingSnapshotCopyWithImpl<$Res, _$RatingSnapshotImpl>
    implements _$$RatingSnapshotImplCopyWith<$Res> {
  __$$RatingSnapshotImplCopyWithImpl(
      _$RatingSnapshotImpl _value, $Res Function(_$RatingSnapshotImpl) _then)
      : super(_value, _then);

  /// Create a copy of RatingSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ratingId = null,
    Object? gameId = null,
    Object? playerId = null,
    Object? defense = null,
    Object? passing = null,
    Object? shooting = null,
    Object? dribbling = null,
    Object? physical = null,
    Object? leadership = null,
    Object? teamPlay = null,
    Object? consistency = null,
    Object? submittedBy = null,
    Object? submittedAt = null,
    Object? isVerified = null,
  }) {
    return _then(_$RatingSnapshotImpl(
      ratingId: null == ratingId
          ? _value.ratingId
          : ratingId // ignore: cast_nullable_to_non_nullable
              as String,
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      defense: null == defense
          ? _value.defense
          : defense // ignore: cast_nullable_to_non_nullable
              as double,
      passing: null == passing
          ? _value.passing
          : passing // ignore: cast_nullable_to_non_nullable
              as double,
      shooting: null == shooting
          ? _value.shooting
          : shooting // ignore: cast_nullable_to_non_nullable
              as double,
      dribbling: null == dribbling
          ? _value.dribbling
          : dribbling // ignore: cast_nullable_to_non_nullable
              as double,
      physical: null == physical
          ? _value.physical
          : physical // ignore: cast_nullable_to_non_nullable
              as double,
      leadership: null == leadership
          ? _value.leadership
          : leadership // ignore: cast_nullable_to_non_nullable
              as double,
      teamPlay: null == teamPlay
          ? _value.teamPlay
          : teamPlay // ignore: cast_nullable_to_non_nullable
              as double,
      consistency: null == consistency
          ? _value.consistency
          : consistency // ignore: cast_nullable_to_non_nullable
              as double,
      submittedBy: null == submittedBy
          ? _value.submittedBy
          : submittedBy // ignore: cast_nullable_to_non_nullable
              as String,
      submittedAt: null == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RatingSnapshotImpl implements _RatingSnapshot {
  const _$RatingSnapshotImpl(
      {required this.ratingId,
      required this.gameId,
      required this.playerId,
      this.defense = 5.0,
      this.passing = 5.0,
      this.shooting = 5.0,
      this.dribbling = 5.0,
      this.physical = 5.0,
      this.leadership = 5.0,
      this.teamPlay = 5.0,
      this.consistency = 5.0,
      required this.submittedBy,
      @TimestampConverter() required this.submittedAt,
      this.isVerified = false});

  factory _$RatingSnapshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$RatingSnapshotImplFromJson(json);

  @override
  final String ratingId;
  @override
  final String gameId;
  @override
  final String playerId;
  @override
  @JsonKey()
  final double defense;
  @override
  @JsonKey()
  final double passing;
  @override
  @JsonKey()
  final double shooting;
  @override
  @JsonKey()
  final double dribbling;
  @override
  @JsonKey()
  final double physical;
  @override
  @JsonKey()
  final double leadership;
  @override
  @JsonKey()
  final double teamPlay;
  @override
  @JsonKey()
  final double consistency;
  @override
  final String submittedBy;
  @override
  @TimestampConverter()
  final DateTime submittedAt;
  @override
  @JsonKey()
  final bool isVerified;

  @override
  String toString() {
    return 'RatingSnapshot(ratingId: $ratingId, gameId: $gameId, playerId: $playerId, defense: $defense, passing: $passing, shooting: $shooting, dribbling: $dribbling, physical: $physical, leadership: $leadership, teamPlay: $teamPlay, consistency: $consistency, submittedBy: $submittedBy, submittedAt: $submittedAt, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RatingSnapshotImpl &&
            (identical(other.ratingId, ratingId) ||
                other.ratingId == ratingId) &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.defense, defense) || other.defense == defense) &&
            (identical(other.passing, passing) || other.passing == passing) &&
            (identical(other.shooting, shooting) ||
                other.shooting == shooting) &&
            (identical(other.dribbling, dribbling) ||
                other.dribbling == dribbling) &&
            (identical(other.physical, physical) ||
                other.physical == physical) &&
            (identical(other.leadership, leadership) ||
                other.leadership == leadership) &&
            (identical(other.teamPlay, teamPlay) ||
                other.teamPlay == teamPlay) &&
            (identical(other.consistency, consistency) ||
                other.consistency == consistency) &&
            (identical(other.submittedBy, submittedBy) ||
                other.submittedBy == submittedBy) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      ratingId,
      gameId,
      playerId,
      defense,
      passing,
      shooting,
      dribbling,
      physical,
      leadership,
      teamPlay,
      consistency,
      submittedBy,
      submittedAt,
      isVerified);

  /// Create a copy of RatingSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RatingSnapshotImplCopyWith<_$RatingSnapshotImpl> get copyWith =>
      __$$RatingSnapshotImplCopyWithImpl<_$RatingSnapshotImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RatingSnapshotImplToJson(
      this,
    );
  }
}

abstract class _RatingSnapshot implements RatingSnapshot {
  const factory _RatingSnapshot(
      {required final String ratingId,
      required final String gameId,
      required final String playerId,
      final double defense,
      final double passing,
      final double shooting,
      final double dribbling,
      final double physical,
      final double leadership,
      final double teamPlay,
      final double consistency,
      required final String submittedBy,
      @TimestampConverter() required final DateTime submittedAt,
      final bool isVerified}) = _$RatingSnapshotImpl;

  factory _RatingSnapshot.fromJson(Map<String, dynamic> json) =
      _$RatingSnapshotImpl.fromJson;

  @override
  String get ratingId;
  @override
  String get gameId;
  @override
  String get playerId;
  @override
  double get defense;
  @override
  double get passing;
  @override
  double get shooting;
  @override
  double get dribbling;
  @override
  double get physical;
  @override
  double get leadership;
  @override
  double get teamPlay;
  @override
  double get consistency;
  @override
  String get submittedBy;
  @override
  @TimestampConverter()
  DateTime get submittedAt;
  @override
  bool get isVerified;

  /// Create a copy of RatingSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RatingSnapshotImplCopyWith<_$RatingSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
