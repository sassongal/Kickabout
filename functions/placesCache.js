/**
 * Google Places API Caching Module
 * 
 * Reduces API calls and costs by caching place search results and details
 * 
 * Cache Strategy:
 * - Search results: 5 minutes (places don't change often)
 * - Place details: 1 hour (details are static)
 */

const admin = require('firebase-admin');
const { info } = require('firebase-functions/logger');

// In-memory cache (cleared on function restart)
const searchCache = new Map();
const detailsCache = new Map();

// Cache TTL
const SEARCH_CACHE_TTL = 5 * 60 * 1000; // 5 minutes
const DETAILS_CACHE_TTL = 60 * 60 * 1000; // 1 hour

// Cache size limits
const MAX_SEARCH_CACHE_SIZE = 500;
const MAX_DETAILS_CACHE_SIZE = 1000;

/**
 * Get cached search result
 * @param {string} cacheKey - Cache key (query + lat + lng)
 * @returns {Object|null} Cached result or null
 */
function getCachedSearch(cacheKey) {
  const entry = searchCache.get(cacheKey);
  
  if (!entry) return null;
  
  // Check if expired
  if (Date.now() - entry.timestamp > SEARCH_CACHE_TTL) {
    searchCache.delete(cacheKey);
    return null;
  }
  
  return entry.data;
}

/**
 * Cache search result
 * @param {string} cacheKey - Cache key
 * @param {Object} data - Result data
 */
function cacheSearch(cacheKey, data) {
  // Clean up if cache is full
  if (searchCache.size >= MAX_SEARCH_CACHE_SIZE) {
    // Remove oldest entries (first 100)
    const keysToRemove = Array.from(searchCache.keys()).slice(0, 100);
    keysToRemove.forEach(key => searchCache.delete(key));
  }
  
  searchCache.set(cacheKey, {
    data,
    timestamp: Date.now(),
  });
}

/**
 * Get cached place details
 * @param {string} placeId - Google Places place ID
 * @returns {Object|null} Cached result or null
 */
function getCachedDetails(placeId) {
  const entry = detailsCache.get(placeId);
  
  if (!entry) return null;
  
  // Check if expired
  if (Date.now() - entry.timestamp > DETAILS_CACHE_TTL) {
    detailsCache.delete(placeId);
    return null;
  }
  
  return entry.data;
}

/**
 * Cache place details
 * @param {string} placeId - Google Places place ID
 * @param {Object} data - Details data
 */
function cacheDetails(placeId, data) {
  // Clean up if cache is full
  if (detailsCache.size >= MAX_DETAILS_CACHE_SIZE) {
    // Remove oldest entries (first 200)
    const keysToRemove = Array.from(detailsCache.keys()).slice(0, 200);
    keysToRemove.forEach(key => detailsCache.delete(key));
  }
  
  detailsCache.set(placeId, {
    data,
    timestamp: Date.now(),
  });
}

/**
 * Generate cache key for search
 * @param {string} query - Search query
 * @param {number} lat - Latitude
 * @param {number} lng - Longitude
 * @returns {string} Cache key
 */
function getSearchCacheKey(query, lat, lng) {
  // Round coordinates to 2 decimal places (~1km precision) for better cache hits
  const roundedLat = Math.round(lat * 100) / 100;
  const roundedLng = Math.round(lng * 100) / 100;
  return `${query.toLowerCase()}_${roundedLat}_${roundedLng}`;
}

/**
 * Clear all caches (for testing/debugging)
 */
function clearAllCaches() {
  searchCache.clear();
  detailsCache.clear();
  info('All Places API caches cleared');
}

/**
 * Get cache statistics (for monitoring)
 */
function getCacheStats() {
  return {
    search: {
      size: searchCache.size,
      maxSize: MAX_SEARCH_CACHE_SIZE,
      hitRate: 'N/A', // Would need to track hits/misses
    },
    details: {
      size: detailsCache.size,
      maxSize: MAX_DETAILS_CACHE_SIZE,
      hitRate: 'N/A',
    },
  };
}

module.exports = {
  getCachedSearch,
  cacheSearch,
  getCachedDetails,
  cacheDetails,
  getSearchCacheKey,
  clearAllCaches,
  getCacheStats,
};

