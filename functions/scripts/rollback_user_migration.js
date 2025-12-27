/**
 * Phase 4 Rollback Script
 *
 * EMERGENCY USE ONLY: Removes new value object fields from user documents
 * if migration needs to be rolled back.
 *
 * ⚠️  WARNING: This script should only be used if:
 * 1. Migration caused critical issues in production
 * 2. You need to revert to the old map-based format
 * 3. You have confirmed with the team that rollback is necessary
 *
 * This script:
 * 1. Removes privacy, notifications, and userLocation fields
 * 2. Keeps old map fields (privacySettings, notificationPreferences, location, etc.)
 * 3. Removes migration metadata
 * 4. Logs all changes for audit trail
 *
 * Usage:
 *   node rollback_user_migration.js [--dry-run] [--confirm]
 *
 * Options:
 *   --dry-run   Preview changes without modifying data
 *   --confirm   Required flag to execute rollback (safety measure)
 */

const admin = require('firebase-admin');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// Check if GCLOUD_PROJECT or FIREBASE_CONFIG environment variable is set
const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_CONFIG || 'kickabout-ddc06';

// Try to load service account key if it exists
let credential;
try {
  const serviceAccount = require('../service-account-key.json');
  credential = admin.credential.cert(serviceAccount);
  console.log('✅ Using service account credentials');
} catch (e) {
  // Service account file not found, use default credentials
  console.log('ℹ️  Using default application credentials (firebase login)');
}

// Initialize Firebase Admin with project ID
try {
  admin.initializeApp({
    credential: credential || admin.credential.applicationDefault(),
    projectId: projectId,
  });
  console.log(`✅ Connected to project: ${projectId}\n`);
} catch (e) {
  if (admin.apps.length === 0) {
    console.error('❌ Failed to initialize Firebase Admin:', e.message);
    console.error('\nPlease ensure you are authenticated:');
    console.error('  1. Run: firebase login');
    console.error('  2. Run: firebase use --add (select kickabout project)');
    console.error('  OR set: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"\n');
    process.exit(1);
  }
}

const db = getFirestore();

// Parse command line arguments
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const isConfirmed = args.includes('--confirm');

// Rollback statistics
const stats = {
  total: 0,
  rolledBack: 0,
  skipped: 0,
  errors: 0,
  startTime: Date.now(),
};

/**
 * Rollback a single user document
 */
async function rollbackUser(userDoc) {
  const userData = userDoc.data();
  const userId = userDoc.id;

  try {
    // Check if user has new value object fields to remove
    const hasNewFields = userData.privacy || userData.notifications || userData.userLocation;

    if (!hasNewFields) {
      stats.skipped++;
      console.log(`⊘ User ${userId} - no new fields to remove`);
      return;
    }

    // Prepare update to remove new fields
    const updateData = {
      privacy: FieldValue.delete(),
      notifications: FieldValue.delete(),
      userLocation: FieldValue.delete(),
      _migrationMetadata: FieldValue.delete(),

      // Add rollback metadata for audit trail
      _rollbackMetadata: {
        rolledBackAt: FieldValue.serverTimestamp(),
        reason: 'Phase 4 migration rollback',
        previouslyMigrated: !!userData._migrationMetadata,
      },
    };

    if (isDryRun) {
      console.log(`[DRY RUN] Would rollback user ${userId}`);
    } else {
      await userDoc.ref.update(updateData);
      console.log(`✓ Rolled back user ${userId}`);
    }

    stats.rolledBack++;
  } catch (error) {
    stats.errors++;
    console.error(`✗ Error rolling back user ${userId}:`, error.message);
  }
}

/**
 * Process users in batches
 */
async function rollbackBatch(startAfter = null) {
  const BATCH_SIZE = 500;

  let query = db.collection('users')
    .orderBy('createdAt')
    .limit(BATCH_SIZE);

  if (startAfter) {
    query = query.startAfter(startAfter);
  }

  const snapshot = await query.get();

  if (snapshot.empty) {
    return null;
  }

  console.log(`\nProcessing batch of ${snapshot.size} users...`);

  // Process users in parallel within batch
  await Promise.all(snapshot.docs.map(doc => rollbackUser(doc)));

  stats.total += snapshot.size;

  return snapshot.docs[snapshot.size - 1];
}

/**
 * Main rollback function
 */
async function runRollback() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('  ⚠️  PHASE 4 MIGRATION ROLLBACK  ⚠️');
  console.log('═══════════════════════════════════════════════════════');

  // Safety check - require confirmation
  if (!isConfirmed && !isDryRun) {
    console.log('\n❌ ERROR: Rollback requires --confirm flag');
    console.log('\nThis is a safety measure to prevent accidental rollbacks.');
    console.log('If you are sure you want to rollback, run:');
    console.log('  node rollback_user_migration.js --confirm\n');
    console.log('To preview changes first:');
    console.log('  node rollback_user_migration.js --dry-run\n');
    process.exit(1);
  }

  console.log(`Mode: ${isDryRun ? 'DRY RUN (no changes)' : '⚠️  LIVE ROLLBACK ⚠️'}`);
  console.log('═══════════════════════════════════════════════════════\n');

  if (!isDryRun) {
    console.log('⚠️  WARNING: This will remove all new value object fields!');
    console.log('⚠️  The app will fall back to using old map-based fields.');
    console.log('⚠️  Make sure the codebase can handle this rollback.\n');

    // Additional confirmation for live rollback
    console.log('Starting rollback in 5 seconds...');
    console.log('Press Ctrl+C to cancel\n');
    await new Promise(resolve => setTimeout(resolve, 5000));
  }

  try {
    let lastDoc = null;
    let batchCount = 0;

    // Process all users in batches
    do {
      batchCount++;
      console.log(`\n--- Batch ${batchCount} ---`);
      lastDoc = await rollbackBatch(lastDoc);
    } while (lastDoc !== null);

    // Print final statistics
    const duration = ((Date.now() - stats.startTime) / 1000).toFixed(2);

    console.log('\n═══════════════════════════════════════════════════════');
    console.log('  Rollback Complete');
    console.log('═══════════════════════════════════════════════════════');
    console.log(`Total users processed: ${stats.total}`);
    console.log(`Successfully rolled back: ${stats.rolledBack}`);
    console.log(`Skipped (no new fields): ${stats.skipped}`);
    console.log(`Errors: ${stats.errors}`);
    console.log(`Duration: ${duration}s`);
    console.log('═══════════════════════════════════════════════════════\n');

    if (isDryRun) {
      console.log('⚠️  This was a DRY RUN - no data was modified');
      console.log('   Run with --confirm to perform actual rollback\n');
    } else {
      console.log('✅ Rollback completed successfully');
      console.log('\nNext steps:');
      console.log('1. Verify app functionality');
      console.log('2. Monitor error logs');
      console.log('3. Keep old map fields (privacySettings, notificationPreferences, location)');
      console.log('4. Do NOT remove old fields from User model\n');
    }

    process.exit(stats.errors > 0 ? 1 : 0);
  } catch (error) {
    console.error('\n✗ Rollback failed:', error);
    process.exit(1);
  }
}

// Run rollback
runRollback();
