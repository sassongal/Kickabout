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
  String? get adminActionReason =>
      throw _privateConstructorUsedError; // Mandatory for rejections/kicks
// Ride-sharing (Trempiyada) fields
  bool get offeringRide =>
      throw _privateConstructorUsedError; // Player is offering a ride
  bool get needsRide =>
      throw _privateConstructorUsedError; // Player needs a ride
  int? get availableSeats =>
      throw _privateConstructorUsedError; // Number of available seats (if offeringRide=true)
  String? get requestedDriverId =>
      throw _privateConstructorUsedError; // ID of driver player requested ride from
// Denormalized game data (to avoid N+1 queries)
  @TimestampConverter()
  DateTime? get gameDate => throw _privateConstructorUsedError;
  String? get gameStatus =>
      throw _privateConstructorUsedError; // 'teamSelection', 'teamsFormed', etc.
  String? get hubId => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  String? get venueName => throw _privateConstructorUsedError;

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
      @SignupStatusConverter() SignupStatus status,
      String? adminActionReason,
      bool offeringRide,
      bool needsRide,
      int? availableSeats,
      String? requestedDriverId,
      @TimestampConverter() DateTime? gameDate,
      String? gameStatus,
      String? hubId,
      String? location,
      String? venueName});
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
    Object? adminActionReason = freezed,
    Object? offeringRide = null,
    Object? needsRide = null,
    Object? availableSeats = freezed,
    Object? requestedDriverId = freezed,
    Object? gameDate = freezed,
    Object? gameStatus = freezed,
    Object? hubId = freezed,
    Object? location = freezed,
    Object? venueName = freezed,
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
      adminActionReason: freezed == adminActionReason
          ? _value.adminActionReason
          : adminActionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      offeringRide: null == offeringRide
          ? _value.offeringRide
          : offeringRide // ignore: cast_nullable_to_non_nullable
              as bool,
      needsRide: null == needsRide
          ? _value.needsRide
          : needsRide // ignore: cast_nullable_to_non_nullable
              as bool,
      availableSeats: freezed == availableSeats
          ? _value.availableSeats
          : availableSeats // ignore: cast_nullable_to_non_nullable
              as int?,
      requestedDriverId: freezed == requestedDriverId
          ? _value.requestedDriverId
          : requestedDriverId // ignore: cast_nullable_to_non_nullable
              as String?,
      gameDate: freezed == gameDate
          ? _value.gameDate
          : gameDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gameStatus: freezed == gameStatus
          ? _value.gameStatus
          : gameStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      hubId: freezed == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      venueName: freezed == venueName
          ? _value.venueName
          : venueName // ignore: cast_nullable_to_non_nullable
              as String?,
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
      @SignupStatusConverter() SignupStatus status,
      String? adminActionReason,
      bool offeringRide,
      bool needsRide,
      int? availableSeats,
      String? requestedDriverId,
      @TimestampConverter() DateTime? gameDate,
      String? gameStatus,
      String? hubId,
      String? location,
      String? venueName});
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
    Object? adminActionReason = freezed,
    Object? offeringRide = null,
    Object? needsRide = null,
    Object? availableSeats = freezed,
    Object? requestedDriverId = freezed,
    Object? gameDate = freezed,
    Object? gameStatus = freezed,
    Object? hubId = freezed,
    Object? location = freezed,
    Object? venueName = freezed,
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
      adminActionReason: freezed == adminActionReason
          ? _value.adminActionReason
          : adminActionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      offeringRide: null == offeringRide
          ? _value.offeringRide
          : offeringRide // ignore: cast_nullable_to_non_nullable
              as bool,
      needsRide: null == needsRide
          ? _value.needsRide
          : needsRide // ignore: cast_nullable_to_non_nullable
              as bool,
      availableSeats: freezed == availableSeats
          ? _value.availableSeats
          : availableSeats // ignore: cast_nullable_to_non_nullable
              as int?,
      requestedDriverId: freezed == requestedDriverId
          ? _value.requestedDriverId
          : requestedDriverId // ignore: cast_nullable_to_non_nullable
              as String?,
      gameDate: freezed == gameDate
          ? _value.gameDate
          : gameDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gameStatus: freezed == gameStatus
          ? _value.gameStatus
          : gameStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      hubId: freezed == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
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
class _$GameSignupImpl implements _GameSignup {
  const _$GameSignupImpl(
      {required this.playerId,
      @TimestampConverter() required this.signedUpAt,
      @SignupStatusConverter() this.status = SignupStatus.pending,
      this.adminActionReason,
      this.offeringRide = false,
      this.needsRide = false,
      this.availableSeats,
      this.requestedDriverId,
      @TimestampConverter() this.gameDate,
      this.gameStatus,
      this.hubId,
      this.location,
      this.venueName});

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
  final String? adminActionReason;
// Mandatory for rejections/kicks
// Ride-sharing (Trempiyada) fields
  @override
  @JsonKey()
  final bool offeringRide;
// Player is offering a ride
  @override
  @JsonKey()
  final bool needsRide;
// Player needs a ride
  @override
  final int? availableSeats;
// Number of available seats (if offeringRide=true)
  @override
  final String? requestedDriverId;
// ID of driver player requested ride from
// Denormalized game data (to avoid N+1 queries)
  @override
  @TimestampConverter()
  final DateTime? gameDate;
  @override
  final String? gameStatus;
// 'teamSelection', 'teamsFormed', etc.
  @override
  final String? hubId;
  @override
  final String? location;
  @override
  final String? venueName;

  @override
  String toString() {
    return 'GameSignup(playerId: $playerId, signedUpAt: $signedUpAt, status: $status, adminActionReason: $adminActionReason, offeringRide: $offeringRide, needsRide: $needsRide, availableSeats: $availableSeats, requestedDriverId: $requestedDriverId, gameDate: $gameDate, gameStatus: $gameStatus, hubId: $hubId, location: $location, venueName: $venueName)';
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
            (identical(other.status, status) || other.status == status) &&
            (identical(other.adminActionReason, adminActionReason) ||
                other.adminActionReason == adminActionReason) &&
            (identical(other.offeringRide, offeringRide) ||
                other.offeringRide == offeringRide) &&
            (identical(other.needsRide, needsRide) ||
                other.needsRide == needsRide) &&
            (identical(other.availableSeats, availableSeats) ||
                other.availableSeats == availableSeats) &&
            (identical(other.requestedDriverId, requestedDriverId) ||
                other.requestedDriverId == requestedDriverId) &&
            (identical(other.gameDate, gameDate) ||
                other.gameDate == gameDate) &&
            (identical(other.gameStatus, gameStatus) ||
                other.gameStatus == gameStatus) &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.venueName, venueName) ||
                other.venueName == venueName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      playerId,
      signedUpAt,
      status,
      adminActionReason,
      offeringRide,
      needsRide,
      availableSeats,
      requestedDriverId,
      gameDate,
      gameStatus,
      hubId,
      location,
      venueName);

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
      @SignupStatusConverter() final SignupStatus status,
      final String? adminActionReason,
      final bool offeringRide,
      final bool needsRide,
      final int? availableSeats,
      final String? requestedDriverId,
      @TimestampConverter() final DateTime? gameDate,
      final String? gameStatus,
      final String? hubId,
      final String? location,
      final String? venueName}) = _$GameSignupImpl;

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
  @override
  String? get adminActionReason; // Mandatory for rejections/kicks
// Ride-sharing (Trempiyada) fields
  @override
  bool get offeringRide; // Player is offering a ride
  @override
  bool get needsRide; // Player needs a ride
  @override
  int? get availableSeats; // Number of available seats (if offeringRide=true)
  @override
  String? get requestedDriverId; // ID of driver player requested ride from
// Denormalized game data (to avoid N+1 queries)
  @override
  @TimestampConverter()
  DateTime? get gameDate;
  @override
  String? get gameStatus; // 'teamSelection', 'teamsFormed', etc.
  @override
  String? get hubId;
  @override
  String? get location;
  @override
  String? get venueName;

  /// Create a copy of GameSignup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameSignupImplCopyWith<_$GameSignupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
