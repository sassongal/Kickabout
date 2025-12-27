// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geographic_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GeographicPoint _$GeographicPointFromJson(Map<String, dynamic> json) {
  return _GeographicPoint.fromJson(json);
}

/// @nodoc
mixin _$GeographicPoint {
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;

  /// Serializes this GeographicPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GeographicPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GeographicPointCopyWith<GeographicPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GeographicPointCopyWith<$Res> {
  factory $GeographicPointCopyWith(
          GeographicPoint value, $Res Function(GeographicPoint) then) =
      _$GeographicPointCopyWithImpl<$Res, GeographicPoint>;
  @useResult
  $Res call({double latitude, double longitude});
}

/// @nodoc
class _$GeographicPointCopyWithImpl<$Res, $Val extends GeographicPoint>
    implements $GeographicPointCopyWith<$Res> {
  _$GeographicPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GeographicPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(_value.copyWith(
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GeographicPointImplCopyWith<$Res>
    implements $GeographicPointCopyWith<$Res> {
  factory _$$GeographicPointImplCopyWith(_$GeographicPointImpl value,
          $Res Function(_$GeographicPointImpl) then) =
      __$$GeographicPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double latitude, double longitude});
}

/// @nodoc
class __$$GeographicPointImplCopyWithImpl<$Res>
    extends _$GeographicPointCopyWithImpl<$Res, _$GeographicPointImpl>
    implements _$$GeographicPointImplCopyWith<$Res> {
  __$$GeographicPointImplCopyWithImpl(
      _$GeographicPointImpl _value, $Res Function(_$GeographicPointImpl) _then)
      : super(_value, _then);

  /// Create a copy of GeographicPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(_$GeographicPointImpl(
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GeographicPointImpl extends _GeographicPoint {
  const _$GeographicPointImpl({required this.latitude, required this.longitude})
      : super._();

  factory _$GeographicPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$GeographicPointImplFromJson(json);

  @override
  final double latitude;
  @override
  final double longitude;

  @override
  String toString() {
    return 'GeographicPoint(latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GeographicPointImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, latitude, longitude);

  /// Create a copy of GeographicPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GeographicPointImplCopyWith<_$GeographicPointImpl> get copyWith =>
      __$$GeographicPointImplCopyWithImpl<_$GeographicPointImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GeographicPointImplToJson(
      this,
    );
  }
}

abstract class _GeographicPoint extends GeographicPoint {
  const factory _GeographicPoint(
      {required final double latitude,
      required final double longitude}) = _$GeographicPointImpl;
  const _GeographicPoint._() : super._();

  factory _GeographicPoint.fromJson(Map<String, dynamic> json) =
      _$GeographicPointImpl.fromJson;

  @override
  double get latitude;
  @override
  double get longitude;

  /// Create a copy of GeographicPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GeographicPointImplCopyWith<_$GeographicPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
