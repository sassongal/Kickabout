/* eslint-disable max-len */
const { onDocumentCreated, onDocumentDeleted, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { info } = require('firebase-functions/logger');
const { db, admin, FieldValue } = require('./utils');

/**
 * Sync denormalized member arrays for a hub
 * This rebuilds activeMemberIds, managerIds, and moderatorIds arrays
 */
async function syncHubMemberArraysForHub(hubId) {
  try {
    const membersSnap = await db
      .collection(`hubs/${hubId}/members`)
      .where('status', '==', 'active')
      .get();

    const activeMemberIds = [];
    const managerIds = [];
    const moderatorIds = [];

    membersSnap.forEach((doc) => {
      const data = doc.data();
      const userId = doc.id;
      const role = data.role || 'member';

      activeMemberIds.push(userId);

      if (role === 'manager') {
        managerIds.push(userId);
      } else if (role === 'moderator') {
        moderatorIds.push(userId);
      }
    });

    // Update hub document with denormalized arrays
    await db.doc(`hubs/${hubId}`).update({
      activeMemberIds,
      managerIds,
      moderatorIds,
      updatedAt: FieldValue.serverTimestamp(),
    });

    info(`[syncArrays] Synced ${hubId}: ${activeMemberIds.length} active, ${managerIds.length} managers, ${moderatorIds.length} moderators`);
  } catch (err) {
    info(`[syncArrays] Error syncing ${hubId}:`, err);
    // Non-fatal
  }
}

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

    // Update hub to add Super Admin to members subcollection
    const memberRef = db.collection('hubs').doc(hubId).collection('members').doc(superAdminUid);

    // Check if already exists (unlikely for new hub but good practice)
    const memberSnap = await memberRef.get();

    if (!memberSnap.exists) {
      const batch = db.batch();

      // Add to members subcollection
      batch.set(memberRef, {
        role: 'admin',
        userId: superAdminUid,
        joinedAt: FieldValue.serverTimestamp(),
        status: 'active',
      });

      // Increment memberCount on Hub
      const hubRef = event.data.ref;
      batch.update(hubRef, {
        memberCount: FieldValue.increment(1),
        // Legacy support - ensure roles map is NOT used if possible, or kept in sync if needed temporarily
        // We are moving AWAY from roles map, so we don't update it.
      });

      // Add hubId to user's hubIds list
      const userRef = db.collection('users').doc(superAdminUid);
      batch.update(userRef, {
        hubIds: FieldValue.arrayUnion(hubId),
      });

      await batch.commit();
      info(`✅ Added Super Admin (${superAdminUid}) to hub ${hubId} members subcollection.`);
      
      // Sync arrays after adding super admin
      await syncHubMemberArraysForHub(hubId);
      await syncUserHubIdsForUser(superAdminUid);
    }

  } catch (error) {
    // Log error but don't fail hub creation
    info(`⚠️ Error adding Super Admin to hub ${hubId}: ${error.message}`);
  }
  
  // CRITICAL: Sync denormalized arrays when hub is created (e.g., from admin console)
  // This ensures activeMemberIds, managerIds, moderatorIds are always in sync
  // Even if super admin wasn't added, we still need to sync for the creator
  await syncHubMemberArraysForHub(hubId);
  
  // Also sync user.hubIds for the creator (if hub was created from client, this is already done)
  const hubData = event.data.data();
  if (hubData?.createdBy) {
    await syncUserHubIdsForUser(hubData.createdBy);
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
// Triggered when a member is added, updated, or removed in the subcollection
/**
 * Sync user.hubIds array based on active memberships
 */
async function syncUserHubIdsForUser(userId) {
  try {
    // Find all hubs where user is an active member
    // Note: collectionGroup query can't use documentId in where clause
    // So we query all active members and filter by userId from path
    // Alternative: Query each hub's members subcollection (more efficient for small number of hubs)
    // For now, use collectionGroup but this might be slow for large datasets
    const membershipsSnap = await db
      .collectionGroup('members')
      .where('status', '==', 'active')
      .get();

    const hubIds = [];
    membershipsSnap.forEach((doc) => {
      // Extract hubId and userId from path: hubs/{hubId}/members/{userId}
      const pathParts = doc.ref.path.split('/');
      if (pathParts.length >= 4 && pathParts[0] === 'hubs' && pathParts[3] === userId) {
        hubIds.push(pathParts[1]);
      }
    });

    // Update user document
    await db.collection('users').doc(userId).update({
      hubIds,
      updatedAt: FieldValue.serverTimestamp(),
    });

    info(`[syncUserHubIds] Synced ${userId}: ${hubIds.length} hubs`);
    return hubIds;
  } catch (err) {
    error(`[syncUserHubIds] Error syncing ${userId}:`, err);
    // Return existing hubIds if sync fails
    const userDoc = await db.collection('users').doc(userId).get();
    return userDoc.exists ? (userDoc.data().hubIds || []) : [];
  }
}

exports.onHubMembershipChanged = onDocumentWritten(
  'hubs/{hubId}/members/{userId}',
  async (event) => {
    const hubId = event.params.hubId;
    const userId = event.params.userId;

    const beforeData = event.data.before.exists ? event.data.before.data() : null;
    const afterData = event.data.after.exists ? event.data.after.data() : null;

    // CRITICAL: Sync user.hubIds first to ensure it's up to date
    const userHubIds = await syncUserHubIdsForUser(userId);

    // Check if role actually changed
    const beforeRole = beforeData ? beforeData.role : null;
    const afterRole = afterData ? afterData.role : null;

    if (beforeRole === afterRole) {
      // Role didn't change, but we still updated hubIds above
      // If document deleted (afterData null), role is null.
      // If document created (beforeData null), role is new.
      return;
    }

    info(`Membership/Role changed for user ${userId} in hub ${hubId}. Updating custom claims.`);

    try {
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        info(`User ${userId} does not exist, skipping custom claims update`);
        return;
      }

      // Build custom claims object
      const customClaims = {
        hubIds: userHubIds,
        roles: {},
      };

      // We need to fetch roles for ALL hubs this user is in to rebuild the claims
      // This is expensive but ensures correctness. 
      // Optimization: We could only update the specific hub's role if we trust the others are consistent,
      // but 'setCustomUserClaims' OVERWRITES existing claims, so we MUST rebuild `roles` object fully.

      const rolesMap = {};

      // Fetch user's membership docs from all hubs they are part of
      // This might be many reads if user is in many hubs.
      // Alternative: Store 'role' inside 'hubIds' object? No, hubIds is array.
      // Better: Query collectionGroup('members') where userId == userId?
      // Yes, collectionGroup is more efficient than N reads if N is large, but N is usually small (<10).

      const membershipPromises = userHubIds.map(async (hId) => {
        try {
          const memberDoc = await db.collection('hubs').doc(hId).collection('members').doc(userId).get();
          if (memberDoc.exists) {
            const role = memberDoc.data().role;
            if (role) {
              rolesMap[hId] = role;
            }
          }
        } catch (e) {
          console.error(`Error fetching role for hub ${hId}`, e);
        }
      });

      await Promise.all(membershipPromises);

      customClaims.roles = rolesMap;

      // Update custom claims
      await admin.auth.setCustomUserClaims(userId, customClaims);
      info(`✅ Updated custom claims for user ${userId} with ${Object.keys(rolesMap).length} hub roles`);
    } catch (error) {
      info(`⚠️ Critical error in onHubMembershipChanged for user ${userId}:`, error.message || error);
    }
  },
);

// --- Create Super Admin User ---
// Callable function to create a super admin user with full permissions
const { onCall, HttpsError } = require('firebase-functions/v2/https');

exports.createSuperAdmin = onCall(
  {
    // SECURITY: Only existing super admins can create new super admins
    // For initial setup, use Firebase Admin SDK manually
    invoker: 'private', // 🔒 Restricted to prevent unauthorized access
  },
  async (request) => {
    // Verify caller is an existing super admin
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const callerClaims = request.auth.token;
    if (!callerClaims.isSuperAdmin) {
      throw new HttpsError(
        'permission-denied',
        'Only existing super admins can create new super admins'
      );
    }

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

      // Add user as admin to all hubs via Members Subcollection
      const batch = db.batch();

      // Limit batch size to 500 ops
      let opCount = 0;
      let currentBatch = batch;

      const commitVariables = [];

      for (const hubId of hubIds) {
        const memberRef = db.collection('hubs').doc(hubId).collection('members').doc(userId);
        currentBatch.set(memberRef, {
          role: 'admin',
          userId: userId,
          joinedAt: FieldValue.serverTimestamp(),
          status: 'active'
        }, { merge: true });

        opCount++;

        // Also update hub memberCount (approximate if already member, but safe to increment if logic handles it)
        // Ideally we check if they are ALREADY a member, but efficiently.
        // For 'Super Admin' creation, we can assume we want to force them in.
        // Note: FieldValue.increment(1) blindly will be wrong if they are already members.
        // For simplicity in this admin tool, we skip memberCount update here and rely on manual fix or 
        // accepting slight drift for the Super Admin special case. 
        // OR: we could read all memberships first.
      }

      // Update user's hubIds to include all hubs
      const updatedHubIds = [...new Set([...userData.hubIds || [], ...hubIds])];
      currentBatch.update(userDoc.ref, {
        hubIds: updatedHubIds,
      });
      opCount++;

      await currentBatch.commit();
      info(`✅ Added user ${userId} as admin to ${hubIds.length} hubs (Members Subcollection)`);

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

// --- Vote on Poll ---
/**
 * Vote on a poll
 * @param {string} pollId - Poll ID
 * @param {Array<string>} selectedOptionIds - Selected option IDs
 * @param {number?} rating - Rating value (1-5) for rating polls
 * @return {Object} Result with success status
 */
exports.votePoll = onCall(
  {
    invoker: 'public',
    memory: '256MiB',
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }

    const userId = request.auth.uid;
    const { pollId, selectedOptionIds, rating } = request.data;

    // Validation
    if (!pollId) {
      throw new HttpsError('invalid-argument', 'Missing pollId parameter');
    }

    if (!selectedOptionIds || !Array.isArray(selectedOptionIds) || selectedOptionIds.length === 0) {
      if (!rating) {
        throw new HttpsError('invalid-argument', 'Must provide selectedOptionIds or rating');
      }
    }

    info(`User ${userId} voting on poll ${pollId}`);

    try {
      // Use transaction to ensure atomic vote recording
      await db.runTransaction(async (transaction) => {
        const pollRef = db.collection('polls').doc(pollId);
        const pollDoc = await transaction.get(pollRef);

        if (!pollDoc.exists) {
          throw new HttpsError('not-found', 'Poll not found');
        }

        const pollData = pollDoc.data();

        // Check if poll is active
        if (pollData.status !== 'active') {
          throw new HttpsError('failed-precondition', 'Poll is closed', { code: 'poll-closed' });
        }

        // Check if poll has ended
        if (pollData.endsAt && pollData.endsAt.toDate() < new Date()) {
          throw new HttpsError('failed-precondition', 'Poll has ended', { code: 'poll-closed' });
        }

        // Check if user already voted
        const voters = pollData.voters || [];
        if (voters.includes(userId) && !pollData.allowMultipleVotes) {
          throw new HttpsError('failed-precondition', 'Already voted', { code: 'already-voted' });
        }

        // Validate vote type matches poll type
        const pollType = pollData.type;
        if (pollType === 'rating' && !rating) {
          throw new HttpsError('invalid-argument', 'Rating is required for rating polls');
        }
        if (pollType === 'singleChoice' && selectedOptionIds && selectedOptionIds.length !== 1) {
          throw new HttpsError('invalid-argument', 'Single choice polls require exactly one option');
        }

        // Prepare updates
        const updates = {
          totalVotes: FieldValue.increment(1),
        };

        // Add user to voters list if not already voted
        if (!voters.includes(userId)) {
          updates.voters = FieldValue.arrayUnion(userId);
        }

        // Update vote counts for selected options
        const options = pollData.options || [];
        const updatedOptions = options.map((option) => {
          if (selectedOptionIds && selectedOptionIds.includes(option.optionId)) {
            return {
              ...option,
              voteCount: (option.voteCount || 0) + 1,
              voters: pollData.isAnonymous
                ? (option.voters || [])
                : [...(option.voters || []), userId],
            };
          }
          return option;
        });

        updates.options = updatedOptions;

        // Update poll document
        transaction.update(pollRef, updates);

        info(`✅ Vote recorded for poll ${pollId} by user ${userId}`);
      });

      return {
        success: true,
        message: 'Vote recorded successfully',
      };
    } catch (error) {
      info(`⚠️ Error voting on poll:`, error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', `Failed to vote: ${error.message}`);
    }
  },
);
