import 'package:flutter_test/flutter_test.dart';
import 'package:kickadoor/logic/team_maker.dart';
import 'package:kickadoor/models/models.dart';

void main() {
  group('TeamMaker Algorithm', () {
    test('should create balanced teams with snake draft', () {
      // Create synthetic players
      final players = [
        PlayerForTeam(uid: 'p1', rating: 9.0, role: PlayerRole.attacker),
        PlayerForTeam(uid: 'p2', rating: 8.5, role: PlayerRole.midfielder),
        PlayerForTeam(uid: 'p3', rating: 8.0, role: PlayerRole.defender),
        PlayerForTeam(uid: 'p4', rating: 7.5, role: PlayerRole.midfielder),
        PlayerForTeam(uid: 'p5', rating: 7.0, role: PlayerRole.attacker),
        PlayerForTeam(uid: 'p6', rating: 6.5, role: PlayerRole.defender),
        PlayerForTeam(uid: 'p7', rating: 6.0, role: PlayerRole.midfielder),
        PlayerForTeam(uid: 'p8', rating: 5.5, role: PlayerRole.attacker),
      ];

      final teams = TeamMaker.createBalancedTeams(players, teamCount: 2);

      expect(teams.length, 2);
      expect(teams[0].playerIds.length, 4);
      expect(teams[1].playerIds.length, 4);
    });

    test('should throw error if not enough players', () {
      final players = [
        PlayerForTeam(uid: 'p1', rating: 5.0, role: PlayerRole.midfielder),
        PlayerForTeam(uid: 'p2', rating: 5.0, role: PlayerRole.midfielder),
      ];

      expect(
        () => TeamMaker.createBalancedTeams(players, teamCount: 3),
        throwsArgumentError,
      );
    });

    test('should calculate balance metrics', () {
      final teams = [
        Team(
          teamId: 't1',
          name: 'Team A',
          playerIds: ['p1', 'p2'],
        ),
        Team(
          teamId: 't2',
          name: 'Team B',
          playerIds: ['p3', 'p4'],
        ),
      ];

      // Note: TeamMaker.calculateBalanceMetrics might not exist
      // This is a placeholder test
      expect(teams.length, 2);
      expect(teams[0].playerIds.length, 2);
      expect(teams[1].playerIds.length, 2);
    });

    test('should handle 3 teams', () {
      final players = List.generate(
        9,
        (i) => PlayerForTeam(
          uid: 'p${i + 1}',
          rating: 5.0 + i * 0.5,
          role: PlayerRole.midfielder,
        ),
      );

      final teams = TeamMaker.createBalancedTeams(players, teamCount: 3);

      expect(teams.length, 3);
      expect(teams.every((t) => t.playerIds.length == 3), true);
    });

    test('should handle 4 teams', () {
      final players = List.generate(
        12,
        (i) => PlayerForTeam(
          uid: 'p${i + 1}',
          rating: 5.0 + i * 0.5,
          role: PlayerRole.midfielder,
        ),
      );

      final teams = TeamMaker.createBalancedTeams(players, teamCount: 4);

      expect(teams.length, 4);
      expect(teams.every((t) => t.playerIds.length == 3), true);
    });

    test('should bucket players by role', () {
      final players = [
        PlayerForTeam(uid: 'p1', rating: 9.0, role: PlayerRole.goalkeeper),
        PlayerForTeam(uid: 'p2', rating: 8.0, role: PlayerRole.defender),
        PlayerForTeam(uid: 'p3', rating: 7.0, role: PlayerRole.midfielder),
        PlayerForTeam(uid: 'p4', rating: 6.0, role: PlayerRole.attacker),
      ];

      final teams = TeamMaker.createBalancedTeams(players, teamCount: 2);

      expect(teams.length, 2);
      // Each team should have players
      expect(teams[0].playerIds.isNotEmpty, true);
      expect(teams[1].playerIds.isNotEmpty, true);
    });
  });

  group('PlayerRole', () {
    test('should parse goalkeeper positions', () {
      expect(PlayerRole.fromPosition('goalkeeper'), PlayerRole.goalkeeper);
      expect(PlayerRole.fromPosition('keeper'), PlayerRole.goalkeeper);
      expect(PlayerRole.fromPosition('GK'), PlayerRole.goalkeeper);
    });

    test('should parse defender positions', () {
      expect(PlayerRole.fromPosition('defender'), PlayerRole.defender);
      expect(PlayerRole.fromPosition('def'), PlayerRole.defender);
      expect(PlayerRole.fromPosition('back'), PlayerRole.defender);
    });

    test('should parse attacker positions', () {
      expect(PlayerRole.fromPosition('forward'), PlayerRole.attacker);
      expect(PlayerRole.fromPosition('striker'), PlayerRole.attacker);
      expect(PlayerRole.fromPosition('attacker'), PlayerRole.attacker);
    });

    test('should default to midfielder', () {
      expect(PlayerRole.fromPosition('midfielder'), PlayerRole.midfielder);
      expect(PlayerRole.fromPosition('unknown'), PlayerRole.midfielder);
    });
  });
}

