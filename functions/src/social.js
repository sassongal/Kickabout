/* eslint-disable max-len */
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { Timestamp } = require('firebase-admin/firestore');
const { info } = require('firebase-functions/logger');
const { db, messaging, FieldValue, getHubMemberIds, getUserFCMTokens } = require('./utils');

const RECENT_POST_DAYS = 90;
const MAX_POSTS_TO_UPDATE = 200;
const BATCH_LIMIT = 450;

async function updatePostsSnapshot(snapshot, updateData) {
  if (snapshot.empty) return 0;

  let batch = db.batch();
  let processed = 0;
  let updated = 0;

  for (const doc of snapshot.docs) {
    batch.update(doc.ref, updateData);
    processed += 1;
    updated += 1;

    if (processed >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      processed = 0;
    }
  }

  if (processed > 0) {
    await batch.commit();
  }

  return updated;
}

exports.onHubMessageCreated = onDocumentCreated(
  'hubs/{hubId}/chat/{messageId}',
  async (event) => {
    const message = event.data.data();
    const hubId = event.params.hubId;
    const messageId = event.params.messageId;

    info(`New message in hub: ${hubId} by ${message.authorId || message.senderId}`);

    try {
      // Fetch hub and user data in parallel for denormalization
      const [hubSnap, userSnap] = await Promise.all([
        db.collection('hubs').doc(hubId).get(),
        db.collection('users').doc(message.authorId || message.senderId).get(),
      ]);

      if (!hubSnap.exists) {
        info('Hub does not exist');
        return;
      }
      const hub = hubSnap.data();
      const user = userSnap.exists ? userSnap.data() : null;

      // Denormalize user data into message document
      const messageUpdate = {};
      if (user) {
        messageUpdate.senderId = message.authorId || message.senderId;
        messageUpdate.senderName = user.name || null;
        messageUpdate.senderPhotoUrl = user.photoUrl || null;
      }

      // Update message with denormalized data
      if (Object.keys(messageUpdate).length > 0) {
        await db
          .collection('hubs')
          .doc(hubId)
          .collection('chat')
          .doc(messageId)
          .update(messageUpdate);
      }

      // Update hub last activity
      await hubSnap.ref.update({
        lastActivity: message.createdAt,
      });

      const hubName = hub.name;

      // Get hub members
      const hubData = hubSnap.data();
      let memberIds = hubData.memberIds || [];
      if (!memberIds.length) {
        memberIds = await getHubMemberIds(hubId);
      }
      if (memberIds.length === 0) return;

      // ✅ PERFORMANCE FIX: Get FCM tokens in PARALLEL using helper
      const filteredMemberIds = memberIds.filter(id => id !== message.senderId);
      const tokenArrays = await Promise.all(
        filteredMemberIds.map((memberId) => getUserFCMTokens(memberId))
      );
      const tokens = tokenArrays.flat();

      if (tokens.length === 0) return;
      const uniqueTokens = [...new Set(tokens)];

      const payload = {
        notification: {
          title: `💬 הודעה חדשה ב-${hubName}`,
          body: `${message.senderName}: ${message.text}`,
        },
        tokens: uniqueTokens,
        data: {
          type: 'hub_chat',
          hubId: hubId,
        },
      };

      await messaging.sendEachForMulticast(payload);
      info(`Sent chat notification for hub ${hubId} to ${uniqueTokens.length} tokens.`);
    } catch (error) {
      info(`Error in onHubMessageCreated for hub ${hubId}:`, error);
    }
  },
);

exports.onCommentCreated = onDocumentCreated(
  'hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}',
  async (event) => {
    const comment = event.data.data();
    const hubId = event.params.hubId;
    const postId = event.params.postId;
    const commentId = event.params.commentId;

    info(`New comment on post: ${postId} by ${comment.authorId}`);

    try {
      // Fetch user data for denormalization
      const userSnap = await db.collection('users').doc(comment.authorId).get();
      const user = userSnap.exists ? userSnap.data() : null;

      // Denormalize user data into comment document
      const commentUpdate = {};
      if (user) {
        commentUpdate.authorName = user.name || null;
        commentUpdate.authorPhotoUrl = user.photoUrl || null;
      }

      // Update comment with denormalized data
      if (Object.keys(commentUpdate).length > 0) {
        await db
          .collection('hubs')
          .doc(hubId)
          .collection('feed')
          .doc('posts')
          .collection('items')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update(commentUpdate);
      }

      // Increment comment count on post
      const postRef = db
        .collection('hubs')
        .doc(hubId)
        .collection('feed')
        .doc('posts')
        .collection('items')
        .doc(postId);

      await postRef.update({
        commentCount: FieldValue.increment(1),
      });

      // Get post data for notification
      const postSnap = await postRef.get();
      if (!postSnap.exists) return;
      const post = postSnap.data();

      // Don't send notification if user comments on their own post
      if (post.authorId === comment.authorId) return;

      // Get post author's FCM token from subcollection
      // ✅ Use helper to get FCM tokens
      const tokens = await getUserFCMTokens(post.authorId);
      if (tokens.length === 0) return;

      const payload = {
        notification: {
          title: `💬 ${user?.name || 'מישהו'} הגיב לפוסט שלך`,
          body: comment.text,
        },
        tokens: tokens,
        data: {
          type: 'new_comment',
          postId: postId,
          hubId: hubId,
        },
      };

      await messaging.sendEachForMulticast(payload);
      info(`Sent comment notification for post ${postId} to user ${post.authorId}.`);
    } catch (error) {
      info(`Error in onCommentCreated for post ${postId}:`, error);
    }
  },
);

// --- Recruiting Posts: Regional Duplication + Notifications ---
exports.onRecruitingPostCreated = onDocumentCreated(
  'hubs/{hubId}/feed/posts/items/{postId}',
  async (event) => {
    const post = event.data.data();
    const postId = event.params.postId;
    const hubId = event.params.hubId;

    // Only process recruiting posts
    if (post.type !== 'hub_recruiting') return;

    info(`Recruiting post ${postId} created in hub ${hubId}. Creating regional feed post...`);

    try {
      // Get hub data
      const hubDoc = await db.collection('hubs').doc(hubId).get();
      if (!hubDoc.exists) return;

      const hubData = hubDoc.data();
      const region = hubData.region;

      if (!region) {
        info('Hub has no region, skipping regional feed post');
        return;
      }

      // Create regional feed post
      const regionalPostRef = db.collection('feedPosts').doc();
      await regionalPostRef.set({
        postId: regionalPostRef.id,
        hubId: hubId,
        hubName: hubData.name,
        hubLogoUrl: hubData.logoUrl || null,
        type: 'hub_recruiting',
        content: post.content,
        photoUrls: post.photoUrls || [],
        createdAt: post.createdAt,
        authorId: post.authorId,
        authorName: post.authorName || null,
        authorPhotoUrl: post.authorPhotoUrl || null,
        region: region,
        gameId: post.gameId || null,
        eventId: post.eventId || null,
        isUrgent: post.isUrgent || false,
        recruitingUntil: post.recruitingUntil || null,
        neededPlayers: post.neededPlayers || 0,
        likeCount: 0,
        commentCount: 0,
      });

      info(`Created regional feed post ${regionalPostRef.id} for recruiting post ${postId}`);

      // Optional: Send notifications to nearby players
      const usersSnapshot = await db.collection('users')
        .where('region', '==', region)
        .where('isActive', '==', true)
        .limit(100)
        .get();

      let memberIds = hubData.memberIds || [];
      if (!memberIds.length) {
        memberIds = await getHubMemberIds(hubId);
      }

      // ✅ PERFORMANCE FIX: Get FCM tokens in PARALLEL using helper
      const nonMemberUserIds = usersSnapshot.docs
        .map((doc) => doc.id)
        .filter((userId) => !memberIds.includes(userId));

      const tokenArrays = await Promise.all(
        nonMemberUserIds.map((userId) => getUserFCMTokens(userId))
      );
      const tokens = tokenArrays.flat();

      if (tokens.length > 0) {
        const uniqueTokens = [...new Set(tokens)];

        const message = {
          notification: {
            title: `⚽ ${hubData.name} מחפש שחקנים!`,
            body: post.content || 'לחץ לפרטים נוספים',
          },
          tokens: uniqueTokens,
          data: {
            type: 'hub_recruiting',
            postId: regionalPostRef.id,
            hubId: hubId,
          },
        };

        await messaging.sendEachForMulticast(message);
        info(`Sent recruiting notification to ${uniqueTokens.length} users in region ${region}`);
      }
    } catch (error) {
      info(`Error creating regional feed post for recruiting post ${postId}:`, error);
    }
  },
);

// --- Contact Messages: Notify Hub Managers ---
exports.onContactMessageCreated = onDocumentCreated(
  'hubs/{hubId}/contactMessages/{messageId}',
  async (event) => {
    const message = event.data.data();
    const hubId = event.params.hubId;
    const messageId = event.params.messageId;

    info(`New contact message ${messageId} in hub ${hubId} from ${message.senderId}`);

    try {
      // Get hub data
      const hubDoc = await db.collection('hubs').doc(hubId).get();
      if (!hubDoc.exists) return;

      const hubData = hubDoc.data();
      const creatorId = hubData.createdBy;

      // Get all hub admins/managers from subcollection
      const managersSnap = await db.collection('hubs').doc(hubId).collection('members')
        .where('role', 'in', ['admin', 'manager'])
        .get();

      const managerIds = managersSnap.docs.map(doc => doc.id);

      // Add creator if not already in list (creator should be admin, but safe to ensure)
      if (creatorId && !managerIds.includes(creatorId)) {
        managerIds.push(creatorId);
      }

      // ✅ PERFORMANCE FIX: Send notifications in PARALLEL
      const uniqueManagerIds = [...new Set(managerIds)];
      const notificationPromises = uniqueManagerIds.map(async (managerId) => {
        try {
          // Use helper if possible, but here we query tokens directly? 
          // Previous code queried tokens doc directly. Let's stick to that pattern or use getUserFCMTokens?
          // getUserFCMTokens is better if available (imported from utils).
          // Checking utils import in this file... yes, getUserFCMTokens is imported?
          // Let's check imports at top of file. 
          // Line 4: const { db, messaging, FieldValue, getHubMemberIds, getUserFCMTokens } = require('./utils');
          // Yes, it is imported. AND previous code in `onHubMessageCreated` uses it.
          // BUT previous code in `onContactMessageCreated` did NOT use it (lines 306-311).
          // I should verify if I can use getUserFCMTokens here for consistency.

          let userTokens = [];

          // Try helper first (handles subcollection)
          try {
            userTokens = await getUserFCMTokens(managerId);
          } catch (e) {
            console.log(`Failed to get tokens via helper for ${managerId}, trying legacy if needed`, e);
          }

          if (!userTokens || userTokens.length === 0) {
            // Fallback or just return
            return;
          }

          const notification = {
            notification: {
              title: `💬 הודעה חדשה מ-${message.senderName || 'שחקן'}`,
              body: (message.message || '').substring(0, 100),
            },
            tokens: userTokens,
            data: {
              type: 'contact_message',
              hubId: hubId,
              messageId: messageId,
            },
          };

          await messaging.sendEachForMulticast(notification);
          info(`Sent contact message notification to manager ${managerId}`);
        } catch (error) {
          info(`Error sending notification to manager ${managerId}: ${error}`);
        }
      });

      await Promise.all(notificationPromises);
    } catch (error) {
      info(`Error sending contact message notification: ${error}`);
    }
  },
);

exports.onFollowCreated = onDocumentCreated(
  'users/{followedId}/followers/{followerId}',
  async (event) => {
    const follower = event.data.data();
    const followedId = event.params.followedId;
    info(`User ${follower.followerId} started following ${followedId}`);

    try {
      const userRef = db.collection('users').doc(followedId);
      const userSnap = await userRef.get();
      if (!userSnap.exists) return;

      await userRef.update({
        followerCount: FieldValue.increment(1),
      });

      // ✅ Use helper to get FCM tokens
      const tokens = await getUserFCMTokens(followedId);
      if (tokens.length === 0) {
        info('Followed user does not have FCM token. No notification sent.');
        return;
      }

      const payload = {
        notification: {
          title: 'עוקב חדש!',
          body: `${follower.followerName} התחיל לעקוב אחריך.`,
        },
        tokens: tokens,
        data: {
          type: 'new_follower',
          followerId: follower.followerId,
        },
      };

      await messaging.sendEachForMulticast(payload);
      info(`Sent follower notification to user ${followedId}.`);
    } catch (error) {
      info(`Error in onFollowCreated for user ${followedId}:`, error);
    }
  },
);

// --- Sync denormalized author fields when user profile changes ---
exports.onUserUpdatedSyncPosts = onDocumentUpdated(
  'users/{userId}',
  async (event) => {
    const userId = event.params.userId;
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!after) return;

    const beforeName = before?.displayName || before?.name || null;
    const afterName = after.displayName || after.name || null;
    const beforePhoto = before?.photoUrl || null;
    const afterPhoto = after.photoUrl || null;

    if (beforeName === afterName && beforePhoto === afterPhoto) {
      return;
    }

    const updateData = {
      authorName: afterName,
      authorPhotoUrl: afterPhoto,
    };

    const cutoff = Timestamp.fromDate(
      new Date(Date.now() - RECENT_POST_DAYS * 24 * 60 * 60 * 1000),
    );

    try {
      const hubPostsQuery = db
        .collectionGroup('items')
        .where('authorId', '==', userId)
        .where('createdAt', '>=', cutoff)
        .orderBy('createdAt', 'desc')
        .limit(MAX_POSTS_TO_UPDATE);

      const regionalPostsQuery = db
        .collection('feedPosts')
        .where('authorId', '==', userId)
        .where('createdAt', '>=', cutoff)
        .orderBy('createdAt', 'desc')
        .limit(MAX_POSTS_TO_UPDATE);

      const [hubSnap, regionalSnap] = await Promise.all([
        hubPostsQuery.get(),
        regionalPostsQuery.get(),
      ]);

      const [hubUpdated, regionalUpdated] = await Promise.all([
        updatePostsSnapshot(hubSnap, updateData),
        updatePostsSnapshot(regionalSnap, updateData),
      ]);

      info(
        `Synced author fields for user ${userId}: hub posts ${hubUpdated}, regional posts ${regionalUpdated}.`,
      );
    } catch (error) {
      info(`Error syncing posts for user ${userId}:`, error);
    }
  },
);
