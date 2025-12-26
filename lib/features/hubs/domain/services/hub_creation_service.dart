import 'package:kattrick/config/env.dart';
import 'package:kattrick/features/hubs/data/repositories/hubs_repository.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/error_handler_service.dart';

/// Service for Hub creation business logic
///
/// Handles:
/// - Validation (creation limits)
/// - Business logic (denormalized fields initialization)
/// - Orchestration (hub creation + member addition + user update)
///
/// ARCHITECTURE: Services use Repositories for data access, not Firestore directly
class HubCreationService {
  final HubsRepository _hubsRepo;

  HubCreationService({
    HubsRepository? hubsRepo,
  })  : _hubsRepo = hubsRepo ?? HubsRepository();

  /// Create a new hub with all business logic
  /// 
  /// This orchestrates:
  /// 1. Validation (creation limits)
  /// 2. Hub creation with denormalized fields
  /// 3. Adding creator as manager member
  /// 4. Updating user's hubIds
  /// 5. Syncing denormalized arrays
  /// 6. Cache invalidation
  Future<String> createHub(Hub hub) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // BUSINESS LOGIC: Validation
      final checkResult = await _hubsRepo.canCreateHub(hub.createdBy);
      if (!checkResult.canCreate) {
        if (checkResult.reason == HubCreationLimitReason.limitReached) {
          throw HubCreationLimitException(
            message: checkResult.message ??
                'הגעת למגבלת יצירת הובים (${checkResult.maxCount}). '
                    'אפשר לעזוב או להעביר בעלות על הוב קיים כדי ליצור חדש.',
            currentCount: checkResult.currentCount ?? 0,
            maxCount: checkResult.maxCount ?? 3,
          );
        } else {
          throw Exception(checkResult.message ??
              'לא ניתן לבדוק את מגבלת יצירת הובים. נסה שוב בעוד רגע.');
        }
      }

      // BUSINESS LOGIC: Generate hub ID
      final hubId = hub.hubId.isNotEmpty ? hub.hubId : _hubsRepo.generateHubId();

      // BUSINESS LOGIC: Initialize denormalized fields
      final hubData = hub.toJson();

      // CRITICAL: Ensure createdBy is explicitly set (required for Firestore rules)
      hubData['hubId'] = hubId;
      hubData['createdBy'] = hub.createdBy; // Explicitly set for security rules
      hubData['memberCount'] = 1;
      hubData['activeMemberIds'] = [hub.createdBy];
      hubData['memberIds'] = [hub.createdBy];
      hubData['managerIds'] = [hub.createdBy];
      hubData['moderatorIds'] = <String>[];

      // Remove legacy 'roles' field
      hubData.remove('roles');

      // DATA ACCESS: Use repository to create hub with member atomically
      await _hubsRepo.createHubWithMemberBatch(
        hubData: hubData,
        hubId: hubId,
        creatorId: hub.createdBy,
      );

      // ARCHITECTURAL NOTE: Cloud Function handles denormalized array sync automatically
      // The onMembershipChange trigger fires when the HubMember document is created,
      // syncing activeMemberIds, managerIds, moderatorIds atomically.
      //
      // Note: The Cloud Function runs asynchronously. For immediate reads after creation,
      // the client should rely on the creator's implicit manager permissions rather than
      // the denormalized arrays (which update within ~500ms).

      return hubId;
    } on HubCreationLimitException {
      rethrow;
    } catch (e, stackTrace) {
      ErrorHandlerService().logError(
        e,
        stackTrace: stackTrace,
        reason: 'Failed to create hub',
      );
      throw Exception('Failed to create hub: $e');
    }
  }
}

