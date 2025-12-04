const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const { info, error, warn } = require('firebase-functions/logger');

const VETERAN_THRESHOLD_DAYS = 60;
const BATCH_SIZE = 500;

/**
 * Scheduled function: Promote members to veteran after 60 days
 * Runs daily at 2 AM UTC
 * 
 * This function ensures veteran status is SERVER-MANAGED, not client-computed.
 * Eliminates DateTime.now() issues, timezone problems, and audit trail gaps.
 */
exports.promoteVeterans = onSchedule(
    {
        schedule: '0 2 * * *', // Daily at 2 AM UTC
        timeZone: 'UTC',
        region: 'us-central1',
        memory: '256MiB',
    },
    async (event) => {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();
        const thresholdDate = new Date(
            now.toMillis() - (VETERAN_THRESHOLD_DAYS * 24 * 60 * 60 * 1000)
        );

        info(`[promoteVeterans] Starting check for members joined before ${thresholdDate.toISOString()}`);

        try {
            // Query all active members eligible for promotion:
            // 1. Joined >= 60 days ago
            // 2. Still have role='member' (not veteran, moderator, or manager)
            // 3. Status = active (not left or banned)
            // 4. Don't already have veteranSince set
            const membersSnapshot = await db.collectionGroup('members')
                .where('status', '==', 'active')
                .where('role', '==', 'member')
                .where('joinedAt', '<=', admin.firestore.Timestamp.fromDate(thresholdDate))
                .where('veteranSince', '==', null)
                .get();

            if (membersSnapshot.empty) {
                info('[promoteVeterans] No members eligible for promotion');
                return null;
            }

            info(`[promoteVeterans] Found ${membersSnapshot.docs.length} members eligible`);

            // Process in batches to avoid write limits (500 per batch)
            let promotedCount = 0;
            let errorCount = 0;
            const batches = [];
            let currentBatch = db.batch();
            let batchOpsCount = 0;

            for (const doc of membersSnapshot.docs) {
                const memberData = doc.data();
                const hubId = doc.ref.parent.parent.id;
                const userId = doc.id;

                // Safety check: Double-verify eligibility
                const daysSinceJoined = Math.floor(
                    (now.toMillis() - memberData.joinedAt.toMillis()) / (24 * 60 * 60 * 1000)
                );

                if (daysSinceJoined < VETERAN_THRESHOLD_DAYS) {
                    warn(`[promoteVeterans] Skipping ${userId} in ${hubId}: only ${daysSinceJoined} days`);
                    continue;
                }

                // Update member: promote to veteran
                currentBatch.update(doc.ref, {
                    role: 'veteran',
                    veteranSince: now,
                    updatedAt: now,
                    updatedBy: 'system:promoteVeterans'
                });

                batchOpsCount++;

                // Commit batch when full
                if (batchOpsCount >= BATCH_SIZE) {
                    batches.push(currentBatch);
                    currentBatch = db.batch();
                    batchOpsCount = 0;
                }
            }

            // Add final batch if not empty
            if (batchOpsCount > 0) {
                batches.push(currentBatch);
            }

            // Commit all batches
            for (let i = 0; i < batches.length; i++) {
                try {
                    await batches[i].commit();
                    const promotedInBatch = Math.min(BATCH_SIZE, membersSnapshot.docs.length - (i * BATCH_SIZE));
                    promotedCount += promotedInBatch;
                    info(`[promoteVeterans] Batch ${i + 1}/${batches.length} committed: ${promotedInBatch} promotions`);
                } catch (err) {
                    error(`[promoteVeterans] Batch ${i + 1} error:`, err);
                    errorCount++;
                }
            }

            info(`[promoteVeterans] Complete: ${promotedCount} promoted, ${errorCount} errors`);

            // Log to system logs for monitoring
            await db.collection('_system_logs').add({
                type: 'veteran_promotion',
                timestamp: now,
                promotedCount,
                errorCount,
                thresholdDays: VETERAN_THRESHOLD_DAYS,
            });

            return null;
        } catch (err) {
            error('[promoteVeterans] Fatal error:', err);
            throw err;
        }
    }
);
