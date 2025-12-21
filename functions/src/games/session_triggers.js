/**
 * Session Lifecycle Triggers
 *
 * Handles automatic finalization when Winner Stays sessions end
 */

const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { info, error } = require('firebase-functions/logger');
const { db, FieldValue } = require('../utils');

/**
 * Trigger: Session Ended
 *
 * Automatically finalizes a session when manager ends it.
 * Sets status to 'completed' which triggers onGameCompleted for stats processing.
 */
exports.onSessionEnded = onDocumentUpdated(
  {
    document: 'games/{gameId}',
    memory: '256MiB',
  },
  async (event) => {
    const gameId = event.params.gameId;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // Check if session just ended
    const sessionEndedBefore = beforeData?.session?.sessionEndedAt;
    const sessionEndedAfter = afterData?.session?.sessionEndedAt;
    const finalizedAt = afterData?.session?.finalizedAt;

    if (!sessionEndedBefore && sessionEndedAfter && !finalizedAt) {
      info(`Session ${gameId} ended. Triggering finalization.`);

      try {
        // Update game status to 'completed' to trigger onGameCompleted
        await db.collection('games').doc(gameId).update({
          status: 'completed',
          'session.finalizedAt': FieldValue.serverTimestamp(),
        });

        info(`✅ Session ${gameId} finalized successfully`);
      } catch (err) {
        error(`❌ Failed to finalize session ${gameId}:`, err);
        throw err;
      }
    }
  }
);

/**
 * Trigger: Session Started
 *
 * Optional: Log when sessions start for analytics
 */
exports.onSessionStarted = onDocumentUpdated(
  {
    document: 'games/{gameId}',
    memory: '128MiB',
  },
  async (event) => {
    const gameId = event.params.gameId;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // Check if session just started
    const isActiveBefore = beforeData?.session?.isActive;
    const isActiveAfter = afterData?.session?.isActive;

    if (!isActiveBefore && isActiveAfter) {
      const teamCount = afterData?.teams?.length || 0;
      info(`🎯 Session ${gameId} started with ${teamCount} teams`);

      // Optional: Update analytics or send notifications
      // This is a placeholder for future enhancements
    }
  }
);

/**
 * Trigger: Auto-End Abandoned Sessions
 *
 * Runs periodically to end sessions that have been inactive for too long
 * (e.g., manager left without ending session)
 *
 * Note: This would typically be a scheduled function, not a document trigger
 * Implement as a Cloud Scheduler task if needed
 */
exports.cleanupAbandonedSessions = async () => {
  const THREE_HOURS_AGO = new Date(Date.now() - 3 * 60 * 60 * 1000);

  try {
    // Find active sessions with no recent match activity
    const abandonedSessionsSnapshot = await db
      .collection('games')
      .where('session.isActive', '==', true)
      .where('session.sessionStartedAt', '<', THREE_HOURS_AGO)
      .get();

    if (abandonedSessionsSnapshot.empty) {
      info('No abandoned sessions found');
      return;
    }

    const batch = db.batch();
    let count = 0;

    abandonedSessionsSnapshot.forEach((doc) => {
      const gameId = doc.id;
      const gameData = doc.data();
      const matches = gameData.session?.matches || [];

      // Check if last match was more than 3 hours ago
      if (matches.length > 0) {
        const lastMatch = matches[matches.length - 1];
        const lastMatchTime = lastMatch.createdAt?.toDate();

        if (lastMatchTime && lastMatchTime > THREE_HOURS_AGO) {
          // Recent activity, skip
          return;
        }
      }

      // End the abandoned session
      batch.update(doc.ref, {
        'session.isActive': false,
        'session.sessionEndedAt': FieldValue.serverTimestamp(),
        'session.sessionEndedBy': 'auto-cleanup',
        status: 'completed',
        'session.finalizedAt': FieldValue.serverTimestamp(),
      });

      count++;
      info(`Auto-ending abandoned session: ${gameId}`);
    });

    if (count > 0) {
      await batch.commit();
      info(`✅ Auto-ended ${count} abandoned sessions`);
    }

    return { cleaned: count };
  } catch (err) {
    error('❌ Failed to cleanup abandoned sessions:', err);
    throw err;
  }
};
