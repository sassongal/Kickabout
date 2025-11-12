import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/data/repositories.dart';
import 'package:kickabout/services/auth_service.dart';
import 'package:kickabout/services/storage_service.dart';
import 'package:kickabout/services/location_service.dart';

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

final ratingsRepositoryProvider = Provider<RatingsRepository>((ref) {
  return RatingsRepository(
    firestore: ref.watch(firestoreProvider),
    hubsRepo: ref.watch(hubsRepositoryProvider),
  );
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(firestore: ref.watch(firestoreProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(firestore: ref.watch(firestoreProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(firestore: ref.watch(firestoreProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
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

