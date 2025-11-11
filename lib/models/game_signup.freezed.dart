// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_signup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameSignup _$GameSignupFromJson(Map<String, dynamic> json) {
  return _GameSignup.fromJson(json);
}

/// @nodoc
mixin _$GameSignup {
  String get playerId => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get signedUpAt => throw _privateConstructorUsedError;
  @SignupStatusConverter()
  SignupStatus get status => throw _privateConstructorUsedError;

  /// Serializes this GameSignup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameSignup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameSignupCopyWith<GameSignup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameSignupCopyWith<$Res> {
  factory $GameSignupCopyWith(
          GameSignup value, $Res Function(GameSignup) then) =
      _$GameSignupCopyWithImpl<$Res, GameSignup>;
  @useResult
  $Res call(
      {String playerId,
      @TimestampConverter() DateTime signedUpAt,
      @SignupStatusConverter() SignupStatus status});
}

/// @nodoc
class _$GameSignupCopyWithImpl<$Res, $Val extends GameSignup>
    implements $GameSignupCopyWith<$Res> {
  _$GameSignupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameSignup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? signedUpAt = null,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      signedUpAt: null == signedUpAt
          ? _value.signedUpAt
          : signedUpAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SignupStatus,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameSignupImplCopyWith<$Res>
    implements $GameSignupCopyWith<$Res> {
  factory _$$GameSignupImplCopyWith(
          _$GameSignupImpl value, $Res Function(_$GameSignupImpl) then) =
      __$$GameSignupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String playerId,
      @TimestampConverter() DateTime signedUpAt,
      @SignupStatusConverter() SignupStatus status});
}

/// @nodoc
class __$$GameSignupImplCopyWithImpl<$Res>
    extends _$GameSignupCopyWithImpl<$Res, _$GameSignupImpl>
    implements _$$GameSignupImplCopyWith<$Res> {
  __$$GameSignupImplCopyWithImpl(
      _$GameSignupImpl _value, $Res Function(_$GameSignupImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameSignup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? signedUpAt = null,
    Object? status = null,
  }) {
    return _then(_$GameSignupImpl(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      signedUpAt: null == signedUpAt
          ? _value.signedUpAt
          : signedUpAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SignupStatus,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameSignupImpl implements _GameSignup {
  const _$GameSignupImpl(
      {required this.playerId,
      @TimestampConverter() required this.signedUpAt,
      @SignupStatusConverter() this.status = SignupStatus.pending});

  factory _$GameSignupImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameSignupImplFromJson(json);

  @override
  final String playerId;
  @override
  @TimestampConverter()
  final DateTime signedUpAt;
  @override
  @JsonKey()
  @SignupStatusConverter()
  final SignupStatus status;

  @override
  String toString() {
    return 'GameSignup(playerId: $playerId, signedUpAt: $signedUpAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameSignupImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.signedUpAt, signedUpAt) ||
                other.signedUpAt == signedUpAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playerId, signedUpAt, status);

  /// Create a copy of GameSignup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameSignupImplCopyWith<_$GameSignupImpl> get copyWith =>
      __$$GameSignupImplCopyWithImpl<_$GameSignupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameSignupImplToJson(
      this,
    );
  }
}

abstract class _GameSignup implements GameSignup {
  const factory _GameSignup(
      {required final String playerId,
      @TimestampConverter() required final DateTime signedUpAt,
      @SignupStatusConverter() final SignupStatus status}) = _$GameSignupImpl;

  factory _GameSignup.fromJson(Map<String, dynamic> json) =
      _$GameSignupImpl.fromJson;

  @override
  String get playerId;
  @override
  @TimestampConverter()
  DateTime get signedUpAt;
  @override
  @SignupStatusConverter()
  SignupStatus get status;

  /// Create a copy of GameSignup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameSignupImplCopyWith<_$GameSignupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
