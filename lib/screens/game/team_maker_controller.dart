import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/logic/team_maker.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class TeamMakerState {
  final List<PlayerForTeam> players;
  final List<Team> teams;
  final Map<String, User> userMap;
  final double balanceScore;
  final bool isLoading;
  final bool isGenerating;
  final bool isSaving;
  final bool hasGenerated;
  final String? errorMessage;

  TeamMakerState({
    this.players = const [],
    this.teams = const [],
    this.userMap = const {},
    this.balanceScore = 0.0,
    this.isLoading = true,
    this.isGenerating = false,
    this.isSaving = false,
    this.hasGenerated = false,
    this.errorMessage,
  });

  TeamMakerState copyWith({
    List<PlayerForTeam>? players,
    List<Team>? teams,
    Map<String, User>? userMap,
    double? balanceScore,
    bool? isLoading,
    bool? isGenerating,
    bool? isSaving,
    bool? hasGenerated,
    String? errorMessage,
  }) {
    return TeamMakerState(
      players: players ?? this.players,
      teams: teams ?? this.teams,
      userMap: userMap ?? this.userMap,
      balanceScore: balanceScore ?? this.balanceScore,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      isSaving: isSaving ?? this.isSaving,
      hasGenerated: hasGenerated ?? this.hasGenerated,
      errorMessage:
          errorMessage, // If null is passed, it remains null? No, usually we want to clear it.
      // For this pattern, let's say if it's passed it updates. To clear, pass null? State copyWith usually ignores null.
      // Let's assume we pass explict null to clear? No, Dart doesn't support that easily without a wrapper.
      // Let's just say errorMessage is nullable. If I want to clear it, I'll deal with it.
    );
  }

  // Helper to clear error
  TeamMakerState clearError() {
    return TeamMakerState(
      players: players,
      teams: teams,
      userMap: userMap,
      balanceScore: balanceScore,
      isLoading: isLoading,
      isGenerating: isGenerating,
      isSaving: isSaving,
      hasGenerated: hasGenerated,
      errorMessage: null,
    );
  }
}

class TeamMakerArgs {
  final String hubId;
  final List<String> playerIds;
  final int teamCount;
  final String? eventId;
  final String? gameId;
  final bool isEvent;

  TeamMakerArgs({
    required this.hubId,
    required this.playerIds,
    required this.teamCount,
    required this.isEvent,
    this.eventId,
    this.gameId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamMakerArgs &&
        other.hubId == hubId &&
        listEquals(other.playerIds, playerIds) &&
        other.teamCount == teamCount &&
        other.eventId == eventId &&
        other.gameId == gameId &&
        other.isEvent == isEvent;
  }

  @override
  int get hashCode {
    return Object.hash(
      hubId,
      Object.hashAll(playerIds),
      teamCount,
      eventId,
      gameId,
      isEvent,
    );
  }
}

class TeamMakerController extends StateNotifier<TeamMakerState> {
  final Ref ref;
  final TeamMakerArgs args;

  TeamMakerController(this.ref, this.args) : super(TeamMakerState()) {
    loadPlayers();
  }

  Future<void> loadPlayers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final hubsRepo = ref.read(hubsRepositoryProvider);

      // Fetch manager ratings
      final hubMembers =
          await hubsRepo.getHubMembersByIds(args.hubId, args.playerIds);

      if (hubMembers.isEmpty) {
        throw Exception(
            'לא ניתן לטעון את חברי ההאב (רשימה ריקה). אנא נסה שוב.');
      }

      final managerRatings = <String, double>{};
      for (final member in hubMembers) {
        if (member.managerRating > 0) {
          managerRatings[member.userId] = member.managerRating;
        }
      }

      final users = await usersRepo.getUsers(args.playerIds);
      final userMap = {for (var user in users) user.uid: user};
      final players = users
          .map((user) => PlayerForTeam.fromUser(user,
              hubId: args.hubId, managerRatings: managerRatings))
          .toList();

      state = state.copyWith(
        isLoading: false,
        players: players,
        userMap: userMap,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Async check for unrated players that returns the list
  Future<List<User>> checkUnratedPlayers() async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hubMembers =
          await hubsRepo.getHubMembersByIds(args.hubId, args.playerIds);

      final managerRatings = <String, double>{};
      for (final member in hubMembers) {
        if (member.managerRating > 0) {
          managerRatings[member.userId] = member.managerRating;
        }
      }

      // Update our local players with freshness if needed, but for now just check unrated
      final unratedPlayers = state.userMap.values.where((user) {
        return !managerRatings.containsKey(user.uid) ||
            managerRatings[user.uid] == 0;
      }).toList();

      return unratedPlayers;
    } catch (e) {
      // On error return empty or rethrow?
      return [];
    }
  }

  Future<void> generateTeams({bool force = false}) async {
    state = state.copyWith(isGenerating: true, errorMessage: null);

    // Note: The unrated check dialog should be handled by the UI before calling this,
    // or we can pause here. But Notifiers shouldn't handle UI dialogs directly.
    // The UI should call checkUnratedPlayers(), show dialog, then call generateTeams().

    try {
      // Simulate delay for UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Use a random seed if force == true to ensure different results
      final seed = force ? DateTime.now().millisecondsSinceEpoch : null;

      final result = TeamMaker.createBalancedTeams(
        state.players,
        teamCount: args.teamCount,
        seed: seed,
      );

      state = state.copyWith(
        isGenerating: false,
        hasGenerated: true,
        teams: result.teams,
        balanceScore: result.balanceScore,
      );

      // Success Haptic
      HapticFeedback.vibrate();
    } on ArgumentError catch (e) {
      // User-friendly error for not enough players
      String msg = 'שגיאה ביצירת קבוצות.';
      if (e.message.toString().contains('Not enough players')) {
        msg = 'אין מספיק שחקנים כדי למלא את מספר הקבוצות המבוקש.';
      } else {
        msg = e.message.toString();
      }
      state = state.copyWith(isGenerating: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(isGenerating: false, errorMessage: e.toString());
    }
  }

  void movePlayer(String playerId, int fromTeamIndex, int toTeamIndex) {
    if (fromTeamIndex == toTeamIndex) return;

    final player = state.players.firstWhere((p) => p.uid == playerId);
    final currentTeams = [...state.teams]; // copy

    final fromTeam = currentTeams[fromTeamIndex];
    final toTeam = currentTeams[toTeamIndex];

    final newFromPlayerIds = List<String>.from(fromTeam.playerIds)
      ..remove(playerId);
    final newFromScore = fromTeam.totalScore - player.rating;

    final newToPlayerIds = List<String>.from(toTeam.playerIds)..add(playerId);
    final newToScore = toTeam.totalScore + player.rating;

    currentTeams[fromTeamIndex] = fromTeam.copyWith(
      playerIds: newFromPlayerIds,
      totalScore: newFromScore,
    );
    currentTeams[toTeamIndex] = toTeam.copyWith(
      playerIds: newToPlayerIds,
      totalScore: newToScore,
    );

    final metrics = TeamMaker.calculateBalanceMetrics(currentTeams);
    final newBalanceScore =
        (1.0 - (metrics.stddev / 5.0)).clamp(0.0, 1.0) * 100;

    state = state.copyWith(
      teams: currentTeams,
      balanceScore: newBalanceScore,
    );

    // Light feedback for manual move
    HapticFeedback.lightImpact();
  }

  Future<bool> saveTeams() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      if (args.isEvent && args.eventId != null) {
        final eventsRepo = ref.read(hubEventsRepositoryProvider);
        await eventsRepo.updateHubEvent(
          args.hubId,
          args.eventId!,
          {
            'teams': state.teams.map((t) => t.toJson()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Apply optimization suggestions (Magic Wand)
  void optimizeTeams() {
    if (!state.hasGenerated || state.teams.isEmpty) return;

    final suggestions = TeamMaker.getOptimizationSuggestions(
      state.teams,
      state.players,
    );

    if (suggestions.isEmpty) {
      // No suggestions available
      return;
    }

    // Apply the best suggestion (first one)
    final bestSuggestion = suggestions.first;

    // Find team indices
    final teamAIndex = state.teams
        .indexWhere((t) => t.teamId == bestSuggestion.teamAId);
    final teamBIndex = state.teams
        .indexWhere((t) => t.teamId == bestSuggestion.teamBId);

    if (teamAIndex == -1 || teamBIndex == -1) return;

    // Swap players: Move playerA from teamA to teamB, then playerB from teamB to teamA
    movePlayer(bestSuggestion.playerAId, teamAIndex, teamBIndex);
    
    // After the first move, re-find indices (they might have changed)
    final updatedTeams = [...state.teams];
    final newTeamAIndex = updatedTeams
        .indexWhere((t) => t.teamId == bestSuggestion.teamAId);
    final newTeamBIndex = updatedTeams
        .indexWhere((t) => t.teamId == bestSuggestion.teamBId);
    if (newTeamAIndex != -1 && newTeamBIndex != -1) {
      movePlayer(bestSuggestion.playerBId, newTeamBIndex, newTeamAIndex);
    }

    HapticFeedback.mediumImpact();
  }

  /// Generate shareable text for teams
  String generateTeamsText() {
    if (state.teams.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('🏆 *כוחות המשחק* 🏆\n');

    for (int i = 0; i < state.teams.length; i++) {
      final team = state.teams[i];
      buffer.writeln('*${team.name}* (${team.playerIds.length} שחקנים):');

      for (final playerId in team.playerIds) {
        final user = state.userMap[playerId];
        if (user != null) {
          buffer.writeln('• ${user.displayName ?? user.name}');
        }
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }
}

final teamMakerControllerProvider = StateNotifierProvider.family
    .autoDispose<TeamMakerController, TeamMakerState, TeamMakerArgs>(
        (ref, args) {
  return TeamMakerController(ref, args);
});
