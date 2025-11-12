import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickabout/models/converters/timestamp_converter.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// Chat message model matching Firestore schema: /hubs/{hubId}/chat/{messageId}
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String messageId,
    required String hubId,
    required String authorId,
    required String text,
    @Default([]) List<String> readBy,
    @TimestampConverter() required DateTime createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

