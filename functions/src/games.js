/* eslint-disable max-len */
const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { info } = require('firebase-functions/logger');
const { db, messaging, FieldValue, getHubMemberIds, getUserFCMTokens } = require('./utils');
const { checkRateLimit } = require('../rateLimit');

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
        .where('status', 'in', ['scheduled', 'recruiting', 'fullyBooked', 'teamSelection', 'teamsFormed']) // Include new statuses
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

          // Null-safe: Skip hub fetch for public games
          if (!game.hubId) {
            info(`Skipping reminder for public game ${gameId} (no hub)`);
            return;
          }

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
          const userIds = signupsSnapshot.docs.map(doc => doc.id);

          // ✅ PERFORMANCE FIX: Fetch FCM tokens in PARALLEL using helper
          const tokenArrays = await Promise.all(
            userIds.map((userId) => getUserFCMTokens(userId))
          );
          tokens.push(...tokenArrays.flat());

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
      info(`✅ Completed sendGameReminder cron job - processed ${gamesSnapshot.size} games`);
      return null;
    } catch (error) {
      info(`⚠️ Error running sendGameReminder:`, error.message || error);
      info(`Stack trace:`, error.stack);
      // Don't throw - this is a scheduled function, we don't want it to fail silently
      // but we also don't want it to crash the entire function
      return null;
    }
  },
);

exports.onGameCreated = onDocumentCreated('games/{gameId}', async (event) => {
  const game = event.data.data();
  const gameId = event.params.gameId;

  info(`New game created: ${gameId}${game.hubId ? ` in hub: ${game.hubId}` : ' (public game)'}`);

  try {
    // Null-safe: Only process hub-specific logic if hubId exists
    if (!game.hubId) {
      info(`Public game ${gameId} created. Skipping hub-specific operations.`);
      // TODO: Add public game feed post logic here if needed
      return;
    }

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

      // ✅ PERFORMANCE FIX: Fetch all gamification docs in PARALLEL
      const gamificationRefs = Object.keys(playerStats).map((playerId) =>
        db
          .collection('users')
          .doc(playerId)
          .collection('gamification')
          .doc('stats')
      );

      const gamificationDocs = await Promise.all(
        gamificationRefs.map((ref) => ref.get())
      );

      // Create map for quick lookup
      const gamificationMap = new Map();
      gamificationDocs.forEach((doc, index) => {
        const playerId = Object.keys(playerStats)[index];
        gamificationMap.set(
          playerId,
          doc.exists
            ? doc.data()
            : {
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
            }
        );
      });

      // Update gamification stats for each player using batch writes
      const batch = db.batch();

      for (const [playerId, stats] of Object.entries(playerStats)) {
        const gamificationRef = db
          .collection('users')
          .doc(playerId)
          .collection('gamification')
          .doc('stats');

        // Get current gamification data from map
        const currentData = gamificationMap.get(playerId);

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

        // SIMPLIFIED: No points, no levels - just participation tracking
        // Only increment stats and check for milestone badges

        // Check for milestone badges (based on gamesPlayed count only)
        const badgesToAward = [];
        if (newStats.gamesPlayed === 1 && !(currentData.badges || []).includes('firstGame')) {
          badgesToAward.push('firstGame');
        }
        if (newStats.gamesPlayed === 10 && !(currentData.badges || []).includes('tenGames')) {
          badgesToAward.push('tenGames');
        }
        if (newStats.gamesPlayed === 50 && !(currentData.badges || []).includes('fiftyGames')) {
          badgesToAward.push('fiftyGames');
        }
        if (newStats.gamesPlayed === 100 && !(currentData.badges || []).includes('hundredGames')) {
          badgesToAward.push('hundredGames');
        }

        // Goal badges (optional - for display only, no points)
        if (newStats.goals >= 1 && !(currentData.badges || []).includes('firstGoal')) {
          badgesToAward.push('firstGoal');
        }
        if (newStats.goals >= 3 && !(currentData.badges || []).includes('hatTrick')) {
          badgesToAward.push('hatTrick');
        }

        // Update gamification document (keep points/level for backward compatibility, but don't update them)
        const updatedBadges = [...(currentData.badges || []), ...badgesToAward];
        batch.set(gamificationRef, {
          userId: playerId,
          // Keep existing points/level (for backward compatibility with old data)
          points: currentData.points || 0,
          level: currentData.level || 1,
          badges: updatedBadges,
          achievements: currentData.achievements || {},
          stats: newStats,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });

        // Log badge awards
        if (badgesToAward.length > 0) {
          info(`Player ${playerId} earned badges: ${badgesToAward.join(', ')}`);
        }

        // Also update user's totalParticipations
        const userRef = db.collection('users').doc(playerId);
        batch.update(userRef, {
          totalParticipations: FieldValue.increment(1),
        });
      }

      // Commit all updates
      await batch.commit();
      info(`Updated statistics for ${Object.keys(playerStats).length} players after game ${gameId} completion.`);

      // ✅ PERFORMANCE FIX: Update denormalized data with PARALLEL reads and BATCH writes
      try {
        // Collect all user IDs we need
        const goalScorerIds = [];
        const allUserIds = new Set();

        for (const [playerId, stats] of Object.entries(playerStats)) {
          if (stats.goals > 0) {
            goalScorerIds.push(playerId);
            allUserIds.add(playerId);
          }
          if (stats.mvpVotes > 0) {
            allUserIds.add(playerId);
          }
        }

        // ✅ Fetch all users in PARALLEL
        const userDocs = await Promise.all(
          Array.from(allUserIds).map((userId) =>
            db.collection('users').doc(userId).get()
          )
        );

        // Create a map for quick lookup
        const userMap = new Map();
        userDocs.forEach((doc) => {
          if (doc.exists) {
            userMap.set(doc.id, doc.data());
          }
        });

        // Build goal scorer names from map
        const goalScorerNames = goalScorerIds.map((playerId) => {
          const userData = userMap.get(playerId);
          return userData?.name || playerId;
        });

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
          const mvpData = userMap.get(mvpPlayerId);
          mvpPlayerName = mvpData?.name || mvpPlayerId;
        }

        // ✅ Fetch venue/hub/event in PARALLEL
        const fetchPromises = [];
        if (gameData.venueId) {
          fetchPromises.push(
            db
              .collection('venues')
              .doc(gameData.venueId)
              .get()
              .then((doc) => ({ type: 'venue', doc: doc }))
          );
        }
        if (gameData.eventId) {
          fetchPromises.push(
            db
              .collection('hubs')
              .doc(gameData.hubId)
              .get()
              .then((hubDoc) => ({
                type: 'hub',
                doc: hubDoc,
                eventId: gameData.eventId,
              }))
          );
        }

        const results = await Promise.all(fetchPromises);
        let venueName = null;

        for (const result of results) {
          if (result.type === 'venue' && result.doc.exists) {
            const venueData = result.doc.data();
            venueName = venueData?.name || null;
          } else if (result.type === 'hub' && result.doc.exists) {
            const eventDoc = await result.doc.ref
              .collection('events')
              .doc(result.eventId)
              .get();
            if (eventDoc.exists) {
              const eventData = eventDoc.data();
              venueName = eventData?.location || null;
            }
          }
        }

        // ✅ BATCH: Update game and hub together
        const hubRef = db.collection('hubs').doc(gameData.hubId);
        const hubDoc = await hubRef.get();

        // Calculate hub-level aggregations
        let totalHubGames = 0;
        let totalHubGoals = 0;
        if (hubDoc.exists) {
          const hubGamesSnapshot = await db
            .collection('games')
            .where('hubId', '==', gameData.hubId)
            .where('status', '==', 'completed')
            .get();

          totalHubGames = hubGamesSnapshot.size;
          totalHubGoals = hubGamesSnapshot.docs.reduce((sum, doc) => {
            const g = doc.data();
            return sum + (g.teamAScore || 0) + (g.teamBScore || 0);
          }, 0);
        }

        // ✅ Use batch for all denormalization updates
        const denormBatch = db.batch();

        // Update game
        denormBatch.update(db.collection('games').doc(gameId), {
          goalScorerIds: goalScorerIds,
          goalScorerNames: goalScorerNames,
          mvpPlayerId: mvpPlayerId,
          mvpPlayerName: mvpPlayerName,
          venueName: venueName,
        });

        // Update hub
        if (hubDoc.exists) {
          denormBatch.update(hubRef, {
            totalGames: totalHubGames,
            totalGoals: totalHubGoals,
            lastGameCompleted: FieldValue.serverTimestamp(),
          });
        }

        // Commit all denormalization updates at once
        await denormBatch.commit();
        info(
          `Updated denormalized data for game ${gameId} and hub ${gameData.hubId}.`
        );
      } catch (denormError) {
        info(`Failed to update denormalized data for game ${gameId}:`, denormError);
      }

      // ✅ PERFORMANCE FIX: Send "Game Summary" notification with PARALLEL token fetch + BATCH send
      try {
        // Fetch hub and all tokens in PARALLEL
        const [hubDoc, ...tokenArrays] = await Promise.all([
          db.collection('hubs').doc(gameData.hubId).get(),
          ...participantIds.map((playerId) => getUserFCMTokens(playerId)),
        ]);

        const hubName = hubDoc.exists
          ? hubDoc.data()?.name || 'האב'
          : 'האב';

        // Collect all tokens
        const tokens = tokenArrays.flat();
        const uniqueTokens = [...new Set(tokens)];

        // ✅ Send all notifications in ONE batch
        if (uniqueTokens.length > 0) {
          const message = {
            notification: {
              title: 'סיכום משחק',
              body: `משחק הושלם ב-${hubName}! תוצאה: ${teamAScore}-${teamBScore}`,
            },
            data: {
              type: 'game_summary',
              gameId: gameId,
              hubId: gameData.hubId,
            },
            tokens: uniqueTokens,
          };

          const response = await messaging.sendEachForMulticast(message);
          info(
            `Sent game summary notifications to ${response.successCount}/${uniqueTokens.length} devices.`
          );
        } else {
          info('No FCM tokens found for game summary notifications.');
        }
      } catch (notificationError) {
        info(`Failed to send game summary notifications:`, notificationError);
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

// --- Game Signup Denormalization Handler ---
// When a signup is created/updated/deleted, update denormalized data in game document
// This avoids N+1 queries when checking game capacity or player lists
exports.onGameSignupChanged = onDocumentWritten(
  'games/{gameId}/signups/{userId}',
  async (event) => {
    const gameId = event.params.gameId;
    const userId = event.params.userId;
    const signupData = event.data?.after?.data();
    const beforeData = event.data?.before?.data();

    // Only process if signup was created or deleted (not just updated)
    const isCreated = !beforeData && signupData;
    const isDeleted = beforeData && !signupData;
    const statusChanged = beforeData?.status !== signupData?.status;

    if (!isCreated && !isDeleted && !statusChanged) {
      // Signup was just updated without status change, skip
      return;
    }

    info(`Game signup ${userId} ${isCreated ? 'created' : isDeleted ? 'deleted' : 'updated'} for game ${gameId}. Updating denormalized data.`);

    try {
      // Get all confirmed signups for this game
      const signupsSnapshot = await db
        .collection('games')
        .doc(gameId)
        .collection('signups')
        .where('status', '==', 'confirmed')
        .get();

      const confirmedPlayerIds = signupsSnapshot.docs.map((doc) => doc.id);
      const confirmedPlayerCount = confirmedPlayerIds.length;

      // Get game document to check maxPlayers
      const gameDoc = await db.collection('games').doc(gameId).get();
      if (!gameDoc.exists) {
        info(`Game ${gameId} not found. Skipping denormalization.`);
        return;
      }

      const gameData = gameDoc.data();
      const teamCount = gameData?.teamCount ?? 2;
      const maxPlayers = gameData?.maxParticipants ?? (teamCount * 3); // Default: 3 per team

      // Update game with denormalized data
      await db.collection('games').doc(gameId).update({
        confirmedPlayerIds: confirmedPlayerIds,
        confirmedPlayerCount: confirmedPlayerCount,
        isFull: confirmedPlayerCount >= maxPlayers,
        updatedAt: FieldValue.serverTimestamp(),
      });

      info(`Updated denormalized data for game ${gameId}: ${confirmedPlayerCount}/${maxPlayers} players confirmed.`);
    } catch (error) {
      info(`Error in onGameSignupChanged for game ${gameId}, user ${userId}:`, error);
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

      // ✅ PERFORMANCE FIX: Fetch all user names in PARALLEL
      const allUserIds = new Set(goalScorerIds);
      if (mvpPlayerId) {
        allUserIds.add(mvpPlayerId);
      }

      const userDocs = await Promise.all(
        Array.from(allUserIds).map((userId) =>
          db.collection('users').doc(userId).get()
        )
      );

      // Create a map for quick lookup
      const userMap = new Map();
      userDocs.forEach((doc) => {
        if (doc.exists) {
          userMap.set(doc.id, doc.data());
        }
      });

      // Build goal scorer names from map
      const goalScorerNames = goalScorerIds.map((playerId) => {
        const userData = userMap.get(playerId);
        return userData?.name || playerId;
      });

      // Get MVP name from map
      let mvpPlayerName = null;
      if (mvpPlayerId) {
        const mvpData = userMap.get(mvpPlayerId);
        mvpPlayerName = mvpData?.name || mvpPlayerId;
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
    invoker: 'authenticated', // ✅ Requires authentication
    memory: '256MiB', // ✅ Reduced from default (512MB not needed)
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }
    const { hubId, gameId, gameTitle, gameTime } = request.data;

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
      let memberIds = hubData.memberIds || [];
      if (!memberIds.length) {
        memberIds = await getHubMemberIds(hubId);
      }

      if (memberIds.length === 0) {
        info(`Hub ${hubId} has no members to notify`);
        return { success: true, notifiedCount: 0 };
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

      // 3. ✅ PERFORMANCE FIX: Get FCM tokens in PARALLEL using helper
      const tokenArrays = await Promise.all(
        memberIds.map((userId) => getUserFCMTokens(userId))
      );
      const tokens = tokenArrays.flat();

      if (tokens.length === 0) {
        info(`No FCM tokens found for hub ${hubId} members`);
        return { success: true, notifiedCount: 0 };
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

// Automated Waitlist Management
// Trigger: When a signup status changes from 'confirmed' to 'cancelled'
// Action: Automatically promote the first waitlist user to 'confirmed'
exports.onSignupStatusChanged = onDocumentUpdated(
  'games/{gameId}/signups/{userId}',
  async (event) => {
    const gameId = event.params.gameId;
    const userId = event.params.userId;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!beforeData || !afterData) {
      // Signup was created or deleted, skip
      return;
    }

    const beforeStatus = beforeData.status;
    const afterStatus = afterData.status;

    // Only process if status changed from 'confirmed' to 'cancelled'
    if (beforeStatus !== 'confirmed' || afterStatus !== 'cancelled') {
      return;
    }

    info(`Signup ${userId} cancelled for game ${gameId}. Checking waitlist...`);

    try {
      // Get all waitlist signups for this game, sorted by signedUpAt (FIFO)
      const waitlistSnapshot = await db
        .collection('games')
        .doc(gameId)
        .collection('signups')
        .where('status', '==', 'waitlist')
        .orderBy('signedUpAt', 'asc')
        .limit(1)
        .get();

      if (waitlistSnapshot.empty) {
        info(`No waitlist users found for game ${gameId}.`);
        return;
      }

      // Get the first waitlist user (FIFO)
      const firstWaitlistDoc = waitlistSnapshot.docs[0];
      const waitlistUserId = firstWaitlistDoc.id;

      // Update waitlist user to confirmed
      await firstWaitlistDoc.ref.update({
        status: 'confirmed',
        updatedAt: FieldValue.serverTimestamp(),
      });

      info(`Promoted waitlist user ${waitlistUserId} to confirmed for game ${gameId}.`);

      // Update game playerCount
      const gameRef = db.collection('games').doc(gameId);
      await gameRef.update({
        confirmedPlayerCount: FieldValue.increment(1),
      });

      // ✅ Send FCM push notification to the promoted user using helper
      try {
        const tokens = await getUserFCMTokens(waitlistUserId);

        if (tokens.length > 0) {
          const gameDoc = await gameRef.get();
          const gameData = gameDoc.data();
          const gameDate = gameData?.gameDate?.toDate();

          const message = {
            notification: {
              title: 'מקום נפתח!',
              body: `אתה עכשיו ברשימת המשתתפים למשחק ב-${gameDate ? gameDate.toLocaleDateString('he-IL') : 'תאריך לא ידוע'}`,
            },
            data: {
              type: 'game_signup_promoted',
              gameId: gameId,
            },
            tokens: tokens,
            android: {
              priority: 'high',
            },
            apns: {
              headers: {
                'apns-priority': '10',
              },
            },
          };

          await messaging.sendEachForMulticast(message);
          info(`Sent push notification to user ${waitlistUserId} about game ${gameId}.`);
        }
      } catch (notificationError) {
        info(`Error sending notification to user ${waitlistUserId}:`, notificationError);
        // Don't fail the whole function if notification fails
      }
    } catch (error) {
      info(`Error in onSignupStatusChanged for game ${gameId}, user ${userId}:`, error);
      // Don't throw - we don't want to retry this function
    }
  },
);

// ========================================
// ✅ NEW: Start Game Early (Gap Analysis #7)
// Callable Function: Start a game up to 30 minutes early
// ========================================
exports.startGameEarly = onCall(
  {
    invoker: 'authenticated',
    memory: '256MiB',
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }

    // ✅ Rate limit: 3 requests per minute (prevent abuse)
    await checkRateLimit(request.auth.uid, 'startGameEarly', 3, 1);

    const { gameId } = request.data;
    const userId = request.auth.uid;

    if (!gameId) {
      throw new HttpsError('invalid-argument', 'Missing gameId');
    }

    try {
      const gameRef = db.collection('games').doc(gameId);
      const gameDoc = await gameRef.get();

      if (!gameDoc.exists) {
        throw new HttpsError('not-found', 'Game not found');
      }

      const game = gameDoc.data();

      // Check if user is organizer
      if (game.organizerId !== userId) {
        throw new HttpsError(
          'permission-denied',
          'Only the organizer can start the game',
        );
      }

      // Check if game is pending
      if (game.status !== 'pending') {
        throw new HttpsError(
          'failed-precondition',
          `Game is already ${game.status}`,
        );
      }

      // ✅ Gap Analysis #7: Can start up to 30 minutes EARLY
      const scheduledAt = game.scheduledAt.toDate();
      const now = new Date();
      const thirtyMinutesEarly = new Date(
        scheduledAt.getTime() - 30 * 60 * 1000,
      );

      if (now < thirtyMinutesEarly) {
        const minutesUntilAllowed = Math.ceil(
          (thirtyMinutesEarly - now) / (60 * 1000),
        );
        throw new HttpsError(
          'failed-precondition',
          `Cannot start game yet. Wait ${minutesUntilAllowed} more minutes (can start 30 min early)`,
        );
      }

      // Start the game: pending → active
      await gameRef.update({
        status: 'active',
        startedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      info(`Game ${gameId} started early by ${userId}`);

      return {
        success: true,
        message: 'Game started successfully',
        gameId: gameId,
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', `Failed to start game: ${error.message}`);
    }
  },
);

