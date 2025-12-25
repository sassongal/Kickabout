/**
 * Script to sync all hub member arrays and user hubIds
 * Run with: node scripts/sync_all_hubs.js
 * 
 * This script:
 * 1. Syncs activeMemberIds, managerIds, moderatorIds for all hubs
 * 2. Syncs hubIds for all users based on their active memberships
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'kickabout-ddc06',
});

const db = admin.firestore();

/**
 * Sync denormalized member arrays for a single hub
 */
async function syncHubMemberArrays(hubId) {
  try {
    // Fetch all active members
    const membersSnap = await db
      .collection(`hubs/${hubId}/members`)
      .where('status', '==', 'active')
      .get();

    const activeMemberIds = [];
    const managerIds = [];
    const moderatorIds = [];

    membersSnap.forEach((doc) => {
      const data = doc.data();
      const userId = doc.id;
      const role = data.role || 'member';

      activeMemberIds.push(userId);

      if (role === 'manager') {
        managerIds.push(userId);
      } else if (role === 'moderator') {
        moderatorIds.push(userId);
      }
    });

    // Update hub document
    await db.doc(`hubs/${hubId}`).update({
      activeMemberIds,
      managerIds,
      moderatorIds,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Synced ${hubId}: ${activeMemberIds.length} active, ${managerIds.length} managers, ${moderatorIds.length} moderators`);
    return { hubId, success: true, memberCount: activeMemberIds.length };
  } catch (error) {
    console.error(`❌ Error syncing ${hubId}:`, error.message);
    return { hubId, success: false, error: error.message };
  }
}

/**
 * Sync user.hubIds array based on active memberships
 */
async function syncUserHubIds(userId) {
  try {
    // Find all hubs where user is an active member
    // Note: collectionGroup query can't use documentId in where clause
    // So we query all active members and filter by userId from path
    const membershipsSnap = await db
      .collectionGroup('members')
      .where('status', '==', 'active')
      .get();

    const hubIds = [];
    membershipsSnap.forEach((doc) => {
      // Extract hubId and userId from path: hubs/{hubId}/members/{userId}
      const pathParts = doc.ref.path.split('/');
      if (pathParts.length >= 4 && pathParts[0] === 'hubs' && pathParts[3] === userId) {
        hubIds.push(pathParts[1]);
      }
    });

    // Update user document
    await db.collection('users').doc(userId).update({
      hubIds,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Synced user ${userId}: ${hubIds.length} hubs`);
    return { userId, success: true, hubCount: hubIds.length };
  } catch (err) {
    console.error(`❌ Error syncing user ${userId}:`, err.message);
    return { userId, success: false, error: err.message };
  }
}

/**
 * Main function
 */
async function main() {
  try {
    console.log('🚀 Starting sync of all hubs and users...\n');

    // Step 1: Sync all hubs
    console.log('📊 Step 1: Syncing hub member arrays...');
    const hubsSnap = await db.collection('hubs').get();
    const totalHubs = hubsSnap.size;
    console.log(`Found ${totalHubs} hubs to sync\n`);

    const hubResults = [];
    let hubSuccessCount = 0;
    let hubErrorCount = 0;

    // Process hubs in batches of 10
    const batchSize = 10;
    for (let i = 0; i < hubsSnap.docs.length; i += batchSize) {
      const batch = hubsSnap.docs.slice(i, i + batchSize);
      const batchResults = await Promise.all(
        batch.map((doc) => syncHubMemberArrays(doc.id))
      );

      batchResults.forEach((result) => {
        hubResults.push(result);
        if (result.success) {
          hubSuccessCount++;
        } else {
          hubErrorCount++;
        }
      });

      console.log(`⏳ Hub progress: ${Math.min(i + batchSize, totalHubs)}/${totalHubs}\n`);
    }

    console.log(`✨ Hub sync complete!`);
    console.log(`✅ Success: ${hubSuccessCount}`);
    console.log(`❌ Errors: ${hubErrorCount}\n`);

    // Step 2: Sync all users
    console.log('📊 Step 2: Syncing user hubIds...');
    const usersSnap = await db.collection('users').get();
    const totalUsers = usersSnap.size;
    console.log(`Found ${totalUsers} users to sync\n`);

    const userResults = [];
    let userSuccessCount = 0;
    let userErrorCount = 0;

    // Process users in batches of 10
    for (let i = 0; i < usersSnap.docs.length; i += batchSize) {
      const batch = usersSnap.docs.slice(i, i + batchSize);
      const batchResults = await Promise.all(
        batch.map((doc) => syncUserHubIds(doc.id))
      );

      batchResults.forEach((result) => {
        userResults.push(result);
        if (result.success) {
          userSuccessCount++;
        } else {
          userErrorCount++;
        }
      });

      console.log(`⏳ User progress: ${Math.min(i + batchSize, totalUsers)}/${totalUsers}\n`);
    }

    console.log(`✨ User sync complete!`);
    console.log(`✅ Success: ${userSuccessCount}`);
    console.log(`❌ Errors: ${userErrorCount}\n`);

    // Summary
    console.log('🎉 All syncs complete!');
    console.log(`\nSummary:`);
    console.log(`- Hubs: ${hubSuccessCount}/${totalHubs} successful`);
    console.log(`- Users: ${userSuccessCount}/${totalUsers} successful`);

    process.exit(0);
  } catch (error) {
    console.error('💥 Sync failed:', error);
    process.exit(1);
  }
}

// Run the script
main();

