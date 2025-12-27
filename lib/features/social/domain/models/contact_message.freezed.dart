// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contact_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ContactMessage _$ContactMessageFromJson(Map<String, dynamic> json) {
  return _ContactMessage.fromJson(json);
}

/// @nodoc
mixin _$ContactMessage {
  String get messageId => throw _privateConstructorUsedError;
  String get hubId => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get postId =>
      throw _privateConstructorUsedError; // Link to recruiting post
  String get message => throw _privateConstructorUsedError; // Player's message
  String get status =>
      throw _privateConstructorUsedError; // 'pending' | 'read' | 'replied'
  @TimestampConverter()
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // Denormalized for display
  String? get senderName => throw _privateConstructorUsedError;
  String? get senderPhotoUrl => throw _privateConstructorUsedError;
  String? get senderPhone => throw _privateConstructorUsedError;
  String? get postContent => throw _privateConstructorUsedError;

  /// Serializes this ContactMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContactMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContactMessageCopyWith<ContactMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContactMessageCopyWith<$Res> {
  factory $ContactMessageCopyWith(
          ContactMessage value, $Res Function(ContactMessage) then) =
      _$ContactMessageCopyWithImpl<$Res, ContactMessage>;
  @useResult
  $Res call(
      {String messageId,
      String hubId,
      String senderId,
      String postId,
      String message,
      String status,
      @TimestampConverter() DateTime createdAt,
      String? senderName,
      String? senderPhotoUrl,
      String? senderPhone,
      String? postContent});
}

/// @nodoc
class _$ContactMessageCopyWithImpl<$Res, $Val extends ContactMessage>
    implements $ContactMessageCopyWith<$Res> {
  _$ContactMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContactMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? hubId = null,
    Object? senderId = null,
    Object? postId = null,
    Object? message = null,
    Object? status = null,
    Object? createdAt = null,
    Object? senderName = freezed,
    Object? senderPhotoUrl = freezed,
    Object? senderPhone = freezed,
    Object? postContent = freezed,
  }) {
    return _then(_value.copyWith(
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      postId: null == postId
          ? _value.postId
          : postId // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderPhotoUrl: freezed == senderPhotoUrl
          ? _value.senderPhotoUrl
          : senderPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      senderPhone: freezed == senderPhone
          ? _value.senderPhone
          : senderPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      postContent: freezed == postContent
          ? _value.postContent
          : postContent // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ContactMessageImplCopyWith<$Res>
    implements $ContactMessageCopyWith<$Res> {
  factory _$$ContactMessageImplCopyWith(_$ContactMessageImpl value,
          $Res Function(_$ContactMessageImpl) then) =
      __$$ContactMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String messageId,
      String hubId,
      String senderId,
      String postId,
      String message,
      String status,
      @TimestampConverter() DateTime createdAt,
      String? senderName,
      String? senderPhotoUrl,
      String? senderPhone,
      String? postContent});
}

/// @nodoc
class __$$ContactMessageImplCopyWithImpl<$Res>
    extends _$ContactMessageCopyWithImpl<$Res, _$ContactMessageImpl>
    implements _$$ContactMessageImplCopyWith<$Res> {
  __$$ContactMessageImplCopyWithImpl(
      _$ContactMessageImpl _value, $Res Function(_$ContactMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ContactMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? hubId = null,
    Object? senderId = null,
    Object? postId = null,
    Object? message = null,
    Object? status = null,
    Object? createdAt = null,
    Object? senderName = freezed,
    Object? senderPhotoUrl = freezed,
    Object? senderPhone = freezed,
    Object? postContent = freezed,
  }) {
    return _then(_$ContactMessageImpl(
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      postId: null == postId
          ? _value.postId
          : postId // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderPhotoUrl: freezed == senderPhotoUrl
          ? _value.senderPhotoUrl
          : senderPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      senderPhone: freezed == senderPhone
          ? _value.senderPhone
          : senderPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      postContent: freezed == postContent
          ? _value.postContent
          : postContent // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ContactMessageImpl implements _ContactMessage {
  const _$ContactMessageImpl(
      {required this.messageId,
      required this.hubId,
      required this.senderId,
      required this.postId,
      required this.message,
      this.status = 'pending',
      @TimestampConverter() required this.createdAt,
      this.senderName,
      this.senderPhotoUrl,
      this.senderPhone,
      this.postContent});

  factory _$ContactMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContactMessageImplFromJson(json);

  @override
  final String messageId;
  @override
  final String hubId;
  @override
  final String senderId;
  @override
  final String postId;
// Link to recruiting post
  @override
  final String message;
// Player's message
  @override
  @JsonKey()
  final String status;
// 'pending' | 'read' | 'replied'
  @override
  @TimestampConverter()
  final DateTime createdAt;
// Denormalized for display
  @override
  final String? senderName;
  @override
  final String? senderPhotoUrl;
  @override
  final String? senderPhone;
  @override
  final String? postContent;

  @override
  String toString() {
    return 'ContactMessage(messageId: $messageId, hubId: $hubId, senderId: $senderId, postId: $postId, message: $message, status: $status, createdAt: $createdAt, senderName: $senderName, senderPhotoUrl: $senderPhotoUrl, senderPhone: $senderPhone, postContent: $postContent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContactMessageImpl &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.postId, postId) || other.postId == postId) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderPhotoUrl, senderPhotoUrl) ||
                other.senderPhotoUrl == senderPhotoUrl) &&
            (identical(other.senderPhone, senderPhone) ||
                other.senderPhone == senderPhone) &&
            (identical(other.postContent, postContent) ||
                other.postContent == postContent));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      messageId,
      hubId,
      senderId,
      postId,
      message,
      status,
      createdAt,
      senderName,
      senderPhotoUrl,
      senderPhone,
      postContent);

  /// Create a copy of ContactMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContactMessageImplCopyWith<_$ContactMessageImpl> get copyWith =>
      __$$ContactMessageImplCopyWithImpl<_$ContactMessageImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContactMessageImplToJson(
      this,
    );
  }
}

abstract class _ContactMessage implements ContactMessage {
  const factory _ContactMessage(
      {required final String messageId,
      required final String hubId,
      required final String senderId,
      required final String postId,
      required final String message,
      final String status,
      @TimestampConverter() required final DateTime createdAt,
      final String? senderName,
      final String? senderPhotoUrl,
      final String? senderPhone,
      final String? postContent}) = _$ContactMessageImpl;

  factory _ContactMessage.fromJson(Map<String, dynamic> json) =
      _$ContactMessageImpl.fromJson;

  @override
  String get messageId;
  @override
  String get hubId;
  @override
  String get senderId;
  @override
  String get postId; // Link to recruiting post
  @override
  String get message; // Player's message
  @override
  String get status; // 'pending' | 'read' | 'replied'
  @override
  @TimestampConverter()
  DateTime get createdAt; // Denormalized for display
  @override
  String? get senderName;
  @override
  String? get senderPhotoUrl;
  @override
  String? get senderPhone;
  @override
  String? get postContent;

  /// Create a copy of ContactMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContactMessageImplCopyWith<_$ContactMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
