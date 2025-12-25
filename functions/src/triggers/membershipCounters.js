const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const { info, error, warn } = require('firebase-functions/logger');

/**
 * Sync denormalized member arrays for a hub
 * This rebuilds activeMemberIds, managerIds, and moderatorIds arrays
 */
async function syncHubMemberArrays(hubId) {
    try {
        const membersSnap = await admin.firestore()
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

        // Update hub document with denormalized arrays
        await admin.firestore().doc(`hubs/${hubId}`).update({
            activeMemberIds,
            managerIds,
            moderatorIds,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        info(`[syncArrays] Synced ${hubId}: ${activeMemberIds.length} active, ${managerIds.length} managers, ${moderatorIds.length} moderators`);
    } catch (err) {
        error(`[syncArrays] Error syncing ${hubId}:`, err);
        throw err;
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
        const membershipsSnap = await admin.firestore()
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
        await admin.firestore().doc(`users/${userId}`).update({
            hubIds,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        info(`[syncUserHubIds] Synced ${userId}: ${hubIds.length} hubs`);
    } catch (err) {
        error(`[syncUserHubIds] Error syncing ${userId}:`, err);
        // Non-fatal - don't throw
    }
}

/**
 * Trigger: Update hub.memberCount and sync arrays when membership status changes
 * Triggers on: hubs/{hubId}/members/{userId} write
 * 
 * This keeps the denormalized memberCount and arrays in sync with actual active members.
 * Only counts members with status='active'.
 */
exports.onMembershipChange = onDocumentWritten('hubs/{hubId}/members/{userId}', async (event) => {
    const hubId = event.params.hubId;
    const userId = event.params.userId;
    const hubRef = admin.firestore().doc(`hubs/${hubId}`); // Using admin.firestore() directly (not db from utils)

    const before = event.data.before.exists ? event.data.before.data() : null;
    const after = event.data.after.exists ? event.data.after.data() : null;

    // Determine status changes
    const wasActive = before?.status === 'active';
    const isActive = after?.status === 'active';

    let delta = 0;
    let eventType = '';

    if (!wasActive && isActive) {
        // New active member OR reactivated member
        delta = 1;
        eventType = event.data.before.exists ? 'reactivated' : 'joined';
        info(`[memberCount] ${userId} ${eventType} ${hubId} (delta: +1)`);
    } else if (wasActive && !isActive) {
        // Member left, was banned, or document deleted
        delta = -1;
        eventType = !event.data.after.exists ? 'deleted' :
            after?.status === 'left' ? 'left' :
                after?.status === 'banned' ? 'banned' : 'deactivated';
        info(`[memberCount] ${userId} ${eventType} ${hubId} (delta: -1)`);
    } else {
        // No status change affecting count (e.g., role change, rating update)
        info(`[memberCount] ${userId} updated in ${hubId} (no count change)`);
        // Still sync arrays in case role changed
        await syncHubMemberArrays(hubId);
        await syncUserHubIds(userId);
        return;
    }

    // Update hub document
    try {
        await hubRef.update({
            memberCount: admin.firestore.FieldValue.increment(delta),
            lastActivity: admin.firestore.FieldValue.serverTimestamp(),
        });

        info(`[memberCount] Updated ${hubId}: memberCount += ${delta}`);
    } catch (err) {
        error(`[memberCount] Error updating ${hubId}:`, err);
        throw err;
    }

    // CRITICAL: Sync denormalized arrays after membership change
    await syncHubMemberArrays(hubId);
    
    // CRITICAL: Sync user.hubIds array
    await syncUserHubIds(userId);
});

/**
 * Trigger: Update member.lastActiveAt when they interact with hub
 * Triggers on: hubs/{hubId}/chatMessages/{messageId} create
 * 
 * Helps identify inactive veterans for analytics and future features.
 */
exports.onChatMessage = onDocumentCreated('hubs/{hubId}/chatMessages/{messageId}', async (event) => {
    const hubId = event.params.hubId;
    const messageData = event.data.data();
    const authorId = messageData.authorId;

    if (!authorId) {
        warn(`[lastActive] Chat message in ${hubId} has no authorId`);
        return;
    }

    const memberRef = admin.firestore().doc(`hubs/${hubId}/members/${authorId}`);

    try {
        // Update lastActiveAt (helps identify inactive members)
        await memberRef.update({
            lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        info(`[lastActive] Updated ${authorId} in ${hubId}`);
    } catch (err) {
        // Member doc might not exist (e.g., guest message, or race condition)
        warn(`[lastActive] Could not update ${authorId} in ${hubId}:`, err);
    }
});

/**
 * Trigger: Update member.lastActiveAt on game signup
 * Triggers on: games/{gameId}/signups/{userId} create
 */
exports.onGameSignup = onDocumentCreated('games/{gameId}/signups/{userId}', async (event) => {
    const gameId = event.params.gameId;
    const userId = event.params.userId;

    try {
        // Get game to find hubId
        const gameDoc = await admin.firestore().doc(`games/${gameId}`).get();
        if (!gameDoc.exists) {
            warn(`[lastActive] Game ${gameId} not found`);
            return;
        }

        const gameData = gameDoc.data();
        const hubId = gameData?.hubId;

        if (!hubId) {
            // Pickup game (no hub)
            return;
        }

        const memberRef = admin.firestore().doc(`hubs/${hubId}/members/${userId}`);

        await memberRef.update({
            lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        info(`[lastActive] Updated ${userId} in ${hubId} (game signup)`);
    } catch (err) {
        warn(`[lastActive] Error on game signup:`, err);
    }
});
