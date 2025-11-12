// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  String get uid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get phoneNumber => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  List<String> get hubIds => throw _privateConstructorUsedError;
  double get currentRankScore => throw _privateConstructorUsedError;
  String get preferredPosition => throw _privateConstructorUsedError;
  int get totalParticipations => throw _privateConstructorUsedError;
  @GeoPointConverter()
  GeoPoint? get location => throw _privateConstructorUsedError;
  String? get geohash => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call(
      {String uid,
      String name,
      String email,
      String? photoUrl,
      String? phoneNumber,
      @TimestampConverter() DateTime createdAt,
      List<String> hubIds,
      double currentRankScore,
      String preferredPosition,
      int totalParticipations,
      @GeoPointConverter() GeoPoint? location,
      String? geohash});
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? email = null,
    Object? photoUrl = freezed,
    Object? phoneNumber = freezed,
    Object? createdAt = null,
    Object? hubIds = null,
    Object? currentRankScore = null,
    Object? preferredPosition = null,
    Object? totalParticipations = null,
    Object? location = freezed,
    Object? geohash = freezed,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hubIds: null == hubIds
          ? _value.hubIds
          : hubIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentRankScore: null == currentRankScore
          ? _value.currentRankScore
          : currentRankScore // ignore: cast_nullable_to_non_nullable
              as double,
      preferredPosition: null == preferredPosition
          ? _value.preferredPosition
          : preferredPosition // ignore: cast_nullable_to_non_nullable
              as String,
      totalParticipations: null == totalParticipations
          ? _value.totalParticipations
          : totalParticipations // ignore: cast_nullable_to_non_nullable
              as int,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
          _$UserImpl value, $Res Function(_$UserImpl) then) =
      __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid,
      String name,
      String email,
      String? photoUrl,
      String? phoneNumber,
      @TimestampConverter() DateTime createdAt,
      List<String> hubIds,
      double currentRankScore,
      String preferredPosition,
      int totalParticipations,
      @GeoPointConverter() GeoPoint? location,
      String? geohash});
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
      : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? email = null,
    Object? photoUrl = freezed,
    Object? phoneNumber = freezed,
    Object? createdAt = null,
    Object? hubIds = null,
    Object? currentRankScore = null,
    Object? preferredPosition = null,
    Object? totalParticipations = null,
    Object? location = freezed,
    Object? geohash = freezed,
  }) {
    return _then(_$UserImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hubIds: null == hubIds
          ? _value._hubIds
          : hubIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentRankScore: null == currentRankScore
          ? _value.currentRankScore
          : currentRankScore // ignore: cast_nullable_to_non_nullable
              as double,
      preferredPosition: null == preferredPosition
          ? _value.preferredPosition
          : preferredPosition // ignore: cast_nullable_to_non_nullable
              as String,
      totalParticipations: null == totalParticipations
          ? _value.totalParticipations
          : totalParticipations // ignore: cast_nullable_to_non_nullable
              as int,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl(
      {required this.uid,
      required this.name,
      required this.email,
      this.photoUrl,
      this.phoneNumber,
      @TimestampConverter() required this.createdAt,
      final List<String> hubIds = const [],
      this.currentRankScore = 5.0,
      this.preferredPosition = 'Midfielder',
      this.totalParticipations = 0,
      @GeoPointConverter() this.location,
      this.geohash})
      : _hubIds = hubIds;

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  final String uid;
  @override
  final String name;
  @override
  final String email;
  @override
  final String? photoUrl;
  @override
  final String? phoneNumber;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  final List<String> _hubIds;
  @override
  @JsonKey()
  List<String> get hubIds {
    if (_hubIds is EqualUnmodifiableListView) return _hubIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hubIds);
  }

  @override
  @JsonKey()
  final double currentRankScore;
  @override
  @JsonKey()
  final String preferredPosition;
  @override
  @JsonKey()
  final int totalParticipations;
  @override
  @GeoPointConverter()
  final GeoPoint? location;
  @override
  final String? geohash;

  @override
  String toString() {
    return 'User(uid: $uid, name: $name, email: $email, photoUrl: $photoUrl, phoneNumber: $phoneNumber, createdAt: $createdAt, hubIds: $hubIds, currentRankScore: $currentRankScore, preferredPosition: $preferredPosition, totalParticipations: $totalParticipations, location: $location, geohash: $geohash)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._hubIds, _hubIds) &&
            (identical(other.currentRankScore, currentRankScore) ||
                other.currentRankScore == currentRankScore) &&
            (identical(other.preferredPosition, preferredPosition) ||
                other.preferredPosition == preferredPosition) &&
            (identical(other.totalParticipations, totalParticipations) ||
                other.totalParticipations == totalParticipations) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.geohash, geohash) || other.geohash == geohash));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      uid,
      name,
      email,
      photoUrl,
      phoneNumber,
      createdAt,
      const DeepCollectionEquality().hash(_hubIds),
      currentRankScore,
      preferredPosition,
      totalParticipations,
      location,
      geohash);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(
      this,
    );
  }
}

abstract class _User implements User {
  const factory _User(
      {required final String uid,
      required final String name,
      required final String email,
      final String? photoUrl,
      final String? phoneNumber,
      @TimestampConverter() required final DateTime createdAt,
      final List<String> hubIds,
      final double currentRankScore,
      final String preferredPosition,
      final int totalParticipations,
      @GeoPointConverter() final GeoPoint? location,
      final String? geohash}) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  String get uid;
  @override
  String get name;
  @override
  String get email;
  @override
  String? get photoUrl;
  @override
  String? get phoneNumber;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  List<String> get hubIds;
  @override
  double get currentRankScore;
  @override
  String get preferredPosition;
  @override
  int get totalParticipations;
  @override
  @GeoPointConverter()
  GeoPoint? get location;
  @override
  String? get geohash;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
