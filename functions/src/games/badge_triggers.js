/* eslint-disable max-len */
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { info } = require('firebase-functions/logger');
const { db, FieldValue } = require('../utils');

/**
 * Badge Award Trigger
 *
 * Listens to changes in user gamification stats and awards badges when milestones are reached.
 * This is separated from onGameCompleted to reduce execution time and improve reliability.
 *
 * Triggered by: users/{userId}/gamification/stats
 */
exports.onUserStatsUpdated = onDocumentUpdated(
    'users/{userId}/gamification/stats',
    async (event) => {
        const userId = event.params.userId;
        const eventId = event.id;
        const beforeData = event.data.before.data();
        const afterData = event.data.after.data();

        if (!beforeData || !afterData) {
            return;
        }

        // ✅ IDEMPOTENCY CHECK
        const processedRef = db.collection('processed_events').doc(eventId);
        const processedDoc = await processedRef.get();

        if (processedDoc.exists) {
            info(`Event ${eventId} already processed for user ${userId}. Skipping.`);
            return;
        }

        await processedRef.set({
            eventType: 'user_stats_updated',
            userId: userId,
            processedAt: FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        });

        try {
            const beforeStats = beforeData.stats || {};
            const afterStats = afterData.stats || {};
            const currentBadges = afterData.badges || [];

            const badgesToAward = [];

            // Check games played milestones
            const beforeGames = beforeStats.gamesPlayed || 0;
            const afterGames = afterStats.gamesPlayed || 0;

            if (beforeGames < 1 && afterGames >= 1 && !currentBadges.includes('firstGame')) {
                badgesToAward.push('firstGame');
            }
            if (beforeGames < 10 && afterGames >= 10 && !currentBadges.includes('tenGames')) {
                badgesToAward.push('tenGames');
            }
            if (beforeGames < 50 && afterGames >= 50 && !currentBadges.includes('fiftyGames')) {
                badgesToAward.push('fiftyGames');
            }
            if (beforeGames < 100 && afterGames >= 100 && !currentBadges.includes('hundredGames')) {
                badgesToAward.push('hundredGames');
            }

            // Check goals milestones
            const beforeGoals = beforeStats.goals || 0;
            const afterGoals = afterStats.goals || 0;

            if (beforeGoals < 1 && afterGoals >= 1 && !currentBadges.includes('firstGoal')) {
                badgesToAward.push('firstGoal');
            }
            if (beforeGoals < 10 && afterGoals >= 10 && !currentBadges.includes('tenGoals')) {
                badgesToAward.push('tenGoals');
            }
            if (beforeGoals < 50 && afterGoals >= 50 && !currentBadges.includes('fiftyGoals')) {
                badgesToAward.push('fiftyGoals');
            }

            // Check for hat trick (3+ goals in a single update)
            const goalDiff = afterGoals - beforeGoals;
            if (goalDiff >= 3 && !currentBadges.includes('hatTrick')) {
                badgesToAward.push('hatTrick');
            }

            // Award badges if any milestones were reached
            if (badgesToAward.length > 0) {
                await db
                    .collection('users')
                    .doc(userId)
                    .collection('gamification')
                    .doc('stats')
                    .update({
                        badges: FieldValue.arrayUnion(...badgesToAward),
                        updatedAt: FieldValue.serverTimestamp(),
                    });

                info(`Awarded badges to user ${userId}: ${badgesToAward.join(', ')}`);
            }
        } catch (error) {
            info(`Error in onUserStatsUpdated for user ${userId}:`, error);
        }
    }
);
