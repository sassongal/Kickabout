/* eslint-disable max-len */
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {info} = require("firebase-functions/logger");

// v2 Imports for new syntax
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");

// Google APIs
const axios = require("axios");

// Initialize Firebase Admin SDK
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// Google Places API
// -----------------
// Note: Make sure the Google Places API Key is set in the function environment
// firebase functions:config:set places.key="YOUR_API_KEY"
const PLACES_API_KEY = process.env.PLACES_KEY;
const PLACES_API_URL = "https://maps.googleapis.com/maps/api/place";

// --- v2 Scheduled Function (replaces v1 pubsub) ---
exports.sendGameReminder = onSchedule(
  "every 30 minutes",
  async (event) => {
    const now = new Date();
    const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000);
    const twoHoursFromNow = new Date(now.getTime() + 2 * 60 * 60 * 1000);

    info("Running sendGameReminder cron job at", now.toISOString());

    try {
      const gamesSnapshot = await db
        .collection("games")
        .where("startTime", ">=", oneHourFromNow)
        .where("startTime", "<", twoHoursFromNow)
        .where("status", "==", "scheduled")
        .get();

      if (gamesSnapshot.empty) {
        info("No games found for reminders.");
        return null;
      }

      info(`Found ${gamesSnapshot.size} games for reminders.`);

      const reminderPromises = gamesSnapshot.docs.map(
        async (gameDoc) => {
          const game = gameDoc.data();
          const gameId = gameDoc.id;

          // ... (rest of your logic is identical)
          const hubSnapshot = await db
            .collection("hubs")
            .doc(game.hubId)
            .get();
          if (!hubSnapshot.exists) return;
          const hubName = hubSnapshot.data().name;

          const signupsSnapshot = await db
            .collection("games")
            .doc(gameId)
            .collection("signups")
            .where("status", "==", "in")
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
              type: "game_reminder",
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
            type: "game_reminder",
            title: `משחק מתחיל בקרוב! (${hubName})`,
            body: `המשחק שלך ב-${hubName} מתחיל בעוד כשעה.`,
            isRead: false,
            entityId: gameId,
            hubId: game.hubId,
          };
          userIds.forEach((userId) => {
            const ref = db
              .collection("users")
              .doc(userId)
              .collection("notifications")
              .doc();
            batch.set(ref, notificationPayload);
          });
          await batch.commit();
        },
      );
      await Promise.all(reminderPromises);
      return null;
    } catch (error) {
      info("Error running sendGameReminder:", error);
      return null;
    }
  },
);

// --- v2 Firestore Triggers (replaces v1 functions.firestore.document) ---

exports.onGameCreated = onDocumentCreated("games/{gameId}", async (event) => {
  const game = event.data.data();
  const gameId = event.params.gameId;

  info(`New game created: ${gameId} in hub: ${game.hubId}`);

  try {
    // Fetch hub and user data in parallel for denormalization
    const [hubSnap, userSnap] = await Promise.all([
      db.collection("hubs").doc(game.hubId).get(),
      db.collection("users").doc(game.createdBy).get(),
    ]);

    if (!hubSnap.exists) {
      info("Hub does not exist");
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
      await db.collection("games").doc(gameId).update(gameUpdate);
    }

    // Create feed post in the correct structure: /hubs/{hubId}/feed/posts/items/{postId}
    const postRef = db
      .collection("hubs")
      .doc(game.hubId)
      .collection("feed")
      .doc("posts")
      .collection("items")
      .doc();
    
    await postRef.set({
      postId: postRef.id,
      hubId: game.hubId,
      hubName: hub.name,
      hubLogoUrl: hub.logoUrl || null,
      type: "game_created",
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
  "hubs/{hubId}/chat/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    const hubId = event.params.hubId;
    const messageId = event.params.messageId;

    info(`New message in hub: ${hubId} by ${message.authorId || message.senderId}`);

    try {
      // Fetch hub and user data in parallel for denormalization
      const [hubSnap, userSnap] = await Promise.all([
        db.collection("hubs").doc(hubId).get(),
        db.collection("users").doc(message.authorId || message.senderId).get(),
      ]);

      if (!hubSnap.exists) {
        info("Hub does not exist");
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
          .collection("hubs")
          .doc(hubId)
          .collection("chat")
          .collection("messages")
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
            .collection("users")
            .doc(memberId)
            .collection("fcm_tokens")
            .doc("tokens")
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
          type: "hub_chat",
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
  "hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}",
  async (event) => {
    const comment = event.data.data();
    const hubId = event.params.hubId;
    const postId = event.params.postId;
    const commentId = event.params.commentId;

    info(`New comment on post: ${postId} by ${comment.authorId}`);

    try {
      // Fetch user data for denormalization
      const userSnap = await db.collection("users").doc(comment.authorId).get();
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
          .collection("hubs")
          .doc(hubId)
          .collection("feed")
          .doc("posts")
          .collection("items")
          .doc(postId)
          .collection("comments")
          .doc(commentId)
          .update(commentUpdate);
      }

      // Increment comment count on post
      const postRef = db
        .collection("hubs")
        .doc(hubId)
        .collection("feed")
        .doc("posts")
        .collection("items")
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
      const postAuthorSnap = await db.collection("users").doc(post.authorId).get();
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
          type: "new_comment",
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
  "users/{followedId}/followers/{followerId}",
  async (event) => {
    const follower = event.data.data();
    const followedId = event.params.followedId;
    info(`User ${follower.followerId} started following ${followedId}`);

    try {
      const userRef = db.collection("users").doc(followedId);
      const userSnap = await userRef.get();
      if (!userSnap.exists) return;

      // ... (rest of your logic is identical)
      await userRef.update({
        followerCount: FieldValue.increment(1),
      });

      const followedUser = userSnap.data();
      if (!followedUser.fcmToken) {
        info("Followed user does not have FCM token. No notification sent.");
        return;
      }

      const payload = {
        notification: {
          title: "עוקב חדש!",
          body: `${follower.followerName} התחיל לעקוב אחריך.`,
        },
        token: followedUser.fcmToken,
        data: {
          type: "new_follower",
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
  "venues/{venueId}",
  async (event) => {
    // This trigger handles create, update, and delete
    const venueId = event.params.venueId;

    // On delete
    if (!event.data.after.exists) {
      info(`Venue ${venueId} deleted. Triggering hub updates.`);
      // ... (rest of your logic is identical)
      const hubsSnap = await db
        .collection("hubs")
        .where("venueIds", "array-contains", venueId)
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
      .collection("hubs")
      .where("venueIds", "array-contains", venueId)
      .get();
    if (hubsSnap.empty) {
      info("No hubs found using this venue.");
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
  "ratings/{userId}/history/{ratingId}",
  async (event) => {
    const rating = event.data.data();
    const userId = event.params.userId;
    const ratingId = event.params.ratingId;

    info(`New rating snapshot created: ${ratingId} for user ${userId}`);

    try {
      // Get user's hub settings to determine rating mode
      const userSnap = await db.collection("users").doc(userId).get();
      if (!userSnap.exists) {
        info("User does not exist");
        return;
      }

      // Get all rating history for this user
      const historySnap = await db
        .collection("ratings")
        .doc(userId)
        .collection("history")
        .orderBy("submittedAt", "desc")
        .limit(10) // Last 10 games
        .get();

      if (historySnap.empty) {
        info("No rating history found");
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
        info("No valid ratings to calculate average");
        return;
      }

      const averageRating = totalRating / count;

      // Update user's currentRankScore (denormalized)
      await db.collection("users").doc(userId).update({
        currentRankScore: averageRating,
      });

      info(`Updated user ${userId} rating to ${averageRating} (from ${count} games).`);
    } catch (error) {
      info(`Error in onRatingSnapshotCreated for user ${userId}:`, error);
    }
  },
);

// --- v2 Callable Functions (already v2, no change needed) ---

exports.searchVenues = onCall(async (request) => {
  const {query, lat, lng} = request.data;
  if (!query) {
    throw new HttpsError("invalid-argument", "Missing 'query' parameter.");
  }
  if (!PLACES_API_KEY) {
    throw new HttpsError(
      "failed-precondition",
      "PLACES_API_KEY is not set.",
    );
  }

  let url = `${PLACES_API_URL}/textsearch/json?query=${encodeURIComponent(
    query,
  )}&key=${PLACES_API_KEY}&language=iw`;
  if (lat && lng) {
    url += `&location=${lat},${lng}&radius=5000`; // 5km radius
  }

  try {
    const response = await axios.get(url);
    return response.data;
  } catch (error) {
    throw new HttpsError("internal", "Failed to call Google Places API.", error);
  }
});

exports.getPlaceDetails = onCall(async (request) => {
  const {placeId} = request.data;
  if (!placeId) {
    throw new HttpsError("invalid-argument", "Missing 'placeId' parameter.");
  }
  if (!PLACES_API_KEY) {
    throw new HttpsError(
      "failed-precondition",
      "PLACES_API_KEY is not set.",
    );
  }

  const url = `${PLACES_API_URL}/details/json?place_id=${placeId}&key=${PLACES_API_KEY}&language=iw&fields=place_id,name,formatted_address,geometry`;

  try {
    const response = await axios.get(url);
    return response.data;
  } catch (error) {
    throw new HttpsError("internal", "Failed to call Google Places API.", error);
  }
});
