/* eslint-disable max-len */
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {getAuth} = require('firebase-admin/auth');
const {info} = require('firebase-functions/logger');

// v2 Imports for new syntax
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {
  onDocumentCreated,
  onDocumentWritten,
  onDocumentDeleted,
  onDocumentUpdated,
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
const admin = {auth: getAuth()};

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
            .where('gameDate', '>=', oneHourFromNow)
            .where('gameDate', '<', twoHoursFromNow)
            .where('status', 'in', ['teamSelection', 'teamsFormed']) // Games that haven't started yet
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
                  .where('status', '==', 'confirmed') // Use 'confirmed' status from SignupStatus enum
                  .get();

              if (signupsSnapshot.empty) return;

              const tokens = [];
              const userIds = [];
              
              // Fetch FCM tokens from users/{userId}/fcm_tokens/tokens subcollection
              for (const signupDoc of signupsSnapshot.docs) {
                const userId = signupDoc.id;
                userIds.push(userId);
                
                try {
                  const tokenDoc = await db
                      .collection('users')
                      .doc(userId)
                      .collection('fcm_tokens')
                      .doc('tokens')
                      .get();
                  
                  if (tokenDoc.exists) {
                    const tokenData = tokenDoc.data();
                    const userTokens = tokenData?.tokens || [];
                    if (Array.isArray(userTokens) && userTokens.length > 0) {
                      tokens.push(...userTokens);
                    }
                  }
                } catch (error) {
                  info(`Failed to get FCM token for user ${userId}: ${error}`);
                }
              }

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
        return null;
      } catch (error) {
        info('Error running sendGameReminder:', error);
        return null;
      }
    },
);

// --- v2 Firestore Triggers (replaces v1 functions.firestore.document) ---

// --- Super Admin Auto-Assignment ---
// Automatically adds Super Admin to every newly created hub
// Note: Super Admin email should be set as a Firebase Secret (SUPER_ADMIN_EMAIL)
// Set it using: echo "your-email@example.com" | firebase functions:secrets:set SUPER_ADMIN_EMAIL
// For now, using environment variable or default (can be overridden via Secret)
exports.addSuperAdminToHub = onDocumentCreated('hubs/{hubId}', async (event) => {
  const hubId = event.params.hubId;
  const hubData = event.data.data();

  info(`New hub created: ${hubId}. Adding Super Admin...`);

  try {
    // Super Admin email - should be set as Firebase Secret in production
    // For development, you can set it here or via environment variable
    // TODO: Move to Firebase Secret: SUPER_ADMIN_EMAIL
    const superAdminEmail = process.env.SUPER_ADMIN_EMAIL || null;

    // Skip if no super admin email configured
    if (!superAdminEmail) {
      info('Super Admin email not configured. Skipping auto-assignment.');
      return;
    }

    // Get Super Admin user by email
    let superAdminUid;
    try {
      const userRecord = await admin.auth().getUserByEmail(superAdminEmail);
      superAdminUid = userRecord.uid;
      info(`Found Super Admin user: ${superAdminUid}`);
    } catch (authError) {
      // If user not found, log and return (don't fail hub creation)
      info(`Super Admin user not found (${superAdminEmail}): ${authError.message}`);
      return;
    }

    // Update hub to add Super Admin as admin
    const hubRef = event.data.ref;
    await hubRef.update({
      [`roles.${superAdminUid}`]: 'admin',
    });

    info(`✅ Added Super Admin (${superAdminUid}) to hub ${hubId} with admin role.`);
  } catch (error) {
    // Log error but don't fail hub creation
    info(`⚠️ Error adding Super Admin to hub ${hubId}: ${error.message}`);
  }
});

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

// --- Hub Deletion Handler ---
// When a hub is deleted, update hubCount on all associated venues
exports.onHubDeleted = onDocumentDeleted(
    'hubs/{hubId}',
    async (event) => {
      const hubId = event.params.hubId;
      const hubData = event.data.data();

      info(`Hub ${hubId} deleted. Updating venue hubCounts.`);

      try {
        // Get all venueIds associated with this hub
        const venueIds = hubData?.venueIds || [];
        const primaryVenueId = hubData?.primaryVenueId;

        // Combine all venue IDs (primary + secondary)
        const allVenueIds = [...new Set([
          ...venueIds,
          ...(primaryVenueId ? [primaryVenueId] : []),
        ])];

        if (allVenueIds.length === 0) {
          info(`No venues associated with hub ${hubId}.`);
          return;
        }

        // Update hubCount for each venue
        const batch = db.batch();
        for (const venueId of allVenueIds) {
          const venueRef = db.collection('venues').doc(venueId);
          batch.update(venueRef, {
            hubCount: FieldValue.increment(-1),
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
        info(`Updated hubCount for ${allVenueIds.length} venues after hub ${hubId} deletion.`);
      } catch (error) {
        info(`Error in onHubDeleted for hub ${hubId}:`, error);
      }
    },
);

exports.onHubMessageCreated = onDocumentCreated(
    'hubs/{hubId}/chat/{messageId}',
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

        // Get post author's FCM token from subcollection
        const tokenDoc = await db
            .collection('users')
            .doc(post.authorId)
            .collection('fcm_tokens')
            .doc('tokens')
            .get();
        
        if (!tokenDoc.exists) return;
        const tokenData = tokenDoc.data();
        const userTokens = tokenData?.tokens || [];
        if (!Array.isArray(userTokens) || userTokens.length === 0) return;
        
        const fcmToken = userTokens[0]; // Use first token

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

        // Get FCM token from subcollection
        const tokenDoc = await db
            .collection('users')
            .doc(followedId)
            .collection('fcm_tokens')
            .doc('tokens')
            .get();
        
        if (!tokenDoc.exists) {
          info('Followed user does not have FCM token. No notification sent.');
          return;
        }
        
        const tokenData = tokenDoc.data();
        const userTokens = tokenData?.tokens || [];
        if (!Array.isArray(userTokens) || userTokens.length === 0) {
          info('Followed user does not have FCM token. No notification sent.');
          return;
        }
        
        const fcmToken = userTokens[0]; // Use first token

        const payload = {
          notification: {
            title: 'עוקב חדש!',
            body: `${follower.followerName} התחיל לעקוב אחריך.`,
          },
          token: fcmToken,
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

      // Note: Hub model uses venueIds array, not venues array
      // Venue updates are handled by the client when needed
      // No batch update needed here since we only track venueIds, not full venue objects
      info(`Venue ${venueId} updated. Hubs using this venue: ${hubsSnap.size}.`);
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

// --- Game Completion Handler ---
// When a game status changes to 'completed', calculate and update player statistics
exports.onGameCompleted = onDocumentUpdated(
    'games/{gameId}',
    async (event) => {
      const gameId = event.params.gameId;
      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();

      // Only process if status changed to 'completed'
      const beforeStatus = beforeData?.status;
      const afterStatus = afterData?.status;

      if (afterStatus !== 'completed' || beforeStatus === 'completed') {
        // Status didn't change to completed, skip
        return;
      }

      info(`Game ${gameId} completed. Calculating player statistics.`);

      try {
        // Get game data to read teams and scores
        const gameData = afterData;
        const teams = gameData.teams || [];
        const teamAScore = gameData.teamAScore ?? 0;
        const teamBScore = gameData.teamBScore ?? 0;

        // Determine winning team based on scores
        let winningTeamId = null;
        if (teams.length >= 2) {
          if (teamAScore > teamBScore) {
            winningTeamId = teams[0]?.teamId || null;
          } else if (teamBScore > teamAScore) {
            winningTeamId = teams[1]?.teamId || null;
          }
          // If tie, winningTeamId remains null (no winner)
        }

        // Get all signups to know which players participated
        const signupsSnapshot = await db
            .collection('games')
            .doc(gameId)
            .collection('signups')
            .where('status', '==', 'confirmed')
            .get();

        if (signupsSnapshot.empty) {
          info(`No confirmed signups found for game ${gameId}. Skipping statistics calculation.`);
          return;
        }

        const participantIds = signupsSnapshot.docs.map((doc) => doc.id);

        // Create a map of playerId -> teamId for quick lookup
        const playerToTeamMap = {};
        teams.forEach((team) => {
          if (team.playerIds && Array.isArray(team.playerIds)) {
            team.playerIds.forEach((playerId) => {
              playerToTeamMap[playerId] = team.teamId;
            });
          }
        });

        // Initialize statistics for each participant
        const playerStats = {};
        participantIds.forEach((playerId) => {
          playerStats[playerId] = {
            goals: 0,
            assists: 0,
            saves: 0,
            mvpVotes: 0,
            teamId: playerToTeamMap[playerId] || null,
          };
        });

        // Get all game events for this game (if any)
        // For retroactive games, events may be empty, which is fine
        const eventsSnapshot = await db
            .collection('games')
            .doc(gameId)
            .collection('events')
            .get();

        // Process all events and aggregate statistics (if events exist)
        if (!eventsSnapshot.empty) {
          eventsSnapshot.forEach((eventDoc) => {
            const event = eventDoc.data();
            const playerId = event.playerId;
            const eventType = event.type;

            if (!playerStats[playerId]) {
              // Player not in signups but has events (edge case)
              playerStats[playerId] = {
                goals: 0,
                assists: 0,
                saves: 0,
                mvpVotes: 0,
                teamId: playerToTeamMap[playerId] || null,
              };
            }

            // Count events by type
            switch (eventType) {
              case 'goal':
                playerStats[playerId].goals += 1;
                break;
              case 'assist':
                playerStats[playerId].assists += 1;
                break;
              case 'save':
                playerStats[playerId].saves += 1;
                break;
              case 'mvpVote':
                playerStats[playerId].mvpVotes += 1;
                break;
            }
          });
        } else {
          info(`No events found for game ${gameId}. Using base statistics (goals/assists/saves = 0).`);
        }

        // Update gamification stats for each player using batch writes
        const batch = db.batch();

        for (const [playerId, stats] of Object.entries(playerStats)) {
          const gamificationRef = db
              .collection('users')
              .doc(playerId)
              .collection('gamification')
              .doc('stats');

          // Get current gamification data
          const gamificationDoc = await gamificationRef.get();
          const currentData = gamificationDoc.exists ? gamificationDoc.data() : {
            points: 0,
            level: 1,
            badges: [],
            achievements: {},
            stats: {
              gamesPlayed: 0,
              gamesWon: 0,
              goals: 0,
              assists: 0,
              saves: 0,
            },
          };

          // Determine if player won (check if their team is the winning team)
          const playerWon = winningTeamId !== null && stats.teamId === winningTeamId;

          // Calculate new stats
          const newStats = {
            gamesPlayed: (currentData.stats?.gamesPlayed || 0) + 1,
            gamesWon: (currentData.stats?.gamesWon || 0) + (playerWon ? 1 : 0),
            goals: (currentData.stats?.goals || 0) + stats.goals,
            assists: (currentData.stats?.assists || 0) + stats.assists,
            saves: (currentData.stats?.saves || 0) + stats.saves,
          };

          // Calculate points: 10 base + 5 per goal + 3 per assist + 2 per save + 20 bonus for win
          const basePoints = 10;
          const goalPoints = stats.goals * 5;
          const assistPoints = stats.assists * 3;
          const savePoints = stats.saves * 2;
          const winBonus = playerWon ? 20 : 0;
          const pointsEarned = basePoints + goalPoints + assistPoints + savePoints + winBonus;
          const newPoints = (currentData.points || 0) + pointsEarned;

          // Calculate level (simplified: level = floor(points / 100) + 1)
          const newLevel = Math.floor(newPoints / 100) + 1;

          // Update gamification document
          batch.set(gamificationRef, {
            userId: playerId,
            points: newPoints,
            level: newLevel,
            badges: currentData.badges || [],
            achievements: currentData.achievements || {},
            stats: newStats,
            updatedAt: FieldValue.serverTimestamp(),
          }, {merge: true});

          // Also update user's totalParticipations
          const userRef = db.collection('users').doc(playerId);
          batch.update(userRef, {
            totalParticipations: FieldValue.increment(1),
          });
        }

        // Commit all updates
        await batch.commit();
        info(`Updated statistics for ${Object.keys(playerStats).length} players after game ${gameId} completion.`);

        // Update denormalized data in game document
        try {
          // Get goal scorers
          const goalScorerIds = [];
          const goalScorerNames = [];
          for (const [playerId, stats] of Object.entries(playerStats)) {
            if (stats.goals > 0) {
              goalScorerIds.push(playerId);
              // Get player name
              const userDoc = await db.collection('users').doc(playerId).get();
              if (userDoc.exists) {
                const userData = userDoc.data();
                goalScorerNames.push(userData?.name || playerId);
              }
            }
          }

          // Get MVP (player with most MVP votes)
          let mvpPlayerId = null;
          let mvpPlayerName = null;
          let maxMvpVotes = 0;
          for (const [playerId, stats] of Object.entries(playerStats)) {
            if (stats.mvpVotes > maxMvpVotes) {
              maxMvpVotes = stats.mvpVotes;
              mvpPlayerId = playerId;
            }
          }
          if (mvpPlayerId) {
            const mvpDoc = await db.collection('users').doc(mvpPlayerId).get();
            if (mvpDoc.exists) {
              const mvpData = mvpDoc.data();
              mvpPlayerName = mvpData?.name || mvpPlayerId;
            }
          }

          // Get venue name
          let venueName = null;
          if (gameData.venueId) {
            const venueDoc = await db.collection('venues').doc(gameData.venueId).get();
            if (venueDoc.exists) {
              const venueData = venueDoc.data();
              venueName = venueData?.name || null;
            }
          } else if (gameData.eventId) {
            // Try to get venue from event
            const hubDoc = await db.collection('hubs').doc(gameData.hubId).get();
            if (hubDoc.exists) {
              const eventDoc = await hubDoc.ref.collection('events').doc(gameData.eventId).get();
              if (eventDoc.exists) {
                const eventData = eventDoc.data();
                venueName = eventData?.location || null;
              }
            }
          }

          // Update game with denormalized data
          await db.collection('games').doc(gameId).update({
            goalScorerIds: goalScorerIds,
            goalScorerNames: goalScorerNames,
            mvpPlayerId: mvpPlayerId,
            mvpPlayerName: mvpPlayerName,
            venueName: venueName,
          });
          info(`Updated denormalized data for game ${gameId}.`);
        } catch (denormError) {
          info(`Failed to update denormalized data for game ${gameId}:`, denormError);
        }

        // Create regional feed post in feedPosts collection (root level)
        const gameRegion = gameData.region;
        if (gameRegion) {
          try {
            const hubDoc = await db.collection('hubs').doc(gameData.hubId).get();
            const hubData = hubDoc.exists ? hubDoc.data() : null;
            
            const feedPostRef = db.collection('feedPosts').doc();
            await feedPostRef.set({
              postId: feedPostRef.id,
              hubId: gameData.hubId,
              hubName: hubData?.name || 'האב',
              hubLogoUrl: hubData?.logoUrl || null,
              type: 'game_completed',
              text: `משחק הושלם ב-${hubData?.name || 'האב'}! תוצאה: ${teamAScore}-${teamBScore}`,
              createdAt: FieldValue.serverTimestamp(),
              authorId: gameData.createdBy,
              authorName: null, // Can be denormalized if needed
              authorPhotoUrl: null,
              entityId: gameId,
              gameId: gameId,
              region: gameRegion, // Copy region from game
              likeCount: 0,
              commentCount: 0,
              likes: [],
              comments: [],
            });
            info(`Created regional feed post for game ${gameId} in region ${gameRegion}.`);
          } catch (feedError) {
            info(`Failed to create regional feed post for game ${gameId}:`, feedError);
          }
        }
      } catch (error) {
        info(`Error in onGameCompleted for game ${gameId}:`, error);
      }
    },
);

// --- Game Events Denormalization Handler ---
// When a game event is created/updated/deleted, update denormalized data in game document
exports.onGameEventChanged = onDocumentWritten(
    'games/{gameId}/events/{eventId}',
    async (event) => {
      const gameId = event.params.gameId;
      const eventId = event.params.eventId;
      const eventData = event.data?.after?.data();
      const beforeData = event.data?.before?.data();

      // Only process if event was created or deleted (not just updated)
      const isCreated = !beforeData && eventData;
      const isDeleted = beforeData && !eventData;
      
      if (!isCreated && !isDeleted) {
        // Event was just updated, skip
        return;
      }

      info(`Game event ${eventId} ${isCreated ? 'created' : 'deleted'} for game ${gameId}. Updating denormalized data.`);

      try {
        // Get all events for this game
        const eventsSnapshot = await db
            .collection('games')
            .doc(gameId)
            .collection('events')
            .get();

        if (eventsSnapshot.empty) {
          // No events, clear denormalized data
          await db.collection('games').doc(gameId).update({
            goalScorerIds: [],
            goalScorerNames: [],
            mvpPlayerId: null,
            mvpPlayerName: null,
          });
          return;
        }

        // Process events
        const goalScorerIds = [];
        const goalScorerIdsSet = new Set();
        let mvpPlayerId = null;

        eventsSnapshot.forEach((eventDoc) => {
          const event = eventDoc.data();
          const eventType = event.type;
          const playerId = event.playerId;

          if (eventType === 'goal' && !goalScorerIdsSet.has(playerId)) {
            goalScorerIds.push(playerId);
            goalScorerIdsSet.add(playerId);
          } else if (eventType === 'mvpVote') {
            mvpPlayerId = playerId;
          }
        });

        // Get player names for goal scorers
        const goalScorerNames = [];
        for (const playerId of goalScorerIds) {
          try {
            const userDoc = await db.collection('users').doc(playerId).get();
            if (userDoc.exists) {
              const userData = userDoc.data();
              goalScorerNames.push(userData?.name || playerId);
            }
          } catch (e) {
            info(`Failed to get name for player ${playerId}:`, e);
          }
        }

        // Get MVP name
        let mvpPlayerName = null;
        if (mvpPlayerId) {
          try {
            const mvpDoc = await db.collection('users').doc(mvpPlayerId).get();
            if (mvpDoc.exists) {
              const mvpData = mvpDoc.data();
              mvpPlayerName = mvpData?.name || mvpPlayerId;
            }
          } catch (e) {
            info(`Failed to get MVP name for player ${mvpPlayerId}:`, e);
          }
        }

        // Update game with denormalized data
        await db.collection('games').doc(gameId).update({
          goalScorerIds: goalScorerIds,
          goalScorerNames: goalScorerNames,
          mvpPlayerId: mvpPlayerId,
          mvpPlayerName: mvpPlayerName,
        });

        info(`Updated denormalized data for game ${gameId} after event change.`);
      } catch (error) {
        info(`Error in onGameEventChanged for game ${gameId}, event ${eventId}:`, error);
      }
    },
);

// --- Notify Hub on New Game ---
/**
 * Notify all hub members when a new game is created
 * @param {string} hubId - Hub ID
 * @param {string} gameId - Game ID
 * @param {string} gameTitle - Optional game title
 * @param {string} gameTime - Optional game time
 * @return {Object} Result with success status and notification count
 */
exports.notifyHubOnNewGame = onCall(
    {
      // Allow unauthenticated calls (can be restricted later if needed)
      invoker: 'public',
    },
    async (request) => {
      const {hubId, gameId, gameTitle, gameTime} = request.data;

      if (!hubId || !gameId) {
        throw new HttpsError(
            'invalid-argument',
            'Missing \'hubId\' or \'gameId\' parameter.',
        );
      }

      info(`Notifying hub ${hubId} about new game ${gameId}`);

      try {
        // 1. Get hub to get name and memberIds
        const hubDoc = await db.collection('hubs').doc(hubId).get();
        if (!hubDoc.exists) {
          throw new HttpsError('not-found', 'Hub not found');
        }

        const hubData = hubDoc.data();
        const hubName = hubData.name || 'האב';
        const memberIds = hubData.memberIds || [];

        if (memberIds.length === 0) {
          info(`Hub ${hubId} has no members to notify`);
          return {success: true, notifiedCount: 0};
        }

        // 2. Get game details if not provided
        let title = gameTitle;
        let time = gameTime;

        if (!title || !time) {
          const gameDoc = await db.collection('games').doc(gameId).get();
          if (gameDoc.exists) {
            const gameData = gameDoc.data();
            if (!title) {
              title = `משחק חדש ב-${hubName}`;
            }
            if (!time && gameData.gameDate) {
              const gameDate = gameData.gameDate.toDate();
              time = gameDate.toLocaleString('he-IL', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
              });
            }
          }
        }

        // 3. Get FCM tokens for all hub members
        const tokens = [];
        const userDocs = await Promise.all(
            memberIds.map((userId) => db.collection('users').doc(userId).get()),
        );

        for (const userDoc of userDocs) {
          if (userDoc.exists) {
            const userData = userDoc.data();
            // Get FCM token from user document or from a tokens subcollection
            // Note: In a real implementation, you might store tokens in a subcollection
            if (userData.fcmToken) {
              tokens.push(userData.fcmToken);
            }
          }
        }

        if (tokens.length === 0) {
          info(`No FCM tokens found for hub ${hubId} members`);
          return {success: true, notifiedCount: 0};
        }

        // 4. Send push notifications
        const message = {
          notification: {
            title: 'הרשמה למשחק חדש נפתחה!',
            body: `${title}${time ? ` - ${time}` : ''}`,
          },
          data: {
            type: 'new_game',
            hubId: hubId,
            gameId: gameId,
          },
          tokens: tokens,
        };

        const response = await messaging.sendEachForMulticast(message);
        info(`Sent ${response.successCount} notifications to hub ${hubId} members`);

        return {
          success: true,
          notifiedCount: response.successCount,
          failedCount: response.failureCount,
        };
      } catch (error) {
        info(`Error in notifyHubOnNewGame for hub ${hubId}:`, error);
        throw new HttpsError('internal', 'Failed to notify hub members.', error);
      }
    },
);

// --- v2 Callable Functions (already v2, no change needed) ---

/**
 * Helper function to determine venue type based on name, types, and address
 * @param {Object} place - Google Places API place object
 * @return {string} 'public', 'rental', 'school', or 'unknown'
 */
function determineVenueType(place) {
  const name = (place.name || '').toLowerCase();
  const address = (place.formatted_address || '').toLowerCase();
  const types = (place.types || []).map((t) => t.toLowerCase());
  const vicinity = (place.vicinity || '').toLowerCase();
  
  const allText = `${name} ${address} ${vicinity}`.toLowerCase();
  
  // Keywords for public venues
  const publicKeywords = [
    'ציבורי', 'public', 'פארק', 'park', 'גן', 'גן ציבורי',
    'municipal', 'עירוני', 'רשות', 'municipality',
  ];
  
  // Keywords for rental venues
  const rentalKeywords = [
    'השכרה', 'rental', 'rent', 'שכירות', 'להשכרה',
    'rentals', 'renting', 'lease', 'leasing',
  ];
  
  // Keywords for school venues
  const schoolKeywords = [
    'בית ספר', 'school', 'תיכון', 'יסודי', 'גן ילדים',
    'high school', 'elementary', 'kindergarten', 'בית ספר יסודי',
    'בית ספר תיכון', 'מגרש בית ספר',
  ];
  
  // Check for school first (most specific)
  if (schoolKeywords.some((keyword) => allText.includes(keyword)) ||
      types.includes('school') || types.includes('primary_school')) {
    return 'school';
  }
  
  // Check for rental
  if (rentalKeywords.some((keyword) => allText.includes(keyword))) {
    return 'rental';
  }
  
  // Check for public (default for parks, municipal facilities)
  if (publicKeywords.some((keyword) => allText.includes(keyword)) ||
      types.includes('park') || types.includes('stadium') ||
      types.includes('sports_complex')) {
    return 'public';
  }
  
  // Default: if it's a stadium or sports complex, assume public
  if (types.includes('stadium') || types.includes('sports_complex') ||
      types.includes('gym') || types.includes('establishment')) {
    return 'public';
  }
  
  return 'unknown';
}

exports.searchVenues = onCall(
    {
      secrets: [googleApisKey],
      invoker: 'public', // Allow unauthenticated calls
    },
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
        const data = response.data;
        
        // Add venueType to each result
        if (data.results && Array.isArray(data.results)) {
          data.results = data.results.map((place) => {
            const venueType = determineVenueType(place);
            return {
              ...place,
              venueType: venueType,
            };
          });
        }

        return data;
      } catch (error) {
        throw new HttpsError('internal', 'Failed to call Google Places API.', error);
      }
    },
);

exports.getPlaceDetails = onCall(
    {
      secrets: [googleApisKey],
      invoker: 'public', // Allow unauthenticated calls
    },
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

      const url = `${PLACES_API_URL}/details/json?place_id=${placeId}&key=${apiKey}&language=iw&fields=place_id,name,formatted_address,geometry,photos,formatted_phone_number`;

      try {
        const response = await axios.get(url);
        return response.data;
      } catch (error) {
        throw new HttpsError('internal', 'Failed to call Google Places API.', error);
      }
    },
);

// --- Get Hubs for Place Function ---
/**
 * Find all hubs that use a specific venue (identified by Google placeId)
 * @param {string} placeId - Google Places API place_id
 * @return {Array} Array of hub objects with hubId, name, and logoUrl
 */
exports.getHubsForPlace = onCall(
    {
      secrets: [googleApisKey],
      invoker: 'public', // Allow unauthenticated calls
    },
    async (request) => {
      const {placeId} = request.data;
      if (!placeId) {
        throw new HttpsError('invalid-argument', 'Missing \'placeId\' parameter.');
      }

      try {
        // 1. Find our internal venue doc using the Google placeId
        const venuesSnapshot = await db.collection('venues')
            .where('googlePlaceId', '==', placeId) // Venue model uses googlePlaceId, not placeId
            .limit(1)
            .get();

        if (venuesSnapshot.empty) {
          // No hubs are using this venue (because we don't even have it saved)
          return [];
        }

        const venueDoc = venuesSnapshot.docs[0];
        const ourVenueId = venueDoc.id;

        // 2. Find all hubs that use this internal venueId
        const hubsSnapshot = await db.collection('hubs')
            .where('venueIds', 'array-contains', ourVenueId)
            .get();

        if (hubsSnapshot.empty) {
          return [];
        }

        // 3. Return a light version of the hubs
        const hubs = hubsSnapshot.docs.map((doc) => ({
          hubId: doc.id,
          name: doc.data().name,
          logoUrl: doc.data().logoUrl || null,
        }));

        return hubs;
      } catch (error) {
        info(`Error finding hubs for placeId ${placeId}:`, error);
        throw new HttpsError('internal', 'Failed to find hubs for this venue.');
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
    {
      secrets: [googleApisKey],
      invoker: 'public', // Allow unauthenticated calls
    },
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
