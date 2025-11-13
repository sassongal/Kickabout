import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';

part 'private_message.freezed.dart';
part 'private_message.g.dart';

/// Private message model
@freezed
class PrivateMessage with _$PrivateMessage {
  const factory PrivateMessage({
    required String messageId,
    required String conversationId,
    required String authorId,
    required String text,
    @Default(false) bool read,
    @TimestampConverter() required DateTime createdAt,
  }) = _PrivateMessage;

  factory PrivateMessage.fromJson(Map<String, dynamic> json) => _$PrivateMessageFromJson(json);
}

/// Conversation model
@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String conversationId,
    required List<String> participants,
    String? lastMessage,
    @TimestampConverter() DateTime? lastMessageAt,
    @Default({}) Map<String, int> unreadCount,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
}

