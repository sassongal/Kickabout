#!/usr/bin/env node
/**
 * Backfill missing authorName/authorPhotoUrl on feed posts.
 *
 * Usage:
 *   cd functions
 *   node scripts/backfillFeedPostAuthors.js
 */

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldPath } = require('firebase-admin/firestore');

initializeApp({
  projectId: 'kickabout-ddc06',
});

const db = getFirestore();

const PAGE_SIZE = 300;
const BATCH_LIMIT = 450;
const userCache = new Map();

async function getAuthorData(userId) {
  if (userCache.has(userId)) return userCache.get(userId);

  const userDoc = await db.collection('users').doc(userId).get();
  if (!userDoc.exists) {
    userCache.set(userId, null);
    return null;
  }

  const data = userDoc.data();
  const authorName = data.displayName || data.name || null;
  const authorPhotoUrl = data.photoUrl || null;
  const payload = { authorName, authorPhotoUrl };

  userCache.set(userId, payload);
  return payload;
}

async function processSnapshot(snapshot) {
  let batch = db.batch();
  let processed = 0;
  let updated = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const authorId = data.authorId;

    if (!authorId) continue;

    const authorData = await getAuthorData(authorId);
    if (!authorData) continue;

    const updateData = {};
    if (!data.authorName && authorData.authorName) {
      updateData.authorName = authorData.authorName;
    }
    if (!data.authorPhotoUrl && authorData.authorPhotoUrl) {
      updateData.authorPhotoUrl = authorData.authorPhotoUrl;
    }

    if (Object.keys(updateData).length === 0) continue;

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

async function backfillMissingField(query, label) {
  let lastDoc = null;
  let totalUpdated = 0;
  let page = 0;

  while (true) {
    let pageQuery = query.orderBy(FieldPath.documentId()).limit(PAGE_SIZE);
    if (lastDoc) {
      pageQuery = pageQuery.startAfter(lastDoc);
    }

    const snapshot = await pageQuery.get();
    if (snapshot.empty) break;

    const updated = await processSnapshot(snapshot);
    totalUpdated += updated;
    page += 1;
    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    console.log(
      `📄 ${label}: page ${page} processed (${snapshot.size}), updated ${updated}`,
    );
  }

  return totalUpdated;
}

async function runBackfill() {
  try {
    console.log('🚀 Backfilling feed posts author fields...');

    const hubPostsAuthorNameQuery = db
      .collectionGroup('items')
      .where('authorName', '==', null);
    const hubPostsAuthorPhotoQuery = db
      .collectionGroup('items')
      .where('authorPhotoUrl', '==', null);
    const regionalAuthorNameQuery = db
      .collection('feedPosts')
      .where('authorName', '==', null);
    const regionalAuthorPhotoQuery = db
      .collection('feedPosts')
      .where('authorPhotoUrl', '==', null);

    const hubNameUpdated = await backfillMissingField(
      hubPostsAuthorNameQuery,
      'Hub feed (authorName)',
    );
    const hubPhotoUpdated = await backfillMissingField(
      hubPostsAuthorPhotoQuery,
      'Hub feed (authorPhotoUrl)',
    );
    const regionalNameUpdated = await backfillMissingField(
      regionalAuthorNameQuery,
      'Regional feed (authorName)',
    );
    const regionalPhotoUpdated = await backfillMissingField(
      regionalAuthorPhotoQuery,
      'Regional feed (authorPhotoUrl)',
    );

    console.log('\n✅ Backfill complete');
    console.log(`Hub feed authorName updated: ${hubNameUpdated}`);
    console.log(`Hub feed authorPhotoUrl updated: ${hubPhotoUpdated}`);
    console.log(`Regional feed authorName updated: ${regionalNameUpdated}`);
    console.log(`Regional feed authorPhotoUrl updated: ${regionalPhotoUpdated}`);
  } catch (error) {
    console.error('❌ Backfill failed:', error);
    process.exit(1);
  }
}

runBackfill()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('💥 Fatal error:', error);
    process.exit(1);
  });
