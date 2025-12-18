/// Migration Script: Hub Membership Refactor
///
/// This script migrates the old Hub god-object design to the new membership-first architecture.
///
/// OLD STRUCTURE (God-Object):
/// /hubs/{hubId}
///   - memberJoinDates: Map<userId, timestamp>
///   - roles: Map<userId, role>
///   - managerRatings: Map<userId, rating>
///   - bannedUserIds: List<userId>
///
/// NEW STRUCTURE (Membership-First):
/// /hubs/{hubId}/members/{userId}
///   - joinedAt: timestamp
///   - role: string
///   - status: string (active/left/banned)
///   - managerRating: number
///   - veteranSince: timestamp?
///
/// SAFETY:
/// - Supports dry-run mode
/// - Validates against user.hubIds
/// - Handles missing data gracefully
/// - Batched writes for performance
/// - Detailed logging
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Migration statistics
class MigrationStats {
  int hubsProcessed = 0;
  int membersCreated = 0;
  int hubsSkipped = 0;
  int errors = 0;
  Map<String, int> statusCounts = {
    'active': 0,
    'left': 0,
    'banned': 0,
  };
  Map<String, int> roleCounts = {
    'manager': 0,
    'moderator': 0,
    'member': 0,
  };

  @override
  String toString() {
    return '''
Migration Statistics:
  Hubs Processed: $hubsProcessed
  Hubs Skipped: $hubsSkipped
  Members Created: $membersCreated
  Errors: $errors
  
  Status Distribution:
    Active: ${statusCounts['active']}
    Left: ${statusCounts['left']}
    Banned: ${statusCounts['banned']}
  
  Role Distribution:
    Manager: ${roleCounts['manager']}
    Moderator: ${roleCounts['moderator']}
    Member: ${roleCounts['member']}
''';
  }
}

/// Main migration function
Future<void> migrateHubMemberships({
  bool dryRun = true,
  int? limitHubs,
  bool verbose = false,
}) async {
  final db = FirebaseFirestore.instance;
  final stats = MigrationStats();

  print('=' * 70);
  print('HUB MEMBERSHIP MIGRATION');
  print('Mode: ${dryRun ? "DRY RUN (no changes)" : "LIVE MIGRATION"}');
  if (limitHubs != null) print('Limit: $limitHubs hubs');
  print('=' * 70);
  print('');

  // Get all hubs
  Query hubsQuery =
      db.collection('hubs').orderBy('createdAt', descending: false);
  if (limitHubs != null) {
    hubsQuery = hubsQuery.limit(limitHubs);
  }

  final hubsSnapshot = await hubsQuery.get();
  print('Found ${hubsSnapshot.docs.length} hubs to process\n');

  for (final hubDoc in hubsSnapshot.docs) {
    final hubId = hubDoc.id;
    final hubData = hubDoc.data() as Map<String, dynamic>;

    try {
      final result = await _migrateHub(
        db,
        hubId,
        hubData,
        dryRun,
        verbose,
      );

      stats.hubsProcessed++;
      stats.membersCreated += result['membersCreated'] as int;

      // Update status counts
      final statusDist = result['statusDistribution'] as Map<String, int>;
      statusDist.forEach((status, count) {
        stats.statusCounts[status] = (stats.statusCounts[status] ?? 0) + count;
      });

      // Update role counts
      final roleDist = result['roleDistribution'] as Map<String, int>;
      roleDist.forEach((role, count) {
        stats.roleCounts[role] = (stats.roleCounts[role] ?? 0) + count;
      });

      print('[✓] $hubId: ${result['membersCreated']} members created');
    } catch (e, st) {
      stats.errors++;
      print('[✗] $hubId: ERROR - $e');
      if (verbose) print(st);
    }
  }

  print('');
  print('=' * 70);
  print(stats);
  print('=' * 70);
}

/// Migrate a single hub
Future<Map<String, dynamic>> _migrateHub(
  FirebaseFirestore db,
  String hubId,
  Map<String, dynamic> hubData,
  bool dryRun,
  bool verbose,
) async {
  final createdBy = hubData['createdBy'] as String;
  final createdAt = hubData['createdAt'] as Timestamp;

  // Extract old membership data
  final memberJoinDates =
      Map<String, dynamic>.from(hubData['memberJoinDates'] ?? {});
  final roles = Map<String, String>.from(hubData['roles'] ?? {});
  final managerRatings =
      Map<String, dynamic>.from(hubData['managerRatings'] ?? {});
  final bannedUserIds = List<String>.from(hubData['bannedUserIds'] ?? []);

  // Collect all unique userIds from all sources
  final allUserIds = <String>{
    createdBy, // Always include creator
    ...memberJoinDates.keys,
    ...roles.keys,
    ...managerRatings.keys,
    ...bannedUserIds,
  };

  if (verbose) {
    print('  Hub: ${hubData['name']}');
    print('  Found ${allUserIds.length} unique users');
  }

  // Validate: Get user.hubIds to determine who's still active
  final userHubIdsMap = await _getUserHubIds(db, allUserIds);

  final batch = dryRun ? null : db.batch();
  int membersCreated = 0;
  final statusDistribution = <String, int>{'active': 0, 'left': 0, 'banned': 0};
  final roleDistribution = <String, int>{
    'manager': 0,
    'moderator': 0,
    'member': 0
  };

  for (final userId in allUserIds) {
    final memberRef = db.doc('hubs/$hubId/members/$userId');

    // Determine role
    String role = 'member';
    if (userId == createdBy) {
      role = 'manager';
    } else if (roles.containsKey(userId)) {
      final roleStr = roles[userId]!;
      if (roleStr == 'manager' || roleStr == 'admin') {
        role = 'manager';
      } else if (roleStr == 'moderator') {
        role = 'moderator';
      }
      // Don't set 'veteran' here - Cloud Function will promote based on joinedAt
    }

    // Determine status
    String status = 'active';
    if (bannedUserIds.contains(userId)) {
      status = 'banned';
    } else {
      final userHubIds = userHubIdsMap[userId] ?? [];
      if (!userHubIds.contains(hubId)) {
        // User not in user.hubIds = they left
        status = 'left';
      }
    }

    // Get joinedAt
    final joinedAtTs = memberJoinDates[userId] as Timestamp?;
    final joinedAt = joinedAtTs ?? createdAt; // Fallback to hub creation

    // Get rating
    final rating = (managerRatings[userId] as num?)?.toDouble() ?? 0.0;

    // Create member doc
    final memberData = {
      'hubId': hubId,
      'userId': userId,
      'joinedAt': joinedAt,
      'role': role,
      'status': status,
      'veteranSince': null, // Will be set by Cloud Function
      'managerRating': rating,
      'lastActiveAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': 'system:migration',
      'statusReason': status == 'banned'
          ? 'Migrated from bannedUserIds list'
          : status == 'left'
              ? 'Not in user.hubIds during migration'
              : null,
    };

    if (dryRun) {
      if (verbose) {
        print('    [DRY] Would create $hubId/members/$userId:');
        print(
            '          role=$role, status=$status, joinedAt=${joinedAt.toDate()}');
      }
    } else {
      batch!.set(memberRef, memberData);
    }

    membersCreated++;
    statusDistribution[status] = (statusDistribution[status] ?? 0) + 1;
    roleDistribution[role] = (roleDistribution[role] ?? 0) + 1;
  }

  // Commit batch
  if (!dryRun && batch != null) {
    await batch.commit();
  }

  return {
    'membersCreated': membersCreated,
    'statusDistribution': statusDistribution,
    'roleDistribution': roleDistribution,
  };
}

/// Get user.hubIds for validation
Future<Map<String, List<String>>> _getUserHubIds(
  FirebaseFirestore db,
  Set<String> userIds,
) async {
  final result = <String, List<String>>{};

  if (userIds.isEmpty) return result;

  // Firestore 'in' query limit: 10 items
  final batches = <List<String>>[];
  final userIdList = userIds.toList();

  for (int i = 0; i < userIdList.length; i += 10) {
    final end = (i + 10 > userIdList.length) ? userIdList.length : i + 10;
    batches.add(userIdList.sublist(i, end));
  }

  for (final batch in batches) {
    final snapshot = await db
        .collection('users')
        .where(FieldPath.documentId, whereIn: batch)
        .get();

    for (final doc in snapshot.docs) {
      if (doc.exists) {
        result[doc.id] = List<String>.from(doc.data()['hubIds'] ?? []);
      } else {
        result[doc.id] = [];
      }
    }
  }

  // Fill in missing users (not found in Firestore)
  for (final userId in userIds) {
    if (!result.containsKey(userId)) {
      result[userId] = [];
    }
  }

  return result;
}

/// Validation: Check migration correctness
Future<void> validateMigration(String hubId) async {
  final db = FirebaseFirestore.instance;

  print('\nValidating hub: $hubId');

  // 1. Count active members in subcollection
  final membersSnapshot = await db
      .collection('hubs/$hubId/members')
      .where('status', isEqualTo: 'active')
      .get();

  final subcollectionActiveCount = membersSnapshot.docs.length;

  // 2. Get hub.memberCount
  final hubDoc = await db.doc('hubs/$hubId').get();
  if (!hubDoc.exists) {
    print('  ✗ Hub not found');
    return;
  }

  final hubData = hubDoc.data()!;
  final hubMemberCount = hubData['memberCount'] as int? ?? 0;

  // 3. Legacy data (for comparison)
  final memberJoinDates =
      Map<String, dynamic>.from(hubData['memberJoinDates'] ?? {});
  final legacyCount = memberJoinDates.length;

  print('  Subcollection active members: $subcollectionActiveCount');
  print('  Hub.memberCount: $hubMemberCount');
  print('  Legacy memberJoinDates count: $legacyCount');

  // Get all members (including inactive)
  final allMembersSnapshot = await db.collection('hubs/$hubId/members').get();
  final statusCounts = <String, int>{};
  for (final doc in allMembersSnapshot.docs) {
    final status = doc.data()['status'] as String;
    statusCounts[status] = (statusCounts[status] ?? 0) + 1;
  }

  print('  Status breakdown:');
  statusCounts.forEach((status, count) {
    print('    $status: $count');
  });

  // Validation checks
  if (subcollectionActiveCount == hubMemberCount) {
    print('  ✓ memberCount matches subcollection active count');
  } else {
    print(
        '  ✗ MISMATCH: Subcollection ($subcollectionActiveCount) != hub.memberCount ($hubMemberCount)');
  }

  print('');
}

/// Main entry point for script execution
Future<void> main(List<String> args) async {
  // Parse args
  final dryRun = !args.contains('--live');
  final verbose = args.contains('--verbose') || args.contains('-v');
  int? limitHubs;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--limit' && i + 1 < args.length) {
      limitHubs = int.tryParse(args[i + 1]);
    }
  }

  // Initialize Firebase
  await Firebase.initializeApp();

  // Run migration
  await migrateHubMemberships(
    dryRun: dryRun,
    limitHubs: limitHubs,
    verbose: verbose,
  );

  // If live migration, validate a few hubs
  if (!dryRun) {
    print('\nRunning validation checks...');
    final db = FirebaseFirestore.instance;
    final sampleHubs = await db.collection('hubs').limit(5).get();

    for (final hubDoc in sampleHubs.docs) {
      await validateMigration(hubDoc.id);
    }
  }
}
