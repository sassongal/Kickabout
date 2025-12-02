#!/usr/bin/env node
/**
 * Script to fix venues with empty or missing hubId
 * 
 * This script:
 * 1. Iterates through all hubs
 * 2. For each hub, updates all venues in venueIds array with the correct hubId
 * 3. Prioritizes primaryVenueId if it exists
 * 
 * Usage:
 *   node scripts/fixVenueHubIds.js
 */

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// Initialize Firebase Admin SDK
initializeApp({
  projectId: 'kickabout-ddc06',
});
const db = getFirestore();

async function fixVenueHubIds() {
  console.log('\n🔧 Starting venue hubId fix...\n');

  try {
    // First, get all hubs and build a map of venueId -> hubId
    const hubsSnapshot = await db.collection('hubs').get();
    console.log(`📊 Found ${hubsSnapshot.size} hubs to process\n`);

    // Build a map: venueId -> hubId (prioritize primaryVenueId/mainVenueId)
    const venueToHubMap = new Map();

    for (const hubDoc of hubsSnapshot.docs) {
      const hubId = hubDoc.id;
      const hubData = hubDoc.data();
      
      const venueIds = Array.isArray(hubData['venueIds']) ? hubData['venueIds'] : [];
      const primaryVenueId = hubData['primaryVenueId'] || null;
      const mainVenueId = hubData['mainVenueId'] || null;

      // Prioritize primaryVenueId/mainVenueId
      if (primaryVenueId && !venueToHubMap.has(primaryVenueId)) {
        venueToHubMap.set(primaryVenueId, hubId);
      }
      if (mainVenueId && !venueToHubMap.has(mainVenueId)) {
        venueToHubMap.set(mainVenueId, hubId);
      }
      
      // Add all venueIds
      for (const venueId of venueIds) {
        if (venueId && !venueToHubMap.has(venueId)) {
          venueToHubMap.set(venueId, hubId);
        }
      }
    }

    console.log(`📝 Built map: ${venueToHubMap.size} venues linked to hubs\n`);

    // Now get all venues and update those with empty hubId
    const venuesSnapshot = await db.collection('venues').get();
    console.log(`📊 Found ${venuesSnapshot.size} venues to check\n`);

    let totalUpdated = 0;
    let totalSkipped = 0;
    let totalErrors = 0;
    const BATCH_SIZE = 500; // Firestore batch limit
    let batch = db.batch();
    let batchCount = 0;

    for (const venueDoc of venuesSnapshot.docs) {
      try {
        const venueId = venueDoc.id;
        const venueData = venueDoc.data();
        const currentHubId = venueData?.['hubId'] || '';

        // Only update if hubId is empty or missing
        if (!currentHubId || currentHubId === '') {
          // Check if this venue is linked to a hub
          const hubId = venueToHubMap.get(venueId);
          
          if (hubId) {
            batch.update(venueDoc.ref, {
              hubId: hubId,
              updatedAt: FieldValue.serverTimestamp(),
            });
            batchCount++;
            totalUpdated++;
            console.log(`📝 Will update venue ${venueId} with hubId: ${hubId}`);

            if (batchCount >= BATCH_SIZE) {
              await batch.commit();
              console.log(`✅ Committed batch: ${totalUpdated} venues updated so far...`);
              batch = db.batch();
              batchCount = 0;
            }
          } else {
            totalSkipped++;
            // Venue is not linked to any hub - this is OK for public venues
          }
        } else {
          totalSkipped++;
        }
      } catch (venueError) {
        console.log(`❌ Error processing venue ${venueDoc.id}: ${venueError.message}`);
        totalErrors++;
      }
    }

    // Commit remaining batch
    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Committed final batch`);
    }

    console.log('\n📊 HubId Fix Summary:');
    console.log(`   ✅ Updated: ${totalUpdated}`);
    console.log(`   ⏭️  Skipped: ${totalSkipped}`);
    console.log(`   ❌ Errors: ${totalErrors}`);
    console.log(`   📝 Total venues processed: ${venuesSnapshot.size}`);
    console.log(`   📝 Total hubs found: ${hubsSnapshot.size}\n`);

    return {
      success: true,
      updated: totalUpdated,
      skipped: totalSkipped,
      errors: totalErrors,
      totalHubs: hubsSnapshot.size,
      totalVenues: venuesSnapshot.size,
    };
  } catch (error) {
    console.error(`\n❌ Error fixing venue hubIds:`, error.message);
    if (error.code) {
      console.error(`   Error Code: ${error.code}`);
    }
    if (error.stack) {
      console.error(`\nStack trace:\n${error.stack}`);
    }
    throw error;
  }
}

// Main execution
fixVenueHubIds()
  .then((result) => {
    if (result.success) {
      console.log('🎉 Venue hubId fix completed successfully!\n');
      process.exit(0);
    } else {
      console.error('\n❌ Fix completed with errors\n');
      process.exit(1);
    }
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });
