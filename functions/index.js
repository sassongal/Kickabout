/* eslint-disable max-len */
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {info} = require('firebase-functions/logger');

// v2 Imports for new syntax
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {
  onDocumentCreated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret} = require('firebase-functions/params');

// Define secret for Google APIs key (server-side only)
const googleApisKey = defineSecret('GOOGLE_APIS_KEY');

// Google APIs
const axios = require('axios');

// Initialize Firebase Admin SDK
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// Google Places API
// -----------------
// Note: API key is now stored as a Firebase Secret (GOOGLE_APIS_KEY)
// Set it using: echo "YOUR_KEY" | firebase functions:secrets:set GOOGLE_APIS_KEY
const PLACES_API_URL = 'https://maps.googleapis.com/maps/api/place';

// --- v2 Scheduled Function (replaces v1 pubsub) ---
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
            .where('startTime', '>=', oneHourFromNow)
            .where('startTime', '<', twoHoursFromNow)
            .where('status', '==', 'scheduled')
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

              // ... (rest of your logic is identical)
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
                  .where('status', '==', 'in')
                  .get();

              if (signupsSnapshot.empty) return;

              const tokens = [];
              const userIds = [];
              signupsSnapshot.forEach((doc) => {
                const signup = doc.data();
                if (signup.fcmToken) {
                  tokens.push(signup.fcmToken);
                }
                userIds.push(doc.id);
              });

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
                isRead: false,
                entityId: gameId,
                hubId: game.hubId,
              };
              userIds.forEach((userId) => {
                const ref = db
                    .collection('users')
                    .doc(userId)
                    .collection('notifications')
                    .doc();
                batch.set(ref, notificationPayload);
              });
              await batch.commit();
            },
        );
        await Promise.all(reminderPromises);
        return null;
      } catch (error) {
        info('Error running sendGameReminder:', error);
        return null;
      }
    },
);

// --- v2 Firestore Triggers (replaces v1 functions.firestore.document) ---

exports.onGameCreated = onDocumentCreated('games/{gameId}', async (event) => {
  const game = event.data.data();
  const gameId = event.params.gameId;

  info(`New game created: ${gameId} in hub: ${game.hubId}`);

  try {
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

exports.onHubMessageCreated = onDocumentCreated(
    'hubs/{hubId}/chat/messages/{messageId}',
    async (event) => {
      const message = event.data.data();
      const hubId = event.params.hubId;
      const messageId = event.params.messageId;

      info(`New message in hub: ${hubId} by ${message.authorId || message.senderId}`);

      try {
      // Fetch hub and user data in parallel for denormalization
        const [hubSnap, userSnap] = await Promise.all([
          db.collection('hubs').doc(hubId).get(),
          db.collection('users').doc(message.authorId || message.senderId).get(),
        ]);

        if (!hubSnap.exists) {
          info('Hub does not exist');
          return;
        }
        const hub = hubSnap.data();
        const user = userSnap.exists ? userSnap.data() : null;

        // Denormalize user data into message document
        const messageUpdate = {};
        if (user) {
          messageUpdate.senderId = message.authorId || message.senderId;
          messageUpdate.senderName = user.name || null;
          messageUpdate.senderPhotoUrl = user.photoUrl || null;
        }

        // Update message with denormalized data
        if (Object.keys(messageUpdate).length > 0) {
          await db
              .collection('hubs')
              .doc(hubId)
              .collection('chat')
              .collection('messages')
              .doc(messageId)
              .update(messageUpdate);
        }

        // Update hub last activity
        await hubSnap.ref.update({
          lastActivity: message.createdAt,
        });

        const hubName = hub.name;

        // Get hub members
        const hubData = hubSnap.data();
        const memberIds = hubData.memberIds || [];
        if (memberIds.length === 0) return;

        // Get FCM tokens for all members except sender
        const tokens = [];
        for (const memberId of memberIds) {
          if (memberId === message.senderId) continue;

          try {
          // FCM tokens are stored in users/{userId}/fcm_tokens/tokens
            const tokenDoc = await db
                .collection('users')
                .doc(memberId)
                .collection('fcm_tokens')
                .doc('tokens')
                .get();

            if (tokenDoc.exists) {
              const tokenData = tokenDoc.data();
              const userTokens = tokenData.tokens || [];
              // Add all tokens for this user (users can have multiple devices)
              if (Array.isArray(userTokens) && userTokens.length > 0) {
                tokens.push(...userTokens);
              }
            }
          } catch (error) {
            info(`Failed to get FCM token for user ${memberId}: ${error}`);
          }
        }

        if (tokens.length === 0) return;
        const uniqueTokens = [...new Set(tokens)];

        const payload = {
          notification: {
            title: `💬 הודעה חדשה ב-${hubName}`,
            body: `${message.senderName}: ${message.text}`,
          },
          tokens: uniqueTokens,
          data: {
            type: 'hub_chat',
            hubId: hubId,
          },
        };

        await messaging.sendEachForMulticast(payload);
        info(`Sent chat notification for hub ${hubId} to ${uniqueTokens.length} tokens.`);
      } catch (error) {
        info(`Error in onHubMessageCreated for hub ${hubId}:`, error);
      }
    },
);

exports.onCommentCreated = onDocumentCreated(
    'hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}',
    async (event) => {
      const comment = event.data.data();
      const hubId = event.params.hubId;
      const postId = event.params.postId;
      const commentId = event.params.commentId;

      info(`New comment on post: ${postId} by ${comment.authorId}`);

      try {
      // Fetch user data for denormalization
        const userSnap = await db.collection('users').doc(comment.authorId).get();
        const user = userSnap.exists ? userSnap.data() : null;

        // Denormalize user data into comment document
        const commentUpdate = {};
        if (user) {
          commentUpdate.authorName = user.name || null;
          commentUpdate.authorPhotoUrl = user.photoUrl || null;
        }

        // Update comment with denormalized data
        if (Object.keys(commentUpdate).length > 0) {
          await db
              .collection('hubs')
              .doc(hubId)
              .collection('feed')
              .doc('posts')
              .collection('items')
              .doc(postId)
              .collection('comments')
              .doc(commentId)
              .update(commentUpdate);
        }

        // Increment comment count on post
        const postRef = db
            .collection('hubs')
            .doc(hubId)
            .collection('feed')
            .doc('posts')
            .collection('items')
            .doc(postId);

        await postRef.update({
          commentCount: FieldValue.increment(1),
        });

        // Get post data for notification
        const postSnap = await postRef.get();
        if (!postSnap.exists) return;
        const post = postSnap.data();

        // Don't send notification if user comments on their own post
        if (post.authorId === comment.authorId) return;

        // Get post author's FCM token
        const postAuthorSnap = await db.collection('users').doc(post.authorId).get();
        if (!postAuthorSnap.exists) return;
        const fcmToken = postAuthorSnap.data().fcmToken;

        if (!fcmToken) return;

        const payload = {
          notification: {
            title: `💬 ${user?.name || 'מישהו'} הגיב לפוסט שלך`,
            body: comment.text,
          },
          token: fcmToken,
          data: {
            type: 'new_comment',
            postId: postId,
            hubId: hubId,
          },
        };

        await messaging.send(payload);
        info(`Sent comment notification for post ${postId} to user ${post.authorId}.`);
      } catch (error) {
        info(`Error in onCommentCreated for post ${postId}:`, error);
      }
    },
);

exports.onFollowCreated = onDocumentCreated(
    'users/{followedId}/followers/{followerId}',
    async (event) => {
      const follower = event.data.data();
      const followedId = event.params.followedId;
      info(`User ${follower.followerId} started following ${followedId}`);

      try {
        const userRef = db.collection('users').doc(followedId);
        const userSnap = await userRef.get();
        if (!userSnap.exists) return;

        // ... (rest of your logic is identical)
        await userRef.update({
          followerCount: FieldValue.increment(1),
        });

        const followedUser = userSnap.data();
        if (!followedUser.fcmToken) {
          info('Followed user does not have FCM token. No notification sent.');
          return;
        }

        const payload = {
          notification: {
            title: 'עוקב חדש!',
            body: `${follower.followerName} התחיל לעקוב אחריך.`,
          },
          token: followedUser.fcmToken,
          data: {
            type: 'new_follower',
            followerId: follower.followerId,
          },
        };

        await messaging.send(payload);
        info(`Sent follower notification to user ${followedId}.`);
      } catch (error) {
        info(`Error in onFollowCreated for user ${followedId}:`, error);
      }
    },
);

exports.onVenueChanged = onDocumentWritten(
    'venues/{venueId}',
    async (event) => {
    // This trigger handles create, update, and delete
      const venueId = event.params.venueId;

      // On delete
      if (!event.data.after.exists) {
        info(`Venue ${venueId} deleted. Triggering hub updates.`);
        // ... (rest of your logic is identical)
        const hubsSnap = await db
            .collection('hubs')
            .where('venueIds', 'array-contains', venueId)
            .get();
        if (hubsSnap.empty) return;

        const batch = db.batch();
        hubsSnap.forEach((doc) => {
          batch.update(doc.ref, {
            venueIds: FieldValue.arrayRemove(venueId),
            venues: FieldValue.arrayRemove(event.data.before.data()),
          });
        });
        await batch.commit();
        info(`Removed venue ${venueId} from ${hubsSnap.size} hubs.`);
        return;
      }

      // On create or update
      const venueData = event.data.after.data();
      info(`Venue ${venueId} created or updated. Triggering hub updates.`);

      // ... (rest of your logic is identical)
      const hubsSnap = await db
          .collection('hubs')
          .where('venueIds', 'array-contains', venueId)
          .get();
      if (hubsSnap.empty) {
        info('No hubs found using this venue.');
        return;
      }

      const batch = db.batch();
      hubsSnap.forEach((doc) => {
        const hub = doc.data();
        // Find the old venue data in the hub's array and replace it
        const oldVenues = hub.venues || [];
        const newVenues = oldVenues.map((v) => (v.id === venueId ? venueData : v));
        batch.update(doc.ref, {venues: newVenues});
      });

      await batch.commit();
      info(`Updated venue ${venueId} in ${hubsSnap.size} hubs.`);
    },
);

// --- Rating Calculation Function (moved from client to server) ---
// This function automatically calculates and updates a user's average rating
// whenever a new rating snapshot is added
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

// --- v2 Callable Functions (already v2, no change needed) ---

exports.searchVenues = onCall(
    {secrets: [googleApisKey]},
    async (request) => {
      const {query, lat, lng} = request.data;
      if (!query) {
        throw new HttpsError('invalid-argument', 'Missing \'query\' parameter.');
      }

      const apiKey = googleApisKey.value();
      if (!apiKey) {
        throw new HttpsError(
            'failed-precondition',
            'GOOGLE_APIS_KEY is not set.',
        );
      }

      let url = `${PLACES_API_URL}/textsearch/json?query=${encodeURIComponent(
          query,
      )}&key=${apiKey}&language=iw`;
      if (lat && lng) {
        url += `&location=${lat},${lng}&radius=5000`; // 5km radius
      }

      try {
        const response = await axios.get(url);
        return response.data;
      } catch (error) {
        throw new HttpsError('internal', 'Failed to call Google Places API.', error);
      }
    },
);

exports.getPlaceDetails = onCall(
    {secrets: [googleApisKey]},
    async (request) => {
      const {placeId} = request.data;
      if (!placeId) {
        throw new HttpsError('invalid-argument', 'Missing \'placeId\' parameter.');
      }

      const apiKey = googleApisKey.value();
      if (!apiKey) {
        throw new HttpsError(
            'failed-precondition',
            'GOOGLE_APIS_KEY is not set.',
        );
      }

      const url = `${PLACES_API_URL}/details/json?place_id=${placeId}&key=${apiKey}&language=iw&fields=place_id,name,formatted_address,geometry`;

      try {
        const response = await axios.get(url);
        return response.data;
      } catch (error) {
        throw new HttpsError('internal', 'Failed to call Google Places API.', error);
      }
    },
);

// --- Weather & Vibe Function ---
/**
 * Helper function to generate Vibe message based on weather and AQI
 * @param {number} temp - Temperature in Celsius
 * @param {string} condition - Weather condition (clear, cloudy, rain, etc.)
 * @param {number} aqi - Air Quality Index (0-300+)
 * @return {string} Vibe message in Hebrew
 */
function getVibeMessage(temp, condition, aqi) {
  // AQI categories: 0-50 (Good), 51-100 (Moderate), 101-150 (Unhealthy for Sensitive), 151+ (Unhealthy)
  // Temperature: ideal for football is 15-25°C
  // Condition: clear, cloudy, rain, etc.

  // Normalize condition code
  const conditionLower = condition ? condition.toLowerCase() : 'clear';
  const isClear = conditionLower === 'clear' || conditionLower.includes('clear');
  const isPartlyCloudy = conditionLower === 'partly_cloudy' ||
                         conditionLower.includes('partly') ||
                         conditionLower.includes('partially');

  // Perfect conditions
  if (aqi <= 50 && temp >= 15 && temp <= 25 && isClear) {
    return 'יום פנטסטי לכדורגל! מזג אוויר מושלם ואוויר נקי.';
  }

  // Great conditions
  if (aqi <= 50 && temp >= 12 && temp <= 28 && (isClear || isPartlyCloudy)) {
    return 'יום מעולה למשחק! תנאים מצוינים.';
  }

  // Good but not perfect
  if (aqi <= 100 && temp >= 10 && temp <= 30) {
    // Handle various condition codes from Google Weather API
    const conditionLower = condition ? condition.toLowerCase() : 'clear';
    if (conditionLower.includes('rain') || conditionLower.includes('drizzle') ||
        conditionLower === 'rain' || conditionLower === 'drizzle') {
      return 'יום גשום, אבל כדורגל זה תמיד כיף! 🌧️';
    }
    if (conditionLower.includes('cloud') || conditionLower === 'cloudy' ||
        conditionLower === 'partly_cloudy') {
      return 'יום מעונן אבל נעים למשחק.';
    }
    return 'יום טוב לכדורגל!';
  }

  // Air quality concerns
  if (aqi > 100) {
    if (aqi > 150) {
      return '⚠️ איכות אוויר לא טובה היום. שקול לשחק במקום סגור או לדחות.';
    }
    return 'איכות אוויר בינונית. אם אתה רגיש, שקול להיזהר.';
  }

  // Temperature extremes
  if (temp < 10) {
    return 'יום קר למשחק. הקפד להתחמם היטב! 🥶';
  }
  if (temp > 30) {
    return 'יום חם מאוד! הקפד לשתות הרבה מים ולהקפיד על הפסקות. ☀️';
  }

  // Default fallback
  return 'יום טוב לכדורגל!';
}

// Home Dashboard Data Function
// Returns weather and vibe data for the home screen
exports.getHomeDashboardData = onCall(
    {secrets: [googleApisKey]},
    async (request) => {
      const {lat, lon} = request.data;

      // Validate input
      if (lat === undefined || lon === undefined) {
        throw new HttpsError(
            'invalid-argument',
            'Missing \'lat\' or \'lon\' parameter.',
        );
      }

      info(`Getting home dashboard data for location: ${lat}, ${lon}`);

      try {
        const apiKey = googleApisKey.value();

        if (!apiKey) {
          throw new HttpsError(
              'failed-precondition',
              'GOOGLE_APIS_KEY is not set. Please configure it as a Firebase Secret.',
          );
        }

        // 1. Call Google Weather API
        const weatherUrl = `https://weather.googleapis.com/v1/currentConditions:lookup?key=${apiKey}`;

        let weatherData;
        let temperature = null;
        let conditionCode = 'clear';

        try {
          const weatherResponse = await axios.post(weatherUrl, {
            location: {
              latitude: lat,
              longitude: lon,
            },
            languageCode: 'iw',
          });

          if (weatherResponse.data && weatherResponse.data.currentConditions) {
            weatherData = weatherResponse.data.currentConditions;
            // Temperature might be in different units, convert to Celsius if needed
            temperature = weatherData.temperature;
            if (weatherData.temperatureUnit === 'FAHRENHEIT') {
              temperature = (temperature - 32) * 5 / 9;
            }
            // conditionCode might be in different formats, normalize it
            conditionCode = weatherData.conditionCode || weatherData.condition || 'clear';
          } else {
            info('Weather API returned unexpected format, using defaults');
          }
        } catch (weatherError) {
          info(`Error calling Weather API: ${weatherError.message}`);
          // Fallback to default values if API fails
          temperature = 22;
          conditionCode = 'clear';
        }

        // 2. Call Google Air Quality API
        const aqiUrl = `https://airquality.googleapis.com/v1/currentConditions:lookup?key=${apiKey}`;

        let aqiIndex = 40; // Default to good air quality

        try {
          const aqiResponse = await axios.post(aqiUrl, {
            location: {
              latitude: lat,
              longitude: lon,
            },
          });

          if (aqiResponse.data && aqiResponse.data.indexes && aqiResponse.data.indexes.length > 0) {
            // Get the main AQI index (usually the first one)
            const mainIndex = aqiResponse.data.indexes[0];
            aqiIndex = mainIndex.aqi || mainIndex.index || 40;
          } else {
            info('Air Quality API returned unexpected format, using default');
          }
        } catch (aqiError) {
          info(`Error calling Air Quality API: ${aqiError.message}`);
          // Fallback to default value if API fails
          aqiIndex = 40;
        }

        // 3. Generate vibe message using the helper function with real data
        const vibeMessage = getVibeMessage(
            temperature || 22,
            conditionCode,
            aqiIndex,
        );

        // 4. Return real data to the app
        return {
          vibeMessage: vibeMessage,
          temperature: temperature ? Math.round(temperature) : null,
          condition: conditionCode,
          aqiIndex: aqiIndex,
          timestamp: new Date().toISOString(),
        };
      } catch (error) {
        info(`Error in getHomeDashboardData:`, error);
        // Return default values on error instead of throwing
        // This ensures the app still works even if APIs fail
        return {
          vibeMessage: 'יום טוב לכדורגל! ☀️',
          temperature: null,
          condition: 'clear',
          aqiIndex: null,
          timestamp: new Date().toISOString(),
        };
      }
    },
);
