/* eslint-disable max-len */
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');
const { info } = require('firebase-functions/logger');
const { defineSecret } = require('firebase-functions/params');

// Initialize Firebase Admin SDK
initializeApp();
const db = getFirestore();
const messaging = getMessaging();
const admin = { auth: getAuth() };
const storage = getStorage();

// Define secret for Google APIs key (server-side only)
const googleApisKey = defineSecret('GOOGLE_APIS_KEY');

// Google Places API URL
const PLACES_API_URL = 'https://maps.googleapis.com/maps/api/place';

// Image processing library (sharp)
let sharp;
try {
  sharp = require('sharp');
} catch (e) {
  info('Warning: sharp not installed. Image resizing will be disabled.');
  info('Install with: npm install sharp');
}

/**
 * Get hub member IDs from subcollection
 * @param {string} hubId - Hub ID
 * @param {number} limit - Maximum number of members to fetch
 * @return {Promise<string[]>} Array of user IDs
 */
async function getHubMemberIds(hubId, limit = 500) {
  const snap = await db
    .collection('hubs')
    .doc(hubId)
    .collection('members')
    .limit(limit)
    .get();
  return snap.docs.map((d) => d.id);
}

/**
 * Get FCM tokens for a user (unified method)
 * Supports both new subcollection structure and old fcmToken field (with auto-migration)
 * @param {string} userId - User ID
 * @return {Promise<string[]>} Array of FCM tokens
 */
async function getUserFCMTokens(userId) {
  try {
    // Try new subcollection structure first
    const tokenDoc = await db
      .collection('users')
      .doc(userId)
      .collection('fcm_tokens')
      .doc('tokens')
      .get();

    if (tokenDoc.exists) {
      const tokenData = tokenDoc.data();
      const tokens = tokenData?.tokens || [];
      if (Array.isArray(tokens) && tokens.length > 0) {
        return tokens;
      }
    }

    // FALLBACK: Check old fcmToken field (for migration period)
    const userDoc = await db.collection('users').doc(userId).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      if (userData?.fcmToken && typeof userData.fcmToken === 'string') {
        // Migrate old token to new structure (async, non-blocking)
        migrateOldFCMToken(userId, userData.fcmToken).catch((err) => {
          info(`Failed to migrate FCM token for user ${userId}: ${err}`);
        });
        return [userData.fcmToken];
      }
    }

    return [];
  } catch (error) {
    info(`Failed to get FCM tokens for user ${userId}: ${error}`);
    return [];
  }
}

/**
 * Migrate old fcmToken to new subcollection structure
 * @param {string} userId - User ID
 * @param {string} oldToken - Old token string
 * @return {Promise<void>}
 */
async function migrateOldFCMToken(userId, oldToken) {
  try {
    const tokenRef = db
      .collection('users')
      .doc(userId)
      .collection('fcm_tokens')
      .doc('tokens');

    const tokenDoc = await tokenRef.get();

    if (tokenDoc.exists) {
      // Add to existing tokens array
      const tokenData = tokenDoc.data();
      const existingTokens = tokenData?.tokens || [];
      if (!existingTokens.includes(oldToken)) {
        await tokenRef.update({
          tokens: FieldValue.arrayUnion(oldToken),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    } else {
      // Create new tokens document
      await tokenRef.set({
        tokens: [oldToken],
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // Remove old field (non-blocking)
    db.collection('users').doc(userId).update({
      fcmToken: FieldValue.delete(),
    }).catch((err) => {
      info(`Failed to remove old fcmToken for user ${userId}: ${err}`);
    });

    info(`Migrated FCM token for user ${userId}`);
  } catch (error) {
    info(`Failed to migrate FCM token for user ${userId}: ${error}`);
  }
}

/**
 * Determine venue type based on name, types, and address
 * @param {Object} place - Google Places API place object
 * @return {string} 'public', 'rental', 'school', or 'unknown'
 */
function determineVenueType(place) {
  const name = (place.name || '').toLowerCase();
  const address = (place.formatted_address || '').toLowerCase();
  const types = (place.types || []).map((t) => t.toLowerCase());
  const vicinity = (place.vicinity || '').toLowerCase();

  const allText = `${name} ${address} ${vicinity}`.toLowerCase();

  // Keywords for public venues
  const publicKeywords = [
    'ציבורי', 'public', 'פארק', 'park', 'גן', 'גן ציבורי',
    'municipal', 'עירוני', 'רשות', 'municipality',
  ];

  // Keywords for rental venues
  const rentalKeywords = [
    'השכרה', 'rental', 'rent', 'שכירות', 'להשכרה',
    'rentals', 'renting', 'lease', 'leasing',
  ];

  // Keywords for school venues
  const schoolKeywords = [
    'בית ספר', 'school', 'תיכון', 'יסודי', 'גן ילדים',
    'high school', 'elementary', 'kindergarten', 'בית ספר יסודי',
    'בית ספר תיכון', 'מגרש בית ספר',
  ];

  // Check for school first (most specific)
  if (schoolKeywords.some((keyword) => allText.includes(keyword)) ||
    types.includes('school') || types.includes('primary_school')) {
    return 'school';
  }

  // Check for rental
  if (rentalKeywords.some((keyword) => allText.includes(keyword))) {
    return 'rental';
  }

  // Check for public (default for parks, municipal facilities)
  if (publicKeywords.some((keyword) => allText.includes(keyword)) ||
    types.includes('park') || types.includes('stadium') ||
    types.includes('sports_complex')) {
    return 'public';
  }

  // Default: if it's a stadium or sports complex, assume public
  if (types.includes('stadium') || types.includes('sports_complex') ||
    types.includes('gym') || types.includes('establishment')) {
    return 'public';
  }

  return 'unknown';
}

/**
 * Generate Vibe message based on weather and AQI
 * @param {number} temp - Temperature in Celsius
 * @param {string} condition - Weather condition (clear, cloudy, rain, etc.)
 * @param {number} aqi - Air Quality Index (0-300+)
 * @return {string} Vibe message in Hebrew
 */
function getVibeMessage(temp, condition, aqi) {
  // AQI categories: 0-50 (Good), 51-100 (Moderate), 101-150 (Unhealthy for Sensitive), 151+ (Unhealthy)
  // Temperature: ideal for football is 15-25°C
  // Condition: clear, cloudy, rain, etc.

  // Normalize condition code
  const conditionLower = condition ? condition.toLowerCase() : 'clear';
  const isClear = conditionLower === 'clear' || conditionLower.includes('clear');
  const isPartlyCloudy = conditionLower === 'partly_cloudy' ||
    conditionLower.includes('partly') ||
    conditionLower.includes('partially');

  // Perfect conditions
  if (aqi <= 50 && temp >= 15 && temp <= 25 && isClear) {
    return 'יום פנטסטי לכדורגל! מזג אוויר מושלם ואוויר נקי.';
  }

  // Great conditions
  if (aqi <= 50 && temp >= 12 && temp <= 28 && (isClear || isPartlyCloudy)) {
    return 'יום מעולה למשחק! תנאים מצוינים.';
  }

  // Good but not perfect
  if (aqi <= 100 && temp >= 10 && temp <= 30) {
    // Handle various condition codes from Google Weather API
    const conditionLower = condition ? condition.toLowerCase() : 'clear';
    if (conditionLower.includes('rain') || conditionLower.includes('drizzle') ||
      conditionLower === 'rain' || conditionLower === 'drizzle') {
      return 'יום גשום, אבל כדורגל זה תמיד כיף! 🌧️';
    }
    if (conditionLower.includes('cloud') || conditionLower === 'cloudy' ||
      conditionLower === 'partly_cloudy') {
      return 'יום מעונן אבל נעים למשחק.';
    }
    return 'יום טוב לכדורגל!';
  }

  // Air quality concerns
  if (aqi > 100) {
    if (aqi > 150) {
      return '⚠️ איכות אוויר לא טובה היום. שקול לשחק במקום סגור או לדחות.';
    }
    return 'איכות אוויר בינונית. אם אתה רגיש, שקול להיזהר.';
  }

  // Temperature extremes
  if (temp < 10) {
    return 'יום קר למשחק. הקפד להתחמם היטב! 🥶';
  }
  if (temp > 30) {
    return 'יום חם מאוד! הקפד לשתות הרבה מים ולהקפיד על הפסקות. ☀️';
  }

  // Default fallback
  return 'יום טוב לכדורגל!';
}

module.exports = {
  db,
  messaging,
  admin,
  storage,
  googleApisKey,
  FieldValue,
  getHubMemberIds,
  determineVenueType,
  getVibeMessage,
  PLACES_API_URL,
  sharp,
  getUserFCMTokens,
  migrateOldFCMToken,
};

