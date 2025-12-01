import 'package:flutter_test/flutter_test.dart';
import 'package:kattrick/logic/team_maker.dart';
import 'package:kattrick/models/models.dart';

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

      final result = TeamMaker.createBalancedTeams(players, teamCount: 2);
      final teams = result.teams;

      expect(teams.length, 2);
      expect(teams[0].playerIds.length, 4);
      expect(teams[1].playerIds.length, 4);

      // Check balance
      final scoreDiff = (teams[0].totalScore - teams[1].totalScore).abs();
      expect(scoreDiff, lessThan(2.0)); // Should be relatively balanced
    });

    test('should handle odd number of players', () {
      final players = List.generate(
        13,
        (i) => PlayerForTeam(
          uid: 'p${i + 1}',
          rating: 5.0 + i * 0.5,
          role: PlayerRole.midfielder,
        ),
      );

      final result = TeamMaker.createBalancedTeams(players, teamCount: 2);
      final teams = result.teams;

      expect(teams.length, 2);
      // One team should have 7, the other 6
      final lengths = teams.map((t) => t.playerIds.length).toList();
      lengths.sort();
      expect(lengths, [6, 7]);
    });

    test('should handle players with identical ratings', () {
      final players = List.generate(
        10,
        (i) => PlayerForTeam(
          uid: 'p${i + 1}',
          rating: 5.0, // All same rating
          role: PlayerRole.midfielder,
        ),
      );

      final result = TeamMaker.createBalancedTeams(players, teamCount: 2);
      final teams = result.teams;

      expect(teams.length, 2);
      expect(teams[0].playerIds.length, 5);
      expect(teams[1].playerIds.length, 5);
      expect(teams[0].totalScore, teams[1].totalScore);
    });

    test('should distribute goalkeepers evenly', () {
      final players = [
        PlayerForTeam(uid: 'gk1', rating: 8.0, role: PlayerRole.goalkeeper),
        PlayerForTeam(uid: 'gk2', rating: 7.0, role: PlayerRole.goalkeeper),
        PlayerForTeam(uid: 'p1', rating: 6.0, role: PlayerRole.midfielder),
        PlayerForTeam(uid: 'p2', rating: 6.0, role: PlayerRole.midfielder),
      ];

      final result = TeamMaker.createBalancedTeams(players, teamCount: 2);
      final teams = result.teams;

      // Check that each team has exactly one goalkeeper
      final team1Gk = teams[0].playerIds.contains('gk1') ||
          teams[0].playerIds.contains('gk2');
      final team2Gk = teams[1].playerIds.contains('gk1') ||
          teams[1].playerIds.contains('gk2');

      expect(team1Gk, true);
      expect(team2Gk, true);
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

    test('should calculate balance metrics correctly', () {
      final teams = [
        Team(
          teamId: 't1',
          name: 'Team A',
          playerIds: ['p1', 'p2'],
          totalScore: 10.0,
        ),
        Team(
          teamId: 't2',
          name: 'Team B',
          playerIds: ['p3', 'p4'],
          totalScore: 12.0,
        ),
      ];

      final metrics = TeamMaker.calculateBalanceMetrics(teams);

      expect(metrics.averageRating, 5.5); // (5.0 + 6.0) / 2
      expect(metrics.minRating, 5.0);
      expect(metrics.maxRating, 6.0);
    });

    test('should suggest optimization swaps', () {
      final players = [
        PlayerForTeam(uid: 'p1', rating: 10.0, role: PlayerRole.midfielder),
        PlayerForTeam(uid: 'p2', rating: 2.0, role: PlayerRole.midfielder),
        PlayerForTeam(uid: 'p3', rating: 6.0, role: PlayerRole.midfielder),
        PlayerForTeam(uid: 'p4', rating: 6.0, role: PlayerRole.midfielder),
      ];

      // Create unbalanced teams manually
      // Team A: 10, 6 -> 16 (avg 8)
      // Team B: 2, 6 -> 8 (avg 4)
      final unbalancedTeams = [
        Team(
          teamId: 't1',
          name: 'Team A',
          playerIds: ['p1', 'p3'],
          totalScore: 16.0,
        ),
        Team(
          teamId: 't2',
          name: 'Team B',
          playerIds: ['p2', 'p4'],
          totalScore: 8.0,
        ),
      ];

      final suggestions =
          TeamMaker.getOptimizationSuggestions(unbalancedTeams, players);

      // Should suggest swapping p1 (10) with p4 (6) or p2 (2) to balance?
      // Swapping p1 (10) <-> p4 (6):
      // A: 6, 6 -> 12
      // B: 2, 10 -> 12
      // Perfect balance!

      expect(suggestions.isNotEmpty, true);
      final swap = suggestions.first;
      // Either p1<->p4 or p1<->p2 (if p2 is 6? no p2 is 2).
      // p3 is 6.
      // p1(10) <-> p4(6) => A(6,6)=12, B(2,10)=12. Perfect.
      // p1(10) <-> p2(2) => A(2,6)=8, B(10,6)=16. Flip. Same imbalance.
      // p3(6) <-> p4(6) => No change.
      // p3(6) <-> p2(2) => A(10,2)=12, B(6,6)=12. Perfect.

      // So valid swaps are (p1, p4) or (p3, p2).

      final isP1Swap = (swap.playerAId == 'p1' && swap.playerBId == 'p4') ||
          (swap.playerAId == 'p4' && swap.playerBId == 'p1');
      final isP3Swap = (swap.playerAId == 'p3' && swap.playerBId == 'p2') ||
          (swap.playerAId == 'p2' && swap.playerBId == 'p3');

      expect(isP1Swap || isP3Swap, true);
    });
  });

  group('PlayerRole', () {
    test('should parse positions correctly', () {
      expect(PlayerRole.fromPosition('GK'), PlayerRole.goalkeeper);
      expect(PlayerRole.fromPosition('CB'), PlayerRole.defender); // 'back'
      expect(PlayerRole.fromPosition('CM'), PlayerRole.midfielder);
      expect(PlayerRole.fromPosition('ST'), PlayerRole.attacker); // 'striker'
    });
  });
}
