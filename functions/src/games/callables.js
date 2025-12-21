/* eslint-disable max-len */
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { info } = require('firebase-functions/logger');
const { db, messaging, FieldValue } = require('../utils');
const { checkRateLimit } = require('../../rateLimit');

// --- Notify Hub on New Game ---
/**
 * Notify all hub members when a new game is created
 * @param {string} hubId - Hub ID
 * @param {string} gameId - Game ID
 * @param {string} gameTitle - Optional game title
 * @param {string} gameTime - Optional game time
 * @return {Object} Result with success status and notification count
 */
exports.notifyHubOnNewGame = onCall(
    {
        invoker: 'public', // ✅ Changed from 'authenticated' to allow Firebase Auth users
        memory: '256MiB', // ✅ Reduced from default (512MB not needed)
    },
    async (request) => {
        // Verify authentication
        if (!request.auth) {
            throw new HttpsError('unauthenticated', 'Must be authenticated');
        }
        const { hubId, gameId, gameTitle, gameTime } = request.data;

        if (!hubId || !gameId) {
            throw new HttpsError(
                'invalid-argument',
                'Missing \'hubId\' or \'gameId\' parameter.',
            );
        }

        // Security Patch: Add an authorization check
        const hubMember = await db.collection('hubs').doc(hubId).collection('members').doc(request.auth.uid).get();
        if (!hubMember.exists || !['owner', 'manager'].includes(hubMember.data()?.role)) {
            throw new HttpsError('permission-denied', 'Only Hub Managers can send notifications.');
        }

        info(`Notifying hub ${hubId} about new game ${gameId}`);

        try {
            // 1. Get hub to get name
            const hubDoc = await db.collection('hubs').doc(hubId).get();
            if (!hubDoc.exists) {
                throw new HttpsError('not-found', 'Hub not found');
            }

            const hubData = hubDoc.data();
            const hubName = hubData.name || 'האב';

            // 2. Get game details if not provided
            let title = gameTitle;
            let time = gameTime;

            if (!title || !time) {
                const gameDoc = await db.collection('games').doc(gameId).get();
                if (gameDoc.exists) {
                    const gameData = gameDoc.data();
                    if (!title) {
                        title = `משחק חדש ב-${hubName}`;
                    }
                    if (!time && gameData.gameDate) {
                        const gameDate = gameData.gameDate.toDate();
                        time = gameDate.toLocaleString('he-IL', {
                            year: 'numeric',
                            month: 'long',
                            day: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit',
                        });
                    }
                }
            }

            // 3. ✅ OPTIMIZED: Send notification to topic instead of individual tokens
            // This is 100x faster and doesn't require fetching member IDs or tokens!
            const message = {
                notification: {
                    title: 'הרשמה למשחק חדש נפתחה!',
                    body: `${title}${time ? ` - ${time}` : ''}`,
                },
                data: {
                    type: 'new_game',
                    hubId: hubId,
                    gameId: gameId,
                },
                topic: `hub_${hubId}`,
            };

            await messaging.send(message);
            info(`Sent notification to topic hub_${hubId}`);

            return {
                success: true,
                message: 'Notification sent to hub topic',
            };
        } catch (error) {
            info(`Error in notifyHubOnNewGame for hub ${hubId}:`, error);
            throw new HttpsError('internal', 'Failed to notify hub members.', error);
        }
    },
);

// ========================================
// ✅ NEW: Start Game Early (Gap Analysis #7)
// Callable Function: Start a game up to 30 minutes early
// ========================================
exports.startGameEarly = onCall(
    {
        invoker: 'public', // ✅ Changed from 'authenticated' to allow Firebase Auth users
        memory: '256MiB',
    },
    async (request) => {
        // Verify authentication
        if (!request.auth) {
            throw new HttpsError('unauthenticated', 'Must be authenticated');
        }

        // ✅ Rate limit: 3 requests per minute (prevent abuse)
        await checkRateLimit(request.auth.uid, 'startGameEarly', 3, 1);

        const { gameId } = request.data;
        const userId = request.auth.uid;

        if (!gameId) {
            throw new HttpsError('invalid-argument', 'Missing gameId');
        }

        try {
            const gameRef = db.collection('games').doc(gameId);
            const gameDoc = await gameRef.get();

            if (!gameDoc.exists) {
                throw new HttpsError('not-found', 'Game not found');
            }

            const game = gameDoc.data();

            // Check if user is organizer
            if (game.organizerId !== userId) {
                throw new HttpsError(
                    'permission-denied',
                    'Only the organizer can start the game',
                );
            }

            // Check if game is pending
            if (game.status !== 'pending') {
                throw new HttpsError(
                    'failed-precondition',
                    `Game is already ${game.status}`,
                );
            }

            // ✅ Gap Analysis #7: Can start up to 30 minutes EARLY
            const scheduledAt = game.scheduledAt.toDate();
            const now = new Date();
            const thirtyMinutesEarly = new Date(
                scheduledAt.getTime() - 30 * 60 * 1000,
            );

            if (now < thirtyMinutesEarly) {
                const minutesUntilAllowed = Math.ceil(
                    (thirtyMinutesEarly - now) / (60 * 1000),
                );
                throw new HttpsError(
                    'failed-precondition',
                    `Cannot start game yet. Wait ${minutesUntilAllowed} more minutes (can start 30 min early)`,
                );
            }

            // Start the game: pending → active
            await gameRef.update({
                status: 'active',
                startedAt: FieldValue.serverTimestamp(),
                updatedAt: FieldValue.serverTimestamp(),
            });

            info(`Game ${gameId} started early by ${userId}`);

            return {
                success: true,
                message: 'Game started successfully',
                gameId: gameId,
            };
        } catch (error) {
            if (error instanceof HttpsError) {
                throw error;
            }
            throw new HttpsError('internal', `Failed to start game: ${error.message}`);
        }
    },
);
