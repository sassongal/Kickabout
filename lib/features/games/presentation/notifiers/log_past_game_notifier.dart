import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/features/games/domain/use_cases/log_past_game_use_case.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/city_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_past_game_notifier.g.dart';

/// State for log past game screen
class LogPastGameState {
  final int currentStep;
  final DateTime selectedDate;
  final String? selectedVenueId;
  final String? selectedEventId;
  final String teamAScore;
  final String teamBScore;
  final Set<String> selectedPlayerIds;
  final List<Team> teams;
  final bool showInCommunityFeed;
  final bool isLoading;
  final Hub? hub;
  final List<Venue> venues;
  final List<User> hubMembers;
  final List<HubEvent> events;

  LogPastGameState({
    this.currentStep = 0,
    DateTime? selectedDate,
    this.selectedVenueId,
    this.selectedEventId,
    this.teamAScore = '',
    this.teamBScore = '',
    this.selectedPlayerIds = const {},
    this.teams = const [],
    this.showInCommunityFeed = false,
    this.isLoading = false,
    this.hub,
    this.venues = const [],
    this.hubMembers = const [],
    this.events = const [],
  }) : selectedDate = selectedDate ?? DateTime.now().subtract(const Duration(days: 1));

  LogPastGameState copyWith({
    int? currentStep,
    DateTime? selectedDate,
    String? selectedVenueId,
    String? selectedEventId,
    String? teamAScore,
    String? teamBScore,
    Set<String>? selectedPlayerIds,
    List<Team>? teams,
    bool? showInCommunityFeed,
    bool? isLoading,
    Hub? hub,
    List<Venue>? venues,
    List<User>? hubMembers,
    List<HubEvent>? events,
  }) {
    return LogPastGameState(
      currentStep: currentStep ?? this.currentStep,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedVenueId: selectedVenueId ?? this.selectedVenueId,
      selectedEventId: selectedEventId ?? this.selectedEventId,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      selectedPlayerIds: selectedPlayerIds ?? this.selectedPlayerIds,
      teams: teams ?? this.teams,
      showInCommunityFeed: showInCommunityFeed ?? this.showInCommunityFeed,
      isLoading: isLoading ?? this.isLoading,
      hub: hub ?? this.hub,
      venues: venues ?? this.venues,
      hubMembers: hubMembers ?? this.hubMembers,
      events: events ?? this.events,
    );
  }

  bool canProceedToNextStep() {
    switch (currentStep) {
      case 0:
        return teamAScore.trim().isNotEmpty && teamBScore.trim().isNotEmpty;
      case 1:
        return selectedPlayerIds.length >= 4; // Minimum 4 players
      case 2:
        return teams.isNotEmpty && teams.every((team) => team.playerIds.isNotEmpty);
      default:
        return false;
    }
  }
}

/// Notifier for managing log past game screen state
@riverpod
class LogPastGameNotifier extends _$LogPastGameNotifier {
  @override
  LogPastGameState build(String hubId) {
    // Load data on initialization
    Future.microtask(() => _loadData(hubId));
    return LogPastGameState();
  }

  Future<void> _loadData(String hubId) async {
    state = state.copyWith(isLoading: true);
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final venuesRepo = ref.read(venuesRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);
      final eventsRepo = ref.read(hubEventsRepositoryProvider);

      // Load hub
      final hub = await hubsRepo.getHub(hubId);

      // Load venues
      final venueIds = hub?.venueIds ?? [];
      final venues = <Venue>[];
      for (final venueId in venueIds) {
        try {
          final venue = await venuesRepo.getVenue(venueId);
          if (venue != null) {
            venues.add(venue);
          }
        } catch (e) {
          // Skip if venue not found
          continue;
        }
      }

      // Load hub members
      final members = hub != null
          ? await usersRepo.getUsers(await hubsRepo.getHubMemberIds(hub.hubId))
          : <User>[];

      // Load events
      final events = await eventsRepo.getHubEvents(hubId);

      state = state.copyWith(
        hub: hub,
        venues: venues,
        hubMembers: members,
        events: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Update current step
  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  /// Move to next step
  void nextStep() {
    if (!state.canProceedToNextStep()) {
      throw Exception(
        state.currentStep == 0
            ? 'נא למלא את כל השדות'
            : state.currentStep == 1
                ? 'נא לבחור לפחות 4 שחקנים'
                : 'נא לחלק את כל השחקנים לקבוצות',
      );
    }
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  /// Move to previous step
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Update selected date
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  /// Update selected venue
  void setSelectedVenueId(String? venueId) {
    state = state.copyWith(selectedVenueId: venueId);
  }

  /// Update selected event
  void setSelectedEventId(String? eventId) {
    state = state.copyWith(selectedEventId: eventId);
  }

  /// Update team scores
  void setTeamAScore(String score) {
    state = state.copyWith(teamAScore: score);
  }

  void setTeamBScore(String score) {
    state = state.copyWith(teamBScore: score);
  }

  /// Toggle player selection
  void togglePlayerSelection(String playerId) {
    final updated = Set<String>.from(state.selectedPlayerIds);
    if (updated.contains(playerId)) {
      updated.remove(playerId);
    } else {
      updated.add(playerId);
    }
    state = state.copyWith(selectedPlayerIds: updated);
  }

  /// Update teams
  void setTeams(List<Team> teams) {
    state = state.copyWith(teams: teams);
  }

  /// Toggle show in community feed
  void toggleShowInCommunityFeed() {
    state = state.copyWith(showInCommunityFeed: !state.showInCommunityFeed);
  }

  /// Save game - uses LogPastGameUseCase
  Future<void> saveGame() async {
    state = state.copyWith(isLoading: true);

    try {
      final logPastGameUseCase = ref.read(logPastGameUseCaseProvider.notifier);

      final teamAScore = int.tryParse(state.teamAScore.trim()) ?? 0;
      final teamBScore = int.tryParse(state.teamBScore.trim()) ?? 0;

      Venue? selectedVenue;
      if (state.selectedVenueId != null) {
        for (final venue in state.venues) {
          if (venue.venueId == state.selectedVenueId) {
            selectedVenue = venue;
            break;
          }
        }
      }

      final city = state.hub?.city ?? selectedVenue?.city;
      final region = state.hub?.region ??
          (city != null ? CityUtils.getRegionForCity(city) : null);

      final params = LogPastGameParams(
        hubId: state.hub!.hubId,
        gameDate: state.selectedDate,
        venueId: state.selectedVenueId,
        eventId: state.selectedEventId,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
        playerIds: state.selectedPlayerIds.toList(),
        teams: state.teams,
        showInCommunityFeed: state.showInCommunityFeed,
        region: region,
        city: city,
      );

      await logPastGameUseCase.execute(params);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

