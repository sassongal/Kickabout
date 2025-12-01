const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { info, warn, error: logError } = require('firebase-functions/logger');
const { checkRateLimit } = require('./rateLimit');
const { getUserFCMTokens } = require('./src/utils');

/**
 * Vote on a poll
 * Callable function with rate limiting and atomic updates
 */
exports.votePoll = onCall(
  {
    region: 'us-central1',
    invoker: 'authenticated',
    memory: '256MiB',
  },
  async (request) => {
    // Authentication check
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'חובה להתחבר כדי להצביע');
    }

    const userId = request.auth.uid;
    const { pollId, selectedOptionIds, rating } = request.data;

    // Validation
    if (!pollId || !selectedOptionIds || !Array.isArray(selectedOptionIds)) {
      throw new HttpsError('invalid-argument', 'נתונים לא תקינים');
    }

    // Rate limiting - 10 votes per minute
    await checkRateLimit(userId, 'votePoll', 10, 1);

    const db = admin.firestore();
    const pollRef = db.collection('polls').doc(pollId);

    try {
      // Use transaction for atomic updates
      const result = await db.runTransaction(async (transaction) => {
        const pollDoc = await transaction.get(pollRef);

        if (!pollDoc.exists) {
          throw new HttpsError('not-found', 'הסקר לא נמצא');
        }

        const poll = pollDoc.data();

        // Check if poll is active
        if (poll.status !== 'active') {
          throw new HttpsError('failed-precondition', 'הסקר לא פעיל להצבעות');
        }

        // Check if poll has ended
        if (poll.endsAt && poll.endsAt.toMillis() < Date.now()) {
          throw new HttpsError('failed-precondition', 'הסקר הסתיים');
        }

        // Check if user is Hub member
        const hubRef = db.collection('hubs').doc(poll.hubId);
        const hubDoc = await transaction.get(hubRef);

        if (!hubDoc.exists) {
          throw new HttpsError('not-found', 'ה-Hub לא נמצא');
        }

        const hub = hubDoc.data();
        const isMember =
          hub.memberIds?.includes(userId) ||
          hub.ownerId === userId ||
          hub.managers?.includes(userId);

        if (!isMember) {
          throw new HttpsError('permission-denied', 'אינך חבר ב-Hub');
        }

        // Check if user has already voted
        if (poll.voters?.includes(userId) && !poll.allowMultipleVotes) {
          throw new HttpsError('already-voted', 'כבר הצבעת בסקר זה');
        }

        // Validate selected options
        const optionIds = poll.options.map((opt) => opt.optionId);
        for (const optionId of selectedOptionIds) {
          if (!optionIds.includes(optionId)) {
            throw new HttpsError('invalid-argument', 'אפשרות לא תקינה');
          }
        }

        // Validate vote type
        if (poll.type === 'singleChoice' && selectedOptionIds.length !== 1) {
          throw new HttpsError(
            'invalid-argument',
            'יש לבחור אפשרות אחת בלבד'
          );
        }

        if (poll.type === 'rating' && !rating) {
          throw new HttpsError('invalid-argument', 'חובה לדרג');
        }

        // Update poll options with new votes
        const updatedOptions = poll.options.map((option) => {
          if (selectedOptionIds.includes(option.optionId)) {
            return {
              ...option,
              voteCount: option.voteCount + 1,
              voters: poll.isAnonymous
                ? option.voters
                : [...(option.voters || []), userId],
            };
          }
          return option;
        });

        // Update poll document
        const updates = {
          options: updatedOptions,
          totalVotes: poll.totalVotes + 1,
          voters: [...(poll.voters || []), userId],
        };

        transaction.update(pollRef, updates);

        // Create vote document in subcollection
        const voteRef = pollRef.collection('votes').doc();
        transaction.set(voteRef, {
          voteId: voteRef.id,
          pollId,
          userId,
          selectedOptionIds,
          rating: rating || null,
          votedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        info('Vote recorded', {
          pollId,
          userId,
          selectedOptionIds,
          totalVotes: updates.totalVotes,
        });

        return { success: true, poll: { ...poll, ...updates } };
      });

      return result;
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logError('Error voting on poll', { error, pollId, userId });
      throw new HttpsError('internal', 'שגיאה בהצבעה');
    }
  }
);

/**
 * Close a poll manually
 * Only creator or Hub managers can close
 */
exports.closePoll = onCall(
  {
    region: 'us-central1',
    invoker: 'authenticated',
    memory: '256MiB',
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'חובה להתחבר');
    }

    const userId = request.auth.uid;
    const { pollId } = request.data;

    if (!pollId) {
      throw new HttpsError('invalid-argument', 'חסר מזהה סקר');
    }

    // Rate limiting - 5 per minute
    await checkRateLimit(userId, 'closePoll', 5, 1);

    const db = admin.firestore();
    const pollRef = db.collection('polls').doc(pollId);

    try {
      const pollDoc = await pollRef.get();

      if (!pollDoc.exists) {
        throw new HttpsError('not-found', 'הסקר לא נמצא');
      }

      const poll = pollDoc.data();

      // Check permissions
      const hubRef = db.collection('hubs').doc(poll.hubId);
      const hubDoc = await hubRef.get();

      if (!hubDoc.exists) {
        throw new HttpsError('not-found', 'ה-Hub לא נמצא');
      }

      const hub = hubDoc.data();
      const isCreator = poll.createdBy === userId;
      const isManager =
        hub.ownerId === userId || hub.managers?.includes(userId);

      if (!isCreator && !isManager) {
        throw new HttpsError('permission-denied', 'אין הרשאה לסגור סקר זה');
      }

      // Close poll
      await pollRef.update({
        status: 'closed',
        closedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      info('Poll closed manually', { pollId, userId });

      // Send notification with results
      await sendPollResultsNotification(pollId, poll);

      return { success: true };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logError('Error closing poll', { error, pollId, userId });
      throw new HttpsError('internal', 'שגיאה בסגירת הסקר');
    }
  }
);

/**
 * Trigger when a new poll is created
 * Sends notifications to Hub members
 */
exports.onPollCreated = onDocumentCreated(
  {
    region: 'us-central1',
    document: 'polls/{pollId}',
    memory: '256MiB',
  },
  async (event) => {
    const pollId = event.params.pollId;
    const poll = event.data.data();

    info('New poll created', { pollId, hubId: poll.hubId });

    try {
      // Send notifications to Hub members
      const db = admin.firestore();
      const hubRef = db.collection('hubs').doc(poll.hubId);
      const hubDoc = await hubRef.get();

      if (!hubDoc.exists) {
        warn('Hub not found for poll', { pollId, hubId: poll.hubId });
        return;
      }

      const hub = hubDoc.data();
      const memberIds = hub.memberIds || [];

      // Don't notify the creator
      const recipientIds = memberIds.filter((id) => id !== poll.createdBy);

      if (recipientIds.length === 0) {
        info('No members to notify', { pollId });
        return;
      }

      // ✅ Fetch FCM tokens in parallel using helper
      const allTokensArrays = await Promise.all(
        recipientIds.map((memberId) => getUserFCMTokens(memberId))
      );
      const tokens = allTokensArrays.flat();

      if (tokens.length === 0) {
        info('No FCM tokens found', { pollId });
        return;
      }

      // Send notification
      const message = {
        notification: {
          title: `סקר חדש: ${poll.question}`,
          body: `סקר חדש ב-${hub.name}. לחץ כדי להצביע!`,
        },
        data: {
          type: 'poll_created',
          pollId,
          hubId: poll.hubId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      info('Poll creation notifications sent', {
        pollId,
        success: response.successCount,
        failed: response.failureCount,
      });
    } catch (error) {
      logError('Error sending poll creation notifications', {
        error,
        pollId,
      });
    }
  }
);

/**
 * Scheduled function to auto-close polls
 * Runs every 10 minutes
 */
exports.scheduledPollAutoClose = onSchedule(
  {
    schedule: 'every 10 minutes',
    timeZone: 'Asia/Jerusalem',
    region: 'us-central1',
    memory: '256MiB',
  },
  async () => {
    info('Running scheduledPollAutoClose');

    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    try {
      // Find active polls that have ended
      const pollsSnapshot = await db
        .collection('polls')
        .where('status', '==', 'active')
        .where('endsAt', '<=', now)
        .get();

      if (pollsSnapshot.empty) {
        info('No polls to auto-close');
        return;
      }

      info(`Found ${pollsSnapshot.size} polls to close`);

      // Close polls in parallel
      const closePromises = pollsSnapshot.docs.map(async (pollDoc) => {
        const pollId = pollDoc.id;
        const poll = pollDoc.data();

        try {
          // Update status
          await pollDoc.ref.update({
            status: 'closed',
            closedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          info('Poll auto-closed', { pollId });

          // Send results notification
          await sendPollResultsNotification(pollId, poll);
        } catch (error) {
          logError('Error auto-closing poll', { error, pollId });
        }
      });

      await Promise.all(closePromises);

      info(`Auto-closed ${pollsSnapshot.size} polls`);
    } catch (error) {
      logError('Error in scheduledPollAutoClose', { error });
    }
  }
);

/**
 * Helper: Send poll results notification
 */
async function sendPollResultsNotification(pollId, poll) {
  try {
    const db = admin.firestore();

    // Find winning option
    let winningOption = null;
    let maxVotes = 0;

    for (const option of poll.options) {
      if (option.voteCount > maxVotes) {
        maxVotes = option.voteCount;
        winningOption = option;
      }
    }

    if (!winningOption) {
      info('No votes on poll, skipping notification', { pollId });
      return;
    }

    // Get Hub members
    const hubRef = db.collection('hubs').doc(poll.hubId);
    const hubDoc = await hubRef.get();

    if (!hubDoc.exists) {
      warn('Hub not found', { pollId, hubId: poll.hubId });
      return;
    }

    const hub = hubDoc.data();
    const memberIds = hub.memberIds || [];

    // ✅ Fetch FCM tokens using helper
    const allTokensArrays = await Promise.all(
      memberIds.map((memberId) => getUserFCMTokens(memberId))
    );
    const tokens = allTokensArrays.flat();

    if (tokens.length === 0) {
      info('No FCM tokens for results notification', { pollId });
      return;
    }

    // Send notification
    const message = {
      notification: {
        title: `הסקר "${poll.question}" הסתיים!`,
        body: `התוצאה: ${winningOption.text} (${winningOption.voteCount} קולות)`,
      },
      data: {
        type: 'poll_closed',
        pollId,
        hubId: poll.hubId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    info('Poll results notifications sent', {
      pollId,
      success: response.successCount,
      failed: response.failureCount,
    });
  } catch (error) {
    logError('Error sending poll results notification', { error, pollId });
  }
}

