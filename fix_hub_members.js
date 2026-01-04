/**
 * Fix a specific hub's member arrays
 * Usage: node fix_hub_members.js <hubId>
 * 
 * This will:
 * 1. Read all active members from the hub's members subcollection
 * 2. Update activeMemberIds, managerIds, moderatorIds on the hub document
 */

const admin = require('firebase-admin');

// Get hub ID from command line
const hubId = process.argv[2];

if (!hubId) {
  console.error('❌ Please provide a hub ID');
  console.error('Usage: node fix_hub_members.js <hubId>');
  process.exit(1);
}

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'kickabout-ddc06',
});

const db = admin.firestore();

async function fixHubMembers() {
  try {
    console.log('Fixing hub: ' + hubId + '\n');

    // Fetch hub document
    const hubDoc = await db.collection('hubs').doc(hubId).get();
    if (!hubDoc.exists) {
      console.error('Hub not found: ' + hubId);
      process.exit(1);
    }

    const hubData = hubDoc.data();
    console.log('Hub name: ' + hubData.name);
    console.log('Created by: ' + hubData.createdBy);
    console.log('\nCurrent arrays:');
    console.log('  activeMemberIds: ' + JSON.stringify(hubData.activeMemberIds || []));
    console.log('  managerIds: ' + JSON.stringify(hubData.managerIds || []));
    console.log('  moderatorIds: ' + JSON.stringify(hubData.moderatorIds || []));

    // Fetch all active members
    const membersSnap = await db
      .collection('hubs/' + hubId + '/members')
      .where('status', '==', 'active')
      .get();

    const activeMemberIds = [];
    const managerIds = [];
    const moderatorIds = [];

    console.log('\n' + membersSnap.size + ' active members found:');
    membersSnap.forEach((doc) => {
      const data = doc.data();
      const userId = doc.id;
      const role = data.role || 'member';

      console.log('  - ' + userId + ': role=' + role);

      activeMemberIds.push(userId);

      if (role === 'manager') {
        managerIds.push(userId);
      } else if (role === 'moderator') {
        moderatorIds.push(userId);
      }
    });

    // Update hub document
    console.log('\nUpdating hub document...');
    await db.doc('hubs/' + hubId).update({
      activeMemberIds: activeMemberIds,
      managerIds: managerIds,
      moderatorIds: moderatorIds,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('\nNew arrays:');
    console.log('  activeMemberIds: ' + JSON.stringify(activeMemberIds));
    console.log('  managerIds: ' + JSON.stringify(managerIds));
    console.log('  moderatorIds: ' + JSON.stringify(moderatorIds));

    console.log('\n✅ Hub fixed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error fixing hub:', error.message);
    process.exit(1);
  }
}

fixHubMembers();
