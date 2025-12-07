import 'package:flutter_test/flutter_test.dart';
import 'package:kattrick/models/models.dart';

void main() {
  group('Game Model Migration Tests', () {
    test('should successfully parse legacy flat structure', () {
      // Arrange: Legacy flat structure from Firestore
      final legacyJson = {
        'gameId': 'game123',
        'createdBy': 'user123',
        'gameDate': DateTime(2024, 1, 1).toIso8601String(),
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2024, 1, 1).toIso8601String(),
        // Legacy flat fields that should be migrated to denormalized
        'createdByName': 'John Doe',
        'hubName': 'Test Hub',
        'venueName': 'Test Venue',
        'confirmedPlayerCount': 10,
        'isFull': false,
        // Legacy flat fields that should be migrated to session
        'matches': [
          {
            'matchId': 'match1',
            'teamAColor': 'Blue',
            'teamBColor': 'Red',
            'scoreA': 3,
            'scoreB': 2,
            'createdAt': DateTime(2024, 1, 1).toIso8601String(),
          }
        ],
        'teamAScore': 3,
        'teamBScore': 2,
        // Legacy flat fields that should be migrated to audit
        'auditLog': [
          {
            'action': 'GAME_CREATED',
            'userId': 'user123',
            'timestamp': DateTime(2024, 1, 1).toIso8601String(),
          }
        ],
      };

      // Act
      final game = Game.fromJson(legacyJson);

      // Assert
      expect(game.gameId, 'game123');
      expect(game.createdBy, 'user123');

      // Verify denormalized data migration
      expect(game.denormalized.createdByName, 'John Doe');
      expect(game.denormalized.hubName, 'Test Hub');
      expect(game.denormalized.venueName, 'Test Venue');
      expect(game.denormalized.confirmedPlayerCount, 10);
      expect(game.denormalized.isFull, false);

      // Verify session data migration
      expect(game.session.matches.length, 1);
      expect(game.session.legacyTeamAScore, 3);
      expect(game.session.legacyTeamBScore, 2);

      // Verify audit data migration
      expect(game.audit.auditLog.length, 1);
    });

    test('should successfully parse new nested structure', () {
      // Arrange: New nested structure
      final nestedJson = {
        'gameId': 'game456',
        'createdBy': 'user456',
        'gameDate': DateTime(2024, 1, 1).toIso8601String(),
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2024, 1, 1).toIso8601String(),
        'denormalized': {
          'createdByName': 'Jane Smith',
          'hubName': 'New Hub',
        },
        'session': {
          'matches': [],
        },
        'audit': {
          'auditLog': [],
        },
      };

      // Act
      final game = Game.fromJson(nestedJson);

      // Assert
      expect(game.gameId, 'game456');
      expect(game.denormalized.createdByName, 'Jane Smith');
      expect(game.denormalized.hubName, 'New Hub');
      expect(game.session.matches.length, 0);
      expect(game.audit.auditLog.length, 0);
    });

    test('should have nested structure in model', () {
      // Arrange
      final game = Game(
        gameId: 'game789',
        createdBy: 'user789',
        gameDate: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        denormalized: const GameDenormalizedData(
          createdByName: 'Test User',
          hubName: 'Test Hub',
        ),
        session: const GameSession(matches: []),
        audit: const GameAudit(auditLog: []),
      );

      // Assert - verify the nested structure exists in the model
      expect(game.gameId, 'game789');
      expect(game.denormalized.createdByName, 'Test User');
      expect(game.denormalized.hubName, 'Test Hub');
      expect(game.session.matches, isEmpty);
      expect(game.audit.auditLog, isEmpty);
    });

    test('should handle empty legacy data gracefully', () {
      // Arrange: Minimal legacy structure
      final minimalJson = {
        'gameId': 'game000',
        'createdBy': 'user000',
        'gameDate': DateTime(2024, 1, 1).toIso8601String(),
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2024, 1, 1).toIso8601String(),
      };

      // Act
      final game = Game.fromJson(minimalJson);

      // Assert
      expect(game.gameId, 'game000');
      expect(game.denormalized.createdByName, isNull);
      expect(game.session.matches, isEmpty);
      expect(game.audit.auditLog, isEmpty);
    });
  });
}
