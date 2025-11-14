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
    const hubRef = db.collection("hubs").doc(game.hubId);
    const hubSnap = await hubRef.get();
    if (!hubSnap.exists) {
      info("Hub does not exist");
      return;
    }
    const hub = hubSnap.data();

    // ... (rest of your logic is identical)
    const postRef = db.collection("feed").doc();
    await postRef.set({
      id: postRef.id,
      hubId: game.hubId,
      hubName: hub.name,
      hubLogoUrl: hub.logoUrl || null,
      type: "game_created",
      text: `משחק חדש נוצר ב-${hub.name}!`,
      createdAt: game.createdAt,
      authorId: game.createdBy,
      authorName: game.createdByName,
      authorPhotoUrl: game.createdByPhotoUrl || null,
      entityId: gameId,
      likeCount: 0,
      commentCount: 0,
    });

    // Update hub stats
    await hubRef.update({
      gameCount: FieldValue.increment(1),
      lastActivity: game.createdAt,
    });

    info(`Feed post and hub stats updated for game ${gameId}.`);
  } catch (error) {
    info(`Error in onGameCreated for game ${gameId}:`, error);
  }
});

exports.onHubMessageCreated = onDocumentCreated(
  "hubs/{hubId}/chat/{messageId}",
  async (event) => {
    const message = event.data.data();
    const hubId = event.params.hubId;

    info(`New message in hub: ${hubId} by ${message.senderName}`);

    try {
      // Update hub last activity
      const hubRef = db.collection("hubs").doc(hubId);
      await hubRef.update({
        lastActivity: message.createdAt,
      });

      // ... (rest of your logic is identical)
      const hubSnap = await hubRef.get();
      if (!hubSnap.exists) return;
      const hubName = hubSnap.data().name;

      const membersSnap = await db
        .collection("hubs")
        .doc(hubId)
        .collection("members")
        .get();
      if (membersSnap.empty) return;

      const tokens = [];
      membersSnap.forEach((doc) => {
        const member = doc.data();
        // Don't send notification to the sender
        if (member.fcmToken && doc.id !== message.senderId) {
          tokens.push(member.fcmToken);
        }
      });

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
  "feed/{postId}/comments/{commentId}",
  async (event) => {
    const comment = event.data.data();
    const postId = event.params.postId;
    info(`New comment on post: ${postId} by ${comment.authorName}`);

    try {
      const postRef = db.collection("feed").doc(postId);

      // Increment comment count on post
      await postRef.update({
        commentCount: FieldValue.increment(1),
      });

      // ... (rest of your logic is identical)
      const postSnap = await postRef.get();
      if (!postSnap.exists) return;
      const post = postSnap.data();

      // Don't send notification if user comments on their own post
      if (post.authorId === comment.authorId) return;

      const userSnap = await db.collection("users").doc(post.authorId).get();
      if (!userSnap.exists) return;
      const fcmToken = userSnap.data().fcmToken;

      if (!fcmToken) return;

      const payload = {
        notification: {
          title: `💬 ${comment.authorName} הגיב לפוסט שלך`,
          body: comment.text,
        },
        token: fcmToken,
        data: {
          type: "new_comment",
          postId: postId,
          hubId: post.hubId || "",
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
