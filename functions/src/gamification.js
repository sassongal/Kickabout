/* eslint-disable max-len */
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { info } = require('firebase-functions/logger');
const { db, FieldValue } = require('./utils');

exports.onRatingSnapshotCreated = onDocumentCreated(
  'ratings/{userId}/history/{ratingId}',
  async (event) => {
    const userId = event.params.userId;
    const ratingId = event.params.ratingId;

    info(`New rating snapshot created: ${ratingId} for user ${userId}`);

    try {
      // Get user's hub settings to determine rating mode
      const userSnap = await db.collection('users').doc(userId).get();
      if (!userSnap.exists) {
        info('User does not exist');
        return;
      }

      // Get all rating history for this user
      const historySnap = await db
        .collection('ratings')
        .doc(userId)
        .collection('history')
        .orderBy('submittedAt', 'desc')
        .limit(10) // Last 10 games
        .get();

      if (historySnap.empty) {
        info('No rating history found');
        return;
      }

      // Calculate average rating based on rating mode
      // For simplicity, we'll use the last 10 games
      let totalRating = 0.0;
      let count = 0;

      historySnap.forEach((doc) => {
        const snapshot = doc.data();
        if (snapshot.basicScore != null) {
          // Basic mode: use basicScore
          totalRating += snapshot.basicScore;
          count += 1;
        } else {
          // Advanced mode: average of 8 categories
          totalRating +=
            (snapshot.defense +
              snapshot.passing +
              snapshot.shooting +
              snapshot.dribbling +
              snapshot.physical +
              snapshot.leadership +
              snapshot.teamPlay +
              snapshot.consistency) /
            8.0;
          count += 1;
        }
      });

      if (count === 0) {
        info('No valid ratings to calculate average');
        return;
      }

      const averageRating = totalRating / count;

      // Update user's currentRankScore (denormalized)
      await db.collection('users').doc(userId).update({
        currentRankScore: averageRating,
      });

      info(`Updated user ${userId} rating to ${averageRating} (from ${count} games).`);
    } catch (error) {
      info(`Error in onRatingSnapshotCreated for user ${userId}:`, error);
    }
  },
);

