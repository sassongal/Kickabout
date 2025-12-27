import 'package:kattrick/features/profile/data/repositories/users_repository.dart';
import 'package:kattrick/features/hubs/data/repositories/hubs_repository.dart';
import 'package:kattrick/models/models.dart';
import 'package:flutter/foundation.dart';

/// Service for merging fictitious players with real user accounts
///
/// When a real user signs up with a phone number that matches a fictitious
/// player, this service:
/// 1. Finds all fictitious users with matching phone
/// 2. For each fictitious user, transfers their hub memberships to real user
/// 3. Preserves their ratings and membership data
/// 4. Deletes the fictitious user document
class PlayerMergeService {
  final UsersRepository _usersRepo;
  final HubsRepository _hubsRepo;

  PlayerMergeService({
    required UsersRepository usersRepo,
    required HubsRepository hubsRepo,
  })  : _usersRepo = usersRepo,
        _hubsRepo = hubsRepo;

  /// Check and merge fictitious players when user signs up
  ///
  /// Should be called after user registration with phone number.
  /// This is a background operation that doesn't block registration.
  Future<MergeResult> checkAndMergeFictitiousPlayers({
    required String realUserId,
    required String phoneNumber,
  }) async {
    if (phoneNumber.trim().isEmpty) {
      return MergeResult(merged: false, count: 0);
    }

    try {
      debugPrint('🔍 Checking for fictitious players with phone: $phoneNumber');

      // 1. Find all fictitious users with this phone number
      final fictitiousUsers = await _usersRepo.getUsersByPhone(
        phoneNumber.trim(),
        fictitiousOnly: true,
      );

      if (fictitiousUsers.isEmpty) {
        debugPrint('✅ No fictitious players found');
        return MergeResult(merged: false, count: 0);
      }

      debugPrint(
          '🎯 Found ${fictitiousUsers.length} fictitious player(s) to merge');

      int mergedCount = 0;

      // 2. For each fictitious user, merge their data
      for (final fictitiousUser in fictitiousUsers) {
        try {
          await _mergeFictitiousPlayer(
            realUserId: realUserId,
            fictitiousUser: fictitiousUser,
          );
          mergedCount++;
        } catch (e) {
          debugPrint(
              '❌ Error merging fictitious player ${fictitiousUser.uid}: $e');
          // Continue with other merges
        }
      }

      debugPrint('✅ Merged $mergedCount fictitious player(s)');
      return MergeResult(merged: true, count: mergedCount);
    } catch (e, stackTrace) {
      debugPrint('❌ Error in checkAndMergeFictitiousPlayers: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't throw - merge is not critical for registration
      return MergeResult(merged: false, count: 0, error: e.toString());
    }
  }

  /// Merge a single fictitious player into real user
  Future<void> _mergeFictitiousPlayer({
    required String realUserId,
    required User fictitiousUser,
  }) async {
    debugPrint(
        '🔄 Merging fictitious player ${fictitiousUser.name} (${fictitiousUser.uid})');

    // 1. Get all hub memberships for fictitious user
    final memberships = await _hubsRepo.getUserMemberships(fictitiousUser.uid);

    // 2. For each hub membership, transfer to real user
    for (final membership in memberships) {
      try {
        // Check if real user is already a member
        final existingMembership = await _hubsRepo.getMembership(
          membership.hubId,
          realUserId,
        );

        if (existingMembership != null) {
          // Real user already member - just preserve the higher rating
          if (membership.managerRating > existingMembership.managerRating) {
            await _hubsRepo.setPlayerRating(
              membership.hubId,
              realUserId,
              membership.managerRating,
            );
          }
        } else {
          // Transfer membership to real user
          await _hubsRepo.transferMembership(
            fromUserId: fictitiousUser.uid,
            toUserId: realUserId,
            hubId: membership.hubId,
            preserveRating: true,
          );
        }
      } catch (e) {
        debugPrint(
            '❌ Error transferring membership for hub ${membership.hubId}: $e');
        // Continue with other hubs
      }
    }

    // 3. Delete fictitious user document
    await _usersRepo.deleteUser(fictitiousUser.uid);

    debugPrint('✅ Fictitious player merged and deleted');
  }
}

/// Result of merge operation
class MergeResult {
  final bool merged;
  final int count;
  final String? error;

  MergeResult({
    required this.merged,
    required this.count,
    this.error,
  });
}
