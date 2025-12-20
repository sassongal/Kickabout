#!/usr/bin/env node
/**
 * LOCAL MIGRATION SCRIPT
 * Run this locally with admin credentials to migrate hub member arrays
 *
 * USAGE:
 *   cd functions
 *   node src/migrations/run_migration_local.js
 *
 * REQUIREMENTS:
 *   - Must have Firebase Admin SDK credentials
 *   - Run from functions directory (or adjust path to service account key)
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
// Uses Application Default Credentials from Firebase CLI
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
 * Main migration function
 */
async function runMigration() {
    try {
        console.log('🚀 Starting hub member arrays migration...');

        // Fetch all hubs
        const hubsSnap = await db.collection('hubs').get();
        const totalHubs = hubsSnap.size;

        console.log(`📊 Found ${totalHubs} hubs to migrate`);

        const results = [];
        let successCount = 0;
        let errorCount = 0;

        // Process hubs in batches of 10 (parallel)
        const batchSize = 10;
        for (let i = 0; i < hubsSnap.docs.length; i += batchSize) {
            const batch = hubsSnap.docs.slice(i, i + batchSize);
            const batchResults = await Promise.all(
                batch.map((doc) => syncHubMemberArrays(doc.id))
            );

            batchResults.forEach((result) => {
                results.push(result);
                if (result.success) {
                    successCount++;
                } else {
                    errorCount++;
                }
            });

            console.log(`⏳ Progress: ${Math.min(i + batchSize, totalHubs)}/${totalHubs}`);
        }

        console.log('\n✨ Migration complete!');
        console.log(`✅ Success: ${successCount}`);
        console.log(`❌ Errors: ${errorCount}`);

        if (errorCount > 0) {
            console.log('\n❌ Failed hubs:');
            results.filter(r => !r.success).forEach(r => {
                console.log(`  - ${r.hubId}: ${r.error}`);
            });
        }

        process.exit(errorCount > 0 ? 1 : 0);
    } catch (error) {
        console.error('💥 Migration failed:', error);
        process.exit(1);
    }
}

// Run the migration
runMigration();
