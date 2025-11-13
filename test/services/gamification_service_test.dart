import 'package:flutter_test/flutter_test.dart';
import 'package:kickadoor/services/gamification_service.dart';

void main() {
  group('GamificationService', () {
    test('calculateGamePoints should return correct points', () {
      // Base participation: 10 points
      // Win bonus: 20 points
      // Goals: 2 * 5 = 10 points
      // Assists: 1 * 3 = 3 points
      // Saves: 0 * 2 = 0 points
      // MVP bonus: 15 points
      // Rating bonus (8.0+): 10 points
      // Total: 10 + 20 + 10 + 3 + 0 + 15 + 10 = 68 points
      
      final points = GamificationService.calculateGamePoints(
        won: true,
        goals: 2,
        assists: 1,
        saves: 0,
        isMVP: true,
        averageRating: 8.5,
      );

      expect(points, 68);
    });

    test('calculateGamePoints should not include win bonus if lost', () {
      final points = GamificationService.calculateGamePoints(
        won: false,
        goals: 1,
        assists: 0,
        saves: 0,
        isMVP: false,
        averageRating: 7.0,
      );

      // Base: 10, Goal: 5, Total: 15
      expect(points, 15);
    });

    test('calculateLevel should return correct level', () {
      expect(GamificationService.calculateLevel(0), 1);
      expect(GamificationService.calculateLevel(100), 2);
      expect(GamificationService.calculateLevel(400), 3);
      expect(GamificationService.calculateLevel(900), 4);
    });

    test('pointsForNextLevel should return correct points', () {
      expect(GamificationService.pointsForNextLevel(1), 100);
      expect(GamificationService.pointsForNextLevel(2), 400);
      expect(GamificationService.pointsForNextLevel(3), 900);
    });
  });
}

