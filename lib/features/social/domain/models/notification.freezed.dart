// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Notification _$NotificationFromJson(Map<String, dynamic> json) {
  return _Notification.fromJson(json);
}

/// @nodoc
mixin _$Notification {
  String get notificationId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // 'game_reminder' | 'message' | 'like' | 'comment' | 'signup' | 'new_follower' | 'hub_chat' | 'new_comment' | 'new_game'
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  Map<String, dynamic>? get data => throw _privateConstructorUsedError;
  bool get read => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get entityId =>
      throw _privateConstructorUsedError; // ID of related entity (gameId, hubId, etc.)
  String? get hubId => throw _privateConstructorUsedError;

  /// Serializes this Notification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationCopyWith<Notification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationCopyWith<$Res> {
  factory $NotificationCopyWith(
          Notification value, $Res Function(Notification) then) =
      _$NotificationCopyWithImpl<$Res, Notification>;
  @useResult
  $Res call(
      {String notificationId,
      String userId,
      String type,
      String title,
      String body,
      Map<String, dynamic>? data,
      bool read,
      @TimestampConverter() DateTime createdAt,
      String? entityId,
      String? hubId});
}

/// @nodoc
class _$NotificationCopyWithImpl<$Res, $Val extends Notification>
    implements $NotificationCopyWith<$Res> {
  _$NotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notificationId = null,
    Object? userId = null,
    Object? type = null,
    Object? title = null,
    Object? body = null,
    Object? data = freezed,
    Object? read = null,
    Object? createdAt = null,
    Object? entityId = freezed,
    Object? hubId = freezed,
  }) {
    return _then(_value.copyWith(
      notificationId: null == notificationId
          ? _value.notificationId
          : notificationId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      read: null == read
          ? _value.read
          : read // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String?,
      hubId: freezed == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationImplCopyWith<$Res>
    implements $NotificationCopyWith<$Res> {
  factory _$$NotificationImplCopyWith(
          _$NotificationImpl value, $Res Function(_$NotificationImpl) then) =
      __$$NotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String notificationId,
      String userId,
      String type,
      String title,
      String body,
      Map<String, dynamic>? data,
      bool read,
      @TimestampConverter() DateTime createdAt,
      String? entityId,
      String? hubId});
}

/// @nodoc
class __$$NotificationImplCopyWithImpl<$Res>
    extends _$NotificationCopyWithImpl<$Res, _$NotificationImpl>
    implements _$$NotificationImplCopyWith<$Res> {
  __$$NotificationImplCopyWithImpl(
      _$NotificationImpl _value, $Res Function(_$NotificationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notificationId = null,
    Object? userId = null,
    Object? type = null,
    Object? title = null,
    Object? body = null,
    Object? data = freezed,
    Object? read = null,
    Object? createdAt = null,
    Object? entityId = freezed,
    Object? hubId = freezed,
  }) {
    return _then(_$NotificationImpl(
      notificationId: null == notificationId
          ? _value.notificationId
          : notificationId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      read: null == read
          ? _value.read
          : read // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String?,
      hubId: freezed == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationImpl implements _Notification {
  const _$NotificationImpl(
      {required this.notificationId,
      required this.userId,
      required this.type,
      required this.title,
      required this.body,
      final Map<String, dynamic>? data,
      this.read = false,
      @TimestampConverter() required this.createdAt,
      this.entityId,
      this.hubId})
      : _data = data;

  factory _$NotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationImplFromJson(json);

  @override
  final String notificationId;
  @override
  final String userId;
  @override
  final String type;
// 'game_reminder' | 'message' | 'like' | 'comment' | 'signup' | 'new_follower' | 'hub_chat' | 'new_comment' | 'new_game'
  @override
  final String title;
  @override
  final String body;
  final Map<String, dynamic>? _data;
  @override
  Map<String, dynamic>? get data {
    final value = _data;
    if (value == null) return null;
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final bool read;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  final String? entityId;
// ID of related entity (gameId, hubId, etc.)
  @override
  final String? hubId;

  @override
  String toString() {
    return 'Notification(notificationId: $notificationId, userId: $userId, type: $type, title: $title, body: $body, data: $data, read: $read, createdAt: $createdAt, entityId: $entityId, hubId: $hubId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationImpl &&
            (identical(other.notificationId, notificationId) ||
                other.notificationId == notificationId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.read, read) || other.read == read) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.hubId, hubId) || other.hubId == hubId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      notificationId,
      userId,
      type,
      title,
      body,
      const DeepCollectionEquality().hash(_data),
      read,
      createdAt,
      entityId,
      hubId);

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      __$$NotificationImplCopyWithImpl<_$NotificationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationImplToJson(
      this,
    );
  }
}

abstract class _Notification implements Notification {
  const factory _Notification(
      {required final String notificationId,
      required final String userId,
      required final String type,
      required final String title,
      required final String body,
      final Map<String, dynamic>? data,
      final bool read,
      @TimestampConverter() required final DateTime createdAt,
      final String? entityId,
      final String? hubId}) = _$NotificationImpl;

  factory _Notification.fromJson(Map<String, dynamic> json) =
      _$NotificationImpl.fromJson;

  @override
  String get notificationId;
  @override
  String get userId;
  @override
  String
      get type; // 'game_reminder' | 'message' | 'like' | 'comment' | 'signup' | 'new_follower' | 'hub_chat' | 'new_comment' | 'new_game'
  @override
  String get title;
  @override
  String get body;
  @override
  Map<String, dynamic>? get data;
  @override
  bool get read;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  String? get entityId; // ID of related entity (gameId, hubId, etc.)
  @override
  String? get hubId;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
