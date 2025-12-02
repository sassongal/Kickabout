#!/usr/bin/env node
/**
 * Script to fix DateTime fields in venues - convert all string DateTime to Firestore Timestamp
 * 
 * This script specifically targets venues with string DateTime fields and converts them to Timestamp
 * 
 * Usage:
 *   node scripts/fixVenueDateTimes.js
 */

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');

// Initialize Firebase Admin SDK
initializeApp({
  projectId: 'kickabout-ddc06',
});
const db = getFirestore();

function parseDateTimeString(value) {
  if (typeof value !== 'string') {
    return null;
  }
  
  try {
    let date;
    // Try ISO format first
    if (value.includes('T') || value.includes('Z')) {
      // Handle timezone issues
      if (value.includes('T') && !value.includes('Z') && !value.includes('+') && !value.includes('-', 10)) {
        date = new Date(value + 'Z');
      } else {
        date = new Date(value);
      }
    } else if (value.includes(' ')) {
      // Try format: "2025-11-29 02:57:49.459"
      const isoString = value.replace(' ', 'T');
      date = new Date(isoString + 'Z');
    } else {
      date = new Date(value);
    }
    
    // Convert Date to Firestore Timestamp
    return Timestamp.fromDate(date);
  } catch (e) {
    console.log(`⚠️  Could not parse DateTime string "${value}": ${e.message}`);
    return null;
  }
}

async function fixVenueDateTimes() {
  console.log('\n🔧 Starting venue DateTime fix...\n');

  try {
    // Get all venues
    const venuesSnapshot = await db.collection('venues').get();
    console.log(`📊 Found ${venuesSnapshot.size} venues to process\n`);

    if (venuesSnapshot.empty) {
      console.log('⚠️  No venues found in database\n');
      return { success: true, updated: 0, skipped: 0, errors: 0 };
    }

    let updated = 0;
    let skipped = 0;
    let errors = 0;
    const BATCH_SIZE = 500; // Firestore batch limit
    let batch = db.batch();
    let batchCount = 0;

    for (const doc of venuesSnapshot.docs) {
      try {
        const venueId = doc.id;
        const data = doc.data();
        
        // Check if createdAt or updatedAt are strings
        const needsUpdate = {};
        let hasStringDateTime = false;
        
        if (data.createdAt && typeof data.createdAt === 'string') {
          const timestamp = parseDateTimeString(data.createdAt);
          if (timestamp) {
            needsUpdate.createdAt = timestamp;
            hasStringDateTime = true;
            console.log(`📝 Venue ${venueId}: createdAt is string, will convert to Timestamp`);
          }
        }
        
        if (data.updatedAt && typeof data.updatedAt === 'string') {
          const timestamp = parseDateTimeString(data.updatedAt);
          if (timestamp) {
            needsUpdate.updatedAt = timestamp;
            hasStringDateTime = true;
            console.log(`📝 Venue ${venueId}: updatedAt is string, will convert to Timestamp`);
          }
        }

        if (hasStringDateTime && Object.keys(needsUpdate).length > 0) {
          // Always update updatedAt to current time (but keep the converted value if we have it)
          if (!needsUpdate.updatedAt) {
            needsUpdate.updatedAt = FieldValue.serverTimestamp();
          }
          
          batch.update(doc.ref, needsUpdate);
          batchCount++;
          updated++;
          console.log(`✅ Will update venue ${venueId} with ${Object.keys(needsUpdate).length} DateTime fields`);

          if (batchCount >= BATCH_SIZE) {
            await batch.commit();
            console.log(`✅ Committed batch: ${updated} venues updated so far...`);
            batch = db.batch();
            batchCount = 0;
          }
        } else {
          skipped++;
        }
      } catch (e) {
        errors++;
        console.log(`❌ Error processing venue ${doc.id}: ${e.message}`);
        if (e.stack) {
          console.log(`   Stack: ${e.stack.split('\n')[0]}`);
        }
      }
    }

    // Commit remaining batch
    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Committed final batch`);
    }

    console.log('\n📊 DateTime Fix Summary:');
    console.log(`   ✅ Updated: ${updated}`);
    console.log(`   ⏭️  Skipped: ${skipped}`);
    console.log(`   ❌ Errors: ${errors}`);
    console.log(`   📝 Total: ${venuesSnapshot.size}\n`);

    return {
      success: true,
      updated,
      skipped,
      errors,
      total: venuesSnapshot.size,
    };
  } catch (error) {
    console.error(`\n❌ Error fixing venue DateTimes:`, error.message);
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
fixVenueDateTimes()
  .then((result) => {
    if (result.success) {
      console.log('🎉 Venue DateTime fix completed successfully!\n');
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
