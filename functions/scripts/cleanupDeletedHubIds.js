/**
 * Remove deleted hub IDs from a user's hubIds array.
 *
 * Usage:
 *   node cleanupDeletedHubIds.js <USER_ID>
 */
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

async function cleanup(userId) {
  const userRef = db.collection('users').doc(userId);
  const userDoc = await userRef.get();
  if (!userDoc.exists) {
    console.error(`User ${userId} not found`);
    return;
  }

  const data = userDoc.data() || {};
  const hubIds = Array.isArray(data.hubIds) ? data.hubIds : [];
  if (hubIds.length === 0) {
    console.log(`User ${userId} has no hubIds. Nothing to clean.`);
    return;
  }

  const missing = [];
  for (const hubId of hubIds) {
    const hubDoc = await db.collection('hubs').doc(hubId).get();
    if (!hubDoc.exists) {
      missing.push(hubId);
    }
  }

  if (missing.length === 0) {
    console.log(`All hubIds are valid for user ${userId}. No cleanup needed.`);
    return;
  }

  await userRef.update({
    hubIds: admin.firestore.FieldValue.arrayRemove(...missing),
  });

  console.log(
    `Removed ${missing.length} deleted hub IDs from user ${userId}: ${missing.join(
      ', ',
    )}`,
  );
}

const userId = process.argv[2];
if (!userId) {
  console.error('Usage: node cleanupDeletedHubIds.js <USER_ID>');
  process.exit(1);
}

cleanup(userId)
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
