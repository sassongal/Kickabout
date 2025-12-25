import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/services/cache_invalidation_service.dart';
import 'package:kattrick/features/hubs/data/repositories/hubs_repository.dart';
import 'package:kattrick/features/hubs/domain/services/hub_permissions_service.dart';
import 'package:kattrick/data/games_repository.dart';
import 'package:kattrick/features/games/data/repositories/session_repository.dart';

/// Repository for Match Approval workflow
/// Handles submitting, approving, and rejecting match results
class MatchApprovalRepository {
  final FirebaseFirestore _firestore;
  final CacheInvalidationService _cacheInvalidation;
  final GamesRepository _gamesRepo;
  final SessionRepository _sessionRepo;

  MatchApprovalRepository({
    FirebaseFirestore? firestore,
    CacheInvalidationService? cacheInvalidation,
    GamesRepository? gamesRepo,
    SessionRepository? sessionRepo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheInvalidation = cacheInvalidation ?? CacheInvalidationService(),
        _gamesRepo = gamesRepo ?? GamesRepository(),
        _sessionRepo = sessionRepo ?? SessionRepository();

  /// Submit a match result with optional moderator approval workflow
  ///
  /// If requiresApproval=true, match is marked as pending and awaits manager approval.
  /// If requiresApproval=false, match is immediately approved.
  Future<void> submitMatchResult(
    String gameId,
    MatchResult match, {
    required String submitterId,
    bool requiresApproval = false,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Set approval status based on workflow
      final matchToSubmit = requiresApproval
          ? match.copyWith(
              approvalStatus: MatchApprovalStatus.pending,
              loggedBy: submitterId,
            )
          : match.copyWith(
              approvalStatus: MatchApprovalStatus.approved,
              loggedBy: submitterId,
              approvedBy: submitterId,
              approvedAt: DateTime.now(),
            );

      // Use existing addMatchToSession logic
      await _sessionRepo.addMatchToSession(gameId, matchToSubmit, submitterId);

      debugPrint(
          '✅ Match submitted: ${match.matchId}, approval=${requiresApproval ? "pending" : "approved"}');
    } catch (e) {
      debugPrint('❌ Failed to submit match result: $e');
      throw Exception('Failed to submit match result: $e');
    }
  }

  /// Manager approves a pending match
  ///
  /// Updates approvalStatus from pending → approved.
  /// Only hub managers can approve matches.
  Future<void> approveMatch(
    String gameId,
    String matchId,
    String managerId,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Verify game exists and user has permission
      final game = await _gamesRepo.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: managerId);
        if (!hubPermissions.isManager) {
          throw Exception(
              'Unauthorized: Only Hub Managers can approve matches');
        }
      } else {
        throw Exception('Only hub sessions support moderator approval');
      }

      // Find and update the match
      await _firestore.runTransaction((transaction) async {
        final gameRef = _firestore.doc(FirestorePaths.game(gameId));
        final gameDoc = await transaction.get(gameRef);

        if (!gameDoc.exists) {
          throw Exception('Game not found');
        }

        final currentGame =
            Game.fromJson({...gameDoc.data()!, 'gameId': gameId});
        final matches = List<MatchResult>.from(currentGame.session.matches);

        // Find the match to approve
        final matchIndex = matches.indexWhere((m) => m.matchId == matchId);
        if (matchIndex == -1) {
          throw Exception('Match not found: $matchId');
        }

        final match = matches[matchIndex];
        if (match.approvalStatus != MatchApprovalStatus.pending) {
          throw Exception('Match is not pending approval');
        }

        // Update match with approval
        matches[matchIndex] = match.copyWith(
          approvalStatus: MatchApprovalStatus.approved,
          approvedBy: managerId,
          approvedAt: DateTime.now(),
        );

        // Update game document
        final matchesJson = matches.map((m) => m.toJson()).toList();
        transaction.update(gameRef, {
          'session.matches': matchesJson,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Invalidate caches
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint('✅ Match approved: $matchId by $managerId');
    } catch (e) {
      debugPrint('❌ Failed to approve match: $e');
      throw Exception('Failed to approve match: $e');
    }
  }

  /// Manager rejects a pending match
  ///
  /// Updates approvalStatus from pending → rejected with reason.
  /// Only hub managers can reject matches.
  Future<void> rejectMatch(
    String gameId,
    String matchId,
    String managerId,
    String reason,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Verify game exists and user has permission
      final game = await _gamesRepo.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found: $gameId');
      }

      // Verify permissions
      if (game.hubId != null) {
        final hubsRepo = HubsRepository();
        final hub = await hubsRepo.getHub(game.hubId!);
        if (hub == null) {
          throw Exception('Hub not found: ${game.hubId}');
        }

        final hubPermissions = HubPermissions(hub: hub, userId: managerId);
        if (!hubPermissions.isManager) {
          throw Exception(
              'Unauthorized: Only Hub Managers can reject matches');
        }
      } else {
        throw Exception('Only hub sessions support moderator approval');
      }

      // Find and update the match
      await _firestore.runTransaction((transaction) async {
        final gameRef = _firestore.doc(FirestorePaths.game(gameId));
        final gameDoc = await transaction.get(gameRef);

        if (!gameDoc.exists) {
          throw Exception('Game not found');
        }

        final currentGame =
            Game.fromJson({...gameDoc.data()!, 'gameId': gameId});
        final matches = List<MatchResult>.from(currentGame.session.matches);

        // Find the match to reject
        final matchIndex = matches.indexWhere((m) => m.matchId == matchId);
        if (matchIndex == -1) {
          throw Exception('Match not found: $matchId');
        }

        final match = matches[matchIndex];
        if (match.approvalStatus != MatchApprovalStatus.pending) {
          throw Exception('Match is not pending approval');
        }

        // Update match with rejection
        matches[matchIndex] = match.copyWith(
          approvalStatus: MatchApprovalStatus.rejected,
          approvedBy: managerId,
          approvedAt: DateTime.now(),
          rejectionReason: reason,
        );

        // Update game document
        final matchesJson = matches.map((m) => m.toJson()).toList();
        transaction.update(gameRef, {
          'session.matches': matchesJson,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Invalidate caches
      _cacheInvalidation.onGameUpdated(gameId, hubId: game.hubId);

      debugPrint('✅ Match rejected: $matchId by $managerId');
    } catch (e) {
      debugPrint('❌ Failed to reject match: $e');
      throw Exception('Failed to reject match: $e');
    }
  }

  /// Stream pending matches awaiting approval
  ///
  /// Returns only matches with approvalStatus=pending
  Stream<List<MatchResult>> watchPendingMatches(String gameId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _gamesRepo.watchGame(gameId).map((game) {
      if (game == null) return [];

      return game.session.matches
          .where((match) => match.approvalStatus == MatchApprovalStatus.pending)
          .toList();
    });
  }
}

