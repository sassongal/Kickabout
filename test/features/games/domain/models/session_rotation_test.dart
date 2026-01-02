import 'package:flutter_test/flutter_test.dart';
import 'package:kattrick/features/games/domain/models/rotation_state.dart';
import 'package:kattrick/features/games/domain/models/session_rotation.dart';
import 'package:kattrick/shared/domain/models/match_result.dart';
import 'package:kattrick/shared/domain/models/team.dart';

void main() {
  group('SessionRotationLogic - Streak Breaker', () {
    late List<Team> testTeams;

    setUp(() {
      // Create 3 test teams for Winner Stays format
      testTeams = [
        Team(
          teamId: 'team_red',
          name: 'Red',
          color: 'Red',
          playerIds: ['p1', 'p2', 'p3'],
          totalScore: 18.0,
        ),
        Team(
          teamId: 'team_blue',
          name: 'Blue',
          color: 'Blue',
          playerIds: ['p4', 'p5', 'p6'],
          totalScore: 18.0,
        ),
        Team(
          teamId: 'team_yellow',
          name: 'Yellow',
          color: 'Yellow',
          playerIds: ['p7', 'p8', 'p9'],
          totalScore: 18.0,
        ),
      ];
    });

    test('Initial state has no win streaks', () {
      final initialState = SessionRotationLogic.createInitialState(testTeams);

      expect(initialState.teamWinStreaks, isEmpty);
      expect(initialState.teamAColor, 'Red');
      expect(initialState.teamBColor, 'Blue');
      expect(initialState.waitingTeamColors, ['Yellow']);
    });

    test('Team wins once - streak counter increments to 1', () {
      final initialState = SessionRotationLogic.createInitialState(testTeams);

      // Red beats Blue 5-3
      final match = MatchResult(
        matchId: 'match_1',
        teamAColor: 'Red',
        teamBColor: 'Blue',
        scoreA: 5,
        scoreB: 3,
        createdAt: DateTime.now(),
        approvalStatus: MatchApprovalStatus.approved,
        scorerIds: const [],
        assistIds: const [],
      );

      final nextState = SessionRotationLogic.calculateNextRotation(
        current: initialState,
        completedMatch: match,
      );

      // Red should stay (winner stays on)
      expect(nextState.teamAColor, 'Red');
      // Yellow should enter (next in queue)
      expect(nextState.teamBColor, 'Yellow');
      // Blue should go to waiting queue
      expect(nextState.waitingTeamColors, ['Blue']);
      // Red should have streak = 1
      expect(nextState.teamWinStreaks['Red'], 1);
      // Blue should have streak = 0 (reset)
      expect(nextState.teamWinStreaks['Blue'], 0);
      // Yellow should have streak = 0 (entering fresh)
      expect(nextState.teamWinStreaks['Yellow'], 0);
    });

    test('Team wins twice - no streak breaker yet', () {
      // Simulate Red winning twice in a row
      var currentState = SessionRotationLogic.createInitialState(testTeams);

      // Match 1: Red beats Blue 5-3 (Red streak = 1)
      currentState = SessionRotationLogic.calculateNextRotation(
        current: currentState,
        completedMatch: MatchResult(
          matchId: 'match_1',
          teamAColor: 'Red',
          teamBColor: 'Blue',
          scoreA: 5,
          scoreB: 3,
          createdAt: DateTime.now(),
          approvalStatus: MatchApprovalStatus.approved,
          scorerIds: const [],
          assistIds: const [],
        ),
      );

      // Match 2: Red beats Yellow 4-2 (Red streak = 2)
      currentState = SessionRotationLogic.calculateNextRotation(
        current: currentState,
        completedMatch: MatchResult(
          matchId: 'match_2',
          teamAColor: 'Red',
          teamBColor: 'Yellow',
          scoreA: 4,
          scoreB: 2,
          createdAt: DateTime.now(),
          approvalStatus: MatchApprovalStatus.approved,
          scorerIds: const [],
          assistIds: const [],
        ),
      );

      // Red should still be playing (no streak breaker at 2 wins)
      expect(currentState.teamAColor, 'Red');
      // Blue should enter
      expect(currentState.teamBColor, 'Blue');
      // Red should have streak = 2
      expect(currentState.teamWinStreaks['Red'], 2);
    });

    test('Team wins 3 times - STREAK BREAKER activates', () {
      // Simulate Red winning 3 times in a row
      var currentState = SessionRotationLogic.createInitialState(testTeams);

      // Match 1: Red beats Blue 5-3 (Red streak = 1)
      currentState = SessionRotationLogic.calculateNextRotation(
        current: currentState,
        completedMatch: MatchResult(
          matchId: 'match_1',
          teamAColor: 'Red',
          teamBColor: 'Blue',
          scoreA: 5,
          scoreB: 3,
          createdAt: DateTime.now(),
          approvalStatus: MatchApprovalStatus.approved,
          scorerIds: const [],
          assistIds: const [],
        ),
      );

      // Match 2: Red beats Yellow 4-2 (Red streak = 2)
      currentState = SessionRotationLogic.calculateNextRotation(
        current: currentState,
        completedMatch: MatchResult(
          matchId: 'match_2',
          teamAColor: 'Red',
          teamBColor: 'Yellow',
          scoreA: 4,
          scoreB: 2,
          createdAt: DateTime.now(),
          approvalStatus: MatchApprovalStatus.approved,
          scorerIds: const [],
          assistIds: const [],
        ),
      );

      // Match 3: Red beats Blue again 3-1 (Would be streak = 3, STREAK BREAKER!)
      currentState = SessionRotationLogic.calculateNextRotation(
        current: currentState,
        completedMatch: MatchResult(
          matchId: 'match_3',
          teamAColor: 'Red',
          teamBColor: 'Blue',
          scoreA: 3,
          scoreB: 1,
          createdAt: DateTime.now(),
          approvalStatus: MatchApprovalStatus.approved,
          scorerIds: const [],
          assistIds: const [],
        ),
      );

      // STREAK BREAKER: Red should be rotated OUT despite winning
      expect(currentState.teamAColor, 'Blue'); // Loser stays (forced)
      // Yellow should enter from queue
      expect(currentState.teamBColor, 'Yellow');
      // Red should be in waiting queue (rotated out)
      expect(currentState.waitingTeamColors, ['Red']);
      // Red's streak should be reset to 0
      expect(currentState.teamWinStreaks['Red'], 0);
      // Blue's streak should be reset to 0 (they're staying but didn't win)
      expect(currentState.teamWinStreaks['Blue'], 0);
    });

    test(
        'shouldForceStreakRotation returns true when streak is 2 (about to be 3)',
        () {
      final state = RotationState(
        teamAColor: 'Red',
        teamBColor: 'Blue',
        waitingTeamColors: const ['Yellow'],
        currentMatchNumber: 3,
        teamWinStreaks: const {'Red': 2, 'Blue': 0, 'Yellow': 0},
      );

      final shouldForce =
          SessionRotationLogic.shouldForceStreakRotation(state, 'Red');

      expect(shouldForce, isTrue);
    });

    test('shouldForceStreakRotation returns false when streak is 1', () {
      final state = RotationState(
        teamAColor: 'Red',
        teamBColor: 'Blue',
        waitingTeamColors: const ['Yellow'],
        currentMatchNumber: 2,
        teamWinStreaks: const {'Red': 1, 'Blue': 0, 'Yellow': 0},
      );

      final shouldForce =
          SessionRotationLogic.shouldForceStreakRotation(state, 'Red');

      expect(shouldForce, isFalse);
    });

    test('Streak resets when team loses', () {
      // Simulate: Red wins twice, then loses
      var currentState = SessionRotationLogic.createInitialState(testTeams);

      // Match 1: Red beats Blue (Red streak = 1)
      currentState = SessionRotationLogic.calculateNextRotation(
        current: currentState,
        completedMatch: MatchResult(
          matchId: 'match_1',
          teamAColor: 'Red',
          teamBColor: 'Blue',
          scoreA: 5,
          scoreB: 3,
          createdAt: DateTime.now(),
          approvalStatus: MatchApprovalStatus.approved,
          scorerIds: const [],
          assistIds: const [],
        ),
      );

      // Match 2: Red beats Yellow (Red streak = 2)
      currentState = SessionRotationLogic.calculateNextRotation(
        current: currentState,
        completedMatch: MatchResult(
          matchId: 'match_2',
          teamAColor: 'Red',
          teamBColor: 'Yellow',
          scoreA: 4,
          scoreB: 2,
          createdAt: DateTime.now(),
          approvalStatus: MatchApprovalStatus.approved,
          scorerIds: const [],
          assistIds: const [],
        ),
      );

      // Match 3: Blue beats Red (Red streak should reset to 0)
      currentState = SessionRotationLogic.calculateNextRotation(
        current: currentState,
        completedMatch: MatchResult(
          matchId: 'match_3',
          teamAColor: 'Red',
          teamBColor: 'Blue',
          scoreA: 2,
          scoreB: 5,
          createdAt: DateTime.now(),
          approvalStatus: MatchApprovalStatus.approved,
          scorerIds: const [],
          assistIds: const [],
        ),
      );

      // Blue should stay (winner)
      expect(currentState.teamAColor, 'Blue');
      // Red should be rotated out
      expect(currentState.waitingTeamColors, contains('Red'));
      // Red's streak should be reset to 0
      expect(currentState.teamWinStreaks['Red'], 0);
      // Blue should have streak = 1
      expect(currentState.teamWinStreaks['Blue'], 1);
    });
  });
}
