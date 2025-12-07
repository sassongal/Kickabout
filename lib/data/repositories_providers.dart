import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/services/hub_permissions_service.dart'; // Added import
import 'package:kattrick/services/auth_service.dart';
import 'package:kattrick/services/storage_service.dart';
import 'package:kattrick/services/location_service.dart';
import 'package:kattrick/services/push_notification_service.dart';
import 'package:kattrick/services/game_reminder_service.dart';
import 'package:kattrick/services/push_notification_integration_service.dart';
import 'package:kattrick/services/scouting_service.dart';
import 'package:kattrick/services/google_places_service.dart';
import 'package:kattrick/services/custom_api_service.dart';
import 'package:kattrick/services/weather_service.dart';
import 'package:kattrick/services/cache_service.dart';
import 'package:kattrick/services/hub_analytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

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

final favoriteTeamsRepositoryProvider =
    Provider<FavoriteTeamsRepository>((ref) {
  return FavoriteTeamsRepository(ref.watch(firestoreProvider));
});

/// Provider that caches the list of all teams
final allTeamsProvider = FutureProvider<List<TeamData>>((ref) {
  return ref.watch(favoriteTeamsRepositoryProvider).getAllTeams();
});

/// Provider for game teams repository (teams within a game)
final gameTeamsRepositoryProvider = Provider<GameTeamsRepository>((ref) {
  return GameTeamsRepository(ref.watch(firestoreProvider));
});

/// Legacy alias for gameTeamsRepositoryProvider (for backward compatibility)
final teamsRepositoryProvider = gameTeamsRepositoryProvider;

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(firestore: ref.watch(firestoreProvider));
});

final hubEventsRepositoryProvider = Provider<HubEventsRepository>((ref) {
  return HubEventsRepository(firestore: ref.watch(firestoreProvider));
});

// Removed: ratingsRepositoryProvider - RatingsRepository is deprecated (manager-only ratings now)

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

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(firestore: ref.watch(firestoreProvider));
});

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository();
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(firestore: ref.watch(firestoreProvider));
});

final privateMessagesRepositoryProvider =
    Provider<PrivateMessagesRepository>((ref) {
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

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// Push notification service provider
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

/// Game reminder service provider
final gameReminderServiceProvider = Provider<GameReminderService>((ref) {
  return GameReminderService();
});

/// Push notification integration service provider
final pushNotificationIntegrationServiceProvider =
    Provider<PushNotificationIntegrationService>((ref) {
  return PushNotificationIntegrationService();
});

/// Auth service provider (exported from app_router)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Auth state stream provider for cache clearing
final _authStateForCacheProvider = StreamProvider<firebase_auth.User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current user ID provider with cache clearing on user change
final currentUserIdProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final currentUserId = authService.currentUserId;

  // FIX: Clear cache when user changes
  final authStateAsync = ref.watch(_authStateForCacheProvider);
  authStateAsync.whenData((firebaseUser) {
    final newUserId = firebaseUser?.uid;
    // Clear cache for any user change (handled in login screen too, but this is a safety net)
    if (newUserId != null && newUserId != currentUserId) {
      CacheService().clear(CacheKeys.user(newUserId));
      debugPrint('🧹 Cleared cache for user change: $newUserId');
    }
  });

  return currentUserId;
});

/// Check if current user is anonymous
final isAnonymousUserProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAnonymous;
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

/// Hub analytics service provider
final hubAnalyticsServiceProvider = Provider<HubAnalyticsService>((ref) {
  return HubAnalyticsService(ref.watch(firestoreProvider));
});

/// Leaderboard provider - watches top ranked users
final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, LeaderboardParams>(
        (ref, params) async {
  final leaderboardRepo = ref.watch(leaderboardRepositoryProvider);
  return leaderboardRepo.getLeaderboard(
    type: params.type,
    hubId: params.hubId,
    period: params.period,
    limit: params.limit,
  );
});

/// Leaderboard parameters
class LeaderboardParams {
  final LeaderboardType type;
  final String? hubId;
  final TimePeriod period;
  final int limit;

  LeaderboardParams({
    required this.type,
    this.hubId,
    required this.period,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardParams &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          hubId == other.hubId &&
          period == other.period &&
          limit == other.limit;

  @override
  int get hashCode =>
      type.hashCode ^ hubId.hashCode ^ period.hashCode ^ limit.hashCode;
}

/// Unread notifications count provider
final unreadNotificationsCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  ref.keepAlive(); // Prevent disposal during navigation
  final notificationsRepo = ref.watch(notificationsRepositoryProvider);
  return notificationsRepo.watchUnreadCount(userId);
});

/// Hubs by creator stream provider with keepAlive for performance
final hubsByCreatorStreamProvider =
    StreamProvider.family<List<Hub>, String>((ref, uid) {
  ref.keepAlive(); // Prevent disposal and reduce rebuilds
  final hubsRepo = ref.watch(hubsRepositoryProvider);
  return hubsRepo.watchHubsByCreator(uid);
});

/// Home dashboard data provider (weather & vibe) - using Open-Meteo (free)
final homeDashboardDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final locationService = ref.read(locationServiceProvider);
    final weatherService = ref.read(weatherServiceProvider);
    final position = await locationService.getCurrentLocation();

    if (position == null) {
      return {
        'vibeMessage': 'יום ענק לכדורגל! ⚽',
        'temperature': null,
        'condition': null,
        'summary': 'יום ענק לכדורגל! ⚽',
      };
    }

    final weather = await weatherService.getCurrentWeather(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (weather == null) {
      return {
        'vibeMessage': 'יום טוב לכדורגל! ☀️',
        'temperature': null,
        'condition': null,
        'summary': 'יום טוב לכדורגל! ☀️',
      };
    }

    return {
      'vibeMessage': weather.summary,
      'temperature': weather.temperature,
      'condition': weather.condition,
      'summary': weather.summary,
      'weatherCode': weather.weatherCode,
    };
  } catch (e) {
    // In case of error, return default message
    return {
      'vibeMessage': 'יום טוב לכדורגל! ☀️',
      'temperature': null,
      'condition': null,
      'summary': 'יום טוב לכדורגל! ☀️',
    };
  }
});

/// Hub role provider - determines user's role in a specific hub
///
/// Hub permissions provider - provides HubPermissions for a user in a hub
/// Usage: ref.watch(hubPermissionsProvider((hubId: 'xxx', userId: 'yyy')))
final hubPermissionsProvider =
    FutureProvider.family<HubPermissions, ({String hubId, String userId})>(
        (ref, params) async {
  try {
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final hub = await hubsRepo.getHub(params.hubId);

    if (hub == null) {
      throw Exception('Hub not found');
    }

    final permissionsService =
        HubPermissionsService(ref.read(firestoreProvider));
    return permissionsService.getPermissions(hub, params.userId);
  } catch (e) {
    rethrow;
  }
});

/// Returns UserRole.admin if user is the hub creator or has manager/moderator role
/// Returns UserRole.member if user is a member of the hub
/// Returns UserRole.none if user is not a member
final hubRoleProvider =
    FutureProvider.family<UserRole, String>((ref, hubId) async {
  try {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      return UserRole.none;
    }

    final hubsRepo = ref.read(hubsRepositoryProvider);
    final hub = await hubsRepo.getHub(hubId);

    if (hub == null) {
      return UserRole.none;
    }

    // Check if user is the creator (always admin)
    if (hub.createdBy == currentUserId) {
      return UserRole.admin;
    }

    // Check explicit role from subcollection
    final roleString = await hubsRepo.getUserRole(hubId, currentUserId);
    if (roleString != null) {
      // Check for 'admin' role directly (used by Super Admin and Firestore rules)
      if (roleString == 'admin') {
        return UserRole.admin;
      }

      // Check HubRole enum values
      final hubRole = HubRole.fromFirestore(roleString);
      // Manager and moderator are considered admin
      if (hubRole == HubRole.manager || hubRole == HubRole.moderator) {
        return UserRole.admin;
      }
      // Member and veteran are considered members
      if (hubRole == HubRole.member || hubRole == HubRole.veteran) {
        return UserRole.member;
      }
    }

    // Check if user is a member
    // Use user.hubIds as source of truth
    final usersRepo = ref.read(usersRepositoryProvider);
    final user = await usersRepo.getUser(currentUserId);

    if (user != null && user.hubIds.contains(hubId)) {
      return UserRole.member;
    }

    // User is not a member
    return UserRole.none;
  } catch (e) {
    // On error, return none
    return UserRole.none;
  }
});

/// Admin tasks provider - counts games that need to be closed
///
/// Returns the number of games that:
/// - User is admin of (hub manager)
/// - Status is 'teamsFormed' or 'inProgress'
/// - gameDate is in the past
final adminTasksProvider = StreamProvider<int>((ref) {
  try {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      return Stream.value(0);
    }

    final hubsRepo = ref.read(hubsRepositoryProvider);
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    // Get current user to check hubRoles
    return usersRepo.watchUser(currentUserId).asyncMap((user) async {
      if (user == null) return 0;

      // Get all hubs where user is admin
      final adminHubIds = <String>{};

      // Check user.hubIds (if exists) or query hubs
      final userHubIds = user.hubIds;
      if (userHubIds.isNotEmpty) {
        for (final hubId in userHubIds) {
          try {
            final hub = await hubsRepo.getHub(hubId);
            if (hub != null) {
              // Check if user is creator or manager
              if (hub.createdBy == currentUserId) {
                adminHubIds.add(hubId);
              } else {
                final roleString =
                    await hubsRepo.getUserRole(hubId, currentUserId);
                if (roleString != null) {
                  final hubRole = HubRole.fromFirestore(roleString);
                  if (hubRole == HubRole.manager ||
                      hubRole == HubRole.moderator) {
                    adminHubIds.add(hubId);
                  }
                }
              }
            }
          } catch (e) {
            // Skip this hub if error
            continue;
          }
        }
      }

      if (adminHubIds.isEmpty) return 0;

      // Query games for each hub
      int totalStuckGames = 0;
      final now = DateTime.now();

      for (final hubId in adminHubIds) {
        try {
          // Get games for this hub
          final games = await gamesRepo.listGamesByHub(hubId);

          // Filter stuck games
          final stuckGames = games.where((game) {
            final isStuckStatus = game.status == GameStatus.teamsFormed ||
                game.status == GameStatus.inProgress;
            final isPastDate = game.gameDate.isBefore(now);
            return isStuckStatus && isPastDate;
          });

          totalStuckGames += stuckGames.length;
        } catch (e) {
          // Skip this hub if error
          continue;
        }
      }

      return totalStuckGames;
    });
  } catch (e) {
    return Stream.value(0);
  }
});
