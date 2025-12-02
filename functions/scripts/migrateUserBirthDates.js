#!/usr/bin/env node
/**
 * Migration Script: Add random birth dates to users without birthDate
 * 
 * This script:
 * 1. Finds all users without birthDate field
 * 2. Assigns a random birth date in 1998 (age ~26)
 * 3. Updates the user document with the new birthDate
 * 
 * Usage:
 *   node scripts/migrateUserBirthDates.js
 * 
 * Safety:
 *   - Only updates users without birthDate
 *   - Uses random dates within 1998
 *   - Logs all changes
 */

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

// Initialize Firebase Admin SDK
initializeApp({
  projectId: 'kickabout-ddc06',
});
const db = getFirestore();

/**
 * Generate a random date in 1998
 * Returns a Date object for a random day in 1998
 */
function generateRandomBirthDate1998() {
  // Random month (1-12)
  const month = Math.floor(Math.random() * 12) + 1;
  
  // Random day (1-28 to avoid month-specific issues)
  const day = Math.floor(Math.random() * 28) + 1;
  
  // Year is always 1998
  const year = 1998;
  
  return new Date(year, month - 1, day); // month is 0-indexed in Date
}

async function migrateUserBirthDates() {
  console.log('\n🔧 Starting user birth date migration...\n');
  console.log('📅 Target year: 1998 (age ~26)\n');

  try {
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    console.log(`📊 Found ${usersSnapshot.size} total users\n`);

    let updatedCount = 0;
    let skippedCount = 0;
    const batch = db.batch();
    let batchCount = 0;
    const BATCH_SIZE = 500; // Firestore batch limit

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const userId = userDoc.id;

      // Check if user already has birthDate
      if (userData.birthDate) {
        skippedCount++;
        continue;
      }

      // Generate random birth date in 1998
      const randomBirthDate = generateRandomBirthDate1998();
      const birthDateTimestamp = Timestamp.fromDate(randomBirthDate);

      // Add to batch
      batch.update(userDoc.ref, {
        birthDate: birthDateTimestamp,
      });

      batchCount++;
      updatedCount++;

      // Commit batch if we reach the limit
      if (batchCount >= BATCH_SIZE) {
        await batch.commit();
        console.log(`✅ Committed batch of ${batchCount} users`);
        batchCount = 0;
      }
    }

    // Commit remaining updates
    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Committed final batch of ${batchCount} users`);
    }

    console.log('\n📊 Migration Summary:');
    console.log(`   ✅ Updated: ${updatedCount} users`);
    console.log(`   ⏭️  Skipped: ${skippedCount} users (already have birthDate)`);
    console.log(`   📊 Total: ${usersSnapshot.size} users\n`);

    console.log('✅ Migration completed successfully!\n');
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

// Run migration
migrateUserBirthDates()
  .then(() => {
    console.log('🎉 Script finished');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Fatal error:', error);
    process.exit(1);
  });
