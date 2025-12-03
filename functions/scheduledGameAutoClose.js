/* eslint-disable max-len */
/**
 * Scheduled Function: Auto-Close Games
 * Gap Analysis #8: Auto-close logic for abandoned games
 * 
 * Rules:
 * 1. Pending games NOT started within 3h after scheduledAt → archived_not_played
 * 2. Active games NOT ended within 5h after startedAt → completed (auto)
 * 
 * Runs: Every 10 minutes
 */

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { info, error } = require('firebase-functions/logger');
const { getUserFCMTokens } = require('./src/utils');

const db = getFirestore();
const messaging = getMessaging();

exports.scheduledGameAutoClose = onSchedule(
  {
    schedule: 'every 10 minutes',
    timeZone: 'Asia/Jerusalem',
    region: 'us-central1',
    memory: '256MiB',
  },
  async (event) => {
    info('Running scheduledGameAutoClose...');
    const now = new Date();

    try {
      // ========================================
      // RULE 1: Auto-close PENDING games (24h after scheduled)
      // ========================================
      const twentyFourHoursAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

      const pendingGamesSnapshot = await db
        .collection('games')
        .where('status', 'in', ['scheduled', 'recruiting', 'fullyBooked', 'teamSelection'])
        .where('gameDate', '<=', twentyFourHoursAgo)
        .limit(50)
        .get();

      info(`Found ${pendingGamesSnapshot.size} pending games to auto-close`);

      const pendingPromises = pendingGamesSnapshot.docs.map(async (gameDoc) => {
        const gameId = gameDoc.id;
        const game = gameDoc.data();

        try {
          // Update game status to archivedNotPlayed
          await gameDoc.ref.update({
            status: 'archivedNotPlayed',
            updatedAt: FieldValue.serverTimestamp(),
            autoClosedAt: FieldValue.serverTimestamp(),
            autoCloseReason: 'not_started_within_24h',
          });

          info(`Auto-closed pending game ${gameId} (not started within 24h)`);

          // Notify organizer
          if (game.createdBy) {
            await notifyGameAutoClose(
              game.createdBy,
              gameId,
              game.hubId,
              'המשחק שלך בוטל אוטומטית מכיוון שלא התחיל תוך 24 שעות',
            );
          }
        } catch (err) {
          error(`Failed to auto-close pending game ${gameId}:`, err);
        }
      });

      await Promise.all(pendingPromises);

      // ========================================
      // RULE 2: Auto-close ACTIVE games (5h after started)
      // ========================================
      const fiveHoursAgo = new Date(now.getTime() - 5 * 60 * 60 * 1000);

      const activeGamesSnapshot = await db
        .collection('games')
        .where('status', '==', 'inProgress')
        .where('startedAt', '<=', fiveHoursAgo)
        .limit(50)
        .get();

      info(`Found ${activeGamesSnapshot.size} active games to auto-complete`);

      const activePromises = activeGamesSnapshot.docs.map(async (gameDoc) => {
        const gameId = gameDoc.id;
        const game = gameDoc.data();

        try {
          // Update game status to completed
          await gameDoc.ref.update({
            status: 'completed',
            completedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            autoCompletedAt: FieldValue.serverTimestamp(),
            autoCompleteReason: 'not_ended_within_5h',
          });

          info(`Auto-completed active game ${gameId} (not ended within 5h)`);

          // Notify organizer to record results
          if (game.createdBy) {
            await notifyGameAutoClose(
              game.createdBy,
              gameId,
              game.hubId,
              'המשחק שלך הסתיים אוטומטית. נא לרשום תוצאות',
            );
          }
        } catch (err) {
          error(`Failed to auto-complete active game ${gameId}:`, err);
        }
      });

      await Promise.all(activePromises);

      info(`Auto-close completed: ${pendingGamesSnapshot.size} pending, ${activeGamesSnapshot.size} active`);
      return null;
    } catch (err) {
      error('Error in scheduledGameAutoClose:', err);
      throw err;
    }
  }
);

/**
 * Helper: Send notification about auto-closed game
 */
async function notifyGameAutoClose(userId, gameId, hubId, message) {
  try {
    // ✅ Use helper to get FCM tokens
    const tokens = await getUserFCMTokens(userId);
    if (tokens.length === 0) return;

    const notification = {
      notification: {
        title: '⚽ סגירה אוטומטית של משחק',
        body: message,
      },
      tokens: tokens,
      data: {
        type: 'game_auto_close',
        gameId: gameId,
        hubId: hubId,
      },
    };

    await messaging.sendEachForMulticast(notification);
    info(`Sent auto-close notification to user ${userId}`);
  } catch (err) {
    error(`Failed to send auto-close notification to user ${userId}:`, err);
  }
}

