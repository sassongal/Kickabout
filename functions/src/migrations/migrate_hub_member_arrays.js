/**
 * ONE-TIME MIGRATION SCRIPT
 * Backfills denormalized member arrays (activeMemberIds, managerIds, moderatorIds)
 * on all existing Hub documents to enable optimized Firestore Rules.
 * 
 * USAGE:
 * 1. Deploy this function: `firebase deploy --only functions:migrateHubMemberArrays`
 * 2. Call via HTTP trigger or Firebase Console
 * 3. Monitor logs for progress
 * 4. Verify in Firestore Console that hubs have the new arrays
 * 5. THEN deploy the new firestore.rules
 * 
 * SAFETY:
 * - Idempotent: Can be run multiple times safely
 * - Non-destructive: Only adds fields, never deletes
 * - Batched: Processes hubs in batches to avoid timeouts
 */

const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions/v2');
const admin = require('firebase-admin');

/**
 * Sync denormalized member arrays for a single hub
 */
async function syncHubMemberArrays(db, hubId) {
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
        console.error(`❌ Error syncing ${hubId}:`, error);
        return { hubId, success: false, error: error.message };
    }
}

/**
 * HTTP-triggered migration function
 * Call this endpoint to migrate all hubs
 */
exports.migrateHubMemberArrays = onRequest(
    { invoker: 'public' },
    async (req, res) => {
    const db = admin.firestore();

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
                batch.map((doc) => syncHubMemberArrays(db, doc.id))
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

        console.log('✨ Migration complete!');
        console.log(`✅ Success: ${successCount}`);
        console.log(`❌ Errors: ${errorCount}`);

        res.status(200).json({
            success: true,
            totalHubs,
            successCount,
            errorCount,
            results,
        });
    } catch (error) {
        console.error('💥 Migration failed:', error);
        res.status(500).json({
            success: false,
            error: error.message,
        });
    }
});

/**
 * Firestore-triggered function to sync member arrays on membership changes
 * IMPORTANT: This should be deployed AFTER the manual migration completes
 */
exports.onMembershipChangeSync = onDocumentWritten(
    'hubs/{hubId}/members/{userId}',
    async (event) => {
        const { hubId } = event.params;
        const db = admin.firestore();

        try {
            await syncHubMemberArrays(db, hubId);
            logger.info(`✅ Auto-synced member arrays for hub ${hubId}`);
        } catch (error) {
            logger.error(`❌ Error auto-syncing hub ${hubId}:`, error);
            // Non-fatal: client-side writes will still work
        }
    }
);
