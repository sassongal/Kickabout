/* eslint-disable max-len */
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { info } = require('firebase-functions/logger');
const { db, messaging, FieldValue, getUserFCMTokens } = require('../utils');

exports.sendGameReminder = onSchedule(
    'every 30 minutes',
    async (event) => {
        const now = new Date();
        const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000);
        const twoHoursFromNow = new Date(now.getTime() + 2 * 60 * 60 * 1000);

        info('Running sendGameReminder cron job at', now.toISOString());

        try {
            const gamesSnapshot = await db
                .collection('games')
                .where('gameDate', '>=', oneHourFromNow)
                .where('gameDate', '<', twoHoursFromNow)
                .where('status', 'in', ['scheduled', 'recruiting', 'fullyBooked', 'teamSelection', 'teamsFormed']) // Include new statuses
                .get();

            if (gamesSnapshot.empty) {
                info('No games found for reminders.');
                return null;
            }

            info(`Found ${gamesSnapshot.size} games for reminders.`);

            const reminderPromises = gamesSnapshot.docs.map(
                async (gameDoc) => {
                    const game = gameDoc.data();
                    const gameId = gameDoc.id;

                    // Null-safe: Skip hub fetch for public games
                    if (!game.hubId) {
                        info(`Skipping reminder for public game ${gameId} (no hub)`);
                        return;
                    }

                    const hubSnapshot = await db
                        .collection('hubs')
                        .doc(game.hubId)
                        .get();
                    if (!hubSnapshot.exists) return;
                    const hubName = hubSnapshot.data().name;

                    const signupsSnapshot = await db
                        .collection('games')
                        .doc(gameId)
                        .collection('signups')
                        .where('status', '==', 'confirmed') // Use 'confirmed' status from SignupStatus enum
                        .get();

                    if (signupsSnapshot.empty) return;

                    const tokens = [];
                    const userIds = signupsSnapshot.docs.map(doc => doc.id);

                    // ✅ PERFORMANCE FIX: Fetch FCM tokens in PARALLEL using helper
                    const tokenArrays = await Promise.all(
                        userIds.map((userId) => getUserFCMTokens(userId))
                    );
                    tokens.push(...tokenArrays.flat());

                    if (tokens.length === 0) return;

                    const uniqueTokens = [...new Set(tokens)];

                    const message = {
                        notification: {
                            title: `⚽ משחק מתחיל בקרוב! (${hubName})`,
                            body: `אל תשכח, המשחק שלכם מתחיל בעוד כשעה. תהיו מוכנים!`,
                        },
                        tokens: uniqueTokens,
                        data: {
                            type: 'game_reminder',
                            gameId: gameId,
                            hubId: game.hubId,
                        },
                    };

                    await messaging.sendEachForMulticast(message);
                    info(`Sent reminder for game ${gameId} to ${uniqueTokens.length} tokens.`);

                    // Create notification docs
                    const batch = db.batch();
                    const notificationPayload = {
                        createdAt: FieldValue.serverTimestamp(),
                        type: 'game_reminder',
                        title: `משחק מתחיל בקרוב! (${hubName})`,
                        body: `המשחק שלך ב-${hubName} מתחיל בעוד כשעה.`,
                        read: false, // Notification model uses 'read', not 'isRead'
                        entityId: gameId,
                        hubId: game.hubId,
                    };
                    userIds.forEach((userId) => {
                        const ref = db
                            .collection('notifications')
                            .doc(userId)
                            .collection('items')
                            .doc();
                        batch.set(ref, notificationPayload);
                    });
                    await batch.commit();
                },
            );
            await Promise.all(reminderPromises);
            info(`✅ Completed sendGameReminder cron job - processed ${gamesSnapshot.size} games`);
            return null;
        } catch (error) {
            info(`⚠️ Error running sendGameReminder:`, error.message || error);
            info(`Stack trace:`, error.stack);
            // Don't throw - this is a scheduled function, we don't want it to fail silently
            // but we also don't want it to crash the entire function
            return null;
        }
    },
);
