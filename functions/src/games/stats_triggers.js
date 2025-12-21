/* eslint-disable max-len */
const { onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { info } = require('firebase-functions/logger');
const { db, messaging, FieldValue } = require('../utils');

// --- Game Completion Trigger ---
exports.onGameCompleted = onDocumentUpdated(
    'games/{gameId}',
    async (event) => {
        const gameId = event.params.gameId;
        const eventId = event.id; // Unique event ID for idempotency
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

        // ✅ IDEMPOTENCY CHECK: Prevent duplicate execution
        // Firebase Functions can sometimes retry, this prevents double-processing
        const processedRef = db.collection('processed_events').doc(eventId);
        const processedDoc = await processedRef.get();

        if (processedDoc.exists) {
            info(`Event ${eventId} already processed for game ${gameId}. Skipping.`);
            return;
        }

        // Mark event as being processed (with TTL for auto-cleanup after 7 days)
        await processedRef.set({
            eventType: 'game_completed',
            gameId: gameId,
            processedAt: FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        });

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

                // Check if this is a multi-match session (Winner Stays format)
                const session = gameData.session || {};
                const matches = session.matches || [];

                if (matches.length > 0) {
                    info(`Processing session game ${gameId} with ${matches.length} matches`);

                    // Aggregate goals/assists across ALL approved matches
                    matches.forEach((match) => {
                        // Only count approved matches
                        if (match.approvalStatus !== 'approved') {
                            info(`Skipping unapproved match ${match.matchId} (status: ${match.approvalStatus})`);
                            return;
                        }

                        // Aggregate goal scorers
                        const matchGoalScorers = match.scorerIds || [];
                        matchGoalScorers.forEach((playerId) => {
                            if (playerStats[playerId]) {
                                playerStats[playerId].goals += 1;
                            }
                        });

                        // Aggregate assist providers
                        const matchAssistProviders = match.assistIds || [];
                        matchAssistProviders.forEach((playerId) => {
                            if (playerStats[playerId]) {
                                playerStats[playerId].assists += 1;
                            }
                        });
                    });

                    info(`✅ Aggregated stats from ${matches.filter(m => m.approvalStatus === 'approved').length} approved matches`);
                } else {
                    // Fallback for legacy single-match games (e.g., from finalizeGame)
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
            }

            // Update gamification stats for each player using batch writes
            // NOTE: Badge awards are now handled by a separate trigger (onUserStatsUpdated)
            const batch = db.batch();

            for (const [playerId, stats] of Object.entries(playerStats)) {
                const gamificationRef = db
                    .collection('users')
                    .doc(playerId)
                    .collection('gamification')
                    .doc('stats');

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

                // Build update object
                // NOTE: Badge awards are now handled by onUserStatsUpdated trigger
                // which listens to changes in gamification/stats
                const updateData = {
                    ...statsUpdate,
                    userId: playerId,
                    updatedAt: FieldValue.serverTimestamp(),
                };

                // Use set() with merge to handle both existing and new documents
                // This allows atomic increments to work even if document doesn't exist yet
                batch.set(gamificationRef, updateData, { merge: true });

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

            // ✅ OPTIMIZED: Send "Game Summary" notification to hub topic
            try {
                const hubDoc = await db.collection('hubs').doc(gameData.hubId).get();
                const hubName = hubDoc.exists
                    ? hubDoc.data()?.name || 'האב'
                    : 'האב';

                // Send to topic instead of individual tokens (100x faster!)
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
                    topic: `hub_${gameData.hubId}`,
                };

                await messaging.send(message);
                info(`Sent game summary notification to topic hub_${gameData.hubId}`);
            } catch (notificationError) {
                info(`Failed to send game summary notifications:`, notificationError);
            }

            // NOTE: Feed post creation is now handled by onGameFeedTrigger
            // which listens to game status changes to 'completed'
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
