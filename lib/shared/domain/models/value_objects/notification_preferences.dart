import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';
part 'notification_preferences.g.dart';

/// Notification preferences value object
///
/// Extracted from User model to follow Single Responsibility Principle.
/// Encapsulates all notification-related preferences in one cohesive object.
@freezed
class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    @Default(true) bool gameReminder,
    @Default(true) bool message,
    @Default(true) bool like,
    @Default(true) bool comment,
    @Default(true) bool signup,
    @Default(true) bool newFollower,
    @Default(true) bool hubChat,
    @Default(true) bool newComment,
    @Default(true) bool newGame,
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  /// Create from legacy Map<String, bool> format for backward compatibility
  factory NotificationPreferences.fromLegacyMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();

    return NotificationPreferences(
      gameReminder: map['game_reminder'] as bool? ?? true,
      message: map['message'] as bool? ?? true,
      like: map['like'] as bool? ?? true,
      comment: map['comment'] as bool? ?? true,
      signup: map['signup'] as bool? ?? true,
      newFollower: map['new_follower'] as bool? ?? true,
      hubChat: map['hub_chat'] as bool? ?? true,
      newComment: map['new_comment'] as bool? ?? true,
      newGame: map['new_game'] as bool? ?? true,
    );
  }
}
