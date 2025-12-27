import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/shared/infrastructure/firestore/converters/timestamp_firestore_converter.dart';

part 'private_message.freezed.dart';
part 'private_message.g.dart';

/// Private message model matching Firestore schema: /private_messages/{conversationId}/messages/{messageId}
@freezed
class PrivateMessage with _$PrivateMessage {
  const factory PrivateMessage({
    required String messageId,
    required String conversationId,
    required String senderId, // Note: Firestore uses 'senderId', not 'authorId'
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
    required List<String> participantIds, // Note: Firestore uses 'participantIds', not 'participants'
    String? lastMessage,
    @TimestampConverter() DateTime? lastMessageAt,
    @Default({}) Map<String, int> unreadCount,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
}

