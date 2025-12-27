/**
 * Phase 4.6.2: Background Migration Script
 *
 * Migrates all user documents to include new value object fields while
 * maintaining backward compatibility with old map fields.
 *
 * This script:
 * 1. Reads all users from Firestore
 * 2. For each user, creates new value object fields from old map fields
 * 3. Writes BOTH old and new formats (dual-write pattern)
 * 4. Tracks progress and errors
 *
 * Usage:
 *   node migrate_user_value_objects.js [--dry-run] [--batch-size=500]
 *
 * Options:
 *   --dry-run       Preview changes without writing to Firestore
 *   --batch-size    Number of users to process in each batch (default: 500)
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
const batchSizeArg = args.find(arg => arg.startsWith('--batch-size='));
const BATCH_SIZE = batchSizeArg
  ? parseInt(batchSizeArg.split('=')[1])
  : 500;

// Migration statistics
const stats = {
  total: 0,
  migrated: 0,
  alreadyMigrated: 0,
  errors: 0,
  startTime: Date.now(),
};

/**
 * Migrate privacy settings from old map to new value object
 */
function migratePrivacySettings(privacySettings) {
  const defaultPrivacy = {
    hideFromSearch: false,
    hideEmail: false,
    hidePhone: false,
    hideCity: false,
    hideStats: false,
    hideRatings: false,
    allowHubInvites: true,
  };

  if (!privacySettings || typeof privacySettings !== 'object') {
    return defaultPrivacy;
  }

  return {
    hideFromSearch: privacySettings.hideFromSearch ?? defaultPrivacy.hideFromSearch,
    hideEmail: privacySettings.hideEmail ?? defaultPrivacy.hideEmail,
    hidePhone: privacySettings.hidePhone ?? defaultPrivacy.hidePhone,
    hideCity: privacySettings.hideCity ?? defaultPrivacy.hideCity,
    hideStats: privacySettings.hideStats ?? defaultPrivacy.hideStats,
    hideRatings: privacySettings.hideRatings ?? defaultPrivacy.hideRatings,
    allowHubInvites: privacySettings.allowHubInvites ?? defaultPrivacy.allowHubInvites,
  };
}

/**
 * Migrate notification preferences from old map to new value object
 */
function migrateNotificationPreferences(notificationPreferences) {
  const defaultNotifications = {
    gameReminder: true,
    message: true,
    like: true,
    comment: true,
    signup: true,
    newFollower: true,
    hubChat: true,
    newComment: true,
    newGame: true,
  };

  if (!notificationPreferences || typeof notificationPreferences !== 'object') {
    return defaultNotifications;
  }

  return {
    gameReminder: notificationPreferences.game_reminder ?? defaultNotifications.gameReminder,
    message: notificationPreferences.message ?? defaultNotifications.message,
    like: notificationPreferences.like ?? defaultNotifications.like,
    comment: notificationPreferences.comment ?? defaultNotifications.comment,
    signup: notificationPreferences.signup ?? defaultNotifications.signup,
    newFollower: notificationPreferences.new_follower ?? defaultNotifications.newFollower,
    hubChat: notificationPreferences.hub_chat ?? defaultNotifications.hubChat,
    newComment: notificationPreferences.new_comment ?? defaultNotifications.newComment,
    newGame: notificationPreferences.new_game ?? defaultNotifications.newGame,
  };
}

/**
 * Migrate location from old flat fields to new value object
 */
function migrateUserLocation(userData) {
  const { location, geohash, city, region } = userData;

  // If no location data, return null
  if (!location && !geohash && !city && !region) {
    return null;
  }

  return {
    location: location || null,
    geohash: geohash || null,
    city: city || null,
    region: region || null,
  };
}

/**
 * Check if user already has new value object fields
 */
function isAlreadyMigrated(userData) {
  return !!(userData.privacy && userData.notifications);
}

/**
 * Migrate a single user document
 */
async function migrateUser(userDoc) {
  const userData = userDoc.data();
  const userId = userDoc.id;

  try {
    // Check if already migrated
    if (isAlreadyMigrated(userData)) {
      stats.alreadyMigrated++;
      console.log(`✓ User ${userId} already migrated`);
      return;
    }

    // Prepare new value object fields
    const privacy = migratePrivacySettings(userData.privacySettings);
    const notifications = migrateNotificationPreferences(userData.notificationPreferences);
    const userLocation = migrateUserLocation(userData);

    // Prepare update data (dual-write pattern)
    const updateData = {
      // NEW format: Value objects
      privacy,
      notifications,
      userLocation,

      // OLD format: Keep existing maps (backward compatibility)
      privacySettings: {
        hideFromSearch: privacy.hideFromSearch,
        hideEmail: privacy.hideEmail,
        hidePhone: privacy.hidePhone,
        hideCity: privacy.hideCity,
        hideStats: privacy.hideStats,
        hideRatings: privacy.hideRatings,
        allowHubInvites: privacy.allowHubInvites,
      },
      notificationPreferences: {
        game_reminder: notifications.gameReminder,
        message: notifications.message,
        like: notifications.like,
        comment: notifications.comment,
        signup: notifications.signup,
        new_follower: notifications.newFollower,
        hub_chat: notifications.hubChat,
        new_comment: notifications.newComment,
        new_game: notifications.newGame,
      },

      // Add migration metadata
      _migrationMetadata: {
        migratedAt: FieldValue.serverTimestamp(),
        migrationVersion: 'phase4.6.2',
      },
    };

    if (isDryRun) {
      console.log(`[DRY RUN] Would migrate user ${userId}:`, {
        privacy,
        notifications,
        userLocation,
      });
    } else {
      await userDoc.ref.update(updateData);
      console.log(`✓ Migrated user ${userId}`);
    }

    stats.migrated++;
  } catch (error) {
    stats.errors++;
    console.error(`✗ Error migrating user ${userId}:`, error.message);
  }
}

/**
 * Process users in batches
 */
async function migrateBatch(startAfter = null) {
  let query = db.collection('users')
    .orderBy('createdAt')
    .limit(BATCH_SIZE);

  if (startAfter) {
    query = query.startAfter(startAfter);
  }

  const snapshot = await query.get();

  if (snapshot.empty) {
    return null; // No more users to process
  }

  console.log(`\nProcessing batch of ${snapshot.size} users...`);

  // Process users in parallel within batch
  await Promise.all(snapshot.docs.map(doc => migrateUser(doc)));

  stats.total += snapshot.size;

  // Return last document for pagination
  return snapshot.docs[snapshot.size - 1];
}

/**
 * Main migration function
 */
async function runMigration() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('  Phase 4.6.2: User Value Objects Migration');
  console.log('═══════════════════════════════════════════════════════');
  console.log(`Mode: ${isDryRun ? 'DRY RUN (no changes)' : 'LIVE MIGRATION'}`);
  console.log(`Batch size: ${BATCH_SIZE}`);
  console.log('═══════════════════════════════════════════════════════\n');

  try {
    let lastDoc = null;
    let batchCount = 0;

    // Process all users in batches
    do {
      batchCount++;
      console.log(`\n--- Batch ${batchCount} ---`);
      lastDoc = await migrateBatch(lastDoc);
    } while (lastDoc !== null);

    // Print final statistics
    const duration = ((Date.now() - stats.startTime) / 1000).toFixed(2);

    console.log('\n═══════════════════════════════════════════════════════');
    console.log('  Migration Complete');
    console.log('═══════════════════════════════════════════════════════');
    console.log(`Total users processed: ${stats.total}`);
    console.log(`Successfully migrated: ${stats.migrated}`);
    console.log(`Already migrated: ${stats.alreadyMigrated}`);
    console.log(`Errors: ${stats.errors}`);
    console.log(`Duration: ${duration}s`);
    console.log(`Rate: ${(stats.total / duration).toFixed(2)} users/sec`);
    console.log('═══════════════════════════════════════════════════════\n');

    if (isDryRun) {
      console.log('⚠️  This was a DRY RUN - no data was modified');
      console.log('   Run without --dry-run to perform actual migration\n');
    }

    process.exit(stats.errors > 0 ? 1 : 0);
  } catch (error) {
    console.error('\n✗ Migration failed:', error);
    process.exit(1);
  }
}

// Run migration
runMigration();
