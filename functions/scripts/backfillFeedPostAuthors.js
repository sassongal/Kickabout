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

async function fetchAuthors(userIds) {
  const authorMap = new Map();
  const idsToFetch = userIds.filter((id) => !userCache.has(id));

  for (let i = 0; i < idsToFetch.length; i += 50) {
    const chunk = idsToFetch.slice(i, i + 50);
    const results = await Promise.all(chunk.map((id) => getAuthorData(id)));
    chunk.forEach((id, idx) => {
      authorMap.set(id, results[idx]);
    });
  }

  // Include cached entries
  userIds.forEach((id) => {
    if (userCache.has(id)) {
      authorMap.set(id, userCache.get(id));
    }
  });

  return authorMap;
}

async function processSnapshot(snapshot, processedDocs) {
  let batch = db.batch();
  let processedInBatch = 0;
  let updated = 0;

  const docsNeedingUpdate = [];
  const authorIds = new Set();

  for (const doc of snapshot.docs) {
    if (processedDocs?.has(doc.ref.path)) continue;
    const data = doc.data();
    const authorId = data.authorId;
    if (!authorId) continue;
    if (!data.authorName || !data.authorPhotoUrl) {
      docsNeedingUpdate.push({ doc, data });
      authorIds.add(authorId);
    }
    processedDocs?.add(doc.ref.path);
  }

  if (docsNeedingUpdate.length === 0) return 0;

  const authorMap = await fetchAuthors([...authorIds]);

  for (const { doc, data } of docsNeedingUpdate) {
    const authorData = authorMap.get(data.authorId);
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
    processedInBatch += 1;
    updated += 1;

    if (processedInBatch >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      processedInBatch = 0;
    }
  }

  if (processedInBatch > 0) {
    await batch.commit();
  }

  return updated;
}

async function backfillMissingField(query, label, processedDocs) {
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

    const updated = await processSnapshot(snapshot, processedDocs);
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
    const processedDocs = new Set();

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
      processedDocs,
    );
    const hubPhotoUpdated = await backfillMissingField(
      hubPostsAuthorPhotoQuery,
      'Hub feed (authorPhotoUrl)',
      processedDocs,
    );
    const regionalNameUpdated = await backfillMissingField(
      regionalAuthorNameQuery,
      'Regional feed (authorName)',
      processedDocs,
    );
    const regionalPhotoUpdated = await backfillMissingField(
      regionalAuthorPhotoQuery,
      'Regional feed (authorPhotoUrl)',
      processedDocs,
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
