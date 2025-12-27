// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationPreferencesImpl _$$NotificationPreferencesImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationPreferencesImpl(
      gameReminder: json['gameReminder'] as bool? ?? true,
      message: json['message'] as bool? ?? true,
      like: json['like'] as bool? ?? true,
      comment: json['comment'] as bool? ?? true,
      signup: json['signup'] as bool? ?? true,
      newFollower: json['newFollower'] as bool? ?? true,
      hubChat: json['hubChat'] as bool? ?? true,
      newComment: json['newComment'] as bool? ?? true,
      newGame: json['newGame'] as bool? ?? true,
    );

Map<String, dynamic> _$$NotificationPreferencesImplToJson(
        _$NotificationPreferencesImpl instance) =>
    <String, dynamic>{
      'gameReminder': instance.gameReminder,
      'message': instance.message,
      'like': instance.like,
      'comment': instance.comment,
      'signup': instance.signup,
      'newFollower': instance.newFollower,
      'hubChat': instance.hubChat,
      'newComment': instance.newComment,
      'newGame': instance.newGame,
    };
