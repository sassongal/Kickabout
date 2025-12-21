/* eslint-disable max-len */
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { info } = require('firebase-functions/logger');
const { db, FieldValue } = require('../utils');

/**
 * Game Feed Post Trigger
 *
 * Creates feed posts when a game is completed.
 * This is separated from onGameCompleted to improve performance and reliability.
 *
 * Triggered by: games/{gameId} (when status changes to 'completed')
 */
exports.onGameFeedTrigger = onDocumentUpdated(
    'games/{gameId}',
    async (event) => {
        const gameId = event.params.gameId;
        const eventId = event.id;
        const beforeData = event.data.before.data();
        const afterData = event.data.after.data();

        // Only process if status changed to 'completed'
        const beforeStatus = beforeData?.status;
        const afterStatus = afterData?.status;

        if (afterStatus !== 'completed' || beforeStatus === 'completed') {
            return;
        }

        // ✅ IDEMPOTENCY CHECK
        const processedRef = db.collection('processed_events').doc(`${eventId}_feed`);
        const processedDoc = await processedRef.get();

        if (processedDoc.exists) {
            info(`Feed post already created for game ${gameId}. Skipping.`);
            return;
        }

        await processedRef.set({
            eventType: 'game_feed_created',
            gameId: gameId,
            processedAt: FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        });

        try {
            const gameData = afterData;
            const teamAScore = gameData.teamAScore ?? 0;
            const teamBScore = gameData.teamBScore ?? 0;
            const gameRegion = gameData.region;

            // Fetch hub data
            const hubDoc = await db.collection('hubs').doc(gameData.hubId).get();
            const hubData = hubDoc.exists ? hubDoc.data() : null;

            if (!hubData) {
                info(`Hub not found for game ${gameId}. Skipping feed post creation.`);
                return;
            }

            // Prepare feed post data (shared between hub and regional feed)
            const feedPostData = {
                hubId: gameData.hubId,
                hubName: hubData.name || 'האב',
                hubLogoUrl: hubData.logoUrl || null,
                type: 'game_completed',
                text: `משחק הושלם ב-${hubData.name || 'האב'}! תוצאה: ${teamAScore}-${teamBScore}`,
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

            // 1️⃣ Create post in HUB feed (for hub members)
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
        } catch (error) {
            info(`⚠️ Failed to create feed posts for game ${gameId}:`, error);
        }
    }
);
