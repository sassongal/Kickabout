/* eslint-disable max-len */
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { info } = require('firebase-functions/logger');
const { db, FieldValue } = require('./utils');

exports.onVenueChanged = onDocumentWritten(
  'venues/{venueId}',
  async (event) => {
    // This trigger handles create, update, and delete
    const venueId = event.params.venueId;

    // On delete
    if (!event.data.after.exists) {
      info(`Venue ${venueId} deleted. Triggering hub updates.`);
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
    info(`Venue ${venueId} created or updated. Triggering hub updates.`);

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

