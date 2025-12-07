/* eslint-disable max-len */
/**
 * Cloud Functions to sync denormalized data to GameSignup documents
 *
 * This is critical for the N+1 query optimization in streamMyUpcomingGames.
 * When a game is created or updated, we need to update all signup documents
 * with denormalized game data to enable efficient collection group queries.
 *
 * See: FIXES_APPLIED_ISSUES_7_12.md - Issue 8
 */

const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { info, warn } = require('firebase-functions/logger');
const { db, FieldValue } = require('../utils');

/**
 * Helper: Extract denormalized data from a game document
 */
function extractDenormalizedGameData(game) {
  return {
    gameDate: game.gameDate || null,
    gameStatus: game.status || null,
    hubId: game.hubId || null,
    location: game.location || null,
    venueName: game.venueName || game.denormalized?.venueName || null,
  };
}

/**
 * Helper: Update all signups for a game with denormalized data
 */
async function syncSignupsForGame(gameId, denormalizedData) {
  try {
    const signupsSnapshot = await db
      .collection('games')
      .doc(gameId)
      .collection('signups')
      .get();

    if (signupsSnapshot.empty) {
      info(`No signups to sync for game ${gameId}`);
      return 0;
    }

    // Use batch for better performance (max 500 operations per batch)
    const batches = [];
    let currentBatch = db.batch();
    let operationCount = 0;
    let signupCount = 0;

    for (const signupDoc of signupsSnapshot.docs) {
      currentBatch.update(signupDoc.ref, denormalizedData);
      operationCount++;
      signupCount++;

      // Create new batch if we hit the limit
      if (operationCount === 500) {
        batches.push(currentBatch);
        currentBatch = db.batch();
        operationCount = 0;
      }
    }

    // Add remaining batch if not empty
    if (operationCount > 0) {
      batches.push(currentBatch);
    }

    // Commit all batches
    await Promise.all(batches.map(batch => batch.commit()));

    info(`Synced ${signupCount} signups for game ${gameId} across ${batches.length} batch(es)`);
    return signupCount;
  } catch (error) {
    warn(`Error syncing signups for game ${gameId}:`, error);
    throw error;
  }
}

/**
 * Trigger: When a game is created, sync denormalized data to any existing signups
 *
 * Note: Signups are usually created AFTER the game, but this handles edge cases
 * where signups might be created first (e.g., during migrations).
 */
exports.onGameCreatedSyncSignups = onDocumentCreated('games/{gameId}', async (event) => {
  const game = event.data.data();
  const gameId = event.params.gameId;

  info(`Syncing signups for newly created game: ${gameId}`);

  try {
    const denormalizedData = extractDenormalizedGameData(game);
    await syncSignupsForGame(gameId, denormalizedData);
  } catch (error) {
    // Log but don't throw - signup sync failure shouldn't block game creation
    warn(`Failed to sync signups for new game ${gameId}:`, error);
  }
});

/**
 * Trigger: When a game is updated, sync changed fields to all signups
 *
 * This ensures signups always have up-to-date game data for queries.
 * Only syncs if relevant fields changed (gameDate, status, hubId, location).
 */
exports.onGameUpdatedSyncSignups = onDocumentUpdated('games/{gameId}', async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const gameId = event.params.gameId;

  // Check if any relevant fields changed
  const relevantFieldsChanged =
    beforeData.gameDate?.toMillis() !== afterData.gameDate?.toMillis() ||
    beforeData.status !== afterData.status ||
    beforeData.hubId !== afterData.hubId ||
    beforeData.location !== afterData.location ||
    beforeData.venueName !== afterData.venueName ||
    beforeData.denormalized?.venueName !== afterData.denormalized?.venueName;

  if (!relevantFieldsChanged) {
    // No relevant changes, skip sync
    return;
  }

  info(`Relevant fields changed for game ${gameId}, syncing signups`);

  try {
    const denormalizedData = extractDenormalizedGameData(afterData);
    await syncSignupsForGame(gameId, denormalizedData);
  } catch (error) {
    // Log but don't throw - signup sync failure shouldn't block game updates
    warn(`Failed to sync signups for updated game ${gameId}:`, error);
  }
});

/**
 * Trigger: When a signup is created, populate it with denormalized game data
 *
 * This is the primary sync mechanism - when a player signs up, we immediately
 * copy the game data to the signup document.
 */
exports.onSignupCreatedPopulateGameData = onDocumentCreated(
  'games/{gameId}/signups/{userId}',
  async (event) => {
    const signup = event.data.data();
    const gameId = event.params.gameId;
    const userId = event.params.userId;

    // Check if already has denormalized data (avoid redundant work)
    if (signup.gameDate && signup.gameStatus) {
      info(`Signup ${gameId}/${userId} already has denormalized data, skipping`);
      return;
    }

    info(`Populating denormalized data for new signup: ${gameId}/${userId}`);

    try {
      // Fetch game document
      const gameDoc = await db.collection('games').doc(gameId).get();

      if (!gameDoc.exists) {
        warn(`Game ${gameId} not found for signup ${userId}`);
        return;
      }

      const game = gameDoc.data();
      const denormalizedData = extractDenormalizedGameData(game);

      // Update signup with denormalized data
      await event.data.ref.update(denormalizedData);

      info(`Populated denormalized data for signup ${gameId}/${userId}`);
    } catch (error) {
      // Log but don't throw - signup creation should succeed even if denormalization fails
      warn(`Failed to populate denormalized data for signup ${gameId}/${userId}:`, error);
    }
  }
);
