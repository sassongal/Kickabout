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
    const venueData = event.data.after.data();
    const isCreate = !event.data.before.exists;

    // Assign venueNumber if missing (for new venues or venues without number)
    if (isCreate || !venueData.venueNumber || venueData.venueNumber === 0) {
      info(`Assigning venueNumber to venue ${venueId}...`);
      
      try {
        // Use a counter document to atomically increment venueNumber
        // This prevents race conditions when multiple venues are created simultaneously
        const counterRef = db.collection('_counters').doc('venues');
        
        // Check if counter exists before transaction (to initialize it if needed)
        const counterDocBefore = await counterRef.get();
        let initialCounterValue = null;
        
        if (!counterDocBefore.exists) {
          // Counter doesn't exist - get highest venueNumber to initialize it
          const venuesSnapshot = await db
            .collection('venues')
            .orderBy('venueNumber', 'desc')
            .limit(1)
            .get();
          
          if (!venuesSnapshot.empty) {
            const highestVenue = venuesSnapshot.docs[0].data();
            initialCounterValue = highestVenue.venueNumber || 0;
          } else {
            initialCounterValue = 0;
          }
        }
        
        await db.runTransaction(async (transaction) => {
          // Get the counter document
          const counterDoc = await transaction.get(counterRef);
          
          let nextVenueNumber = 1;
          if (counterDoc.exists) {
            const counterData = counterDoc.data();
            nextVenueNumber = (counterData.count || 0) + 1;
            // Update counter atomically
            transaction.update(counterRef, {
              count: nextVenueNumber,
              updatedAt: FieldValue.serverTimestamp(),
            });
          } else {
            // First time - initialize counter with the value we found
            nextVenueNumber = (initialCounterValue || 0) + 1;
            
            // Create counter document
            transaction.set(counterRef, {
              count: nextVenueNumber,
              createdAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
            });
          }

          // Double-check that this venue doesn't already have a number (race condition protection)
          const venueDoc = await transaction.get(event.data.after.ref);
          const currentVenueData = venueDoc.data();
          
          if (currentVenueData.venueNumber && currentVenueData.venueNumber > 0) {
            info(`Venue ${venueId} already has venueNumber ${currentVenueData.venueNumber}, skipping assignment.`);
            return; // Venue already has a number, skip
          }

          // Update the venue with the new venueNumber
          transaction.update(event.data.after.ref, {
            venueNumber: nextVenueNumber,
            updatedAt: FieldValue.serverTimestamp(),
          });

          info(`✅ Assigned venueNumber ${nextVenueNumber} to venue ${venueId}`);
        });
      } catch (error) {
        info(`❌ Error assigning venueNumber to venue ${venueId}: ${error.message}`);
        // Fallback: try to get highest number without transaction (less safe but works)
        try {
          const venuesSnapshot = await db
            .collection('venues')
            .orderBy('venueNumber', 'desc')
            .limit(1)
            .get();

          let nextVenueNumber = 1;
          if (!venuesSnapshot.empty) {
            const highestVenue = venuesSnapshot.docs[0].data();
            const highestNumber = highestVenue.venueNumber || 0;
            nextVenueNumber = highestNumber + 1;
          }

          await event.data.after.ref.update({
            venueNumber: nextVenueNumber,
            updatedAt: FieldValue.serverTimestamp(),
          });

          info(`✅ Assigned venueNumber ${nextVenueNumber} to venue ${venueId} (fallback method)`);
        } catch (fallbackError) {
          info(`❌ Fallback method also failed for venue ${venueId}: ${fallbackError.message}`);
          // Don't throw - allow venue creation to continue even if venueNumber assignment fails
          // The venue can be fixed later by running the normalization script
        }
      }
    }

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

