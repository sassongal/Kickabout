import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// Chat message model matching Firestore schema: /hubs/{hubId}/chat/messages/{messageId}
/// Denormalized fields: senderId, senderName, senderPhotoUrl for efficient display
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String messageId,
    required String hubId,
    required String authorId,
    required String text,
    @Default([]) List<String> readBy,
    @TimestampConverter() required DateTime createdAt,
    // Denormalized fields for efficient display (no need to fetch user)
    String? senderId, // Alias for authorId (used by Functions)
    String? senderName, // Denormalized from users/{authorId}.name
    String? senderPhotoUrl, // Denormalized from users/{authorId}.photoUrl
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

