/* eslint-disable max-len */
/**
 * Rate Limiting Module for Kattrick Cloud Functions
 * 
 * Prevents spam and abuse by limiting the number of requests
 * a user can make to specific functions within a time window.
 * 
 * Uses Firestore transactions to ensure accuracy even under
 * concurrent requests.
 */

const admin = require('firebase-admin');
const { HttpsError } = require('firebase-functions/v2/https');
const { info, warn } = require('firebase-functions/logger');

/**
 * Check if user has exceeded rate limit for an action
 * 
 * @param {string} userId - The user's Firebase UID
 * @param {string} action - The action name (e.g., 'searchVenues')
 * @param {number} maxRequests - Maximum requests allowed
 * @param {number} windowMinutes - Time window in minutes
 * @returns {Promise<void>}
 * @throws {HttpsError} If rate limit exceeded
 * 
 * @example
 * await checkRateLimit(userId, 'searchVenues', 10, 1); // 10 requests per minute
 */
async function checkRateLimit(userId, action, maxRequests, windowMinutes = 1) {
  const now = Date.now();
  const windowStart = now - (windowMinutes * 60 * 1000);
  
  const rateLimitRef = admin.firestore()
    .collection('_rate_limits')
    .doc(userId)
    .collection('actions')
    .doc(action);
  
  try {
    await admin.firestore().runTransaction(async (transaction) => {
      const doc = await transaction.get(rateLimitRef);
      const data = doc.exists ? doc.data() : { requests: [] };
      
      // Filter out requests outside the time window
      const recentRequests = (data.requests || [])
        .filter(ts => ts > windowStart);
      
      // Check if limit exceeded
      if (recentRequests.length >= maxRequests) {
        // Log rate limit hit
        warn('Rate limit exceeded', {
          userId,
          action,
          requestCount: recentRequests.length,
          maxRequests,
          windowMinutes,
          timestamp: new Date().toISOString(),
        });
        
        throw new HttpsError(
          'resource-exhausted',
          `יותר מדי בקשות. נסה שוב בעוד ${windowMinutes} ${windowMinutes === 1 ? 'דקה' : 'דקות'}.`
        );
      }
      
      // Add current request
      recentRequests.push(now);
      
      // Keep only recent requests (prevent array from growing indefinitely)
      const cleanRequests = recentRequests.slice(-maxRequests * 2);
      
      // Update Firestore
      transaction.set(rateLimitRef, {
        requests: cleanRequests,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        action: action,
        userId: userId,
      }, { merge: true });
      
      // Log every 5th request to monitor usage (reduce log spam)
      if (recentRequests.length % 5 === 0) {
        info('Rate limit check', {
          userId,
          action,
          requestCount: recentRequests.length,
          maxRequests,
          percentUsed: Math.round((recentRequests.length / maxRequests) * 100),
        });
      }
    });
  } catch (error) {
    if (error instanceof HttpsError) {
      // Re-throw rate limit errors
      throw error;
    }
    
    // Log other errors but don't block user (fail-open strategy)
    // This ensures rate limiting system failures don't break the app
    warn('Rate limit system error (failing open)', {
      error: error.message,
      userId,
      action,
    });
    
    // Allow request to proceed
    return;
  }
}

/**
 * Reset rate limit for a user action (useful for testing)
 * 
 * @param {string} userId - The user's Firebase UID
 * @param {string} action - The action name
 * @returns {Promise<void>}
 */
async function resetRateLimit(userId, action) {
  const rateLimitRef = admin.firestore()
    .collection('_rate_limits')
    .doc(userId)
    .collection('actions')
    .doc(action);
  
  await rateLimitRef.delete();
  
  info('Rate limit reset', { userId, action });
}

/**
 * Get rate limit status for a user action
 * 
 * @param {string} userId - The user's Firebase UID
 * @param {string} action - The action name
 * @param {number} maxRequests - Maximum requests allowed
 * @param {number} windowMinutes - Time window in minutes
 * @returns {Promise<{count: number, remaining: number, resetAt: Date}>}
 */
async function getRateLimitStatus(userId, action, maxRequests, windowMinutes = 1) {
  const now = Date.now();
  const windowStart = now - (windowMinutes * 60 * 1000);
  
  const rateLimitRef = admin.firestore()
    .collection('_rate_limits')
    .doc(userId)
    .collection('actions')
    .doc(action);
  
  const doc = await rateLimitRef.get();
  
  if (!doc.exists) {
    return {
      count: 0,
      remaining: maxRequests,
      resetAt: new Date(now + windowMinutes * 60 * 1000),
    };
  }
  
  const data = doc.data();
  const recentRequests = (data.requests || [])
    .filter(ts => ts > windowStart);
  
  // Find oldest request to calculate reset time
  const oldestRequest = recentRequests.length > 0 
    ? Math.min(...recentRequests)
    : now;
  
  return {
    count: recentRequests.length,
    remaining: Math.max(0, maxRequests - recentRequests.length),
    resetAt: new Date(oldestRequest + windowMinutes * 60 * 1000),
  };
}

module.exports = {
  checkRateLimit,
  resetRateLimit,
  getRateLimitStatus,
};

