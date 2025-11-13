const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const axiosRetryModule = require('axios-retry');
const NodeCache = require('node-cache');

admin.initializeApp();

const db = admin.firestore();

// Configure axios retry - handle both ESM and CJS exports
const axiosRetry = axiosRetryModule.default || axiosRetryModule;
const { exponentialDelay, isNetworkOrIdempotentRequestError } = axiosRetryModule;

axiosRetry(axios, {
  retries: 3,
  retryDelay: exponentialDelay,
  retryCondition: (error) => {
    return isNetworkOrIdempotentRequestError(error) ||
           (error.response && error.response.status === 429); // Rate limit
  },
});

// Cache for API responses (5 minutes TTL)
const apiCache = new NodeCache({ stdTTL: 300, checkperiod: 60 });
const userRateLimitCache = new NodeCache({ stdTTL: 2 }); // 2 seconds for rate limiting

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

/**
 * Cloud Function: Search venues using Google Places API (server-side)
 * This keeps the API key secure and allows caching/rate limiting
 */
exports.searchVenues = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
    );
  }

  const { latitude, longitude, radius, query, includeRentals } = data;

  // Validate input
  if (!latitude || !longitude) {
    throw new functions.https.HttpsError(
        'invalid-argument',
        'latitude and longitude are required',
    );
  }

  // Rate limiting per user
  const userId = context.auth.uid;
  const userCacheKey = `user_${userId}_venue_search`;
  const lastSearch = userRateLimitCache.get(userCacheKey);
  if (lastSearch && Date.now() - lastSearch < 2000) {
    throw new functions.https.HttpsError(
        'resource-exhausted',
        'Rate limit exceeded. Please wait 2 seconds between searches.',
    );
  }
  userRateLimitCache.set(userCacheKey, Date.now());

  try {
    // Check cache first
    const cacheKey = `venues_${latitude}_${longitude}_${radius || 5000}_${query || 'default'}_${includeRentals || false}`;
    const cached = apiCache.get(cacheKey);
    if (cached) {
      console.log(`Cache hit for venue search: ${cacheKey}`);
      return cached;
    }

    // Get API key from functions config
    const GOOGLE_PLACES_API_KEY = functions.config().googleplaces?.apikey;
    if (!GOOGLE_PLACES_API_KEY) {
      throw new functions.https.HttpsError(
          'failed-precondition',
          'Google Places API key not configured',
      );
    }

    const results = [];

    // 1. Text search
    if (query) {
      try {
        const textSearchResponse = await axios.get(
            'https://maps.googleapis.com/maps/api/place/textsearch/json',
            {
              params: {
                query: query,
                location: `${latitude},${longitude}`,
                radius: radius || 5000,
                type: 'stadium|gym|park|establishment',
                key: GOOGLE_PLACES_API_KEY,
                language: 'he',
              },
            },
        );

        if (textSearchResponse.data.status === 'OK') {
          results.push(...textSearchResponse.data.results);
        }
      } catch (error) {
        console.error('Text search error:', error.message);
      }
    }

    // 2. Nearby search
    try {
      const nearbyResponse = await axios.get(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
          {
            params: {
              location: `${latitude},${longitude}`,
              radius: radius || 5000,
              type: 'stadium|gym|park|establishment',
              keyword: 'מגרש כדורגל|football field|soccer field',
              key: GOOGLE_PLACES_API_KEY,
              language: 'he',
            },
          },
      );

      if (nearbyResponse.data.status === 'OK') {
        results.push(...nearbyResponse.data.results);
      }
    } catch (error) {
      console.error('Nearby search error:', error.message);
    }

    // 3. Rental search (if requested)
    if (includeRentals) {
      try {
        const rentalResponse = await axios.get(
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
            {
              params: {
                location: `${latitude},${longitude}`,
                radius: radius || 5000,
                type: 'establishment',
                keyword: 'השכרת מגרש|field rental|sports rental',
                key: GOOGLE_PLACES_API_KEY,
                language: 'he',
              },
            },
        );

        if (rentalResponse.data.status === 'OK') {
          rentalResponse.data.results.forEach((place) => {
            place.isRental = true; // Mark as rental
            results.push(place);
          });
        }
      } catch (error) {
        console.error('Rental search error:', error.message);
      }
    }

    // Remove duplicates by place_id
    const uniqueResults = [];
    const seenPlaceIds = new Set();
    for (const place of results) {
      if (!seenPlaceIds.has(place.place_id)) {
        seenPlaceIds.add(place.place_id);
        uniqueResults.push(place);
      }
    }

    // Calculate distances and sort
    const resultsWithDistance = uniqueResults.map((place) => {
      const placeLat = place.geometry.location.lat;
      const placeLng = place.geometry.location.lng;
      const distance = calculateDistance(latitude, longitude, placeLat, placeLng);
      return {
        ...place,
        distance: distance,
      };
    });

    resultsWithDistance.sort((a, b) => a.distance - b.distance);

    const response = {
      results: resultsWithDistance,
      count: resultsWithDistance.length,
    };

    // Cache the result
    apiCache.set(cacheKey, response);

    return response;
  } catch (error) {
    console.error('Error in searchVenues:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Cloud Function: Get place details from Google Places API
 */
exports.getPlaceDetails = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
    );
  }

  const { placeId } = data;
  if (!placeId) {
    throw new functions.https.HttpsError(
        'invalid-argument',
        'placeId is required',
    );
  }

  try {
    // Check cache
    const cacheKey = `place_details_${placeId}`;
    const cached = apiCache.get(cacheKey);
    if (cached) {
      return cached;
    }

    const GOOGLE_PLACES_API_KEY = functions.config().googleplaces?.apikey;
    if (!GOOGLE_PLACES_API_KEY) {
      throw new functions.https.HttpsError(
          'failed-precondition',
          'Google Places API key not configured',
      );
    }

    const response = await axios.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        {
          params: {
            place_id: placeId,
            fields: 'name,formatted_address,geometry,formatted_phone_number,rating,user_ratings_total,types,website,opening_hours',
            key: GOOGLE_PLACES_API_KEY,
            language: 'he',
          },
        },
    );

    if (response.data.status !== 'OK') {
      throw new functions.https.HttpsError(
          'not-found',
          'Place not found',
      );
    }

    const result = {
      place: response.data.result,
    };

    // Cache for 1 hour (place details don't change often)
    apiCache.set(cacheKey, result, 3600);

    return result;
  } catch (error) {
    console.error('Error in getPlaceDetails:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Cloud Function: Sync venue with custom API
 */
exports.syncVenueToCustomAPI = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
    );
  }

  const { venueId } = data;
  if (!venueId) {
    throw new functions.https.HttpsError(
        'invalid-argument',
        'venueId is required',
    );
  }

  try {
    // Get venue from Firestore
    const venueDoc = await db.collection('venues').doc(venueId).get();
    if (!venueDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Venue not found');
    }

    const venue = venueDoc.data();
    const customApiUrl = functions.config().customapi?.baseurl;
    const customApiKey = functions.config().customapi?.apikey;

    if (!customApiUrl) {
      throw new functions.https.HttpsError(
          'failed-precondition',
          'Custom API not configured',
      );
    }

    // Sync to custom API
    const response = await axios.post(
        `${customApiUrl}/venues/sync`,
        {
          venue: {
            ...venue,
            venueId: venueId,
          },
        },
        {
          headers: {
            'Content-Type': 'application/json',
            ...(customApiKey && { 'Authorization': `Bearer ${customApiKey}` }),
          },
        },
    );

    return { success: true, data: response.data };
  } catch (error) {
    console.error('Error in syncVenueToCustomAPI:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Cloud Function: Trigger when venue is created/updated - sync to custom API
 */
exports.onVenueChanged = functions.firestore
    .document('venues/{venueId}')
    .onWrite(async (change, context) => {
      const venueId = context.params.venueId;
      const venue = change.after.exists ? change.after.data() : null;

      if (!venue) {
        // Venue was deleted, skip sync
        return;
      }

      try {
        const customApiUrl = functions.config().customapi?.baseurl;
        if (!customApiUrl) {
          console.log('Custom API not configured, skipping sync');
          return;
        }

        // Sync to custom API (async, don't wait)
        const syncFunction = functions.https.callable('syncVenueToCustomAPI');
        await syncFunction({ venueId: venueId });
        console.log(`Synced venue ${venueId} to custom API`);
      } catch (error) {
        console.error(`Error syncing venue ${venueId}:`, error);
      }
    });

/**
 * Helper function: Calculate distance between two points (Haversine formula)
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371000; // Earth radius in meters
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
}

function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

