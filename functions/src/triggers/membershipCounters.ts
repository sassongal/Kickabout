import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Trigger: Update hub.memberCount when membership status changes
 * Triggers on: hubs/{hubId}/members/{userId} write
 * 
 * This keeps the denormalized memberCount in sync with actual active members.
 * Only counts members with status='active'.
 */
export const onMembershipChange = functions.firestore
    .document('hubs/{hubId}/members/{userId}')
    .onWrite(async (change, context) => {
        const hubId = context.params.hubId;
        const userId = context.params.userId;
        const hubRef = admin.firestore().doc(`hubs/${hubId}`);

        const before = change.before.exists ? change.before.data() : null;
        const after = change.after.exists ? change.after.data() : null;

        // Determine status changes
        const wasActive = before?.status === 'active';
        const isActive = after?.status === 'active';

        let delta = 0;
        let event = '';

        if (!wasActive && isActive) {
            // New active member OR reactivated member
            delta = 1;
            event = change.before.exists ? 'reactivated' : 'joined';
            console.log(`[memberCount] ${userId} ${event} ${hubId} (delta: +1)`);
        } else if (wasActive && !isActive) {
            // Member left, was banned, or document deleted
            delta = -1;
            event = !change.after.exists ? 'deleted' :
                after?.status === 'left' ? 'left' :
                    after?.status === 'banned' ? 'banned' : 'deactivated';
            console.log(`[memberCount] ${userId} ${event} ${hubId} (delta: -1)`);
        } else {
            // No status change affecting count (e.g., role change, rating update)
            console.log(`[memberCount] ${userId} updated in ${hubId} (no count change)`);
            return null;
        }

        // Update hub document
        try {
            await hubRef.update({
                memberCount: admin.firestore.FieldValue.increment(delta),
                lastActivity: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(`[memberCount] Updated ${hubId}: memberCount += ${delta}`);
        } catch (error) {
            console.error(`[memberCount] Error updating ${hubId}:`, error);
            throw error;
        }

        return null;
    });

/**
 * Trigger: Update member.lastActiveAt when they interact with hub
 * Triggers on: hubs/{hubId}/chatMessages/{messageId} create
 * 
 * Helps identify inactive veterans for analytics and future features.
 */
export const onChatMessage = functions.firestore
    .document('hubs/{hubId}/chatMessages/{messageId}')
    .onCreate(async (snapshot, context) => {
        const hubId = context.params.hubId;
        const messageData = snapshot.data();
        const authorId = messageData.authorId;

        if (!authorId) {
            console.warn(`[lastActive] Chat message in ${hubId} has no authorId`);
            return null;
        }

        const memberRef = admin.firestore().doc(`hubs/${hubId}/members/${authorId}`);

        try {
            // Update lastActiveAt (helps identify inactive members)
            await memberRef.update({
                lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(`[lastActive] Updated ${authorId} in ${hubId}`);
        } catch (error) {
            // Member doc might not exist (e.g., guest message, or race condition)
            console.warn(`[lastActive] Could not update ${authorId} in ${hubId}:`, error);
        }

        return null;
    });

/**
 * Trigger: Update member.lastActiveAt on game signup
 * Triggers on: games/{gameId}/signups/{userId} create
 */
export const onGameSignup = functions.firestore
    .document('games/{gameId}/signups/{userId}')
    .onCreate(async (snapshot, context) => {
        const gameId = context.params.gameId;
        const userId = context.params.userId;

        try {
            // Get game to find hubId
            const gameDoc = await admin.firestore().doc(`games/${gameId}`).get();
            if (!gameDoc.exists) {
                console.warn(`[lastActive] Game ${gameId} not found`);
                return null;
            }

            const gameData = gameDoc.data();
            const hubId = gameData?.hubId;

            if (!hubId) {
                // Pickup game (no hub)
                return null;
            }

            const memberRef = admin.firestore().doc(`hubs/${hubId}/members/${userId}`);

            await memberRef.update({
                lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(`[lastActive] Updated ${userId} in ${hubId} (game signup)`);
        } catch (error) {
            console.warn(`[lastActive] Error on game signup:`, error);
        }

        return null;
    });
