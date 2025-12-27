import 'package:flutter_test/flutter_test.dart';
import 'package:kattrick/features/gamification/infrastructure/services/gamification_service.dart';
import 'package:kattrick/models/models.dart';

void main() {
  group('GamificationService', () {
    // NOTE: calculateGamePoints, calculateLevel, and pointsForNextLevel
    // are now handled by Cloud Functions, not by the client
    // These tests are removed as those methods no longer exist in GamificationService

    test('checkMilestoneBadges should award first game badge', () {
      final badges = GamificationService.checkMilestoneBadges(1, []);
      expect(badges.contains(BadgeType.firstGame.name), true);
    });

    test('checkMilestoneBadges should award ten games badge', () {
      final badges = GamificationService.checkMilestoneBadges(
          10, [BadgeType.firstGame.name]);
      expect(badges.contains(BadgeType.tenGames.name), true);
    });

    test('checkMilestoneBadges should award fifty games badge', () {
      final badges = GamificationService.checkMilestoneBadges(50, [
        BadgeType.firstGame.name,
        BadgeType.tenGames.name,
      ]);
      expect(badges.contains(BadgeType.fiftyGames.name), true);
    });

    test('checkMilestoneBadges should award hundred games badge', () {
      final badges = GamificationService.checkMilestoneBadges(100, [
        BadgeType.firstGame.name,
        BadgeType.tenGames.name,
        BadgeType.fiftyGames.name,
      ]);
      expect(badges.contains(BadgeType.hundredGames.name), true);
    });

    test('checkMilestoneBadges should not award already earned badges', () {
      final badges = GamificationService.checkMilestoneBadges(100, [
        BadgeType.firstGame.name,
        BadgeType.tenGames.name,
        BadgeType.fiftyGames.name,
        BadgeType.hundredGames.name,
      ]);
      expect(badges.isEmpty, true);
    });
  });
}
