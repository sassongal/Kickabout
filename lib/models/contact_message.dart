import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';

part 'contact_message.freezed.dart';
part 'contact_message.g.dart';

/// Contact message sent from a player to Hub Manager via recruiting post
/// Stored in: /hubs/{hubId}/contactMessages/{messageId}
@freezed
class ContactMessage with _$ContactMessage {
  const factory ContactMessage({
    required String messageId,
    required String hubId,
    required String senderId,
    required String postId, // Link to recruiting post
    required String message, // Player's message
    @Default('pending') String status, // 'pending' | 'read' | 'replied'
    @TimestampConverter() required DateTime createdAt,
    // Denormalized for display
    String? senderName,
    String? senderPhotoUrl,
    String? senderPhone,
    String? postContent, // Brief excerpt of the recruiting post
  }) = _ContactMessage;

  factory ContactMessage.fromJson(Map<String, dynamic> json) =>
      _$ContactMessageFromJson(json);
}
