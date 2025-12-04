const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const { info, error, warn } = require('firebase-functions/logger');

/**
 * Trigger: Update hub.memberCount when membership status changes
 * Triggers on: hubs/{hubId}/members/{userId} write
 * 
 * This keeps the denormalized memberCount in sync with actual active members.
 * Only counts members with status='active'.
 */
exports.onMembershipChange = onDocumentWritten('hubs/{hubId}/members/{userId}', async (event) => {
    const hubId = event.params.hubId;
    const userId = event.params.userId;
    const hubRef = admin.firestore().doc(`hubs/${hubId}`);

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
