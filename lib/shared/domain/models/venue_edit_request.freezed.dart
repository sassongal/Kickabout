// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_edit_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VenueEditRequest _$VenueEditRequestFromJson(Map<String, dynamic> json) {
  return _VenueEditRequest.fromJson(json);
}

/// @nodoc
mixin _$VenueEditRequest {
  String get requestId => throw _privateConstructorUsedError;
  String get venueId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  Map<String, dynamic> get changes => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Serializes this VenueEditRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VenueEditRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VenueEditRequestCopyWith<VenueEditRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VenueEditRequestCopyWith<$Res> {
  factory $VenueEditRequestCopyWith(
          VenueEditRequest value, $Res Function(VenueEditRequest) then) =
      _$VenueEditRequestCopyWithImpl<$Res, VenueEditRequest>;
  @useResult
  $Res call(
      {String requestId,
      String venueId,
      String userId,
      Map<String, dynamic> changes,
      @TimestampConverter() DateTime createdAt,
      String status});
}

/// @nodoc
class _$VenueEditRequestCopyWithImpl<$Res, $Val extends VenueEditRequest>
    implements $VenueEditRequestCopyWith<$Res> {
  _$VenueEditRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VenueEditRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestId = null,
    Object? venueId = null,
    Object? userId = null,
    Object? changes = null,
    Object? createdAt = null,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      requestId: null == requestId
          ? _value.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as String,
      venueId: null == venueId
          ? _value.venueId
          : venueId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      changes: null == changes
          ? _value.changes
          : changes // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VenueEditRequestImplCopyWith<$Res>
    implements $VenueEditRequestCopyWith<$Res> {
  factory _$$VenueEditRequestImplCopyWith(_$VenueEditRequestImpl value,
          $Res Function(_$VenueEditRequestImpl) then) =
      __$$VenueEditRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String requestId,
      String venueId,
      String userId,
      Map<String, dynamic> changes,
      @TimestampConverter() DateTime createdAt,
      String status});
}

/// @nodoc
class __$$VenueEditRequestImplCopyWithImpl<$Res>
    extends _$VenueEditRequestCopyWithImpl<$Res, _$VenueEditRequestImpl>
    implements _$$VenueEditRequestImplCopyWith<$Res> {
  __$$VenueEditRequestImplCopyWithImpl(_$VenueEditRequestImpl _value,
      $Res Function(_$VenueEditRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of VenueEditRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestId = null,
    Object? venueId = null,
    Object? userId = null,
    Object? changes = null,
    Object? createdAt = null,
    Object? status = null,
  }) {
    return _then(_$VenueEditRequestImpl(
      requestId: null == requestId
          ? _value.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as String,
      venueId: null == venueId
          ? _value.venueId
          : venueId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      changes: null == changes
          ? _value._changes
          : changes // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VenueEditRequestImpl implements _VenueEditRequest {
  const _$VenueEditRequestImpl(
      {required this.requestId,
      required this.venueId,
      required this.userId,
      required final Map<String, dynamic> changes,
      @TimestampConverter() required this.createdAt,
      this.status = 'pending'})
      : _changes = changes;

  factory _$VenueEditRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$VenueEditRequestImplFromJson(json);

  @override
  final String requestId;
  @override
  final String venueId;
  @override
  final String userId;
  final Map<String, dynamic> _changes;
  @override
  Map<String, dynamic> get changes {
    if (_changes is EqualUnmodifiableMapView) return _changes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_changes);
  }

  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'VenueEditRequest(requestId: $requestId, venueId: $venueId, userId: $userId, changes: $changes, createdAt: $createdAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VenueEditRequestImpl &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.venueId, venueId) || other.venueId == venueId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(other._changes, _changes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, requestId, venueId, userId,
      const DeepCollectionEquality().hash(_changes), createdAt, status);

  /// Create a copy of VenueEditRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VenueEditRequestImplCopyWith<_$VenueEditRequestImpl> get copyWith =>
      __$$VenueEditRequestImplCopyWithImpl<_$VenueEditRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VenueEditRequestImplToJson(
      this,
    );
  }
}

abstract class _VenueEditRequest implements VenueEditRequest {
  const factory _VenueEditRequest(
      {required final String requestId,
      required final String venueId,
      required final String userId,
      required final Map<String, dynamic> changes,
      @TimestampConverter() required final DateTime createdAt,
      final String status}) = _$VenueEditRequestImpl;

  factory _VenueEditRequest.fromJson(Map<String, dynamic> json) =
      _$VenueEditRequestImpl.fromJson;

  @override
  String get requestId;
  @override
  String get venueId;
  @override
  String get userId;
  @override
  Map<String, dynamic> get changes;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  String get status;

  /// Create a copy of VenueEditRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VenueEditRequestImplCopyWith<_$VenueEditRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
