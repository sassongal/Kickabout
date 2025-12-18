/* eslint-disable max-len */
const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { info } = require('firebase-functions/logger');
const { db, FieldValue, getUserFCMTokens } = require('../utils');

// --- Game Creation Trigger ---
exports.onGameCreated = onDocumentCreated('games/{gameId}', async (event) => {
    const game = event.data.data();
    const gameId = event.params.gameId;

    info(`New game created: ${gameId}${game.hubId ? ` in hub: ${game.hubId}` : ' (public game)'}`);

    try {
        // Null-safe: Only process hub-specific logic if hubId exists
        if (!game.hubId) {
            info(`Public game ${gameId} created. Skipping hub-specific operations.`);
            // TODO: Add public game feed post logic here if needed
            return;
        }

        // Fetch hub and user data in parallel for denormalization
        const [hubSnap, userSnap] = await Promise.all([
            db.collection('hubs').doc(game.hubId).get(),
            db.collection('users').doc(game.createdBy).get(),
        ]);

        if (!hubSnap.exists) {
            info('Hub does not exist');
            return;
        }
        const hub = hubSnap.data();
        const user = userSnap.exists ? userSnap.data() : null;

        // Denormalize user data into game document for efficient queries
        const gameUpdate = {};
        if (user) {
            gameUpdate.createdByName = user.name || null;
            gameUpdate.createdByPhotoUrl = user.photoUrl || null;
        }

        // Update game with denormalized data
        if (Object.keys(gameUpdate).length > 0) {
            await db.collection('games').doc(gameId).update(gameUpdate);
        }

        // Create feed post in the correct structure: /hubs/{hubId}/feed/posts/items/{postId}
        const postRef = db
            .collection('hubs')
            .doc(game.hubId)
            .collection('feed')
            .doc('posts')
            .collection('items')
            .doc();

        await postRef.set({
            postId: postRef.id,
            hubId: game.hubId,
            hubName: hub.name,
            hubLogoUrl: hub.logoUrl || null,
            type: 'game_created',
            text: `משחק חדש נוצר ב-${hub.name}!`,
            createdAt: game.createdAt,
            authorId: game.createdBy,
            authorName: user?.name || null,
            authorPhotoUrl: user?.photoUrl || null,
            entityId: gameId,
            gameId: gameId,
            likeCount: 0,
            commentCount: 0,
            likes: [],
            comments: [],
        });

        // Update hub stats
        await hubSnap.ref.update({
            gameCount: FieldValue.increment(1),
            lastActivity: game.createdAt,
        });

        info(`Feed post and hub stats updated for game ${gameId}.`);
    } catch (error) {
        info(`Error in onGameCreated for game ${gameId}:`, error);
    }
});

// --- Game Signup Denormalization Handler ---
exports.onGameSignupChanged = onDocumentWritten(
    'games/{gameId}/signups/{userId}',
    async (event) => {
        const gameId = event.params.gameId;
        const userId = event.params.userId;
        const signupData = event.data?.after?.data();
        const beforeData = event.data?.before?.data();

        // Only process if signup was created or deleted (not just updated)
        // or if status changed
        const isCreated = !beforeData && signupData;
        const isDeleted = beforeData && !signupData;
        const statusChanged = beforeData?.status !== signupData?.status;

        if (!isCreated && !isDeleted && !statusChanged) {
            // Signup was just updated without status change, skip
            return;
        }

        info(`Game signup ${userId} ${isCreated ? 'created' : isDeleted ? 'deleted' : 'updated'} for game ${gameId}. Updating denormalized data.`);

        try {
            // Get all confirmed signups for this game
            const signupsSnapshot = await db
                .collection('games')
                .doc(gameId)
                .collection('signups')
                .where('status', '==', 'confirmed')
                .get();

            const confirmedPlayerIds = signupsSnapshot.docs.map((doc) => doc.id);
            const confirmedPlayerCount = confirmedPlayerIds.length;

            // Get game document to check maxPlayers
            const gameDoc = await db.collection('games').doc(gameId).get();
            if (!gameDoc.exists) {
                info(`Game ${gameId} not found. Skipping denormalization.`);
                return;
            }

            const gameData = gameDoc.data();
            const teamCount = gameData?.teamCount ?? 2;
            const maxPlayers = gameData?.maxParticipants ?? (teamCount * 3); // Default: 3 per team

            // Update game with denormalized data
            await db.collection('games').doc(gameId).update({
                confirmedPlayerIds: confirmedPlayerIds,
                confirmedPlayerCount: confirmedPlayerCount,
                isFull: confirmedPlayerCount >= maxPlayers,
                updatedAt: FieldValue.serverTimestamp(),
            });

            info(`Updated denormalized data for game ${gameId}: ${confirmedPlayerCount}/${maxPlayers} players confirmed.`);
        } catch (error) {
            info(`Error in onGameSignupChanged for game ${gameId}, user ${userId}:`, error);
        }
    },
);

// --- Signup Status Changed (Waitlist) ---
exports.onSignupStatusChanged = onDocumentUpdated(
    'games/{gameId}/signups/{userId}',
    async (event) => {
        const gameId = event.params.gameId;
        const userId = event.params.userId;
        const beforeData = event.data.before.data();
        const afterData = event.data.after.data();

        if (!beforeData || !afterData) {
            return;
        }

        const beforeStatus = beforeData.status;
        const afterStatus = afterData.status;

        if (beforeStatus !== 'confirmed' || afterStatus !== 'cancelled') {
            return;
        }

        info(`Signup ${userId} cancelled for game ${gameId}. Checking waitlist...`);

        try {
            const waitlistSnapshot = await db
                .collection('games')
                .doc(gameId)
                .collection('signups')
                .where('status', '==', 'waitlist')
                .orderBy('signedUpAt', 'asc')
                .limit(1)
                .get();

            if (waitlistSnapshot.empty) {
                info(`No waitlist users found for game ${gameId}.`);
                return;
            }

            const firstWaitlistDoc = waitlistSnapshot.docs[0];
            const waitlistUserId = firstWaitlistDoc.id;

            await firstWaitlistDoc.ref.update({
                status: 'confirmed',
                updatedAt: FieldValue.serverTimestamp(),
            });

            info(`Promoted waitlist user ${waitlistUserId} to confirmed for game ${gameId}.`);

            const gameRef = db.collection('games').doc(gameId);
            await gameRef.update({
                confirmedPlayerCount: FieldValue.increment(1),
            });

            try {
                const tokens = await getUserFCMTokens(waitlistUserId);

                if (tokens.length > 0) {
                    const gameDoc = await gameRef.get();
                    const gameData = gameDoc.data();
                    const gameDate = gameData?.gameDate?.toDate();

                    const message = {
                        notification: {
                            title: 'מקום נפתח!',
                            body: `אתה עכשיו ברשימת המשתתפים למשחק ב-${gameDate ? gameDate.toLocaleDateString('he-IL') : 'תאריך לא ידוע'}`,
                        },
                        data: {
                            type: 'game_signup_promoted',
                            gameId: gameId,
                            hubId: gameData?.hubId || '',
                        },
                        tokens: tokens,
                    };

                    const response = await messaging.sendEachForMulticast(message);
                    info(
                        `Sent waitlist promotion notification to ${response.successCount} devices for user ${waitlistUserId}.`
                    );
                } else {
                    info(`No FCM tokens found for promoted waitlist user ${waitlistUserId}.`);
                }
            } catch (notificationError) {
                info(`Failed to send waitlist promotion notification:`, notificationError);
            }
        } catch (error) {
            info(`Error in onSignupStatusChanged for game ${gameId}:`, error);
        }
    },
);
