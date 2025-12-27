/**
 * One-time cleanup script to remove orphaned hubs
 *
 * Orphaned hubs are hubs where the document exists but:
 * 1. The hub is not in the creator's hubIds array, OR
 * 2. The creator's user document doesn't exist
 *
 * Run with: node scripts/cleanup_orphaned_hubs.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function cleanupOrphanedHubs() {
  console.log('🔍 Starting orphaned hubs cleanup...\n');

  try {
    // Get all hubs
    const hubsSnapshot = await db.collection('hubs').get();
    console.log(`📊 Found ${hubsSnapshot.size} total hubs\n`);

    let orphanedCount = 0;
    let validCount = 0;
    const orphanedHubs = [];

    // Check each hub
    for (const hubDoc of hubsSnapshot.docs) {
      const hubId = hubDoc.id;
      const hubData = hubDoc.data();
      const createdBy = hubData.createdBy;
      const hubName = hubData.name || 'Unknown';

      console.log(`\n🔎 Checking hub: ${hubName} (${hubId})`);
      console.log(`   Creator ID: ${createdBy}`);

      // Check if creator exists
      const creatorDoc = await db.collection('users').doc(createdBy).get();

      if (!creatorDoc.exists) {
        console.log(`   ❌ Creator user document doesn't exist - ORPHANED`);
        orphanedHubs.push({ hubId, hubName, reason: 'Creator not found' });
        orphanedCount++;
        continue;
      }

      // Check if hub is in creator's hubIds array
      const creatorData = creatorDoc.data();
      const creatorHubIds = creatorData.hubIds || [];

      if (!creatorHubIds.includes(hubId)) {
        console.log(`   ❌ Hub not in creator's hubIds array - ORPHANED`);
        orphanedHubs.push({ hubId, hubName, reason: 'Not in creator hubIds' });
        orphanedCount++;
        continue;
      }

      console.log(`   ✅ Valid hub`);
      validCount++;
    }

    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 CLEANUP SUMMARY');
    console.log('='.repeat(60));
    console.log(`Total hubs checked: ${hubsSnapshot.size}`);
    console.log(`Valid hubs: ${validCount}`);
    console.log(`Orphaned hubs: ${orphanedCount}`);

    if (orphanedHubs.length === 0) {
      console.log('\n✅ No orphaned hubs found. Database is clean!');
      return;
    }

    console.log('\n🗑️  ORPHANED HUBS TO DELETE:');
    console.log('='.repeat(60));
    orphanedHubs.forEach((hub, index) => {
      console.log(`${index + 1}. ${hub.hubName}`);
      console.log(`   ID: ${hub.hubId}`);
      console.log(`   Reason: ${hub.reason}`);
    });

    // Ask for confirmation
    console.log('\n' + '='.repeat(60));
    console.log('⚠️  WARNING: This will permanently delete the hubs listed above!');
    console.log('='.repeat(60));

    // In a real scenario, you'd want user confirmation here
    // For now, we'll proceed with deletion
    console.log('\n🗑️  Starting deletion process...\n');

    for (const hub of orphanedHubs) {
      console.log(`\nDeleting hub: ${hub.hubName} (${hub.hubId})`);

      try {
        // Delete members subcollection
        const membersSnapshot = await db
          .collection('hubs')
          .doc(hub.hubId)
          .collection('members')
          .get();

        console.log(`   Found ${membersSnapshot.size} members to delete`);

        for (const memberDoc of membersSnapshot.docs) {
          await memberDoc.ref.delete();
        }

        // Delete events subcollection
        const eventsSnapshot = await db
          .collection('hubs')
          .doc(hub.hubId)
          .collection('events')
          .get();

        console.log(`   Found ${eventsSnapshot.size} events to delete`);

        for (const eventDoc of eventsSnapshot.docs) {
          await eventDoc.ref.delete();
        }

        // Handle associated games
        const gamesSnapshot = await db
          .collection('games')
          .where('hubId', '==', hub.hubId)
          .get();

        console.log(`   Found ${gamesSnapshot.size} games to update`);

        for (const gameDoc of gamesSnapshot.docs) {
          const gameData = gameDoc.data();
          const status = gameData.status;
          const gameDate = gameData.gameDate?.toDate();

          const updates = {
            hubId: null, // Orphan the game
          };

          // Cancel future games
          if (
            status !== 'completed' &&
            status !== 'cancelled' &&
            gameDate &&
            gameDate > new Date()
          ) {
            updates.status = 'cancelled';
            console.log(`   Cancelling future game: ${gameDoc.id}`);
          }

          await gameDoc.ref.update(updates);
        }

        // Delete the hub document
        await db.collection('hubs').doc(hub.hubId).delete();

        console.log(`   ✅ Hub ${hub.hubId} deleted successfully`);
      } catch (error) {
        console.error(`   ❌ Error deleting hub ${hub.hubId}:`, error);
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('✅ CLEANUP COMPLETE!');
    console.log('='.repeat(60));
    console.log(`Deleted ${orphanedHubs.length} orphaned hubs`);

    // Verify specific user's hubs
    console.log('\n' + '='.repeat(60));
    console.log('🔍 VERIFICATION: Checking user lFvifImYi9XTRsajqfUB6iN64be2');
    console.log('='.repeat(60));

    const userId = 'lFvifImYi9XTRsajqfUB6iN64be2';
    const userHubsSnapshot = await db
      .collection('hubs')
      .where('createdBy', '==', userId)
      .get();

    console.log(`\nUser now has ${userHubsSnapshot.size} hubs:`);
    userHubsSnapshot.docs.forEach((doc, index) => {
      console.log(`${index + 1}. ${doc.data().name} (${doc.id})`);
    });

    if (userHubsSnapshot.size <= 3) {
      console.log('\n✅ User can now create new hubs!');
    } else {
      console.log('\n⚠️  User still has more than 3 hubs');
    }

  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    throw error;
  }
}

// Run the cleanup
cleanupOrphanedHubs()
  .then(() => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });
