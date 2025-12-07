import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Data migration script: Backfill denormalized data in GameSignup documents
///
/// This script populates the new denormalized fields (gameDate, gameStatus, hubId, location, venueName)
/// in existing signup documents to support the optimized N+1 query fix.
///
/// Usage:
/// 1. Run this script ONCE after deploying the new GameSignup model
/// 2. Monitor progress and check for errors
/// 3. After completion, verify that new queries work correctly
///
/// Safety features:
/// - Dry run mode to preview changes
/// - Batch processing (500 writes per batch)
/// - Progress logging every 100 signups
/// - Error handling with continue-on-error
///
/// See: FIXES_APPLIED_ISSUES_7_12.md - Issue 8
class MigrateSignupDenormalizedData {
  final FirebaseFirestore _firestore;
  final bool dryRun;
  final int batchSize;

  MigrateSignupDenormalizedData({
    FirebaseFirestore? firestore,
    this.dryRun = true,
    this.batchSize = 500,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Run the migration
  Future<MigrationResult> migrate() async {
    debugPrint('🚀 Starting signup denormalization migration...');
    debugPrint('Mode: ${dryRun ? "DRY RUN" : "LIVE"}');

    final result = MigrationResult();
    final startTime = DateTime.now();

    try {
      // Get all games (we'll process signups game by game)
      final gamesSnapshot = await _firestore.collection('games').get();

      debugPrint('Found ${gamesSnapshot.docs.length} games to process');

      for (final gameDoc in gamesSnapshot.docs) {
        try {
          await _processGameSignups(gameDoc, result);
        } catch (e) {
          debugPrint('❌ Error processing game ${gameDoc.id}: $e');
          result.gameErrors++;
        }
      }

      final duration = DateTime.now().difference(startTime);
      result.duration = duration;

      _printSummary(result);

      return result;
    } catch (e) {
      debugPrint('💥 Fatal error during migration: $e');
      rethrow;
    }
  }

  /// Process all signups for a single game
  Future<void> _processGameSignups(
    DocumentSnapshot gameDoc,
    MigrationResult result,
  ) async {
    final gameId = gameDoc.id;
    final gameData = gameDoc.data() as Map<String, dynamic>?;

    if (gameData == null) {
      debugPrint('⚠️  Game $gameId has no data, skipping');
      return;
    }

    // Extract denormalized data from game
    final denormalizedData = _extractDenormalizedData(gameData);

    // Get all signups for this game
    final signupsSnapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('signups')
        .get();

    if (signupsSnapshot.docs.isEmpty) {
      // No signups to process
      return;
    }

    result.gamesProcessed++;

    // Process signups in batches
    final signups = signupsSnapshot.docs;
    var batch = _firestore.batch();
    var batchCount = 0;

    for (var i = 0; i < signups.length; i++) {
      final signupDoc = signups[i];
      final signupData = signupDoc.data();

      // Check if already has denormalized data (skip if yes)
      if (signupData['gameDate'] != null && signupData['gameStatus'] != null) {
        result.skipped++;
        continue;
      }

      // Add update to batch
      if (!dryRun) {
        batch.update(signupDoc.reference, denormalizedData);
      }

      batchCount++;
      result.updated++;

      // Commit batch if we reach the limit
      if (batchCount >= batchSize) {
        if (!dryRun) {
          await batch.commit();
        }
        batch = _firestore.batch();
        batchCount = 0;
      }

      // Progress logging
      if (result.updated % 100 == 0) {
        debugPrint('Progress: ${result.updated} signups updated...');
      }
    }

    // Commit remaining batch
    if (batchCount > 0 && !dryRun) {
      await batch.commit();
    }
  }

  /// Extract denormalized data from game document
  Map<String, dynamic> _extractDenormalizedData(Map<String, dynamic> gameData) {
    // Handle both nested and flat structure (for backward compatibility)
    final denormalized = gameData['denormalized'] as Map<String, dynamic>?;

    return {
      'gameDate': gameData['gameDate'],
      'gameStatus': gameData['status'],
      'hubId': gameData['hubId'],
      'location': gameData['location'],
      'venueName': denormalized?['venueName'] ?? gameData['venueName'],
    };
  }

  /// Print migration summary
  void _printSummary(MigrationResult result) {
    debugPrint('\n' + '=' * 60);
    debugPrint('📊 MIGRATION SUMMARY');
    debugPrint('=' * 60);
    debugPrint('Mode: ${dryRun ? "DRY RUN (no changes made)" : "LIVE"}');
    debugPrint('Duration: ${result.duration.inSeconds}s');
    debugPrint('');
    debugPrint('Games processed: ${result.gamesProcessed}');
    debugPrint('Signups updated: ${result.updated}');
    debugPrint('Signups skipped (already migrated): ${result.skipped}');
    debugPrint('Game errors: ${result.gameErrors}');
    debugPrint('');
    debugPrint('Total signups affected: ${result.updated + result.skipped}');

    if (dryRun) {
      debugPrint('\n⚠️  This was a DRY RUN - no data was modified');
      debugPrint('To apply changes, run with dryRun: false');
    } else {
      debugPrint('\n✅ Migration completed successfully!');
      debugPrint('');
      debugPrint('Next steps:');
      debugPrint('1. Deploy Cloud Functions to sync future changes');
      debugPrint('2. Test streamMyUpcomingGames query');
      debugPrint('3. Monitor for any data inconsistencies');
    }

    debugPrint('=' * 60);
  }
}

/// Migration result statistics
class MigrationResult {
  int gamesProcessed = 0;
  int updated = 0;
  int skipped = 0;
  int gameErrors = 0;
  Duration duration = Duration.zero;
}

/// Example usage (run from Flutter app or Firebase emulator):
///
/// ```dart
/// // Dry run first to see what would be changed
/// final migration = MigrateSignupDenormalizedData(dryRun: true);
/// final result = await migration.migrate();
///
/// // If everything looks good, run for real
/// final liveMigration = MigrateSignupDenormalizedData(dryRun: false);
/// await liveMigration.migrate();
/// ```
