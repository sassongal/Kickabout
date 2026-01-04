const admin = require('firebase-admin');
const serviceAccount = require('./functions/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkHubMembership() {
  const hubId = '1WE1kk3fwIhBXrTx1dFn';

  try {
    const hubDoc = await db.collection('hubs').doc(hubId).get();

    if (!hubDoc.exists) {
      console.log('Hub not found: ' + hubId);
      return;
    }

    const hubData = hubDoc.data();
    console.log('\nHub found: ' + hubData.name);
    console.log('createdBy: ' + hubData.createdBy);
    console.log('activeMemberIds: ' + JSON.stringify(hubData.activeMemberIds || []));
    console.log('memberIds: ' + JSON.stringify(hubData.memberIds || []));
    console.log('managerIds: ' + JSON.stringify(hubData.managerIds || []));

    const membersSnapshot = await db.collection('hubs').doc(hubId).collection('members').get();
    console.log('\nMembers subcollection (' + membersSnapshot.size + ' members):');
    membersSnapshot.forEach(doc => {
      const data = doc.data();
      console.log('  - ' + doc.id + ': role=' + data.role + ', status=' + data.status);
    });

  } catch (error) {
    console.error('Error: ' + error.message);
  }

  process.exit(0);
}

checkHubMembership();
