/* eslint-disable max-len */
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { info, error } = require('firebase-functions/logger');
const { db, admin } = require('../utils');

// --- Man of the Match (MOTM) Voting Handler ---
// Monitors voting progress and automatically closes when 80% threshold reached
exports.onMotmVoteAdded = onDocumentUpdated("games/{gameId}", async (event) => {
    const gameId = event.params.gameId;
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!beforeData || !afterData) {
        return;
    }

    // Only process if MOTM voting is enabled for this game
    if (!afterData.motmVotingEnabled) {
        return;
    }

    // Skip if voting already closed
    if (afterData.motmVotingClosedAt) {
        return;
    }

    // Only trigger when game status is 'completed' and votes changed
    if (afterData.status !== "completed") {
        return;
    }

    const beforeVotes = beforeData.motmVotes || {};
    const afterVotes = afterData.motmVotes || {};

    // Check if a new vote was added
    if (Object.keys(beforeVotes).length >= Object.keys(afterVotes).length) {
        return; // No new votes
    }

    info(`MOTM vote added to game ${gameId}. Processing...`);

    try {
        // Get confirmed participants count
        const signupsSnapshot = await db
            .collection("games")
            .doc(gameId)
            .collection("signups")
            .where("status", "==", "confirmed")
            .get();

        const totalParticipants = signupsSnapshot.size;
        const totalVotes = Object.keys(afterVotes).length;
        const votingPercentage = totalParticipants > 0 ? totalVotes / totalParticipants : 0;

        info(`MOTM voting progress: ${totalVotes}/${totalParticipants} (${(votingPercentage * 100).toFixed(0)}%)`);

        // Close voting if 80% threshold reached
        if (votingPercentage >= 0.80) {
            info(`MOTM voting threshold reached (80%). Closing voting and calculating winner...`);

            // Count votes for each player
            const voteCounts = {};
            for (const votedPlayerId of Object.values(afterVotes)) {
                voteCounts[votedPlayerId] = (voteCounts[votedPlayerId] || 0) + 1;
            }

            // Find winner (highest votes)
            let winnerId = null;
            let maxVotes = 0;
            const candidates = [];

            for (const [playerId, count] of Object.entries(voteCounts)) {
                if (count > maxVotes) {
                    maxVotes = count;
                    winnerId = playerId;
                    candidates.length = 0;
                    candidates.push(playerId);
                } else if (count === maxVotes) {
                    candidates.push(playerId);
                }
            }

            // Tie-breaker: If multiple players have same votes, choose one with higher rating
            if (candidates.length > 1) {
                info(`MOTM voting tie detected: ${candidates.length} players with ${maxVotes} votes. Using rating as tie-breaker.`);

                const hubId = afterData.hubId;
                if (hubId) {
                    let highestRating = 0;
                    for (const playerId of candidates) {
                        const memberDoc = await db
                            .collection("hubs")
                            .doc(hubId)
                            .collection("members")
                            .doc(playerId)
                            .get();

                        if (memberDoc.exists) {
                            const rating = memberDoc.data().managerRating || 0;
                            if (rating > highestRating) {
                                highestRating = rating;
                                winnerId = playerId;
                            }
                        }
                    }
                }
            }

            // Update game with winner and close voting
            await db.collection("games").doc(gameId).update({
                motmWinnerId: winnerId,
                motmVotingClosedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Update winner's HubMember totalMvps count
            const hubId = afterData.hubId;
            if (hubId && winnerId) {
                const memberRef = db
                    .collection("hubs")
                    .doc(hubId)
                    .collection("members")
                    .doc(winnerId);

                await memberRef.update({
                    totalMvps: admin.firestore.FieldValue.increment(1),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedBy: "system:onMotmVoteAdded",
                });

                info(`MOTM winner ${winnerId} awarded MVP badge. Total MVPs incremented.`);
            }

            // TODO: Post to hub feed with trophy graphic (Phase 2)
            // TODO: Send notification to winner (Phase 2)

            info(`MOTM voting closed for game ${gameId}. Winner: ${winnerId} with ${maxVotes} votes.`);
        }
    } catch (err) {
        error(`Error processing MOTM votes for game ${gameId}:`, err);
    }
});

// --- MOTM Voting Auto-Close (2-hour timeout) ---
// Scheduled function that runs every 30 minutes to check for expired voting
exports.closeExpiredMotmVoting = onSchedule("every 30 minutes", async (event) => {
    info("Running scheduled MOTM voting timeout check...");

    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);

    try {
        // Find games with active MOTM voting that were completed > 2 hours ago
        const gamesSnapshot = await db
            .collection("games")
            .where("status", "==", "completed")
            .where("motmVotingEnabled", "==", true)
            .where("motmVotingClosedAt", "==", null)
            .where("updatedAt", "<=", twoHoursAgo)
            .limit(50) // Process in batches
            .get();

        if (gamesSnapshot.empty) {
            info("No expired MOTM voting sessions found.");
            return;
        }

        info(`Found ${gamesSnapshot.size} games with expired MOTM voting. Closing...`);

        for (const gameDoc of gamesSnapshot.docs) {
            const gameId = gameDoc.id;
            const gameData = gameDoc.data();
            const votes = gameData.motmVotes || {};

            // Count votes
            const voteCounts = {};
            for (const votedPlayerId of Object.values(votes)) {
                voteCounts[votedPlayerId] = (voteCounts[votedPlayerId] || 0) + 1;
            }

            // Find winner
            let winnerId = null;
            let maxVotes = 0;
            for (const [playerId, count] of Object.entries(voteCounts)) {
                if (count > maxVotes) {
                    maxVotes = count;
                    winnerId = playerId;
                }
            }

            // Close voting (even if no votes)
            const updateData = {
                motmVotingClosedAt: admin.firestore.FieldValue.serverTimestamp(),
            };

            if (winnerId) {
                updateData.motmWinnerId = winnerId;

                // Update winner's MVP count
                const hubId = gameData.hubId;
                if (hubId) {
                    await db
                        .collection("hubs")
                        .doc(hubId)
                        .collection("members")
                        .doc(winnerId)
                        .update({
                            totalMvps: admin.firestore.FieldValue.increment(1),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                            updatedBy: "system:closeExpiredMotmVoting",
                        });
                }
            }

            await db.collection("games").doc(gameId).update(updateData);

            info(`Closed MOTM voting for game ${gameId} (timeout). Winner: ${winnerId || "none"}`);
        }

        info(`Successfully closed ${gamesSnapshot.size} expired MOTM voting sessions.`);
    } catch (err) {
        error("Error in closeExpiredMotmVoting:", err);
    }
});
