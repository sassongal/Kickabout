import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/features/hubs/data/repositories/hubs_repository.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/cache_service.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/services/firestore_paths.dart';

/// Service for Hub creation business logic
/// 
/// Handles:
/// - Validation (creation limits)
/// - Business logic (denormalized fields initialization)
/// - Orchestration (hub creation + member addition + user update)
/// 
/// Repository only handles pure data access
class HubCreationService {
  final HubsRepository _hubsRepo;
  final FirebaseFirestore _firestore;

  HubCreationService({
    HubsRepository? hubsRepo,
    FirebaseFirestore? firestore,
  })  : _hubsRepo = hubsRepo ?? HubsRepository(),
        _firestore = firestore ?? FirebaseFirestore.instance;

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

      // BUSINESS LOGIC: Initialize denormalized fields
      final hubData = hub.toJson();
      final docRef = hub.hubId.isNotEmpty
          ? _firestore.doc(FirestorePaths.hub(hub.hubId))
          : _firestore.collection(FirestorePaths.hubs()).doc();
      
      // CRITICAL: Ensure createdBy is explicitly set (required for Firestore rules)
      hubData['hubId'] = docRef.id;
      hubData['createdBy'] = hub.createdBy; // Explicitly set for security rules
      hubData['memberCount'] = 1;
      hubData['activeMemberIds'] = [hub.createdBy];
      hubData['memberIds'] = [hub.createdBy];
      hubData['managerIds'] = [hub.createdBy];
      hubData['moderatorIds'] = <String>[];

      // Remove legacy 'roles' field
      hubData.remove('roles');

      // ORCHESTRATION: Batch write hub + member + user update
      final batch = _firestore.batch();

      // Create hub document
      batch.set(docRef, hubData, SetOptions(merge: false));

      // BUSINESS LOGIC: Add creator as manager member
      final memberRef = docRef.collection('members').doc(hub.createdBy);
      batch.set(memberRef, {
        'hubId': docRef.id,
        'userId': hub.createdBy,
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'manager',
        'status': 'active',
        'veteranSince': null,
        'managerRating': 0.0,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': hub.createdBy,
        'statusReason': null,
      });

      // ORCHESTRATION: Update user's hubIds
      final userRef = _firestore.doc(FirestorePaths.user(hub.createdBy));
      final userDoc = await userRef.get();
      final userData = userDoc.data();
      final userHubIds = List<String>.from(userData?['hubIds'] ?? []);

      if (!userHubIds.contains(docRef.id)) {
        batch.update(userRef, {
          'hubIds': FieldValue.arrayUnion([docRef.id]),
        });
      }

      await batch.commit();

      // ARCHITECTURAL FIX: Cloud Function now handles denormalized array sync automatically
      // The onMembershipChange trigger fires when the HubMember document is created,
      // syncing activeMemberIds, managerIds, moderatorIds atomically.
      //
      // REMOVED: await _hubsRepo.syncDenormalizedMemberArrays(docRef.id);
      // REMOVED: await Future.delayed(const Duration(milliseconds: 100));
      //
      // Note: The Cloud Function runs asynchronously. For immediate reads after creation,
      // the client should rely on the creator's implicit manager permissions rather than
      // the denormalized arrays (which update within ~500ms).

      // Infrastructure: Invalidate cache
      CacheService().clear(CacheKeys.hub(docRef.id));

      return docRef.id;
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

