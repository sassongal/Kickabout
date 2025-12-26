# Phase 4 Implementation Guide: Repository Split

**Status**: Ready to Start
**Estimated Effort**: 5-7 days
**Risk Level**: Medium (Large refactor, but interfaces remain similar)

---

## Overview

Split the monolithic `HubsRepository` (1680 lines) into focused repositories aligned with aggregate boundaries.

**Current**: One god object handling 5 different concerns
**Target**: 4 focused repositories with clear responsibilities

---

## Repository Analysis

### Current HubsRepository Breakdown

**File**: [hubs_repository.dart](../lib/features/hubs/data/repositories/hubs_repository.dart) (1680 lines)

1. **Hub CRUD** (~200 lines) → ✅ **KEEP in HubsRepository**
   - `createHub()`, `getHub()`, `updateHub()`, `deleteHub()`
   - Core hub entity operations

2. **Membership Management** (~400 lines) → ✅ **KEEP in HubsRepository**
   - `addMember()`, `removeMember()`, `updateMemberRole()`, `banMember()`
   - Core to hub aggregate (members are part of hub identity)

3. **Venue Associations** (~200 lines) → 🔄 **EXTRACT to HubVenuesRepository**
   - Lines 1202-1310
   - Methods: 2 (setHubPrimaryVenue, unlinkVenueFromHub)
   - Reason: Venues are a separate aggregate, weakly associated with hubs

4. **Join Requests** (~200 lines) → 🔄 **EXTRACT to HubJoinRequestsRepository**
   - Lines 1636-1680
   - Methods: 2 (watchPendingJoinRequestsCount, watchPendingJoinRequests)
   - Reason: Join requests are a separate workflow, not core hub data

5. **Contact Messages** (~200 lines) → 🔄 **EXTRACT to HubContactRepository**
   - Lines 1373-1520
   - Methods: 4 (streamContactMessages, sendContactMessage, checkExistingContactMessage, updateContactMessageStatus)
   - Reason: Contact messages are a separate communication channel

---

## Step-by-Step Implementation

### Step 1: Create HubVenuesRepository (Easiest)

**New File**: `lib/features/hubs/data/repositories/hub_venues_repository.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/utils/firestore_paths.dart';

/// Repository for hub-venue associations
///
/// Handles venue relationships without mixing core hub logic.
class HubVenuesRepository {
  final FirebaseFirestore _firestore;

  HubVenuesRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Set primary venue for a hub (for map display)
  Future<void> setPrimaryVenue(String hubId, String venueId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    await _firestore.doc(FirestorePaths.hub(hubId)).update({
      'primaryVenueId': venueId,
      'primaryVenueLocation': FieldValue.delete(), // Use venue's location
    });
  }

  /// Set main venue for a hub (home field)
  Future<void> setMainVenue(String hubId, String venueId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    await _firestore.doc(FirestorePaths.hub(hubId)).update({
      'mainVenueId': venueId,
    });
  }

  /// Unlink a venue from a hub
  Future<void> unlinkVenueFromHub(String hubId, String venueId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    await _firestore.doc(FirestorePaths.hub(hubId)).update({
      'venueIds': FieldValue.arrayRemove([venueId]),
    });
  }

  /// Get all venue IDs associated with a hub
  Future<List<String>> getHubVenueIds(String hubId) async {
    if (!Env.isFirebaseAvailable) return [];

    final doc = await _firestore.doc(FirestorePaths.hub(hubId)).get();
    final data = doc.data();
    if (data == null) return [];

    return List<String>.from(data['venueIds'] ?? []);
  }
}
```

**Provider**: Add to `repositories_providers.dart`

```dart
@riverpod
HubVenuesRepository hubVenuesRepository(HubVenuesRepositoryRef ref) {
  final firestore = ref.watch(firestoreProvider);
  return HubVenuesRepository(firestore: firestore);
}
```

**Migration Tasks**:
1. ✅ Copy methods from HubsRepository lines 1202-1310
2. ✅ Create provider
3. ✅ Find all usages: `grep -r "setPrimaryVenue\|setMainVenue\|unlinkVenueFromHub" lib/`
4. ✅ Update callers to use `hubVenuesRepositoryProvider`
5. ✅ Delete methods from HubsRepository
6. ✅ Run tests

**Affected Files** (estimated 3-5 files):
- Venue selector widgets
- Hub settings screens

---

### Step 2: Create HubJoinRequestsRepository (Medium)

**New File**: `lib/features/hubs/data/repositories/hub_join_requests_repository.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/config/env.dart';

/// Repository for hub join request management
///
/// Handles the join approval workflow separately from core hub operations.
class HubJoinRequestsRepository {
  final FirebaseFirestore _firestore;

  HubJoinRequestsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Create a new join request
  Future<String> createJoinRequest({
    required String hubId,
    required String userId,
    String? message,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    final ref = _firestore
        .collection('hubs/$hubId/joinRequests')
        .doc();

    await ref.set({
      'userId': userId,
      'status': 'pending',
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  /// Approve a join request
  Future<void> approveJoinRequest(String hubId, String requestId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    await _firestore
        .doc('hubs/$hubId/joinRequests/$requestId')
        .update({'status': 'approved'});
  }

  /// Reject a join request
  Future<void> rejectJoinRequest(String hubId, String requestId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    await _firestore
        .doc('hubs/$hubId/joinRequests/$requestId')
        .update({'status': 'rejected'});
  }

  /// Watch pending join requests count
  Stream<int> watchPendingCount(String hubId) {
    if (!Env.isFirebaseAvailable) return Stream.value(0);

    return _firestore
        .collection('hubs/$hubId/joinRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Watch pending join requests
  Stream<QuerySnapshot> watchPendingRequests(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(
        _firestore.collection('hubs/$hubId/joinRequests').snapshots() as QuerySnapshot,
      );
    }

    return _firestore
        .collection('hubs/$hubId/joinRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
```

**Migration Tasks**:
1. ✅ Copy methods from HubsRepository lines 1636-1680
2. ✅ Create provider
3. ✅ Find usages: `grep -r "watchPendingJoinRequests\|createJoinRequest\|approveJoinRequest" lib/`
4. ✅ Update callers
5. ✅ Delete from HubsRepository
6. ✅ Run tests

**Affected Files** (estimated 2-3 files):
- Join request approval screens
- Hub admin dashboards

---

### Step 3: Create HubContactRepository (Medium)

**New File**: `lib/features/hubs/data/repositories/hub_contact_repository.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/contact_message.dart';

/// Repository for hub contact message management
///
/// Handles user-to-hub communication separately from core hub operations.
class HubContactRepository {
  final FirebaseFirestore _firestore;

  HubContactRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Send a contact message to hub managers
  Future<void> sendContactMessage({
    required String hubId,
    required String senderId,
    required String message,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    await _firestore
        .collection('hubs/$hubId/contactMessages')
        .add({
      'senderId': senderId,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark a contact message as read
  Future<void> markMessageAsRead(String hubId, String messageId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    await _firestore
        .doc('hubs/$hubId/contactMessages/$messageId')
        .update({'isRead': true});
  }

  /// Update contact message status
  Future<void> updateMessageStatus({
    required String hubId,
    required String messageId,
    required String status,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    await _firestore
        .doc('hubs/$hubId/contactMessages/$messageId')
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check for existing contact message from user
  Future<ContactMessage?> checkExistingMessage(
    String hubId,
    String senderId,
  ) async {
    if (!Env.isFirebaseAvailable) return null;

    final snapshot = await _firestore
        .collection('hubs/$hubId/contactMessages')
        .where('senderId', isEqualTo: senderId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return ContactMessage.fromJson({
      'id': snapshot.docs.first.id,
      ...snapshot.docs.first.data(),
    });
  }

  /// Stream unread contact messages (for hub managers)
  Stream<List<ContactMessage>> streamContactMessages(String hubId) {
    if (!Env.isFirebaseAvailable) return Stream.value([]);

    return _firestore
        .collection('hubs/$hubId/contactMessages')
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContactMessage.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }
}
```

**Migration Tasks**:
1. ✅ Copy methods from HubsRepository lines 1373-1520
2. ✅ Create provider
3. ✅ Find usages: `grep -r "sendContactMessage\|streamContactMessages\|checkExistingContactMessage" lib/`
4. ✅ Update callers
5. ✅ Delete from HubsRepository
6. ✅ Run tests

**Affected Files** (estimated 3-4 files):
- Contact hub screens
- Hub manager notification screens

---

### Step 4: Clean Up HubsRepository

After extracting all three repositories:

1. **Delete extracted methods** from HubsRepository
2. **Verify line count**: Should drop from 1680 → ~900 lines
3. **Update documentation**: Add comments explaining the split
4. **Run full test suite**

---

## Testing Strategy

### Unit Tests (Create New)
- `hub_venues_repository_test.dart`
- `hub_join_requests_repository_test.dart`
- `hub_contact_repository_test.dart`

### Integration Tests
- Verify all screens still work
- Test venue selection flows
- Test join request workflows
- Test contact message sending

### Manual Testing Checklist
- [ ] Hub settings screen → venue selection
- [ ] Join hub flow → request approval
- [ ] Contact hub → message sending
- [ ] Hub admin → view join requests
- [ ] Hub admin → view contact messages

---

## Risk Mitigation

### High Risk Areas
1. **Firestore path changes**: Triple-check collection paths match exactly
2. **Provider dependencies**: Ensure all providers are registered
3. **Breaking changes**: Search for all usages before deleting methods

### Rollback Plan
- Keep feature branch
- Tag commit before Phase 4 starts
- Can revert entire phase if needed

---

## Success Metrics

| Metric | Before | Target | Verification |
|--------|--------|--------|--------------|
| HubsRepository Lines | 1680 | ~900 | `wc -l hubs_repository.dart` |
| Repository Count | 1 | 4 | Count files in repositories/ |
| Average Repository Size | 1680 | ~450 | Calculate average |
| Method Count per Repo | 50+ | 10-15 | Count methods |

---

## Timeline Estimate

- **Day 1**: Create HubVenuesRepository, migrate callers, test (3-4 hours)
- **Day 2**: Create HubJoinRequestsRepository, migrate callers, test (4-5 hours)
- **Day 3**: Create HubContactRepository, migrate callers, test (4-5 hours)
- **Day 4**: Clean up HubsRepository, documentation (2-3 hours)
- **Day 5**: Full testing and validation (4-6 hours)

**Total**: 5 days (buffer included)

---

## Related Documentation

- Main Plan: `/Users/galsasson/.claude/plans/partitioned-growing-bear.md`
- Progress Tracker: [REFACTORING_PROGRESS.md](../REFACTORING_PROGRESS.md)
- Architecture Grade: Current 8.2/10 → Target 8.5/10 after Phase 4
