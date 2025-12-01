/* eslint-disable max-len */
const { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { info } = require('firebase-functions/logger');
const { db, admin, FieldValue } = require('./utils');

exports.addSuperAdminToHub = onDocumentCreated('hubs/{hubId}', async (event) => {
  const hubId = event.params.hubId;

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
      const userRecord = await admin.auth.getUserByEmail(superAdminEmail);
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

// --- Custom Claims Update for Hub Members (Subcollection-aware) ---
exports.onHubMemberChanged = onDocumentUpdated(
  'hubs/{hubId}',
  async (event) => {
    const hubId = event.params.hubId;
    const afterData = event.data.after.data();
    if (!afterData) return;

    const afterRoles = afterData.roles || {};
    const affectedUserIds = new Set(Object.keys(afterRoles));

    if (affectedUserIds.size === 0) return;

    info(`Hub ${hubId} role map changed. Updating custom claims for ${affectedUserIds.size} users.`);

    try {
      const updatePromises = Array.from(affectedUserIds).map(async (userId) => {
        try {
          const userDoc = await db.collection('users').doc(userId).get();
          if (!userDoc.exists) {
            info(`User ${userId} does not exist, skipping custom claims update`);
            return;
          }
          const hubIds = userDoc.data().hubIds || [];

          // Build custom claims object
          const customClaims = {
            hubIds: hubIds,
            roles: {},
          };

          // Get roles for each hub
          for (const hId of hubIds) {
            try {
              const hubDoc = await db.collection('hubs').doc(hId).get();
              if (hubDoc.exists) {
                const hubData = hubDoc.data();
                const userRole = hubData.roles?.[userId] || null;
                if (userRole) {
                  customClaims.roles[hId] = userRole;
                }
              }
            } catch (hubError) {
              info(`Error fetching hub ${hId} for user ${userId}:`, hubError);
              // Continue with other hubs
            }
          }

          // Update custom claims
          await admin.auth.setCustomUserClaims(userId, customClaims);
          info(`✅ Updated custom claims for user ${userId} with ${Object.keys(customClaims.roles).length} hub roles`);
        } catch (error) {
          info(`⚠️ Error updating custom claims for user ${userId}:`, error.message || error);
          // Don't throw - continue with other users
        }
      });

      await Promise.all(updatePromises);
      info(`✅ Completed custom claims update for hub ${hubId}`);
    } catch (error) {
      info(`⚠️ Critical error in onHubMemberChanged for hub ${hubId}:`, error.message || error);
      // Don't throw - this is a background function
    }
  },
);

// --- Create Super Admin User ---
// Callable function to create a super admin user with full permissions
const { onCall, HttpsError } = require('firebase-functions/v2/https');

exports.createSuperAdmin = onCall(
  {
    // This function should be protected - only callable by existing super admins or manually
    // For now, we'll allow authenticated users (you can restrict this later)
    invoker: 'authenticated',
  },
  async (request) => {
    const { phoneNumber } = request.data;

    if (!phoneNumber) {
      throw new HttpsError('invalid-argument', 'Phone number is required');
    }

    info(`Creating super admin for phone: ${phoneNumber}`);

    try {
      // Find user by phone number
      const usersSnapshot = await db
        .collection('users')
        .where('phoneNumber', '==', phoneNumber.trim())
        .limit(1)
        .get();

      if (usersSnapshot.empty) {
        throw new HttpsError('not-found', `User with phone number ${phoneNumber} not found`);
      }

      const userDoc = usersSnapshot.docs[0];
      const userId = userDoc.id;
      const userData = userDoc.data();

      info(`Found user: ${userId} (${userData.name || userData.email})`);

      // Get all hubs
      const hubsSnapshot = await db.collection('hubs').get();
      const hubIds = hubsSnapshot.docs.map((doc) => doc.id);

      info(`Found ${hubIds.length} hubs to add admin to`);

      // Add user as admin to all hubs
      const batch = db.batch();
      for (const hubId of hubIds) {
        const hubRef = db.collection('hubs').doc(hubId);
        batch.update(hubRef, {
          [`roles.${userId}`]: 'admin',
        });
      }

      // Update user's hubIds to include all hubs
      const updatedHubIds = [...new Set([...userData.hubIds || [], ...hubIds])];
      batch.update(userDoc.ref, {
        hubIds: updatedHubIds,
      });

      await batch.commit();
      info(`✅ Added user ${userId} as admin to ${hubIds.length} hubs`);

      // Set custom claims for super admin
      const customClaims = {
        isSuperAdmin: true,
        hubIds: updatedHubIds,
        roles: {},
      };

      // Add admin role for all hubs
      for (const hubId of hubIds) {
        customClaims.roles[hubId] = 'admin';
      }

      await admin.auth.setCustomUserClaims(userId, customClaims);
      info(`✅ Set super admin custom claims for user ${userId}`);

      return {
        success: true,
        userId: userId,
        userName: userData.name || userData.email,
        hubsAdded: hubIds.length,
        message: `Super admin created successfully. User is now admin of ${hubIds.length} hubs.`,
      };
    } catch (error) {
      info(`⚠️ Error creating super admin:`, error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', `Failed to create super admin: ${error.message}`);
    }
  },
);
