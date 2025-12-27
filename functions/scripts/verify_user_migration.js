/**
 * Phase 4.6.3: Migration Verification Script
 *
 * Verifies that all user documents have been successfully migrated to
 * include new value object fields with correct data.
 *
 * This script:
 * 1. Checks all users have new value object fields (privacy, notifications, userLocation)
 * 2. Validates data integrity between old and new formats
 * 3. Reports any inconsistencies or missing data
 * 4. Generates detailed migration report
 *
 * Usage:
 *   node verify_user_migration.js [--verbose] [--fix-errors]
 *
 * Options:
 *   --verbose      Show detailed information for each user
 *   --fix-errors   Automatically fix detected errors
 */

const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

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
const isVerbose = args.includes('--verbose');
const shouldFix = args.includes('--fix-errors');

// Verification statistics
const stats = {
  total: 0,
  fullyMigrated: 0,
  partiallyMigrated: 0,
  notMigrated: 0,
  dataIntegrityErrors: 0,
  fixed: 0,
  errors: [],
};

/**
 * Validate privacy settings consistency
 */
function validatePrivacy(userData) {
  const errors = [];
  const { privacy, privacySettings } = userData;

  if (!privacy) {
    errors.push('Missing privacy value object');
    return errors;
  }

  if (!privacySettings) {
    errors.push('Missing privacySettings map (backward compatibility)');
    return errors;
  }

  // Check consistency between old and new formats
  const checks = [
    ['hideFromSearch', 'hideFromSearch'],
    ['hideEmail', 'hideEmail'],
    ['hidePhone', 'hidePhone'],
    ['hideCity', 'hideCity'],
    ['hideStats', 'hideStats'],
    ['hideRatings', 'hideRatings'],
    ['allowHubInvites', 'allowHubInvites'],
  ];

  for (const [newKey, oldKey] of checks) {
    if (privacy[newKey] !== privacySettings[oldKey]) {
      errors.push(`Privacy mismatch: ${newKey} (${privacy[newKey]} vs ${privacySettings[oldKey]})`);
    }
  }

  return errors;
}

/**
 * Validate notification preferences consistency
 */
function validateNotifications(userData) {
  const errors = [];
  const { notifications, notificationPreferences } = userData;

  if (!notifications) {
    errors.push('Missing notifications value object');
    return errors;
  }

  if (!notificationPreferences) {
    errors.push('Missing notificationPreferences map (backward compatibility)');
    return errors;
  }

  // Check consistency between old and new formats
  const checks = [
    ['gameReminder', 'game_reminder'],
    ['message', 'message'],
    ['like', 'like'],
    ['comment', 'comment'],
    ['signup', 'signup'],
    ['newFollower', 'new_follower'],
    ['hubChat', 'hub_chat'],
    ['newComment', 'new_comment'],
    ['newGame', 'new_game'],
  ];

  for (const [newKey, oldKey] of checks) {
    if (notifications[newKey] !== notificationPreferences[oldKey]) {
      errors.push(`Notification mismatch: ${newKey} (${notifications[newKey]} vs ${notificationPreferences[oldKey]})`);
    }
  }

  return errors;
}

/**
 * Validate user location consistency
 */
function validateLocation(userData) {
  const errors = [];
  const { userLocation, location, geohash, city, region } = userData;

  // Location is optional, but if present, should be consistent
  const hasOldLocation = location || geohash || city || region;
  const hasNewLocation = userLocation && Object.keys(userLocation).length > 0;

  if (hasOldLocation && !hasNewLocation) {
    errors.push('Has old location fields but missing userLocation value object');
    return errors;
  }

  if (hasNewLocation && hasOldLocation) {
    // Check consistency
    if (userLocation.geohash !== geohash) {
      errors.push(`Location mismatch: geohash (${userLocation.geohash} vs ${geohash})`);
    }
    if (userLocation.city !== city) {
      errors.push(`Location mismatch: city (${userLocation.city} vs ${city})`);
    }
    if (userLocation.region !== region) {
      errors.push(`Location mismatch: region (${userLocation.region} vs ${region})`);
    }
  }

  return errors;
}

/**
 * Verify a single user document
 */
async function verifyUser(userDoc) {
  const userData = userDoc.data();
  const userId = userDoc.id;

  stats.total++;

  const issues = [];

  // Check if user has new value object fields
  const hasPrivacy = !!userData.privacy;
  const hasNotifications = !!userData.notifications;

  if (!hasPrivacy && !hasNotifications) {
    stats.notMigrated++;
    issues.push('NOT MIGRATED: Missing all value objects');
  } else if (!hasPrivacy || !hasNotifications) {
    stats.partiallyMigrated++;
    if (!hasPrivacy) issues.push('Missing privacy value object');
    if (!hasNotifications) issues.push('Missing notifications value object');
  } else {
    // Fully migrated - validate data integrity
    const privacyErrors = validatePrivacy(userData);
    const notificationErrors = validateNotifications(userData);
    const locationErrors = validateLocation(userData);

    const allErrors = [...privacyErrors, ...notificationErrors, ...locationErrors];

    if (allErrors.length > 0) {
      stats.dataIntegrityErrors++;
      issues.push(...allErrors);
    } else {
      stats.fullyMigrated++;
      if (isVerbose) {
        console.log(`✓ User ${userId} - fully migrated and verified`);
      }
      return; // All good!
    }
  }

  // Log issues
  if (issues.length > 0) {
    console.error(`\n✗ User ${userId}:`);
    issues.forEach(issue => console.error(`  - ${issue}`));

    stats.errors.push({
      userId,
      issues,
      userData: isVerbose ? userData : null,
    });

    // Optionally fix errors
    if (shouldFix && issues.some(i => i.includes('mismatch') || i.includes('Missing'))) {
      await fixUser(userDoc, userData);
    }
  }
}

/**
 * Fix a user document with errors
 */
async function fixUser(userDoc, userData) {
  try {
    console.log(`  → Attempting to fix user ${userDoc.id}...`);

    // Re-run migration logic
    const { migratePrivacySettings, migrateNotificationPreferences, migrateUserLocation } =
      require('./migrate_user_value_objects');

    const updateData = {
      privacy: migratePrivacySettings(userData.privacySettings),
      notifications: migrateNotificationPreferences(userData.notificationPreferences),
      userLocation: migrateUserLocation(userData),
    };

    await userDoc.ref.update(updateData);
    stats.fixed++;
    console.log(`  ✓ Fixed user ${userDoc.id}`);
  } catch (error) {
    console.error(`  ✗ Failed to fix user ${userDoc.id}:`, error.message);
  }
}

/**
 * Generate detailed report
 */
function generateReport() {
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('  Migration Verification Report');
  console.log('═══════════════════════════════════════════════════════');
  console.log(`Total users: ${stats.total}`);
  console.log(`Fully migrated: ${stats.fullyMigrated} (${((stats.fullyMigrated / stats.total) * 100).toFixed(2)}%)`);
  console.log(`Partially migrated: ${stats.partiallyMigrated}`);
  console.log(`Not migrated: ${stats.notMigrated}`);
  console.log(`Data integrity errors: ${stats.dataIntegrityErrors}`);
  if (shouldFix) {
    console.log(`Fixed: ${stats.fixed}`);
  }
  console.log('═══════════════════════════════════════════════════════\n');

  // Migration status
  const migrationComplete = stats.notMigrated === 0 && stats.dataIntegrityErrors === 0;

  if (migrationComplete) {
    console.log('✅ MIGRATION COMPLETE');
    console.log('   All users successfully migrated with correct data');
    console.log('   Safe to proceed to Phase 4.6.4 (remove old fields)\n');
    return true;
  } else {
    console.log('⚠️  MIGRATION INCOMPLETE');
    if (stats.notMigrated > 0) {
      console.log(`   ${stats.notMigrated} users not migrated`);
    }
    if (stats.dataIntegrityErrors > 0) {
      console.log(`   ${stats.dataIntegrityErrors} users have data integrity errors`);
    }
    console.log('\nRecommended actions:');
    console.log('1. Run migration script again: node migrate_user_value_objects.js');
    console.log('2. Review errors above');
    if (!shouldFix) {
      console.log('3. Run with --fix-errors to automatically fix issues');
    }
    console.log('4. DO NOT proceed to Phase 4.6.4 until all users are migrated\n');
    return false;
  }
}

/**
 * Main verification function
 */
async function runVerification() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('  Phase 4.6.3: Migration Verification');
  console.log('═══════════════════════════════════════════════════════');
  console.log(`Verbose mode: ${isVerbose ? 'ON' : 'OFF'}`);
  console.log(`Auto-fix errors: ${shouldFix ? 'ON' : 'OFF'}`);
  console.log('═══════════════════════════════════════════════════════\n');

  try {
    console.log('Fetching all users...\n');

    // Process users in batches to avoid memory issues
    const BATCH_SIZE = 500;
    let lastDoc = null;
    let processedCount = 0;

    do {
      let query = db.collection('users')
        .orderBy('createdAt')
        .limit(BATCH_SIZE);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();

      if (snapshot.empty) break;

      // Verify users in parallel within batch
      await Promise.all(snapshot.docs.map(doc => verifyUser(doc)));

      processedCount += snapshot.size;
      console.log(`Processed ${processedCount} users...`);

      lastDoc = snapshot.docs[snapshot.size - 1];
    } while (lastDoc);

    // Generate final report
    const success = generateReport();

    // Exit with appropriate code
    process.exit(success ? 0 : 1);
  } catch (error) {
    console.error('\n✗ Verification failed:', error);
    process.exit(1);
  }
}

// Run verification
runVerification();
