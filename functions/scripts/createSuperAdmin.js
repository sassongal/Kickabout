#!/usr/bin/env node
/**
 * Script to create a super admin user with full permissions
 * 
 * Usage:
 *   node scripts/createSuperAdmin.js <phoneNumber>
 * 
 * Example:
 *   node scripts/createSuperAdmin.js 0546468676
 */

const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// Initialize Firebase Admin SDK with explicit project ID
initializeApp({
  projectId: 'kickabout-ddc06',
});
const db = getFirestore();
const auth = getAuth();

async function createSuperAdmin(phoneNumber) {
  console.log(`\n🔧 Creating super admin for phone: ${phoneNumber}\n`);

  try {
    // Find user by phone number
    const usersSnapshot = await db
      .collection('users')
      .where('phoneNumber', '==', phoneNumber.trim())
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      throw new Error(`❌ User with phone number ${phoneNumber} not found`);
    }

    const userDoc = usersSnapshot.docs[0];
    const userId = userDoc.id;
    const userData = userDoc.data();

    console.log(`✅ Found user: ${userId}`);
    console.log(`   Name: ${userData.name || 'N/A'}`);
    console.log(`   Email: ${userData.email || 'N/A'}`);
    console.log(`   Phone: ${userData.phoneNumber || 'N/A'}\n`);

    // Get all hubs
    const hubsSnapshot = await db.collection('hubs').get();
    const hubIds = hubsSnapshot.docs.map((doc) => doc.id);

    console.log(`📊 Found ${hubIds.length} hubs to add admin to\n`);

    if (hubIds.length === 0) {
      console.log('⚠️  No hubs found. User will be set as super admin but won\'t be added to any hubs.\n');
    }

    // Add user as admin to all hubs
    const batch = db.batch();
    for (const hubId of hubIds) {
      const hubRef = db.collection('hubs').doc(hubId);
      const hubData = hubsSnapshot.docs.find(doc => doc.id === hubId)?.data();
      const hubName = hubData?.name || hubId;
      
      batch.update(hubRef, {
        [`roles.${userId}`]: 'admin',
      });
      console.log(`   ✓ Adding admin to hub: ${hubName} (${hubId})`);
    }

    // Update user's hubIds to include all hubs
    const updatedHubIds = [...new Set([...userData.hubIds || [], ...hubIds])];
    batch.update(userDoc.ref, {
      hubIds: updatedHubIds,
    });

    await batch.commit();
    console.log(`\n✅ Added user ${userId} as admin to ${hubIds.length} hubs`);

    // Set custom claims for super admin
    const customClaims = {
      isSuperAdmin: true,
      hubIds: updatedHubIds,
      roles: {},
    };

    // Add admin role for all hubs
    for (const hubId of hubIds) {
      customClaims.roles[hubId] = 'admin';
    }

    await auth.setCustomUserClaims(userId, customClaims);
    console.log(`✅ Set super admin custom claims for user ${userId}`);

    console.log('\n🎉 Success! Super admin created successfully!\n');
    console.log('Summary:');
    console.log(`   User ID: ${userId}`);
    console.log(`   User Name: ${userData.name || userData.email}`);
    console.log(`   Phone: ${phoneNumber}`);
    console.log(`   Hubs Added: ${hubIds.length}`);
    console.log(`   Custom Claims: isSuperAdmin=true, roles=${hubIds.length} hubs\n`);

    return {
      success: true,
      userId: userId,
      userName: userData.name || userData.email,
      hubsAdded: hubIds.length,
      message: `Super admin created successfully. User is now admin of ${hubIds.length} hubs.`,
    };
  } catch (error) {
    console.error(`\n❌ Error creating super admin:`, error.message);
    if (error.code) {
      console.error(`   Error Code: ${error.code}`);
    }
    if (error.stack) {
      console.error(`\nStack trace:\n${error.stack}`);
    }
    process.exit(1);
  }
}

// Main execution
const phoneNumber = process.argv[2];

if (!phoneNumber) {
  console.error('\n❌ Error: Phone number is required\n');
  console.log('Usage:');
  console.log('  node scripts/createSuperAdmin.js <phoneNumber>\n');
  console.log('Example:');
  console.log('  node scripts/createSuperAdmin.js 0546468676\n');
  process.exit(1);
}

createSuperAdmin(phoneNumber)
  .then(() => {
    console.log('✅ Script completed successfully\n');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });
