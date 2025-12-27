import 'package:kattrick/features/hubs/data/repositories/hubs_repository.dart';
import 'package:kattrick/features/games/data/repositories/game_queries_repository.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/hubs/domain/models/hub_role.dart';

/// Service for calculating admin task counts
///
/// Extracts business logic from adminTasks provider to follow
/// domain service pattern. Providers should only handle state management.
class AdminTaskService {
  final HubsRepository _hubsRepo;
  final GameQueriesRepository _gameQueriesRepo;

  AdminTaskService({
    required HubsRepository hubsRepo,
    required GameQueriesRepository gameQueriesRepo,
  })  : _hubsRepo = hubsRepo,
        _gameQueriesRepo = gameQueriesRepo;

  /// Get count of stuck games that need manager attention
  ///
  /// A game is "stuck" if:
  /// - Status is teamsFormed or inProgress
  /// - Game date is in the past
  ///
  /// Returns total count across all hubs where user is admin.
  Future<int> getAdminTasksCount(String userId) async {
    try {
      // Get all hubs where user is admin
      final adminHubIds = await getAdminHubIds(userId);

      if (adminHubIds.isEmpty) return 0;

      // Query games for each hub
      int totalStuckGames = 0;
      final now = DateTime.now();

      for (final hubId in adminHubIds) {
        try {
          final stuckGames = await getStuckGames(hubId);

          // Filter by past date (games in future aren't stuck yet)
          final pastStuckGames = stuckGames.where((game) {
            return game.gameDate.isBefore(now);
          });

          totalStuckGames += pastStuckGames.length;
        } catch (e) {
          // Skip this hub if error
          continue;
        }
      }

      return totalStuckGames;
    } catch (e) {
      return 0;
    }
  }

  /// Get list of hub IDs where user is admin (creator, manager, or moderator)
  ///
  /// Checks:
  /// 1. If user is hub creator
  /// 2. If user role is manager or moderator
  Future<Set<String>> getAdminHubIds(String userId) async {
    final adminHubIds = <String>{};

    try {
      // Get hubs where user is member
      final userHubs = await _hubsRepo.getHubsByMember(userId);

      for (final hub in userHubs) {
        // Check if user is creator
        if (hub.createdBy == userId) {
          adminHubIds.add(hub.hubId);
          continue;
        }

        // Check if user is manager or moderator
        try {
          final roleString = await _hubsRepo.getUserRole(hub.hubId, userId);
          if (roleString != null) {
            final hubRole = HubRole.fromFirestore(roleString);
            if (hubRole == HubRole.manager || hubRole == HubRole.moderator) {
              adminHubIds.add(hub.hubId);
            }
          }
        } catch (e) {
          // Skip role check if error
          continue;
        }
      }
    } catch (e) {
      // Return empty set if error
    }

    return adminHubIds;
  }

  /// Get stuck games for a hub
  ///
  /// A game is stuck if status is teamsFormed or inProgress.
  /// Note: Date filtering should be done by caller.
  Future<List<Game>> getStuckGames(String hubId) async {
    try {
      // Get all games for this hub
      final games = await _gameQueriesRepo.listGamesByHub(hubId);

      // Filter stuck games
      return games.where((game) {
        return game.status == GameStatus.teamsFormed ||
            game.status == GameStatus.inProgress;
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
