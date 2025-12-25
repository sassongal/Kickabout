import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/core/providers/services_providers.dart';
import 'package:kattrick/core/providers/auth_providers.dart';
import 'package:kattrick/data/leaderboard_repository.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/models/hub_member.dart';
import 'package:kattrick/features/hubs/domain/services/hub_permissions_service.dart';

part 'complex_providers.g.dart';

// ============================================================================
// HUB STATE PROVIDERS - SINGLE SOURCE OF TRUTH
// ============================================================================

/// Unified hub stream provider - SINGLE SOURCE OF TRUTH for hub data
///
/// This provider eliminates duplicate watchHub() subscriptions across screens.
/// All hub-related UI should watch this provider instead of calling repository directly.
///
/// Benefits:
/// - Cache coherence: One subscription shared across all widgets
/// - Memory efficiency: No duplicate streams
/// - Consistent state: All widgets see the same data
/// - Easy invalidation: ref.invalidate(hubStreamProvider(hubId))
///
/// Usage:
/// ```dart
/// final hubAsync = ref.watch(hubStreamProvider(hubId));
/// return hubAsync.when(
///   data: (hub) => hub != null ? HubContent(hub) : NotFound(),
///   loading: () => LoadingIndicator(),
///   error: (err, stack) => ErrorDisplay(err),
/// );
/// ```
@riverpod
Stream<Hub?> hubStream(HubStreamRef ref, String hubId) {
  ref.keepAlive(); // Cache across navigation
  final hubsRepo = ref.watch(hubsRepositoryProvider);
  return hubsRepo.watchHub(hubId);
}

/// Hub permissions provider - computes effective permissions for a user in a hub
///
/// This provider automatically watches hub state and membership, recomputing
/// permissions when either changes.
///
/// Usage:
/// ```dart
/// final permissions = await ref.watch(hubPermissionsStreamProvider((hubId: hubId, userId: userId)).future);
/// if (permissions.canCreateGames) { ... }
/// ```
@riverpod
Stream<HubPermissions?> hubPermissionsStream(
  HubPermissionsStreamRef ref,
  ({String hubId, String userId}) params,
) async* {
  // Get repository and service
  final hubsRepo = ref.read(hubsRepositoryProvider);
  final permissionsService = ref.read(hubPermissionsServiceProvider);

  // Watch hub changes
  final hubStream = hubsRepo.watchHub(params.hubId);

  await for (final hub in hubStream) {
    if (hub == null) {
      yield null;
      continue;
    }

    // Fetch membership (could be cached by repository)
    final membership = await hubsRepo.getMembership(params.hubId, params.userId);

    // Compute permissions using service
    yield permissionsService.createPermissions(hub, membership, params.userId);
  }
}

/// Hub role stream provider - derives user's role in a hub
///
/// Convenience provider that extracts just the role from permissions.
///
/// Usage:
/// ```dart
/// final role = ref.watch(hubRoleStreamProvider((hubId: hubId, userId: userId)));
/// ```
@riverpod
Stream<HubMemberRole?> hubRoleStream(
  HubRoleStreamRef ref,
  ({String hubId, String userId}) params,
) async* {
  // Get the hub permissions stream
  final hubsRepo = ref.read(hubsRepositoryProvider);
  final permissionsService = ref.read(hubPermissionsServiceProvider);
  final hubStream = hubsRepo.watchHub(params.hubId);

  await for (final hub in hubStream) {
    if (hub == null) {
      yield null;
      continue;
    }

    final membership = await hubsRepo.getMembership(params.hubId, params.userId);
    final permissions = permissionsService.createPermissions(hub, membership, params.userId);
    yield permissions.effectiveRole;
  }
}

// ============================================================================
// HUB MEMBERS PAGINATION PROVIDER
// ============================================================================

/// Paginated hub members provider - replaces manual pagination state
///
/// Automatically fetches members in pages, maintains state across rebuilds,
/// and provides loading indicators for infinite scroll.
///
/// Usage:
/// ```dart
/// final membersAsync = ref.watch(paginatedHubMembersProvider(
///   (hubId: hubId, page: currentPage, pageSize: 20)
/// ));
/// ```
@riverpod
Future<List<User>> paginatedHubMembers(
  PaginatedHubMembersRef ref,
  ({String hubId, int page, int pageSize}) params,
) async {
  final hubsRepo = ref.watch(hubsRepositoryProvider);
  final usersRepo = ref.watch(usersRepositoryProvider);

  // Fetch all member IDs from subcollection
  final memberIds = await hubsRepo.getHubMemberIds(params.hubId);

  // Calculate pagination bounds
  final startIndex = params.page * params.pageSize;
  final endIndex = (startIndex + params.pageSize).clamp(0, memberIds.length);

  if (startIndex >= memberIds.length) {
    return []; // No more data
  }

  // Fetch only the users for this page
  final pageIds = memberIds.sublist(startIndex, endIndex);
  return usersRepo.getUsers(pageIds);
}

/// Total hub members count provider
@riverpod
Future<int> hubMembersCount(HubMembersCountRef ref, String hubId) async {
  final hubsRepo = ref.watch(hubsRepositoryProvider);
  final memberIds = await hubsRepo.getHubMemberIds(hubId);
  return memberIds.length;
}

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

/// Leaderboard provider - watches top ranked users
@riverpod
Future<List<LeaderboardEntry>> leaderboard(
  LeaderboardRef ref,
  LeaderboardParams params,
) async {
  final leaderboardRepo = ref.watch(leaderboardRepositoryProvider);
  return leaderboardRepo.getLeaderboard(
    type: params.type,
    hubId: params.hubId,
    period: params.period,
    limit: params.limit,
  );
}

/// Unread notifications count provider
@riverpod
Stream<int> unreadNotificationsCount(
  UnreadNotificationsCountRef ref,
  String userId,
) {
  ref.keepAlive(); // Prevent disposal during navigation
  final notificationsRepo = ref.watch(notificationsRepositoryProvider);
  return notificationsRepo.watchUnreadCount(userId);
}

/// Hubs by creator stream provider with keepAlive for performance
@riverpod
Stream<List<Hub>> hubsByCreator(
  HubsByCreatorRef ref,
  String uid,
) {
  ref.keepAlive(); // Prevent disposal and reduce rebuilds
  final hubsRepo = ref.watch(hubsRepositoryProvider);
  return hubsRepo.watchHubsByCreator(uid);
}

/// Home dashboard data provider (weather & vibe) - using Open-Meteo (free)
@riverpod
Future<Map<String, dynamic>> homeDashboardData(HomeDashboardDataRef ref) async {
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
}

/// Hub permissions provider - provides HubPermissions for a user in a hub
/// Usage: ref.watch(hubPermissionsProvider((hubId: 'xxx', userId: 'yyy')))
@riverpod
Future<HubPermissions> hubPermissions(
  HubPermissionsRef ref,
  ({String hubId, String userId}) params,
) async {
  try {
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final hub = await hubsRepo.getHub(params.hubId);

    if (hub == null) {
      throw Exception('Hub not found');
    }

    final permissionsService = HubPermissionsService(
      hubsRepo: ref.read(hubsRepositoryProvider),
    );
    return permissionsService.getPermissions(hub, params.userId);
  } catch (e) {
    rethrow;
  }
}

/// Returns UserRole.admin if user is the hub creator or has manager/moderator role
/// Returns UserRole.member if user is a member of the hub
/// Returns UserRole.none if user is not a member
@riverpod
Future<UserRole> hubRole(HubRoleRef ref, String hubId) async {
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
}

/// Admin tasks provider - counts games that need to be closed
///
/// Returns the number of games that:
/// - User is admin of (hub manager)
/// - Status is 'teamsFormed' or 'inProgress'
/// - gameDate is in the past
@riverpod
Stream<int> adminTasks(AdminTasksRef ref) {
  try {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      return Stream.value(0);
    }

    final hubsRepo = ref.read(hubsRepositoryProvider);
    final gameQueriesRepo = ref.read(gameQueriesRepositoryProvider);
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
          final games = await gameQueriesRepo.listGamesByHub(hubId);

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
}

