// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_audit_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameAuditEvent _$GameAuditEventFromJson(Map<String, dynamic> json) {
  return _GameAuditEvent.fromJson(json);
}

/// @nodoc
mixin _$GameAuditEvent {
  /// Action type (e.g., "PLAYER_KICKED", "GAME_RESCHEDULED", "PLAYER_APPROVED")
  String get action => throw _privateConstructorUsedError;

  /// User ID who performed the action
  String get userId => throw _privateConstructorUsedError;

  /// When the action was performed
  @TimestampConverter()
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Optional reason/notes for the action
  String? get reason => throw _privateConstructorUsedError;

  /// Serializes this GameAuditEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameAuditEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameAuditEventCopyWith<GameAuditEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameAuditEventCopyWith<$Res> {
  factory $GameAuditEventCopyWith(
          GameAuditEvent value, $Res Function(GameAuditEvent) then) =
      _$GameAuditEventCopyWithImpl<$Res, GameAuditEvent>;
  @useResult
  $Res call(
      {String action,
      String userId,
      @TimestampConverter() DateTime timestamp,
      String? reason});
}

/// @nodoc
class _$GameAuditEventCopyWithImpl<$Res, $Val extends GameAuditEvent>
    implements $GameAuditEventCopyWith<$Res> {
  _$GameAuditEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameAuditEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? action = null,
    Object? userId = null,
    Object? timestamp = null,
    Object? reason = freezed,
  }) {
    return _then(_value.copyWith(
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameAuditEventImplCopyWith<$Res>
    implements $GameAuditEventCopyWith<$Res> {
  factory _$$GameAuditEventImplCopyWith(_$GameAuditEventImpl value,
          $Res Function(_$GameAuditEventImpl) then) =
      __$$GameAuditEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String action,
      String userId,
      @TimestampConverter() DateTime timestamp,
      String? reason});
}

/// @nodoc
class __$$GameAuditEventImplCopyWithImpl<$Res>
    extends _$GameAuditEventCopyWithImpl<$Res, _$GameAuditEventImpl>
    implements _$$GameAuditEventImplCopyWith<$Res> {
  __$$GameAuditEventImplCopyWithImpl(
      _$GameAuditEventImpl _value, $Res Function(_$GameAuditEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameAuditEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? action = null,
    Object? userId = null,
    Object? timestamp = null,
    Object? reason = freezed,
  }) {
    return _then(_$GameAuditEventImpl(
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameAuditEventImpl implements _GameAuditEvent {
  const _$GameAuditEventImpl(
      {required this.action,
      required this.userId,
      @TimestampConverter() required this.timestamp,
      this.reason});

  factory _$GameAuditEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameAuditEventImplFromJson(json);

  /// Action type (e.g., "PLAYER_KICKED", "GAME_RESCHEDULED", "PLAYER_APPROVED")
  @override
  final String action;

  /// User ID who performed the action
  @override
  final String userId;

  /// When the action was performed
  @override
  @TimestampConverter()
  final DateTime timestamp;

  /// Optional reason/notes for the action
  @override
  final String? reason;

  @override
  String toString() {
    return 'GameAuditEvent(action: $action, userId: $userId, timestamp: $timestamp, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameAuditEventImpl &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, action, userId, timestamp, reason);

  /// Create a copy of GameAuditEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameAuditEventImplCopyWith<_$GameAuditEventImpl> get copyWith =>
      __$$GameAuditEventImplCopyWithImpl<_$GameAuditEventImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameAuditEventImplToJson(
      this,
    );
  }
}

abstract class _GameAuditEvent implements GameAuditEvent {
  const factory _GameAuditEvent(
      {required final String action,
      required final String userId,
      @TimestampConverter() required final DateTime timestamp,
      final String? reason}) = _$GameAuditEventImpl;

  factory _GameAuditEvent.fromJson(Map<String, dynamic> json) =
      _$GameAuditEventImpl.fromJson;

  /// Action type (e.g., "PLAYER_KICKED", "GAME_RESCHEDULED", "PLAYER_APPROVED")
  @override
  String get action;

  /// User ID who performed the action
  @override
  String get userId;

  /// When the action was performed
  @override
  @TimestampConverter()
  DateTime get timestamp;

  /// Optional reason/notes for the action
  @override
  String? get reason;

  /// Create a copy of GameAuditEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameAuditEventImplCopyWith<_$GameAuditEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
