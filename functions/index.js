const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/**
 * Send FCM notification to a user
 */
async function sendFCMNotification(userId, title, body, data) {
  try {
    // Get user's FCM token
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log(`User ${userId} not found`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return;
    }

    // Send notification
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log(`Successfully sent message to ${userId}:`, response);
    return response;
  } catch (error) {
    console.error(`Error sending FCM to ${userId}:`, error);
    throw error;
  }
}

/**
 * Cloud Function: Triggered when a new game is created
 */
exports.onGameCreated = functions.firestore
    .document('games/{gameId}')
    .onCreate(async (snapshot, context) => {
      const snap = snapshot;
      const game = snap.data();
      const gameId = context.params.gameId;

      try {
        // Get hub members
        const hubDoc = await db.collection('hubs').doc(game.hubId).get();
        if (!hubDoc.exists) {
          console.log(`Hub ${game.hubId} not found`);
          return;
        }

        const hub = hubDoc.data();
        const memberIds = hub.memberIds || [];

        // Get creator info
        const creatorDoc = await db.collection('users').doc(game.createdBy).get();
        const creatorName = creatorDoc.exists ? creatorDoc.data().name : 'מישהו';

        // Send notifications to all members except creator
        const notifications = memberIds
            .filter((memberId) => memberId !== game.createdBy)
            .map((memberId) => {
              return sendFCMNotification(
                  memberId,
                  'משחק חדש!',
                  `${creatorName} יצר משחק חדש ב-${hub.name || 'ההוב'}`,
                  {
                    type: 'new_game',
                    gameId: gameId,
                    hubId: game.hubId,
                  },
              );
            });

        await Promise.all(notifications);
        console.log(`Sent ${notifications.length} notifications for game ${gameId}`);
      } catch (error) {
        console.error(`Error in onGameCreated:`, error);
      }
    });

/**
 * Cloud Function: Triggered when a new message is sent in hub chat
 */
exports.onHubMessageCreated = functions.firestore
    .document('hubs/{hubId}/chat/{messageId}')
    .onCreate(async (snapshot, context) => {
      const snap = snapshot;
      const message = snap.data();
      const hubId = context.params.hubId;

      try {
        // Get hub members
        const hubDoc = await db.collection('hubs').doc(hubId).get();
        if (!hubDoc.exists) {
          console.log(`Hub ${hubId} not found`);
          return;
        }

        const hub = hubDoc.data();
        const memberIds = hub.memberIds || [];

        // Get sender info
        const senderDoc = await db.collection('users').doc(message.userId).get();
        const senderName = senderDoc.exists ? senderDoc.data().name : 'מישהו';

        // Send notifications to all members except sender
        const notifications = memberIds
            .filter((memberId) => memberId !== message.userId)
            .map((memberId) => {
              return sendFCMNotification(
                  memberId,
                  'הודעה חדשה',
                  `${senderName}: ${message.text || ''}`,
                  {
                    type: 'new_message',
                    hubId: hubId,
                  },
              );
            });

        await Promise.all(notifications);
        console.log(`Sent ${notifications.length} notifications for message in hub ${hubId}`);
      } catch (error) {
        console.error(`Error in onHubMessageCreated:`, error);
      }
    });

/**
 * Cloud Function: Triggered when a new comment is added to a post
 */
exports.onCommentCreated = functions.firestore
    .document('hubs/{hubId}/feed/{postId}/comments/{commentId}')
    .onCreate(async (snapshot, context) => {
      const snap = snapshot;
      const comment = snap.data();
      const postId = context.params.postId;
      const hubId = context.params.hubId;

      try {
        // Get post author
        const postDoc = await db
            .collection('hubs')
            .doc(hubId)
            .collection('feed')
            .doc(postId)
            .get();

        if (!postDoc.exists) {
          console.log(`Post ${postId} not found`);
          return;
        }

        const post = postDoc.data();
        const postAuthorId = post.authorId;

        // Don't notify if commenter is the post author
        if (comment.userId === postAuthorId) {
          return;
        }

        // Get commenter info
        const commenterDoc = await db.collection('users').doc(comment.userId).get();
        const commenterName = commenterDoc.exists ? commenterDoc.data().name : 'מישהו';

        // Send notification to post author
        await sendFCMNotification(
            postAuthorId,
            'תגובה חדשה',
            `${commenterName} הגיב על הפוסט שלך`,
            {
              type: 'new_comment',
              postId: postId,
              hubId: hubId,
            },
        );

        console.log(`Sent notification to post author ${postAuthorId}`);
      } catch (error) {
        console.error(`Error in onCommentCreated:`, error);
      }
    });

/**
 * Cloud Function: Triggered when a user follows another user
 */
exports.onFollowCreated = functions.firestore
    .document('users/{userId}/following/{followingId}')
    .onCreate(async (snapshot, context) => {
      const snap = snapshot;
      const followingId = context.params.followingId;
      const userId = context.params.userId;

      try {
        // Get follower info
        const followerDoc = await db.collection('users').doc(userId).get();
        const followerName = followerDoc.exists ? followerDoc.data().name : 'מישהו';

        // Send notification to followed user
        await sendFCMNotification(
            followingId,
            'עוקב חדש',
            `${followerName} התחיל לעקוב אחריך`,
            {
              type: 'new_follow',
              userId: userId,
            },
        );

        console.log(`Sent notification to ${followingId} about new follower ${userId}`);
      } catch (error) {
        console.error(`Error in onFollowCreated:`, error);
      }
    });

/**
 * Cloud Function: Triggered when a game reminder should be sent
 * This is called by the app when scheduling reminders
 */
exports.sendGameReminder = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
    );
  }

  const {gameId, userIds} = data;

  if (!gameId || !userIds || !Array.isArray(userIds)) {
    throw new functions.https.HttpsError(
        'invalid-argument',
        'gameId and userIds array are required',
    );
  }

  try {
    // Get game info
    const gameDoc = await db.collection('games').doc(gameId).get();
    if (!gameDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Game not found');
    }

    const game = gameDoc.data();
    const gameDate = game.gameDate.toDate();
    const location = game.location || 'מיקום לא צוין';

    // Format date
    const dateStr = gameDate.toLocaleDateString('he-IL', {
      day: 'numeric',
      month: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });

    // Send notifications to all users
    const notifications = userIds.map((userId) => {
      return sendFCMNotification(
          userId,
          'תזכורת משחק',
          `משחק מחר ב-${dateStr} ב-${location}`,
          {
            type: 'game_reminder',
            gameId: gameId,
          },
      );
    });

    await Promise.all(notifications);
    console.log(`Sent ${notifications.length} game reminders for game ${gameId}`);

    return {success: true, count: notifications.length};
  } catch (error) {
    console.error(`Error in sendGameReminder:`, error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

