#!/usr/bin/env node
/**
 * Script to force-create a Super Admin using local Owner credentials.
 * This bypasses Firestore Rules and IAM restrictions by using your local gcloud session.
 * * Usage:
 * node scripts/createSuperAdmin.js
 */

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// Initialize Firebase Admin SDK with Application Default Credentials
// This uses the credentials from 'gcloud auth application-default login'
initializeApp({
  credential: applicationDefault(),
  projectId: 'kickabout-ddc06', // Your exact project ID
});

const db = getFirestore();
const auth = getAuth();

// Your specific UID from the logs
const TARGET_UID = 'lFvifImYi9XTRsajqfUB6iN64be2';

async function makeMeSuperAdmin() {
  console.log(`\n🚀 Starting Super Admin promotion for UID: ${TARGET_UID}...\n`);

  try {
    // 1. Verify User Exists
    const userDocRef = db.collection('users').doc(TARGET_UID);
    const userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      console.log(`❌ User document not found in Firestore. Creating barebones profile...`);
      await userDocRef.set({
        uid: TARGET_UID,
        createdAt: new Date(),
        isSuperAdmin: true
      }, { merge: true });
    } else {
      console.log(`✅ User found: ${userDoc.data().name || 'No Name'} (${userDoc.data().phoneNumber || 'No Phone'})`);
    }

    // 2. Fetch all Hubs to give you control over them
    console.log(`\n📊 Fetching all hubs to grant access...`);
    const hubsSnapshot = await db.collection('hubs').get();
    const hubIds = hubsSnapshot.docs.map((doc) => doc.id);
    console.log(`   Found ${hubIds.length} hubs.`);

    // 3. Update User Document (Firestore)
    const updatedHubIds = [...new Set([...(userDoc.data()?.hubIds || []), ...hubIds])];

    await userDocRef.update({
      isSuperAdmin: true,
      role: 'super_admin', // Just in case UI looks for this
      hubIds: updatedHubIds
    });
    console.log(`✅ Firestore: Marked user as Super Admin and added to all hubs.`);

    // 4. Update Hubs (Firestore) - Add you as admin to EVERY hub
    if (hubIds.length > 0) {
      const batch = db.batch();
      let operationCount = 0;

      for (const hubId of hubIds) {
        const hubRef = db.collection('hubs').doc(hubId);
        // Add you to the roles map as 'admin'
        batch.update(hubRef, {
          [`roles.${TARGET_UID}`]: 'admin'
        });
        operationCount++;
      }

      await batch.commit();
      console.log(`✅ Firestore: Added you as 'admin' to ${operationCount} hubs.`);
    }

    // 5. Set Custom Claims (Auth) - The "God Mode" key
    // This allows you to pass "request.auth.token.isSuperAdmin" checks in Security Rules
    const customClaims = {
      isSuperAdmin: true,
      roles: {}
    };

    // Add explicit admin role for every hub in the token as well
    for (const hubId of hubIds) {
      customClaims.roles[hubId] = 'admin';
    }

    await auth.setCustomUserClaims(TARGET_UID, customClaims);
    console.log(`✅ Auth: Set custom claims (isSuperAdmin=true) on your user token.`);

    console.log('\n🎉 SUCCESS! You are now a Super Admin.');
    console.log('👉 IMPORTANT: You must LOG OUT and LOG IN again in the app for changes to take effect!\n');

  } catch (error) {
    console.error(`\n❌ Error:`, error);
    process.exit(1);
  }
}

// Execute
makeMeSuperAdmin()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });