// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'private_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PrivateMessage _$PrivateMessageFromJson(Map<String, dynamic> json) {
  return _PrivateMessage.fromJson(json);
}

/// @nodoc
mixin _$PrivateMessage {
  String get messageId => throw _privateConstructorUsedError;
  String get conversationId => throw _privateConstructorUsedError;
  String get authorId => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  bool get read => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this PrivateMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrivateMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrivateMessageCopyWith<PrivateMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrivateMessageCopyWith<$Res> {
  factory $PrivateMessageCopyWith(
          PrivateMessage value, $Res Function(PrivateMessage) then) =
      _$PrivateMessageCopyWithImpl<$Res, PrivateMessage>;
  @useResult
  $Res call(
      {String messageId,
      String conversationId,
      String authorId,
      String text,
      bool read,
      @TimestampConverter() DateTime createdAt});
}

/// @nodoc
class _$PrivateMessageCopyWithImpl<$Res, $Val extends PrivateMessage>
    implements $PrivateMessageCopyWith<$Res> {
  _$PrivateMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrivateMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? conversationId = null,
    Object? authorId = null,
    Object? text = null,
    Object? read = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      read: null == read
          ? _value.read
          : read // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PrivateMessageImplCopyWith<$Res>
    implements $PrivateMessageCopyWith<$Res> {
  factory _$$PrivateMessageImplCopyWith(_$PrivateMessageImpl value,
          $Res Function(_$PrivateMessageImpl) then) =
      __$$PrivateMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String messageId,
      String conversationId,
      String authorId,
      String text,
      bool read,
      @TimestampConverter() DateTime createdAt});
}

/// @nodoc
class __$$PrivateMessageImplCopyWithImpl<$Res>
    extends _$PrivateMessageCopyWithImpl<$Res, _$PrivateMessageImpl>
    implements _$$PrivateMessageImplCopyWith<$Res> {
  __$$PrivateMessageImplCopyWithImpl(
      _$PrivateMessageImpl _value, $Res Function(_$PrivateMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of PrivateMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? conversationId = null,
    Object? authorId = null,
    Object? text = null,
    Object? read = null,
    Object? createdAt = null,
  }) {
    return _then(_$PrivateMessageImpl(
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      read: null == read
          ? _value.read
          : read // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PrivateMessageImpl implements _PrivateMessage {
  const _$PrivateMessageImpl(
      {required this.messageId,
      required this.conversationId,
      required this.authorId,
      required this.text,
      this.read = false,
      @TimestampConverter() required this.createdAt});

  factory _$PrivateMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrivateMessageImplFromJson(json);

  @override
  final String messageId;
  @override
  final String conversationId;
  @override
  final String authorId;
  @override
  final String text;
  @override
  @JsonKey()
  final bool read;
  @override
  @TimestampConverter()
  final DateTime createdAt;

  @override
  String toString() {
    return 'PrivateMessage(messageId: $messageId, conversationId: $conversationId, authorId: $authorId, text: $text, read: $read, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrivateMessageImpl &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.read, read) || other.read == read) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, messageId, conversationId, authorId, text, read, createdAt);

  /// Create a copy of PrivateMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrivateMessageImplCopyWith<_$PrivateMessageImpl> get copyWith =>
      __$$PrivateMessageImplCopyWithImpl<_$PrivateMessageImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PrivateMessageImplToJson(
      this,
    );
  }
}

abstract class _PrivateMessage implements PrivateMessage {
  const factory _PrivateMessage(
          {required final String messageId,
          required final String conversationId,
          required final String authorId,
          required final String text,
          final bool read,
          @TimestampConverter() required final DateTime createdAt}) =
      _$PrivateMessageImpl;

  factory _PrivateMessage.fromJson(Map<String, dynamic> json) =
      _$PrivateMessageImpl.fromJson;

  @override
  String get messageId;
  @override
  String get conversationId;
  @override
  String get authorId;
  @override
  String get text;
  @override
  bool get read;
  @override
  @TimestampConverter()
  DateTime get createdAt;

  /// Create a copy of PrivateMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrivateMessageImplCopyWith<_$PrivateMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Conversation _$ConversationFromJson(Map<String, dynamic> json) {
  return _Conversation.fromJson(json);
}

/// @nodoc
mixin _$Conversation {
  String get conversationId => throw _privateConstructorUsedError;
  List<String> get participants => throw _privateConstructorUsedError;
  String? get lastMessage => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  Map<String, int> get unreadCount => throw _privateConstructorUsedError;

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationCopyWith<Conversation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationCopyWith<$Res> {
  factory $ConversationCopyWith(
          Conversation value, $Res Function(Conversation) then) =
      _$ConversationCopyWithImpl<$Res, Conversation>;
  @useResult
  $Res call(
      {String conversationId,
      List<String> participants,
      String? lastMessage,
      @TimestampConverter() DateTime? lastMessageAt,
      Map<String, int> unreadCount});
}

/// @nodoc
class _$ConversationCopyWithImpl<$Res, $Val extends Conversation>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? conversationId = null,
    Object? participants = null,
    Object? lastMessage = freezed,
    Object? lastMessageAt = freezed,
    Object? unreadCount = null,
  }) {
    return _then(_value.copyWith(
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      participants: null == participants
          ? _value.participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConversationImplCopyWith<$Res>
    implements $ConversationCopyWith<$Res> {
  factory _$$ConversationImplCopyWith(
          _$ConversationImpl value, $Res Function(_$ConversationImpl) then) =
      __$$ConversationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String conversationId,
      List<String> participants,
      String? lastMessage,
      @TimestampConverter() DateTime? lastMessageAt,
      Map<String, int> unreadCount});
}

/// @nodoc
class __$$ConversationImplCopyWithImpl<$Res>
    extends _$ConversationCopyWithImpl<$Res, _$ConversationImpl>
    implements _$$ConversationImplCopyWith<$Res> {
  __$$ConversationImplCopyWithImpl(
      _$ConversationImpl _value, $Res Function(_$ConversationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? conversationId = null,
    Object? participants = null,
    Object? lastMessage = freezed,
    Object? lastMessageAt = freezed,
    Object? unreadCount = null,
  }) {
    return _then(_$ConversationImpl(
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      participants: null == participants
          ? _value._participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      unreadCount: null == unreadCount
          ? _value._unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationImpl implements _Conversation {
  const _$ConversationImpl(
      {required this.conversationId,
      required final List<String> participants,
      this.lastMessage,
      @TimestampConverter() this.lastMessageAt,
      final Map<String, int> unreadCount = const {}})
      : _participants = participants,
        _unreadCount = unreadCount;

  factory _$ConversationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationImplFromJson(json);

  @override
  final String conversationId;
  final List<String> _participants;
  @override
  List<String> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  @override
  final String? lastMessage;
  @override
  @TimestampConverter()
  final DateTime? lastMessageAt;
  final Map<String, int> _unreadCount;
  @override
  @JsonKey()
  Map<String, int> get unreadCount {
    if (_unreadCount is EqualUnmodifiableMapView) return _unreadCount;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_unreadCount);
  }

  @override
  String toString() {
    return 'Conversation(conversationId: $conversationId, participants: $participants, lastMessage: $lastMessage, lastMessageAt: $lastMessageAt, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationImpl &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            const DeepCollectionEquality()
                .equals(other._participants, _participants) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            const DeepCollectionEquality()
                .equals(other._unreadCount, _unreadCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      conversationId,
      const DeepCollectionEquality().hash(_participants),
      lastMessage,
      lastMessageAt,
      const DeepCollectionEquality().hash(_unreadCount));

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      __$$ConversationImplCopyWithImpl<_$ConversationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationImplToJson(
      this,
    );
  }
}

abstract class _Conversation implements Conversation {
  const factory _Conversation(
      {required final String conversationId,
      required final List<String> participants,
      final String? lastMessage,
      @TimestampConverter() final DateTime? lastMessageAt,
      final Map<String, int> unreadCount}) = _$ConversationImpl;

  factory _Conversation.fromJson(Map<String, dynamic> json) =
      _$ConversationImpl.fromJson;

  @override
  String get conversationId;
  @override
  List<String> get participants;
  @override
  String? get lastMessage;
  @override
  @TimestampConverter()
  DateTime? get lastMessageAt;
  @override
  Map<String, int> get unreadCount;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
