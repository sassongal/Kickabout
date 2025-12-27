import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kattrick/core/providers/firestore_provider.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/games/data/repositories/session_repository.dart';
import 'package:kattrick/features/games/data/repositories/match_approval_repository.dart';
import 'package:kattrick/features/games/data/repositories/game_queries_repository.dart';
import 'package:kattrick/features/games/infrastructure/services/game_finalization_service.dart';
import 'package:kattrick/features/games/infrastructure/services/game_signup_service.dart';
import 'package:kattrick/features/hubs/domain/services/hub_creation_service.dart';
import 'package:kattrick/features/hubs/data/repositories/hub_venues_repository.dart';
import 'package:kattrick/features/hubs/data/repositories/hub_contact_repository.dart';
import 'package:kattrick/features/hubs/data/repositories/hub_join_requests_repository.dart';
import 'package:kattrick/shared/domain/events/event_bus.dart';

part 'repositories_providers.g.dart';

/// Users Repository Provider
@riverpod
UsersRepository usersRepository(UsersRepositoryRef ref) {
  return UsersRepository(firestore: ref.watch(firestoreProvider));
}

/// Hubs Repository Provider
@riverpod
HubsRepository hubsRepository(HubsRepositoryRef ref) {
  return HubsRepository(firestore: ref.watch(firestoreProvider));
}

/// Games Repository Provider (Basic CRUD only)
@riverpod
GamesRepository gamesRepository(GamesRepositoryRef ref) {
  return GamesRepository(firestore: ref.watch(firestoreProvider));
}

/// Session Repository Provider (Session lifecycle)
@riverpod
SessionRepository sessionRepository(SessionRepositoryRef ref) {
  return SessionRepository(
    firestore: ref.watch(firestoreProvider),
    gamesRepo: ref.watch(gamesRepositoryProvider),
    hubsRepo: ref.watch(hubsRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
}

/// Match Approval Repository Provider (Match approval workflow)
@riverpod
MatchApprovalRepository matchApprovalRepository(MatchApprovalRepositoryRef ref) {
  return MatchApprovalRepository(
    firestore: ref.watch(firestoreProvider),
    gamesRepo: ref.watch(gamesRepositoryProvider),
    sessionRepo: ref.watch(sessionRepositoryProvider),
    hubsRepo: ref.watch(hubsRepositoryProvider),
  );
}

/// Game Queries Repository Provider (Complex queries)
@riverpod
GameQueriesRepository gameQueriesRepository(GameQueriesRepositoryRef ref) {
  return GameQueriesRepository(firestore: ref.watch(firestoreProvider));
}

/// Game Finalization Service Provider (Game finalization logic)
@riverpod
GameFinalizationService gameFinalizationService(GameFinalizationServiceRef ref) {
  return GameFinalizationService(
    gamesRepository: ref.watch(gamesRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
}

/// Hub Creation Service Provider (Hub creation business logic)
@riverpod
HubCreationService hubCreationService(HubCreationServiceRef ref) {
  return HubCreationService(
    hubsRepo: ref.watch(hubsRepositoryProvider),
  );
}

/// Signups Repository Provider
@riverpod
SignupsRepository signupsRepository(SignupsRepositoryRef ref) {
  return SignupsRepository(firestore: ref.watch(firestoreProvider));
}

/// Game Signup Service Provider (Signup business logic)
@riverpod
GameSignupService gameSignupService(GameSignupServiceRef ref) {
  return GameSignupService(
    gamesRepo: ref.watch(gamesRepositoryProvider),
    signupsRepo: ref.watch(signupsRepositoryProvider),
  );
}

/// Favorite Teams Repository Provider
@riverpod
FavoriteTeamsRepository favoriteTeamsRepository(FavoriteTeamsRepositoryRef ref) {
  return FavoriteTeamsRepository(ref.watch(firestoreProvider));
}

/// Provider that caches the list of all teams
@riverpod
Future<List<TeamData>> allTeams(AllTeamsRef ref) async {
  final repository = ref.watch(favoriteTeamsRepositoryProvider);
  return repository.getAllTeams();
}

/// Game Teams Repository Provider (teams within a game)
@riverpod
GameTeamsRepository gameTeamsRepository(GameTeamsRepositoryRef ref) {
  return GameTeamsRepository(ref.watch(firestoreProvider));
}

/// Legacy alias for gameTeamsRepositoryProvider (for backward compatibility)
@riverpod
GameTeamsRepository teamsRepository(TeamsRepositoryRef ref) {
  return ref.watch(gameTeamsRepositoryProvider);
}

/// Events Repository Provider
@riverpod
EventsRepository eventsRepository(EventsRepositoryRef ref) {
  return EventsRepository(firestore: ref.watch(firestoreProvider));
}

/// Hub Events Repository Provider
@riverpod
HubEventsRepository hubEventsRepository(HubEventsRepositoryRef ref) {
  return HubEventsRepository(firestore: ref.watch(firestoreProvider));
}

/// Feed Repository Provider
@riverpod
FeedRepository feedRepository(FeedRepositoryRef ref) {
  return FeedRepository(firestore: ref.watch(firestoreProvider));
}

/// Comments Repository Provider
@riverpod
CommentsRepository commentsRepository(CommentsRepositoryRef ref) {
  return CommentsRepository(firestore: ref.watch(firestoreProvider));
}

/// Follow Repository Provider
@riverpod
FollowRepository followRepository(FollowRepositoryRef ref) {
  return FollowRepository(
    firestore: ref.watch(firestoreProvider),
    usersRepository: ref.watch(usersRepositoryProvider),
  );
}

/// Chat Repository Provider
@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return ChatRepository(firestore: ref.watch(firestoreProvider));
}

/// Notifications Repository Provider
@riverpod
NotificationsRepository notificationsRepository(NotificationsRepositoryRef ref) {
  return NotificationsRepository(firestore: ref.watch(firestoreProvider));
}

/// Gamification Repository Provider
@riverpod
GamificationRepository gamificationRepository(GamificationRepositoryRef ref) {
  return GamificationRepository();
}

/// Leaderboard Repository Provider
@riverpod
LeaderboardRepository leaderboardRepository(LeaderboardRepositoryRef ref) {
  return LeaderboardRepository(firestore: ref.watch(firestoreProvider));
}

/// Private Messages Repository Provider
@riverpod
PrivateMessagesRepository privateMessagesRepository(PrivateMessagesRepositoryRef ref) {
  return PrivateMessagesRepository(firestore: ref.watch(firestoreProvider));
}

/// Venues Repository Provider
@riverpod
VenuesRepository venuesRepository(VenuesRepositoryRef ref) {
  return VenuesRepository(firestore: ref.watch(firestoreProvider));
}

// ============================================================================
// HUB SPLIT REPOSITORIES - Extracted from HubsRepository (Phase 3)
// ============================================================================

/// Hub Venues Repository Provider
///
/// Manages hub-venue relationships (linking/unlinking).
/// Extracted from HubsRepository to follow Single Responsibility Principle.
@riverpod
HubVenuesRepository hubVenuesRepository(HubVenuesRepositoryRef ref) {
  return HubVenuesRepository(firestore: ref.watch(firestoreProvider));
}

/// Hub Contact Repository Provider
///
/// Manages player-to-manager contact messages.
/// Extracted from HubsRepository to follow Single Responsibility Principle.
@riverpod
HubContactRepository hubContactRepository(HubContactRepositoryRef ref) {
  return HubContactRepository(firestore: ref.watch(firestoreProvider));
}

/// Hub Join Requests Repository Provider
///
/// Manages join request approval/rejection workflow.
/// Extracted from HubsRepository to follow Single Responsibility Principle.
/// ⚠️ CRITICAL: Uses transactions for atomic operations!
@riverpod
HubJoinRequestsRepository hubJoinRequestsRepository(
  HubJoinRequestsRepositoryRef ref,
) {
  return HubJoinRequestsRepository(firestore: ref.watch(firestoreProvider));
}

