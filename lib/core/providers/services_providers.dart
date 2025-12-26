import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kattrick/core/providers/firestore_provider.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/services/storage_service.dart';
import 'package:kattrick/services/location_service.dart';
import 'package:kattrick/services/push_notification_service.dart';
import 'package:kattrick/services/game_reminder_service.dart';
import 'package:kattrick/services/push_notification_integration_service.dart';
import 'package:kattrick/services/auth_service.dart';
import 'package:kattrick/services/scouting_service.dart';
import 'package:kattrick/services/google_places_service.dart';
import 'package:kattrick/services/custom_api_service.dart';
import 'package:kattrick/services/weather_service.dart';
import 'package:kattrick/features/hubs/domain/services/hub_analytics_service.dart';
import 'package:kattrick/features/hubs/domain/services/hub_permissions_service.dart';
import 'package:kattrick/features/hubs/domain/services/hub_membership_service.dart';

part 'services_providers.g.dart';

/// Storage Service Provider
@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService(
    functions: FirebaseFunctions.instance,
    auth: firebase_auth.FirebaseAuth.instance,
  );
}

/// Location Service Provider
@riverpod
LocationService locationService(LocationServiceRef ref) {
  return LocationService();
}

/// Weather Service Provider
@riverpod
WeatherService weatherService(WeatherServiceRef ref) {
  return WeatherService();
}

/// Push Notification Service Provider
@riverpod
PushNotificationService pushNotificationService(PushNotificationServiceRef ref) {
  return PushNotificationService();
}

/// Game Reminder Service Provider
@riverpod
GameReminderService gameReminderService(GameReminderServiceRef ref) {
  return GameReminderService();
}

/// Push Notification Integration Service Provider
@riverpod
PushNotificationIntegrationService pushNotificationIntegrationService(
    PushNotificationIntegrationServiceRef ref) {
  return PushNotificationIntegrationService();
}

/// Auth Service Provider
@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

/// Scouting Service Provider
@riverpod
ScoutingService scoutingService(ScoutingServiceRef ref) {
  return ScoutingService(
    usersRepo: ref.watch(usersRepositoryProvider),
    hubsRepo: ref.watch(hubsRepositoryProvider),
    locationService: ref.watch(locationServiceProvider),
  );
}

/// Google Places Service Provider
@riverpod
GooglePlacesService googlePlacesService(GooglePlacesServiceRef ref) {
  return GooglePlacesService();
}

/// Custom API Service Provider
@riverpod
CustomApiService customApiService(CustomApiServiceRef ref) {
  return CustomApiService();
}

/// Hub Analytics Service Provider
@riverpod
HubAnalyticsService hubAnalyticsService(HubAnalyticsServiceRef ref) {
  return HubAnalyticsService(ref.watch(firestoreProvider));
}

/// Hub Permissions Service Provider - SINGLETON for permission calculations
///
/// This service is now a singleton to avoid repeated instantiation.
/// Use via providers instead of direct instantiation.
@riverpod
HubPermissionsService hubPermissionsService(HubPermissionsServiceRef ref) {
  return HubPermissionsService(
    hubsRepo: ref.watch(hubsRepositoryProvider),
  );
}

/// Hub Membership Service Provider
///
/// Orchestrates hub membership operations with business validation.
/// Use this instead of calling repository methods directly.
@riverpod
HubMembershipService hubMembershipService(HubMembershipServiceRef ref) {
  return HubMembershipService(
    hubsRepo: ref.watch(hubsRepositoryProvider),
    usersRepo: ref.watch(usersRepositoryProvider),
    notificationService: ref.watch(pushNotificationServiceProvider),
  );
}

