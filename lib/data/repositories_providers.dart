import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/services/auth_service.dart';
import 'package:kickadoor/services/storage_service.dart';
import 'package:kickadoor/services/location_service.dart';
import 'package:kickadoor/services/push_notification_service.dart';
import 'package:kickadoor/services/game_reminder_service.dart';
import 'package:kickadoor/services/push_notification_integration_service.dart';
import 'package:kickadoor/services/scouting_service.dart';
import 'package:kickadoor/services/google_places_service.dart';
import 'package:kickadoor/services/custom_api_service.dart';

/// Providers for repositories
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(firestore: ref.watch(firestoreProvider));
});

final hubsRepositoryProvider = Provider<HubsRepository>((ref) {
  return HubsRepository(firestore: ref.watch(firestoreProvider));
});

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  return GamesRepository(firestore: ref.watch(firestoreProvider));
});

final signupsRepositoryProvider = Provider<SignupsRepository>((ref) {
  return SignupsRepository(firestore: ref.watch(firestoreProvider));
});

final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  return TeamsRepository(firestore: ref.watch(firestoreProvider));
});

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(firestore: ref.watch(firestoreProvider));
});

final hubEventsRepositoryProvider = Provider<HubEventsRepository>((ref) {
  return HubEventsRepository(firestore: ref.watch(firestoreProvider));
});

final ratingsRepositoryProvider = Provider<RatingsRepository>((ref) {
  return RatingsRepository(
    firestore: ref.watch(firestoreProvider),
    hubsRepo: ref.watch(hubsRepositoryProvider),
  );
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(firestore: ref.watch(firestoreProvider));
});

final commentsRepositoryProvider = Provider<CommentsRepository>((ref) {
  return CommentsRepository(firestore: ref.watch(firestoreProvider));
});

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(firestore: ref.watch(firestoreProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(firestore: ref.watch(firestoreProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(firestore: ref.watch(firestoreProvider));
});

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository();
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(firestore: ref.watch(firestoreProvider));
});

final privateMessagesRepositoryProvider = Provider<PrivateMessagesRepository>((ref) {
  return PrivateMessagesRepository(firestore: ref.watch(firestoreProvider));
});

final venuesRepositoryProvider = Provider<VenuesRepository>((ref) {
  return VenuesRepository(firestore: ref.watch(firestoreProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Push notification service provider
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

/// Game reminder service provider
final gameReminderServiceProvider = Provider<GameReminderService>((ref) {
  return GameReminderService();
});

/// Push notification integration service provider
final pushNotificationIntegrationServiceProvider = Provider<PushNotificationIntegrationService>((ref) {
  return PushNotificationIntegrationService();
});

/// Auth service provider (exported from app_router)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current user ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserId;
});

/// Scouting service provider
final scoutingServiceProvider = Provider<ScoutingService>((ref) {
  return ScoutingService(
    usersRepo: ref.watch(usersRepositoryProvider),
    hubsRepo: ref.watch(hubsRepositoryProvider),
    locationService: ref.watch(locationServiceProvider),
  );
});

/// Google Places service provider
final googlePlacesServiceProvider = Provider<GooglePlacesService>((ref) {
  return GooglePlacesService();
});

/// Custom API service provider
final customApiServiceProvider = Provider<CustomApiService>((ref) {
  return CustomApiService();
});

