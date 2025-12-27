/**
 * Backfill Geohashes Script
 *
 * This script scans all venues in Firestore and ensures they have valid geohashes.
 * Uses geofire-common for standardized geohash generation (precision 8).
 *
 * Setup:
 *   1. Authenticate with Firebase CLI: `firebase login`
 *   2. Set your project: `firebase use --add` (select kickabout project)
 *
 * OR set environment variable:
 *   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
 *
 * Usage:
 *   npm run backfill-geohashes -- --dry-run # Test without making changes
 *   npm run backfill-geohashes              # Execute backfill
 */

const admin = require('firebase-admin');
const geohash = require('geofire-common');

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
  console.log(`✅ Firebase Admin initialized with project: ${projectId}`);
} catch (error) {
  // Already initialized (useful when running in Firebase Functions environment)
  if (error.code === 'app/duplicate-app') {
    console.log('Firebase Admin already initialized');
  } else {
    console.error('❌ Error initializing Firebase Admin:', error.message);
    console.log('\n📝 Authentication Options:');
    console.log('\nOption 1 - Firebase CLI (Recommended):');
    console.log('   1. Run: firebase login --reauth');
    console.log('   2. Run: firebase use kickabout-ddc06');
    console.log('   3. Try running this script again');
    console.log('\nOption 2 - Service Account Key:');
    console.log('   1. Go to: https://console.firebase.google.com/project/kickabout-ddc06/settings/serviceaccounts/adminsdk');
    console.log('   2. Click "Generate new private key"');
    console.log('   3. Save as: functions/service-account-key.json');
    console.log('   4. Try running this script again\n');
    process.exit(1);
  }
}

const db = admin.firestore();

// Configuration
const BATCH_SIZE = 500;  // Firestore batch limit
const LOG_INTERVAL = 50; // Log progress every N documents
const GEOHASH_PRECISION = 8; // Standard precision for location queries

// Statistics
const stats = {
  total: 0,
  updated: 0,
  skipped: 0,
  errors: 0,
  missingLocation: 0
};

/**
 * Check if a document needs geohash update
 */
function needsGeohashUpdate(doc) {
  const data = doc.data();

  // Check if location exists
  if (!data.location || !data.location._latitude || !data.location._longitude) {
    return { needsUpdate: false, reason: 'missing_location' };
  }

  // Check if geohash is missing
  if (!data.geohash) {
    return { needsUpdate: true, reason: 'missing_geohash' };
  }

  // Validate existing geohash
  const lat = data.location._latitude;
  const lng = data.location._longitude;
  const correctGeohash = geohash.geohashForLocation([lat, lng], GEOHASH_PRECISION);

  if (data.geohash !== correctGeohash) {
    return { needsUpdate: true, reason: 'invalid_geohash' };
  }

  return { needsUpdate: false, reason: 'valid' };
}

/**
 * Process a batch of venues
 */
async function processBatch(venues, dryRun = false) {
  const batch = db.batch();
  let batchCount = 0;

  for (const doc of venues) {
    const data = doc.data();
    const check = needsGeohashUpdate(doc);

    stats.total++;

    if (!data.location || !data.location._latitude || !data.location._longitude) {
      stats.missingLocation++;
      stats.skipped++;
      continue;
    }

    if (!check.needsUpdate) {
      stats.skipped++;
      continue;
    }

    // Calculate correct geohash
    const lat = data.location._latitude;
    const lng = data.location._longitude;
    const correctGeohash = geohash.geohashForLocation([lat, lng], GEOHASH_PRECISION);

    // Log the update
    console.log(`  ✓ ${doc.id}: ${data.name || 'Unnamed'}`);
    console.log(`    Location: ${lat.toFixed(6)}, ${lng.toFixed(6)}`);
    console.log(`    Old geohash: ${data.geohash || '(none)'}`);
    console.log(`    New geohash: ${correctGeohash}`);
    console.log(`    Reason: ${check.reason}`);

    if (!dryRun) {
      batch.update(doc.ref, { geohash: correctGeohash });
      batchCount++;
    }

    stats.updated++;

    // Log progress
    if (stats.total % LOG_INTERVAL === 0) {
      console.log(`\nProgress: ${stats.total} venues processed...`);
    }
  }

  // Commit batch if not dry run
  if (!dryRun && batchCount > 0) {
    try {
      await batch.commit();
      console.log(`  ✓ Batch committed: ${batchCount} venues updated`);
    } catch (error) {
      console.error(`  ✗ Batch commit error:`, error);
      stats.errors += batchCount;
    }
  }

  return batchCount;
}

/**
 * Main backfill function
 */
async function backfillGeohashes(dryRun = false) {
  console.log('═══════════════════════════════════════════════');
  console.log('  Kickabout Geohash Backfill Script');
  console.log('═══════════════════════════════════════════════');
  console.log(`Mode: ${dryRun ? 'DRY RUN (no changes)' : 'LIVE (updating database)'}`);
  console.log(`Precision: ${GEOHASH_PRECISION} characters`);
  console.log(`Batch size: ${BATCH_SIZE}`);
  console.log('───────────────────────────────────────────────\n');

  const startTime = Date.now();

  try {
    // Get all venues
    const venuesRef = db.collection('venues');
    const snapshot = await venuesRef.get();

    console.log(`Found ${snapshot.size} venues in database\n`);

    if (snapshot.empty) {
      console.log('No venues found. Exiting.');
      return;
    }

    // Process in batches
    let currentBatch = [];

    for (const doc of snapshot.docs) {
      currentBatch.push(doc);

      if (currentBatch.length >= BATCH_SIZE) {
        await processBatch(currentBatch, dryRun);
        currentBatch = [];
      }
    }

    // Process remaining documents
    if (currentBatch.length > 0) {
      await processBatch(currentBatch, dryRun);
    }

  } catch (error) {
    console.error('\n✗ Fatal error:', error);
    stats.errors++;
  }

  // Print summary
  const duration = ((Date.now() - startTime) / 1000).toFixed(2);

  console.log('\n═══════════════════════════════════════════════');
  console.log('  Backfill Complete');
  console.log('═══════════════════════════════════════════════');
  console.log(`Duration: ${duration}s`);
  console.log(`Total venues: ${stats.total}`);
  console.log(`Updated: ${stats.updated}`);
  console.log(`Skipped (valid): ${stats.skipped - stats.missingLocation}`);
  console.log(`Skipped (no location): ${stats.missingLocation}`);
  console.log(`Errors: ${stats.errors}`);
  console.log('═══════════════════════════════════════════════\n');

  if (dryRun && stats.updated > 0) {
    console.log('⚠️  This was a DRY RUN. No changes were made.');
    console.log('   Run without --dry-run to apply changes.\n');
  }
}

// Parse command line arguments
const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');

// Run the backfill
backfillGeohashes(dryRun)
  .then(() => {
    console.log('Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Script failed:', error);
    process.exit(1);
  });
