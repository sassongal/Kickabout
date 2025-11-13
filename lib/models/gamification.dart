import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';

part 'gamification.freezed.dart';
part 'gamification.g.dart';

/// Gamification model matching Firestore schema: /users/{uid}/gamification/stats
@freezed
class Gamification with _$Gamification {
  const factory Gamification({
    required String userId,
    @Default(0) int points,
    @Default(1) int level,
    @Default([]) List<String> badges,
    @Default({}) Map<String, dynamic> achievements,
    @Default({
      'gamesPlayed': 0,
      'gamesWon': 0,
      'goals': 0,
      'assists': 0,
      'saves': 0,
    }) Map<String, int> stats,
    @TimestampConverter() DateTime? updatedAt,
  }) = _Gamification;

  factory Gamification.fromJson(Map<String, dynamic> json) => _$GamificationFromJson(json);
}

/// Badge types enum
enum BadgeType {
  firstGame,
  tenGames,
  fiftyGames,
  hundredGames,
  firstGoal,
  hatTrick,
  mvp,
  leader,
  consistent,
  social,
}

extension BadgeTypeExtension on BadgeType {
  String get name {
    switch (this) {
      case BadgeType.firstGame:
        return 'first_game';
      case BadgeType.tenGames:
        return 'ten_games';
      case BadgeType.fiftyGames:
        return 'fifty_games';
      case BadgeType.hundredGames:
        return 'hundred_games';
      case BadgeType.firstGoal:
        return 'first_goal';
      case BadgeType.hatTrick:
        return 'hat_trick';
      case BadgeType.mvp:
        return 'mvp';
      case BadgeType.leader:
        return 'leader';
      case BadgeType.consistent:
        return 'consistent';
      case BadgeType.social:
        return 'social';
    }
  }

  String get displayName {
    switch (this) {
      case BadgeType.firstGame:
        return 'משחק ראשון';
      case BadgeType.tenGames:
        return '10 משחקים';
      case BadgeType.fiftyGames:
        return '50 משחקים';
      case BadgeType.hundredGames:
        return '100 משחקים';
      case BadgeType.firstGoal:
        return 'שער ראשון';
      case BadgeType.hatTrick:
        return 'שלושער';
      case BadgeType.mvp:
        return 'MVP';
      case BadgeType.leader:
        return 'מנהיג';
      case BadgeType.consistent:
        return 'עקבי';
      case BadgeType.social:
        return 'חברתי';
    }
  }
}

