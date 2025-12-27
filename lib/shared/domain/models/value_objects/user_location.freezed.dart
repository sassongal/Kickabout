// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_location.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserLocation _$UserLocationFromJson(Map<String, dynamic> json) {
  return _UserLocation.fromJson(json);
}

/// @nodoc
mixin _$UserLocation {
  @NullableGeographicPointFirestoreConverter()
  GeographicPoint? get location => throw _privateConstructorUsedError;
  String? get geohash => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get region => throw _privateConstructorUsedError;

  /// Serializes this UserLocation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserLocationCopyWith<UserLocation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserLocationCopyWith<$Res> {
  factory $UserLocationCopyWith(
          UserLocation value, $Res Function(UserLocation) then) =
      _$UserLocationCopyWithImpl<$Res, UserLocation>;
  @useResult
  $Res call(
      {@NullableGeographicPointFirestoreConverter() GeographicPoint? location,
      String? geohash,
      String? city,
      String? region});

  $GeographicPointCopyWith<$Res>? get location;
}

/// @nodoc
class _$UserLocationCopyWithImpl<$Res, $Val extends UserLocation>
    implements $UserLocationCopyWith<$Res> {
  _$UserLocationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? location = freezed,
    Object? geohash = freezed,
    Object? city = freezed,
    Object? region = freezed,
  }) {
    return _then(_value.copyWith(
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeographicPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of UserLocation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GeographicPointCopyWith<$Res>? get location {
    if (_value.location == null) {
      return null;
    }

    return $GeographicPointCopyWith<$Res>(_value.location!, (value) {
      return _then(_value.copyWith(location: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserLocationImplCopyWith<$Res>
    implements $UserLocationCopyWith<$Res> {
  factory _$$UserLocationImplCopyWith(
          _$UserLocationImpl value, $Res Function(_$UserLocationImpl) then) =
      __$$UserLocationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@NullableGeographicPointFirestoreConverter() GeographicPoint? location,
      String? geohash,
      String? city,
      String? region});

  @override
  $GeographicPointCopyWith<$Res>? get location;
}

/// @nodoc
class __$$UserLocationImplCopyWithImpl<$Res>
    extends _$UserLocationCopyWithImpl<$Res, _$UserLocationImpl>
    implements _$$UserLocationImplCopyWith<$Res> {
  __$$UserLocationImplCopyWithImpl(
      _$UserLocationImpl _value, $Res Function(_$UserLocationImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? location = freezed,
    Object? geohash = freezed,
    Object? city = freezed,
    Object? region = freezed,
  }) {
    return _then(_$UserLocationImpl(
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeographicPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserLocationImpl implements _UserLocation {
  const _$UserLocationImpl(
      {@NullableGeographicPointFirestoreConverter() this.location,
      this.geohash,
      this.city,
      this.region});

  factory _$UserLocationImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserLocationImplFromJson(json);

  @override
  @NullableGeographicPointFirestoreConverter()
  final GeographicPoint? location;
  @override
  final String? geohash;
  @override
  final String? city;
  @override
  final String? region;

  @override
  String toString() {
    return 'UserLocation(location: $location, geohash: $geohash, city: $city, region: $region)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserLocationImpl &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.geohash, geohash) || other.geohash == geohash) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.region, region) || other.region == region));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, location, geohash, city, region);

  /// Create a copy of UserLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserLocationImplCopyWith<_$UserLocationImpl> get copyWith =>
      __$$UserLocationImplCopyWithImpl<_$UserLocationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserLocationImplToJson(
      this,
    );
  }
}

abstract class _UserLocation implements UserLocation {
  const factory _UserLocation(
      {@NullableGeographicPointFirestoreConverter()
      final GeographicPoint? location,
      final String? geohash,
      final String? city,
      final String? region}) = _$UserLocationImpl;

  factory _UserLocation.fromJson(Map<String, dynamic> json) =
      _$UserLocationImpl.fromJson;

  @override
  @NullableGeographicPointFirestoreConverter()
  GeographicPoint? get location;
  @override
  String? get geohash;
  @override
  String? get city;
  @override
  String? get region;

  /// Create a copy of UserLocation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserLocationImplCopyWith<_$UserLocationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
