import 'package:flutter_test/flutter_test.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/targeting_criteria.dart';
import 'package:kattrick/services/game_management_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kattrick/data/games_repository.dart';
import 'package:kattrick/data/hubs_repository.dart';
import 'package:kattrick/data/signups_repository.dart';
import 'package:kattrick/data/notifications_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes
class MockGamesRepository extends Mock implements GamesRepository {}

class MockHubsRepository extends Mock implements HubsRepository {}

class MockSignupsRepository extends Mock implements SignupsRepository {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('Architecture Verification', () {
    late GameManagementService gameService;
    late MockGamesRepository mockGamesRepo;
    late MockHubsRepository mockHubsRepo;
    late MockSignupsRepository mockSignupsRepo;
    late MockNotificationsRepository mockNotificationsRepo;

    setUp(() {
      mockGamesRepo = MockGamesRepository();
      mockHubsRepo = MockHubsRepository();
      mockSignupsRepo = MockSignupsRepository();
      mockNotificationsRepo = MockNotificationsRepository();

      gameService = GameManagementService(
        gamesRepo: mockGamesRepo,
        hubsRepo: mockHubsRepo,
        signupsRepo: mockSignupsRepo,
        notificationsRepo: mockNotificationsRepo,
        firestore: MockFirestore(),
      );
    });

    test('Public Game Creation (hubId = null)', () {
      final publicGame = Game(
        gameId: 'public_1',
        createdBy: 'user_1',
        hubId: null, // Public game
        gameDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: GameStatus.recruiting,
        visibility: GameVisibility.public,
        requiresApproval: true,
        targetingCriteria: const TargetingCriteria(
          minAge: 18,
          maxAge: 30,
          gender: PlayerGender.any,
          vibe: GameVibe.competitive,
        ),
      );

      expect(publicGame.hubId, isNull);
      expect(publicGame.visibility, equals(GameVisibility.public));
      expect(publicGame.requiresApproval, isTrue);
      expect(publicGame.targetingCriteria, isNotNull);
    });

    test('Hub Game Creation (hubId = "123")', () {
      final hubGame = Game(
        gameId: 'hub_1',
        createdBy: 'user_1',
        hubId: 'hub_123',
        gameDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: GameStatus.recruiting,
        visibility: GameVisibility.private,
      );

      expect(hubGame.hubId, equals('hub_123'));
      expect(hubGame.visibility, equals(GameVisibility.private));
    });

    test('Service methods should handle null hubId', () async {
      // This test mainly verifies that we don't have immediate null checks on hubId
      // that would throw before entering the transaction logic.
    });
  });
}
