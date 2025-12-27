// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hub_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HubMember _$HubMemberFromJson(Map<String, dynamic> json) {
  return _HubMember.fromJson(json);
}

/// @nodoc
mixin _$HubMember {
  String get hubId => throw _privateConstructorUsedError;
  String get userId =>
      throw _privateConstructorUsedError; // Core membership data
  @TimestampConverter()
  DateTime get joinedAt => throw _privateConstructorUsedError;
  HubMemberRole get role => throw _privateConstructorUsedError;
  HubMemberStatus get status =>
      throw _privateConstructorUsedError; // Time-based promotions (SERVER-MANAGED ONLY by Cloud Function)
  @TimestampConverter()
  DateTime? get veteranSince =>
      throw _privateConstructorUsedError; // Additional metadata (moved from Hub.managerRatings map)
  double get managerRating =>
      throw _privateConstructorUsedError; // Activity tracking
  @TimestampConverter()
  DateTime? get lastActiveAt =>
      throw _privateConstructorUsedError; // Audit trail
  @TimestampConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  String? get updatedBy =>
      throw _privateConstructorUsedError; // userId or 'system:functionName'
// Optional: reason for status change (for bans/kicks)
  String? get statusReason => throw _privateConstructorUsedError;

  /// Serializes this HubMember to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HubMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HubMemberCopyWith<HubMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HubMemberCopyWith<$Res> {
  factory $HubMemberCopyWith(HubMember value, $Res Function(HubMember) then) =
      _$HubMemberCopyWithImpl<$Res, HubMember>;
  @useResult
  $Res call(
      {String hubId,
      String userId,
      @TimestampConverter() DateTime joinedAt,
      HubMemberRole role,
      HubMemberStatus status,
      @TimestampConverter() DateTime? veteranSince,
      double managerRating,
      @TimestampConverter() DateTime? lastActiveAt,
      @TimestampConverter() DateTime? updatedAt,
      String? updatedBy,
      String? statusReason});
}

/// @nodoc
class _$HubMemberCopyWithImpl<$Res, $Val extends HubMember>
    implements $HubMemberCopyWith<$Res> {
  _$HubMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HubMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hubId = null,
    Object? userId = null,
    Object? joinedAt = null,
    Object? role = null,
    Object? status = null,
    Object? veteranSince = freezed,
    Object? managerRating = null,
    Object? lastActiveAt = freezed,
    Object? updatedAt = freezed,
    Object? updatedBy = freezed,
    Object? statusReason = freezed,
  }) {
    return _then(_value.copyWith(
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as HubMemberRole,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as HubMemberStatus,
      veteranSince: freezed == veteranSince
          ? _value.veteranSince
          : veteranSince // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      managerRating: null == managerRating
          ? _value.managerRating
          : managerRating // ignore: cast_nullable_to_non_nullable
              as double,
      lastActiveAt: freezed == lastActiveAt
          ? _value.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedBy: freezed == updatedBy
          ? _value.updatedBy
          : updatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      statusReason: freezed == statusReason
          ? _value.statusReason
          : statusReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HubMemberImplCopyWith<$Res>
    implements $HubMemberCopyWith<$Res> {
  factory _$$HubMemberImplCopyWith(
          _$HubMemberImpl value, $Res Function(_$HubMemberImpl) then) =
      __$$HubMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String hubId,
      String userId,
      @TimestampConverter() DateTime joinedAt,
      HubMemberRole role,
      HubMemberStatus status,
      @TimestampConverter() DateTime? veteranSince,
      double managerRating,
      @TimestampConverter() DateTime? lastActiveAt,
      @TimestampConverter() DateTime? updatedAt,
      String? updatedBy,
      String? statusReason});
}

/// @nodoc
class __$$HubMemberImplCopyWithImpl<$Res>
    extends _$HubMemberCopyWithImpl<$Res, _$HubMemberImpl>
    implements _$$HubMemberImplCopyWith<$Res> {
  __$$HubMemberImplCopyWithImpl(
      _$HubMemberImpl _value, $Res Function(_$HubMemberImpl) _then)
      : super(_value, _then);

  /// Create a copy of HubMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hubId = null,
    Object? userId = null,
    Object? joinedAt = null,
    Object? role = null,
    Object? status = null,
    Object? veteranSince = freezed,
    Object? managerRating = null,
    Object? lastActiveAt = freezed,
    Object? updatedAt = freezed,
    Object? updatedBy = freezed,
    Object? statusReason = freezed,
  }) {
    return _then(_$HubMemberImpl(
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as HubMemberRole,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as HubMemberStatus,
      veteranSince: freezed == veteranSince
          ? _value.veteranSince
          : veteranSince // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      managerRating: null == managerRating
          ? _value.managerRating
          : managerRating // ignore: cast_nullable_to_non_nullable
              as double,
      lastActiveAt: freezed == lastActiveAt
          ? _value.lastActiveAt
          : lastActiveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedBy: freezed == updatedBy
          ? _value.updatedBy
          : updatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      statusReason: freezed == statusReason
          ? _value.statusReason
          : statusReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HubMemberImpl extends _HubMember {
  const _$HubMemberImpl(
      {required this.hubId,
      required this.userId,
      @TimestampConverter() required this.joinedAt,
      this.role = HubMemberRole.member,
      this.status = HubMemberStatus.active,
      @TimestampConverter() this.veteranSince,
      this.managerRating = 0.0,
      @TimestampConverter() this.lastActiveAt,
      @TimestampConverter() this.updatedAt,
      this.updatedBy,
      this.statusReason})
      : super._();

  factory _$HubMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$HubMemberImplFromJson(json);

  @override
  final String hubId;
  @override
  final String userId;
// Core membership data
  @override
  @TimestampConverter()
  final DateTime joinedAt;
  @override
  @JsonKey()
  final HubMemberRole role;
  @override
  @JsonKey()
  final HubMemberStatus status;
// Time-based promotions (SERVER-MANAGED ONLY by Cloud Function)
  @override
  @TimestampConverter()
  final DateTime? veteranSince;
// Additional metadata (moved from Hub.managerRatings map)
  @override
  @JsonKey()
  final double managerRating;
// Activity tracking
  @override
  @TimestampConverter()
  final DateTime? lastActiveAt;
// Audit trail
  @override
  @TimestampConverter()
  final DateTime? updatedAt;
  @override
  final String? updatedBy;
// userId or 'system:functionName'
// Optional: reason for status change (for bans/kicks)
  @override
  final String? statusReason;

  @override
  String toString() {
    return 'HubMember(hubId: $hubId, userId: $userId, joinedAt: $joinedAt, role: $role, status: $status, veteranSince: $veteranSince, managerRating: $managerRating, lastActiveAt: $lastActiveAt, updatedAt: $updatedAt, updatedBy: $updatedBy, statusReason: $statusReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HubMemberImpl &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.veteranSince, veteranSince) ||
                other.veteranSince == veteranSince) &&
            (identical(other.managerRating, managerRating) ||
                other.managerRating == managerRating) &&
            (identical(other.lastActiveAt, lastActiveAt) ||
                other.lastActiveAt == lastActiveAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.updatedBy, updatedBy) ||
                other.updatedBy == updatedBy) &&
            (identical(other.statusReason, statusReason) ||
                other.statusReason == statusReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      hubId,
      userId,
      joinedAt,
      role,
      status,
      veteranSince,
      managerRating,
      lastActiveAt,
      updatedAt,
      updatedBy,
      statusReason);

  /// Create a copy of HubMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HubMemberImplCopyWith<_$HubMemberImpl> get copyWith =>
      __$$HubMemberImplCopyWithImpl<_$HubMemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HubMemberImplToJson(
      this,
    );
  }
}

abstract class _HubMember extends HubMember {
  const factory _HubMember(
      {required final String hubId,
      required final String userId,
      @TimestampConverter() required final DateTime joinedAt,
      final HubMemberRole role,
      final HubMemberStatus status,
      @TimestampConverter() final DateTime? veteranSince,
      final double managerRating,
      @TimestampConverter() final DateTime? lastActiveAt,
      @TimestampConverter() final DateTime? updatedAt,
      final String? updatedBy,
      final String? statusReason}) = _$HubMemberImpl;
  const _HubMember._() : super._();

  factory _HubMember.fromJson(Map<String, dynamic> json) =
      _$HubMemberImpl.fromJson;

  @override
  String get hubId;
  @override
  String get userId; // Core membership data
  @override
  @TimestampConverter()
  DateTime get joinedAt;
  @override
  HubMemberRole get role;
  @override
  HubMemberStatus
      get status; // Time-based promotions (SERVER-MANAGED ONLY by Cloud Function)
  @override
  @TimestampConverter()
  DateTime?
      get veteranSince; // Additional metadata (moved from Hub.managerRatings map)
  @override
  double get managerRating; // Activity tracking
  @override
  @TimestampConverter()
  DateTime? get lastActiveAt; // Audit trail
  @override
  @TimestampConverter()
  DateTime? get updatedAt;
  @override
  String? get updatedBy; // userId or 'system:functionName'
// Optional: reason for status change (for bans/kicks)
  @override
  String? get statusReason;

  /// Create a copy of HubMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HubMemberImplCopyWith<_$HubMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
