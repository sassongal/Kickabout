import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/features/games/domain/use_cases/submit_game_use_case.dart';
import 'package:kattrick/features/games/infrastructure/use_cases/log_match_result_use_case.dart';
import 'package:kattrick/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_game_notifier.g.dart';

/// State for log game screen
class LogGameState {
  final HubEvent? event;
  final Hub? hub; // For payment link
  final List<User> registeredPlayers;
  final bool isLoading;
  final bool isSubmitting;
  final int teamAScore;
  final int teamBScore;
  final Map<String, bool> presentPlayers; // playerId -> isPresent
  final Map<String, Set<String>> playerHighlights; // playerId -> {goal, assist, mvp}
  final Map<String, bool> paidPlayers; // playerId -> isPaid

  const LogGameState({
    this.event,
    this.hub,
    this.registeredPlayers = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.presentPlayers = const {},
    this.playerHighlights = const {},
    this.paidPlayers = const {},
  });

  LogGameState copyWith({
    HubEvent? event,
    Hub? hub,
    List<User>? registeredPlayers,
    bool? isLoading,
    bool? isSubmitting,
    int? teamAScore,
    int? teamBScore,
    Map<String, bool>? presentPlayers,
    Map<String, Set<String>>? playerHighlights,
    Map<String, bool>? paidPlayers,
  }) {
    return LogGameState(
      event: event ?? this.event,
      hub: hub ?? this.hub,
      registeredPlayers: registeredPlayers ?? this.registeredPlayers,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      presentPlayers: presentPlayers ?? this.presentPlayers,
      playerHighlights: playerHighlights ?? this.playerHighlights,
      paidPlayers: paidPlayers ?? this.paidPlayers,
    );
  }

  bool get isSessionMode {
    return event?.teams.any((team) => team.color != null) ?? false;
  }
}

/// Notifier for managing log game screen state
@riverpod
class LogGameNotifier extends _$LogGameNotifier {
  @override
  LogGameState build(String hubId, String eventId) {
    // Load event on initialization (fire and forget)
    Future.microtask(() => _loadEvent(hubId, eventId));
    return const LogGameState();
  }

  Future<void> _loadEvent(String hubId, String eventId) async {
    state = state.copyWith(isLoading: true);
    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);

      final event = await hubEventsRepo.getHubEvent(hubId, eventId);
      if (event == null) {
        state = state.copyWith(isLoading: false);
        throw Exception('אירוע לא נמצא');
      }

      // Check if event already has a game
      if (event.gameId != null && event.gameId!.isNotEmpty) {
        state = state.copyWith(isLoading: false);
        throw Exception('המשחק כבר נרשם');
      }

      // Load registered players
      final players = await usersRepo.getUsers(event.registeredPlayerIds);

      // Load hub for payment link
      final hub = await hubsRepo.getHub(hubId);

      // Initialize present players (default: all checked)
      final presentMap = <String, bool>{};
      final paidMap = <String, bool>{};
      for (final player in players) {
        presentMap[player.uid] = true; // Default: all present
        paidMap[player.uid] = false; // Default: not paid
      }

      state = state.copyWith(
        event: event,
        hub: hub,
        registeredPlayers: players,
        presentPlayers: presentMap,
        paidPlayers: paidMap,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Reload event (used after logging match result)
  Future<void> reloadEvent() async {
    if (state.event == null) return;
    await _loadEvent(state.event!.hubId, state.event!.eventId);
  }

  /// Update team scores
  void updateScores({int? teamAScore, int? teamBScore}) {
    state = state.copyWith(
      teamAScore: teamAScore ?? state.teamAScore,
      teamBScore: teamBScore ?? state.teamBScore,
    );
  }

  /// Toggle player presence
  void togglePlayerPresence(String playerId) {
    final updated = Map<String, bool>.from(state.presentPlayers);
    updated[playerId] = !(updated[playerId] ?? false);
    state = state.copyWith(presentPlayers: updated);
  }

  /// Toggle player highlight (goal, assist, mvp)
  void togglePlayerHighlight(String playerId, String highlight) {
    final updated = Map<String, Set<String>>.from(state.playerHighlights);
    final highlights = Set<String>.from(updated[playerId] ?? {});
    if (highlights.contains(highlight)) {
      highlights.remove(highlight);
    } else {
      highlights.add(highlight);
    }
    if (highlights.isEmpty) {
      updated.remove(playerId);
    } else {
      updated[playerId] = highlights;
    }
    state = state.copyWith(playerHighlights: updated);
  }

  /// Toggle player payment status
  void togglePlayerPayment(String playerId) {
    final updated = Map<String, bool>.from(state.paidPlayers);
    updated[playerId] = !(updated[playerId] ?? false);
    state = state.copyWith(paidPlayers: updated);
  }

  /// Update paid players map (for initialization)
  void setPaidPlayers(Map<String, bool> paidPlayers) {
    state = state.copyWith(paidPlayers: paidPlayers);
  }

  /// Submit game - uses SubmitGameUseCase
  Future<String> submitGame() async {
    if (state.event == null) {
      throw Exception('Event not loaded');
    }

    // Validate: at least one team must have players
    final presentPlayerIds = state.presentPlayers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (presentPlayerIds.isEmpty) {
      throw Exception('יש לבחור לפחות שחקן אחד נוכח');
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final submitGameUseCase = ref.read(submitGameUseCaseProvider.notifier);

      // Extract goal scorers and MVP
      final goalScorerIds = state.playerHighlights.entries
          .where((e) =>
              e.value.contains('goal') && presentPlayerIds.contains(e.key))
          .map((e) => e.key)
          .toList();

      final mvpPlayerId = state.playerHighlights.entries
          .where((e) =>
              e.value.contains('mvp') && presentPlayerIds.contains(e.key))
          .map((e) => e.key)
          .firstOrNull;

      final params = SubmitGameParams(
        eventId: state.event!.eventId,
        hubId: state.event!.hubId,
        teamAScore: state.teamAScore,
        teamBScore: state.teamBScore,
        presentPlayerIds: presentPlayerIds,
        goalScorerIds: goalScorerIds.isNotEmpty ? goalScorerIds : null,
        mvpPlayerId: mvpPlayerId,
        isSessionMode: state.isSessionMode,
        aggregateWins: state.event!.aggregateWins,
        matches: state.event!.matches,
      );

      final gameId = await submitGameUseCase.execute(params);
      state = state.copyWith(isSubmitting: false);
      return gameId;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  /// Log match result - uses LogMatchResultUseCase
  Future<void> logMatchResult({
    required String teamAColor,
    required String teamBColor,
    required int scoreA,
    required int scoreB,
  }) async {
    if (state.event == null) {
      throw Exception('Event not loaded');
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final logMatchResultUseCase = ref.read(logMatchResultUseCaseProvider.notifier);

      final params = LogMatchResultParams(
        hubId: state.event!.hubId,
        eventId: state.event!.eventId,
        teamAColor: teamAColor,
        teamBColor: teamBColor,
        scoreA: scoreA,
        scoreB: scoreB,
        currentEvent: state.event!,
      );

      await logMatchResultUseCase.execute(params);

      // Reload event to get updated matches and aggregate wins
      await reloadEvent();

      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

