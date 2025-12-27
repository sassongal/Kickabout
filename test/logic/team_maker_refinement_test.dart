import 'package:kattrick/features/games/domain/models/team_maker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeamMaker Balancing', () {
    test('Strict player count balance with multiple roles', () {
      final players = [
        // 2 Goalkeepers
        PlayerForTeam(uid: 'gk1', rating: 5.0, role: PlayerRole.goalkeeper),
        PlayerForTeam(uid: 'gk2', rating: 4.0, role: PlayerRole.goalkeeper),
        // 3 Defenders
        PlayerForTeam(uid: 'def1', rating: 5.0, role: PlayerRole.defender),
        PlayerForTeam(uid: 'def2', rating: 4.0, role: PlayerRole.defender),
        PlayerForTeam(uid: 'def3', rating: 3.0, role: PlayerRole.defender),
        // 6 Midfielders
        ...List.generate(
            6,
            (i) => PlayerForTeam(
                uid: 'mid$i', rating: 4.0, role: PlayerRole.midfielder)),
      ];

      // Total 11 players for 2 teams. One team should have 6, one should have 5.
      final result = TeamMaker.createBalancedTeams(players, teamCount: 2);

      expect(result.teams[0].playerIds.length, anyOf(5, 6));
      expect(result.teams[1].playerIds.length, anyOf(5, 6));
      expect(
          (result.teams[0].playerIds.length - result.teams[1].playerIds.length)
              .abs(),
          lessThanOrEqualTo(1));
    });

    test('Randomization with same input', () {
      final players = List.generate(
          20,
          (i) => PlayerForTeam(
              uid: 'p$i', rating: (i % 5) + 2.0, role: PlayerRole.midfielder));

      final result1 =
          TeamMaker.createBalancedTeams(players, teamCount: 4, seed: 123);
      final result2 =
          TeamMaker.createBalancedTeams(players, teamCount: 4, seed: 123);
      final result3 =
          TeamMaker.createBalancedTeams(players, teamCount: 4, seed: 456);

      // Same seed should produce same results
      expect(result1.teams[0].playerIds, equals(result2.teams[0].playerIds));

      // Different seed should (likely) produce different results
      bool identical = true;
      for (int i = 0; i < 4; i++) {
        if (result1.teams[i].playerIds.join() !=
            result3.teams[i].playerIds.join()) {
          identical = false;
          break;
        }
      }
      expect(identical, isFalse,
          reason: 'Different seeds should produce different team compositions');
    });
  });
}
