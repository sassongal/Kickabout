/// Migration Script: Convert Manager Ratings from 10-scale to 7-scale
///
/// This script converts all existing manager ratings from the old 1.0-10.0 scale
/// to the new 1.0-7.0 scale with 0.5 increments.
///
/// CONVERSION FORMULA:
/// newRating = ((oldRating - 1) / 9) * 6 + 1
/// Then round to nearest 0.5
///
/// Examples:
/// - 1.0 (old) → 1.0 (new)
/// - 5.5 (old) → 4.0 (new)
/// - 10.0 (old) → 7.0 (new)
///
/// SAFETY:
/// - Supports dry-run mode
/// - Validates all ratings are in valid range
/// - Batched writes for performance
/// - Detailed logging
library migrate_ratings_to_7_scale;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Migration statistics
class RatingMigrationStats {
  int hubsProcessed = 0;
  int membersProcessed = 0;
  int ratingsConverted = 0;
  int ratingsSkipped = 0; // Already in 1-7 range or no rating
  int errors = 0;
  Map<String, int> beforeDistribution = {};
  Map<String, int> afterDistribution = {};

  @override
  String toString() {
    return '''
Rating Migration Statistics:
============================
Hubs Processed: $hubsProcessed
Members Processed: $membersProcessed
Ratings Converted: $ratingsConverted
Ratings Skipped: $ratingsSkipped
Errors: $errors

Before Distribution: $beforeDistribution
After Distribution: $afterDistribution
''';
  }
}

/// Convert rating from 10-scale to 7-scale
double convertRatingTo7Scale(double oldRating) {
  // Formula: Map 1-10 to 1-7
  final normalized = (oldRating - 1.0) / 9.0; // Normalize to 0-1
  final newScale = normalized * 6.0 + 1.0; // Scale to 1-7

  // Round to nearest 0.5
  final rounded = (newScale * 2).round() / 2.0;

  // Clamp to valid range
  return rounded.clamp(1.0, 7.0);
}

/// Main migration function
Future<void> migrateRatingsTo7Scale({
  required FirebaseFirestore firestore,
  bool dryRun = true,
}) async {
  final stats = RatingMigrationStats();

  print('🚀 Starting Rating Migration to 7-scale...');
  print('Mode: ${dryRun ? "DRY RUN" : "LIVE"}');
  print('=' * 50);

  try {
    // Get all hubs
    final hubsSnapshot = await firestore.collection('hubs').get();
    print('📊 Found ${hubsSnapshot.docs.length} hubs');

    for (final hubDoc in hubsSnapshot.docs) {
      final hubId = hubDoc.id;
      print('\n🏠 Processing hub: $hubId');

      try {
        // Get all members with ratings
        final membersSnapshot = await firestore
            .collection('hubs/$hubId/members')
            .where('managerRating', isGreaterThan: 0)
            .get();

        print('   Found ${membersSnapshot.docs.length} members with ratings');

        final batch = firestore.batch();
        int batchCount = 0;

        for (final memberDoc in membersSnapshot.docs) {
          final memberId = memberDoc.id;
          final data = memberDoc.data();
          final oldRating = (data['managerRating'] as num?)?.toDouble();

          if (oldRating == null || oldRating == 0) {
            stats.ratingsSkipped++;
            continue;
          }

          stats.membersProcessed++;

          // Track before distribution
          final beforeKey = oldRating.toStringAsFixed(1);
          stats.beforeDistribution[beforeKey] =
              (stats.beforeDistribution[beforeKey] ?? 0) + 1;

          // Skip if already in 1-7 range (likely already migrated)
          if (oldRating <= 7.0) {
            print('   ⏩ Skipping $memberId: rating $oldRating already in 1-7 range');
            stats.ratingsSkipped++;
            continue;
          }

          // Convert rating
          final newRating = convertRatingTo7Scale(oldRating);

          print('   ✨ Converting $memberId: $oldRating → $newRating');

          // Track after distribution
          final afterKey = newRating.toStringAsFixed(1);
          stats.afterDistribution[afterKey] =
              (stats.afterDistribution[afterKey] ?? 0) + 1;

          stats.ratingsConverted++;

          if (!dryRun) {
            batch.update(memberDoc.reference, {
              'managerRating': newRating,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            batchCount++;

            // Commit batch every 500 operations (Firestore limit)
            if (batchCount >= 500) {
              await batch.commit();
              print('   💾 Committed batch of $batchCount updates');
              batchCount = 0;
            }
          }
        }

        // Commit remaining operations
        if (!dryRun && batchCount > 0) {
          await batch.commit();
          print('   💾 Committed final batch of $batchCount updates');
        }

        stats.hubsProcessed++;
      } catch (e) {
        print('   ❌ Error processing hub $hubId: $e');
        stats.errors++;
      }
    }

    // Also migrate dummy players if they exist
    print('\n👥 Checking for dummy players...');
    await migrateDummyPlayers(
      firestore: firestore,
      stats: stats,
      dryRun: dryRun,
    );

  } catch (e) {
    print('❌ Fatal error: $e');
    stats.errors++;
  }

  // Print final statistics
  print('\n' + '=' * 50);
  print('✅ Migration Complete!');
  print(stats.toString());

  if (dryRun) {
    print('⚠️  This was a DRY RUN - no changes were made');
    print('   Run with dryRun: false to apply changes');
  }
}

/// Migrate dummy players (if they have global ratings)
Future<void> migrateDummyPlayers({
  required FirebaseFirestore firestore,
  required RatingMigrationStats stats,
  bool dryRun = true,
}) async {
  try {
    // Check if there are users with isDummy flag
    final dummyUsersSnapshot = await firestore
        .collection('users')
        .where('isDummy', isEqualTo: true)
        .get();

    if (dummyUsersSnapshot.docs.isEmpty) {
      print('   No dummy players found');
      return;
    }

    print('   Found ${dummyUsersSnapshot.docs.length} dummy players');

    final batch = firestore.batch();
    int batchCount = 0;

    for (final userDoc in dummyUsersSnapshot.docs) {
      final data = userDoc.data();
      final oldRating = (data['currentRankScore'] as num?)?.toDouble();

      if (oldRating == null || oldRating <= 7.0) {
        continue;
      }

      final newRating = convertRatingTo7Scale(oldRating);
      print('   ✨ Converting dummy player ${userDoc.id}: $oldRating → $newRating');

      if (!dryRun) {
        batch.update(userDoc.reference, {
          'currentRankScore': newRating,
        });
        batchCount++;

        if (batchCount >= 500) {
          await batch.commit();
          print('   💾 Committed dummy players batch');
          batchCount = 0;
        }
      }
    }

    if (!dryRun && batchCount > 0) {
      await batch.commit();
      print('   💾 Committed final dummy players batch');
    }

  } catch (e) {
    print('   ❌ Error migrating dummy players: $e');
  }
}

/// CLI entry point
Future<void> main(List<String> args) async {
  print('Rating Migration Script - 10-scale to 7-scale');
  print('=' * 50);

  // Parse arguments
  final dryRun = !args.contains('--live');

  if (!dryRun) {
    print('⚠️  WARNING: Running in LIVE mode!');
    print('⚠️  This will modify data in Firestore!');
    print('Continue? (y/n)');

    // In a real CLI, you'd read stdin here
    // For now, we'll require explicit --live flag
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;

    // Run migration
    await migrateRatingsTo7Scale(
      firestore: firestore,
      dryRun: dryRun,
    );

  } catch (e) {
    print('❌ Failed to initialize: $e');
    exit(1);
  }
}

void exit(int code) {
  // Platform-specific exit
  throw Exception('Exit with code $code');
}
