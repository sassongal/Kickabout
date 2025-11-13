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
    required String type, // 'game' | 'message' | 'like' | 'comment' | 'signup'
    required String title,
    required String body,
    Map<String, dynamic>? data,
    @Default(false) bool read,
    @TimestampConverter() required DateTime createdAt,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
}

