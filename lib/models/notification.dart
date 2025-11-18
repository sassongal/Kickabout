import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// Notification model matching Firestore schema: /notifications/{uid}/items/{notifId}
@freezed
class Notification with _$Notification {
  const factory Notification({
    required String notificationId,
    required String userId,
    required String type, // 'game_reminder' | 'message' | 'like' | 'comment' | 'signup' | 'new_follower' | 'hub_chat' | 'new_comment' | 'new_game'
    required String title,
    required String body,
    Map<String, dynamic>? data,
    @Default(false) bool read,
    @TimestampConverter() required DateTime createdAt,
    String? entityId, // ID of related entity (gameId, hubId, etc.)
    String? hubId, // Hub ID if notification is hub-related
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
}

