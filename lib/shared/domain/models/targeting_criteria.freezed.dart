// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'targeting_criteria.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TargetingCriteria _$TargetingCriteriaFromJson(Map<String, dynamic> json) {
  return _TargetingCriteria.fromJson(json);
}

/// @nodoc
mixin _$TargetingCriteria {
  int? get minAge => throw _privateConstructorUsedError;
  int? get maxAge => throw _privateConstructorUsedError;
  PlayerGender get gender => throw _privateConstructorUsedError;
  GameVibe get vibe => throw _privateConstructorUsedError;

  /// Serializes this TargetingCriteria to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TargetingCriteria
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TargetingCriteriaCopyWith<TargetingCriteria> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TargetingCriteriaCopyWith<$Res> {
  factory $TargetingCriteriaCopyWith(
          TargetingCriteria value, $Res Function(TargetingCriteria) then) =
      _$TargetingCriteriaCopyWithImpl<$Res, TargetingCriteria>;
  @useResult
  $Res call({int? minAge, int? maxAge, PlayerGender gender, GameVibe vibe});
}

/// @nodoc
class _$TargetingCriteriaCopyWithImpl<$Res, $Val extends TargetingCriteria>
    implements $TargetingCriteriaCopyWith<$Res> {
  _$TargetingCriteriaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TargetingCriteria
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minAge = freezed,
    Object? maxAge = freezed,
    Object? gender = null,
    Object? vibe = null,
  }) {
    return _then(_value.copyWith(
      minAge: freezed == minAge
          ? _value.minAge
          : minAge // ignore: cast_nullable_to_non_nullable
              as int?,
      maxAge: freezed == maxAge
          ? _value.maxAge
          : maxAge // ignore: cast_nullable_to_non_nullable
              as int?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as PlayerGender,
      vibe: null == vibe
          ? _value.vibe
          : vibe // ignore: cast_nullable_to_non_nullable
              as GameVibe,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TargetingCriteriaImplCopyWith<$Res>
    implements $TargetingCriteriaCopyWith<$Res> {
  factory _$$TargetingCriteriaImplCopyWith(_$TargetingCriteriaImpl value,
          $Res Function(_$TargetingCriteriaImpl) then) =
      __$$TargetingCriteriaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int? minAge, int? maxAge, PlayerGender gender, GameVibe vibe});
}

/// @nodoc
class __$$TargetingCriteriaImplCopyWithImpl<$Res>
    extends _$TargetingCriteriaCopyWithImpl<$Res, _$TargetingCriteriaImpl>
    implements _$$TargetingCriteriaImplCopyWith<$Res> {
  __$$TargetingCriteriaImplCopyWithImpl(_$TargetingCriteriaImpl _value,
      $Res Function(_$TargetingCriteriaImpl) _then)
      : super(_value, _then);

  /// Create a copy of TargetingCriteria
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minAge = freezed,
    Object? maxAge = freezed,
    Object? gender = null,
    Object? vibe = null,
  }) {
    return _then(_$TargetingCriteriaImpl(
      minAge: freezed == minAge
          ? _value.minAge
          : minAge // ignore: cast_nullable_to_non_nullable
              as int?,
      maxAge: freezed == maxAge
          ? _value.maxAge
          : maxAge // ignore: cast_nullable_to_non_nullable
              as int?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as PlayerGender,
      vibe: null == vibe
          ? _value.vibe
          : vibe // ignore: cast_nullable_to_non_nullable
              as GameVibe,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TargetingCriteriaImpl implements _TargetingCriteria {
  const _$TargetingCriteriaImpl(
      {this.minAge,
      this.maxAge,
      this.gender = PlayerGender.any,
      this.vibe = GameVibe.casual});

  factory _$TargetingCriteriaImpl.fromJson(Map<String, dynamic> json) =>
      _$$TargetingCriteriaImplFromJson(json);

  @override
  final int? minAge;
  @override
  final int? maxAge;
  @override
  @JsonKey()
  final PlayerGender gender;
  @override
  @JsonKey()
  final GameVibe vibe;

  @override
  String toString() {
    return 'TargetingCriteria(minAge: $minAge, maxAge: $maxAge, gender: $gender, vibe: $vibe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TargetingCriteriaImpl &&
            (identical(other.minAge, minAge) || other.minAge == minAge) &&
            (identical(other.maxAge, maxAge) || other.maxAge == maxAge) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.vibe, vibe) || other.vibe == vibe));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, minAge, maxAge, gender, vibe);

  /// Create a copy of TargetingCriteria
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TargetingCriteriaImplCopyWith<_$TargetingCriteriaImpl> get copyWith =>
      __$$TargetingCriteriaImplCopyWithImpl<_$TargetingCriteriaImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TargetingCriteriaImplToJson(
      this,
    );
  }
}

abstract class _TargetingCriteria implements TargetingCriteria {
  const factory _TargetingCriteria(
      {final int? minAge,
      final int? maxAge,
      final PlayerGender gender,
      final GameVibe vibe}) = _$TargetingCriteriaImpl;

  factory _TargetingCriteria.fromJson(Map<String, dynamic> json) =
      _$TargetingCriteriaImpl.fromJson;

  @override
  int? get minAge;
  @override
  int? get maxAge;
  @override
  PlayerGender get gender;
  @override
  GameVibe get vibe;

  /// Create a copy of TargetingCriteria
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TargetingCriteriaImplCopyWith<_$TargetingCriteriaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
