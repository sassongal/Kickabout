/* eslint-disable max-len */
const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { info } = require('firebase-functions/logger');
const { db, FieldValue, getUserFCMTokens, messaging } = require('../utils');

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

// --- Signup Status Changed (Waitlist Automation) ---
// Automatically promotes waitlist users when a confirmed player cancels
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

        // Trigger waitlist promotion only when:
        // 1. A confirmed player cancels (confirmed -> cancelled)
        // 2. An admin removes a confirmed player (confirmed -> rejected)
        const shouldPromoteWaitlist =
            beforeStatus === 'confirmed' &&
            (afterStatus === 'cancelled' || afterStatus === 'rejected');

        if (!shouldPromoteWaitlist) {
            return;
        }

        info(`Signup ${userId} ${afterStatus} for game ${gameId}. Checking waitlist...`);

        try {
            // Use a transaction to prevent race conditions when multiple players cancel simultaneously
            const promotedUserId = await db.runTransaction(async (transaction) => {
                // 1. Get the first waitlist user
                const waitlistSnapshot = await transaction.get(
                    db.collection('games')
                        .doc(gameId)
                        .collection('signups')
                        .where('status', '==', 'waitlist')
                        .orderBy('signedUpAt', 'asc')
                        .limit(1),
                );

                if (waitlistSnapshot.empty) {
                    info(`No waitlist users found for game ${gameId}.`);
                    return null;
                }

                const firstWaitlistDoc = waitlistSnapshot.docs[0];
                const waitlistUserId = firstWaitlistDoc.id;

                // 2. Get game to check current state
                const gameRef = db.collection('games').doc(gameId);
                const gameDoc = await transaction.get(gameRef);

                if (!gameDoc.exists) {
                    info(`Game ${gameId} not found. Skipping waitlist promotion.`);
                    return null;
                }

                const gameData = gameDoc.data();
                const maxPlayers = gameData?.maxParticipants ?? (gameData?.teamCount ?? 2) * 3;
                const currentConfirmedCount = gameData?.confirmedPlayerCount ?? 0;

                // 3. Check if there's actually space (safety check)
                if (currentConfirmedCount >= maxPlayers) {
                    info(`Game ${gameId} is still full (${currentConfirmedCount}/${maxPlayers}). Not promoting waitlist user.`);
                    return null;
                }

                // 4. Promote the waitlist user
                transaction.update(firstWaitlistDoc.ref, {
                    status: 'confirmed',
                    updatedAt: FieldValue.serverTimestamp(),
                });

                // 5. Update game isFull status
                const newConfirmedCount = currentConfirmedCount; // Will be incremented by onGameSignupChanged trigger
                const stillFull = newConfirmedCount >= maxPlayers;

                transaction.update(gameRef, {
                    isFull: stillFull,
                    updatedAt: FieldValue.serverTimestamp(),
                });

                info(`✅ Promoted waitlist user ${waitlistUserId} to confirmed for game ${gameId}. Space: ${newConfirmedCount}/${maxPlayers}`);

                return waitlistUserId; // Return for notification sending
            });

            // If no user was promoted, exit early
            if (!promotedUserId) {
                return;
            }

            // Send notification to promoted user
            try {
                const tokens = await getUserFCMTokens(promotedUserId);

                if (tokens.length > 0) {
                    const gameRef = db.collection('games').doc(gameId);
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
                        `Sent waitlist promotion notification to ${response.successCount} devices for user ${promotedUserId}.`
                    );
                } else {
                    info(`No FCM tokens found for promoted waitlist user ${promotedUserId}.`);
                }
            } catch (notificationError) {
                info(`Failed to send waitlist promotion notification:`, notificationError);
            }
        } catch (error) {
            info(`Error in onSignupStatusChanged for game ${gameId}:`, error);
        }
    },
);

// --- Player Pairing Tracking (for Chemistry Score) ---
// Updates player pairing stats when game status changes to 'completed'
exports.onGameCompleted = onDocumentUpdated("games/{gameId}", async (event) => {
    const gameId = event.params.gameId;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!beforeData || !afterData) {
        return;
    }

    const beforeStatus = beforeData.status;
    const afterStatus = afterData.status;

    // Only process if status changed to 'completed'
    if (beforeStatus !== "completed" && afterStatus === "completed") {
        info(`Game ${gameId} completed. Updating player pairings...`);

        try {
            const hubId = afterData.hubId;
            if (!hubId) {
                info(`Game ${gameId} has no hubId, skipping pairing updates`);
                return;
            }

            // Get game teams (from gameSession subcollection)
            const sessionSnapshot = await db
                .collection("games")
                .doc(gameId)
                .collection("gameSession")
                .doc("current")
                .get();

            if (!sessionSnapshot.exists) {
                info(`No game session found for game ${gameId}`);
                return;
            }

            const sessionData = sessionSnapshot.data();
            const teams = sessionData.teams || [];
            const finalScore = sessionData.finalScore || {};

            // Determine winning team(s)
            let winningTeamIds = [];
            if (finalScore) {
                const scores = Object.entries(finalScore).map(([teamId, score]) => ({
                    teamId,
                    score,
                }));
                const maxScore = Math.max(...scores.map((s) => s.score));
                winningTeamIds = scores.filter((s) => s.score === maxScore).map((s) => s.teamId);
            }

            // Update pairings for each team
            for (const team of teams) {
                const playerIds = team.playerIds || [];
                const didWin = winningTeamIds.includes(team.teamId);

                // Create/update pairing for each pair of players on this team
                for (let i = 0; i < playerIds.length; i++) {
                    for (let j = i + 1; j < playerIds.length; j++) {
                        const player1 = playerIds[i];
                        const player2 = playerIds[j];

                        // Sort alphabetically for consistent pairing ID
                        const sorted = [player1, player2].sort();
                        const pairingId = `${sorted[0]}_${sorted[1]}`;

                        const pairingRef = db
                            .collection("hubs")
                            .doc(hubId)
                            .collection("pairings")
                            .doc(pairingId);

                        // Use transaction to safely increment counters
                        await db.runTransaction(async (transaction) => {
                            const pairingDoc = await transaction.get(pairingRef);

                            if (pairingDoc.exists) {
                                // Update existing pairing
                                const data = pairingDoc.data();
                                const newGamesPlayed = (data.gamesPlayedTogether || 0) + 1;
                                const newGamesWon = (data.gamesWonTogether || 0) + (didWin ? 1 : 0);
                                const newWinRate = newGamesWon / newGamesPlayed;

                                transaction.update(pairingRef, {
                                    gamesPlayedTogether: newGamesPlayed,
                                    gamesWonTogether: newGamesWon,
                                    winRate: newWinRate,
                                    lastPlayedTogether: admin.firestore.FieldValue.serverTimestamp(),
                                });
                            } else {
                                // Create new pairing
                                transaction.set(pairingRef, {
                                    player1Id: sorted[0],
                                    player2Id: sorted[1],
                                    gamesPlayedTogether: 1,
                                    gamesWonTogether: didWin ? 1 : 0,
                                    winRate: didWin ? 1.0 : 0.0,
                                    lastPlayedTogether: admin.firestore.FieldValue.serverTimestamp(),
                                    pairingId,
                                });
                            }
                        });
                    }
                }
            }

            info(`Successfully updated pairings for game ${gameId}`);
        } catch (error) {
            error(`Error updating pairings for game ${gameId}:`, error);
        }
    }
});

// --- Game Cancellation Handler ---
exports.onGameCancelled = onDocumentUpdated("games/{gameId}", async (event) => {
    const gameId = event.params.gameId;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!beforeData || !afterData) {
        return;
    }

    const beforeStatus = beforeData.status;
    const afterStatus = afterData.status;

    // Only process if status changed to 'cancelled'
    if (beforeStatus !== "cancelled" && afterStatus === "cancelled") {
        info(`Game ${gameId} was cancelled. Processing notifications...`);

        try {
            // Get all confirmed signups
            const signupsSnapshot = await db
                .collection("games")
                .doc(gameId)
                .collection("signups")
                .where("status", "==", "confirmed")
                .get();

            const playerIds = signupsSnapshot.docs.map((doc) => doc.id);

            // Get cancellation reason from audit log (most recent entry)
            const auditSnapshot = await db
                .collection("games")
                .doc(gameId)
                .collection("audit")
                .orderBy("timestamp", "desc")
                .limit(1)
                .get();

            const cancellationReason =
                !auditSnapshot.empty && auditSnapshot.docs[0].data().reason
                    ? auditSnapshot.docs[0].data().reason
                    : "לא צוין";

            // Send FCM notifications to all confirmed players
            for (const playerId of playerIds) {
                try {
                    const tokens = await getUserFCMTokens(playerId);

                    if (tokens.length > 0) {
                        const message = {
                            notification: {
                                title: "משחק בוטל",
                                body: `המשחק בוטל. סיבה: ${cancellationReason}`,
                            },
                            data: {
                                type: "game_cancelled",
                                gameId: gameId,
                                hubId: afterData.hubId || "",
                                reason: cancellationReason,
                            },
                            tokens: tokens,
                        };

                        await messaging.sendEachForMulticast(message);
                    }
                } catch (notificationError) {
                    info(
                        `Failed to send cancellation notification to ${playerId}:`,
                        notificationError
                    );
                }
            }

            info(
                `Sent cancellation notifications for game ${gameId} to ${playerIds.length} players.`
            );
        } catch (error) {
            info(`Error in onGameCancelled for game ${gameId}:`, error);
        }
    }
});
