/* eslint-disable max-len */
const { onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { info } = require('firebase-functions/logger');
const { db, messaging, FieldValue, getUserFCMTokens } = require('../utils');

// --- Game Completion Trigger ---
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

        // If coming from the new finalization flow, skip this function
        // as processGameCompletion handles it.
        if (beforeStatus === 'processing_completion') {
            info(`Game ${gameId} was processed by new flow. Skipping onGameCompleted.`);
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
                info(`No events found for game ${gameId}. Checking for simple mode stats on game document.`);
                // Fallback for games logged without events (e.g., from finalizeGame)
                const goalScorers = gameData.goalScorerIds || [];
                goalScorers.forEach((playerId) => {
                    if (playerStats[playerId]) {
                        playerStats[playerId].goals += 1;
                    }
                });

                const assistProviders = gameData.assistPlayerIds || [];
                assistProviders.forEach((playerId) => {
                    if (playerStats[playerId]) {
                        playerStats[playerId].assists += 1;
                    }
                });

                if (gameData.mvpPlayerId) {
                    const mvpPlayerId = gameData.mvpPlayerId;
                    if (playerStats[mvpPlayerId]) {
                        playerStats[mvpPlayerId].mvpVotes += 1;
                    }
                }
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

                // Get current gamification data from map (for badge checks only)
                const currentData = gamificationMap.get(playerId);

                // Determine if player won (check if their team is the winning team)
                const playerWon = winningTeamId !== null && stats.teamId === winningTeamId;

                // 🔒 ATOMIC INCREMENTS - No more race conditions!
                // Use FieldValue.increment for all stats to prevent concurrent write issues
                const statsUpdate = {
                    'stats.gamesPlayed': FieldValue.increment(1),
                    'stats.goals': FieldValue.increment(stats.goals),
                    'stats.assists': FieldValue.increment(stats.assists),
                    'stats.saves': FieldValue.increment(stats.saves),
                };

                if (playerWon) {
                    statsUpdate['stats.gamesWon'] = FieldValue.increment(1);
                }

                // Check for milestone badges (based on current data - best effort)
                // Note: Exact milestone detection requires reading fresh data, but for UX
                // it's acceptable to award badges based on pre-read data
                const badgesToAward = [];
                const currentGamesPlayed = currentData.stats?.gamesPlayed || 0;
                const currentGoals = currentData.stats?.goals || 0;
                const currentBadges = currentData.badges || [];

                // Award badges at milestones (approximate - may be +/- 1 game due to concurrency)
                if (currentGamesPlayed + 1 === 1 && !currentBadges.includes('firstGame')) {
                    badgesToAward.push('firstGame');
                }
                if (currentGamesPlayed + 1 === 10 && !currentBadges.includes('tenGames')) {
                    badgesToAward.push('tenGames');
                }
                if (currentGamesPlayed + 1 === 50 && !currentBadges.includes('fiftyGames')) {
                    badgesToAward.push('fiftyGames');
                }
                if (currentGamesPlayed + 1 === 100 && !currentBadges.includes('hundredGames')) {
                    badgesToAward.push('hundredGames');
                }

                // Goal badges
                if (currentGoals + stats.goals >= 1 && !currentBadges.includes('firstGoal')) {
                    badgesToAward.push('firstGoal');
                }
                if (currentGoals + stats.goals >= 3 && !currentBadges.includes('hatTrick')) {
                    badgesToAward.push('hatTrick');
                }

                // Build update object
                const updateData = {
                    ...statsUpdate,
                    userId: playerId,
                    updatedAt: FieldValue.serverTimestamp(),
                };

                // Add badges if any were earned
                if (badgesToAward.length > 0) {
                    updateData.badges = FieldValue.arrayUnion(...badgesToAward);
                }

                // Use set() with merge to handle both existing and new documents
                // This allows atomic increments to work even if document doesn't exist yet
                batch.set(gamificationRef, updateData, { merge: true });

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

                // 🔒 ATOMIC INCREMENT for hub stats - no more expensive recounts!
                // Calculate total goals for this game
                const totalGoalsThisGame = (gameData.teamAScore || 0) + (gameData.teamBScore || 0);

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

                // Update hub with atomic increments
                denormBatch.update(hubRef, {
                    totalGames: FieldValue.increment(1),
                    totalGoals: FieldValue.increment(totalGoalsThisGame),
                    lastGameCompleted: FieldValue.serverTimestamp(),
                });

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

            // ✅ SOCIAL LOOP FIX: Create feed posts in BOTH hub feed AND regional feed
            const gameRegion = gameData.region;
            try {
                const hubDoc = await db.collection('hubs').doc(gameData.hubId).get();
                const hubData = hubDoc.exists ? hubDoc.data() : null;

                // Prepare feed post data (shared between hub and regional feed)
                const feedPostData = {
                    hubId: gameData.hubId,
                    hubName: hubData?.name || 'האב',
                    hubLogoUrl: hubData?.logoUrl || null,
                    type: 'game_completed',
                    text: `משחק הושלם ב-${hubData?.name || 'האב'}! תוצאה: ${teamAScore}-${teamBScore}`,
                    createdAt: FieldValue.serverTimestamp(),
                    authorId: gameData.createdBy,
                    authorName: null,
                    authorPhotoUrl: null,
                    entityId: gameId,
                    gameId: gameId,
                    region: gameRegion,
                    likeCount: 0,
                    commentCount: 0,
                    likes: [],
                    comments: [],
                };

                const feedBatch = db.batch();

                // 1️⃣ Create post in HUB feed (for hub members) - THIS WAS MISSING!
                const hubFeedPostRef = db
                    .collection('hubs')
                    .doc(gameData.hubId)
                    .collection('feed')
                    .doc('posts')
                    .collection('items')
                    .doc();
                feedBatch.set(hubFeedPostRef, {
                    ...feedPostData,
                    postId: hubFeedPostRef.id,
                });

                // 2️⃣ Create post in REGIONAL feed (for discovery)
                if (gameRegion) {
                    const regionalFeedPostRef = db.collection('feedPosts').doc();
                    feedBatch.set(regionalFeedPostRef, {
                        ...feedPostData,
                        postId: regionalFeedPostRef.id,
                    });
                }

                await feedBatch.commit();
                info(`✅ Created feed posts for game ${gameId} in hub feed and regional feed (${gameRegion || 'no region'}).`);
            } catch (feedError) {
                info(`⚠️ Failed to create feed posts for game ${gameId}:`, feedError);
            }
        } catch (error) {
            info(`Error in onGameCompleted for game ${gameId}:`, error);
        }
    },
);

// --- Game Events Denormalization Handler ---
exports.onGameEventChanged = onDocumentWritten(
    'games/{gameId}/events/{eventId}',
    async (event) => {
        const gameId = event.params.gameId;
        const eventId = event.params.eventId;
        const eventData = event.data?.after?.data();
        const beforeData = event.data?.before?.data();

        const isCreated = !beforeData && eventData;
        const isDeleted = beforeData && !eventData;

        if (!isCreated && !isDeleted) {
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
                await db.collection('games').doc(gameId).update({
                    goalScorerIds: [],
                    goalScorerNames: [],
                    mvpPlayerId: null,
                    mvpPlayerName: null,
                });
                return;
            }

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

            const allUserIds = new Set(goalScorerIds);
            if (mvpPlayerId) {
                allUserIds.add(mvpPlayerId);
            }

            const userDocs = await Promise.all(
                Array.from(allUserIds).map((userId) =>
                    db.collection('users').doc(userId).get()
                )
            );

            const userMap = new Map();
            userDocs.forEach((doc) => {
                if (doc.exists) {
                    userMap.set(doc.id, doc.data());
                }
            });

            const goalScorerNames = goalScorerIds.map((playerId) => {
                const userData = userMap.get(playerId);
                return userData?.name || playerId;
            });

            let mvpPlayerName = null;
            if (mvpPlayerId) {
                const mvpData = userMap.get(mvpPlayerId);
                mvpPlayerName = mvpData?.name || mvpPlayerId;
            }

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
