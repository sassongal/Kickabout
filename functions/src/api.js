/* eslint-disable max-len */
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { info } = require('firebase-functions/logger');
const axios = require('axios');
const { db, googleApisKey, PLACES_API_URL, determineVenueType, getVibeMessage } = require('./utils');
const { checkRateLimit } = require('../rateLimit');
const {
  getCachedSearch,
  cacheSearch,
  getCachedDetails,
  cacheDetails,
  getSearchCacheKey,
} = require('../placesCache');

exports.searchVenues = onCall(
  {
    secrets: [googleApisKey],
    invoker: 'public', // ✅ Changed from 'authenticated' to allow Firebase Auth users
    region: 'us-central1', // ✅ Add region explicitly
    memory: '256MiB', // ✅ Optimized: Reduced from 512MB
  },
  async (request) => {
    // Validate authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }

    // ✅ Rate limit: 10 requests per minute
    await checkRateLimit(request.auth.uid, 'searchVenues', 10, 1);

    const { query, lat, lng } = request.data;
    if (!query) {
      throw new HttpsError('invalid-argument', 'Missing \'query\' parameter.');
    }

    // ✅ Check cache first
    const cacheKey = getSearchCacheKey(query, lat || 0, lng || 0);
    const cachedResult = getCachedSearch(cacheKey);
    if (cachedResult) {
      info(`Cache hit for search: ${query}`);
      return cachedResult;
    }

    const apiKey = googleApisKey.value();
    if (!apiKey) {
      throw new HttpsError(
        'failed-precondition',
        'GOOGLE_APIS_KEY is not set.',
      );
    }

    let url = `${PLACES_API_URL}/textsearch/json?query=${encodeURIComponent(
      query,
    )}&key=${apiKey}&language=iw`;
    if (lat && lng) {
      url += `&location=${lat},${lng}&radius=5000`; // 5km radius
    }

    try {
      const response = await axios.get(url);

      // Check for Google Places API errors
      if (response.data && response.data.error_message) {
        const errorMsg = response.data.error_message;
        info(`Google Places API error: ${errorMsg}`);

        // Check for REQUEST_DENIED error
        if (response.data.status === 'REQUEST_DENIED') {
          throw new HttpsError(
            'failed-precondition',
            'Google Places API error: REQUEST_DENIED. Please check API key configuration.',
          );
        }

        throw new HttpsError('internal', `Google Places API error: ${errorMsg}`);
      }

      const data = response.data;

      // Add venueType to each result
      if (data.results && Array.isArray(data.results)) {
        data.results = data.results.map((place) => {
          const venueType = determineVenueType(place);
          return {
            ...place,
            venueType: venueType,
          };
        });
      }

      // ✅ Cache the result
      cacheSearch(cacheKey, data);

      return data;
    } catch (error) {
      // Handle axios errors
      if (error.response && error.response.data) {
        const apiError = error.response.data;
        if (apiError.error_message) {
          info(`Google Places API error: ${apiError.error_message}`);
          if (apiError.status === 'REQUEST_DENIED') {
            throw new HttpsError(
              'failed-precondition',
              'Google Places API error: REQUEST_DENIED. Please check API key configuration and billing.',
            );
          }
        }
      }
      // Re-throw HttpsError as-is
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', 'Failed to call Google Places API.', error);
    }
  },
);

exports.getPlaceDetails = onCall(
  {
    secrets: [googleApisKey],
    invoker: 'public', // ✅ Changed from 'authenticated' to allow Firebase Auth users
    memory: '256MiB', // ✅ Optimized: Reduced from 512MB
  },
  async (request) => {
    // Validate authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }

    // ✅ Rate limit: 20 requests per minute
    await checkRateLimit(request.auth.uid, 'getPlaceDetails', 20, 1);

    const { placeId } = request.data;
    if (!placeId) {
      throw new HttpsError('invalid-argument', 'Missing \'placeId\' parameter.');
    }

    // ✅ Check cache first
    const cachedDetails = getCachedDetails(placeId);
    if (cachedDetails) {
      info(`Cache hit for place details: ${placeId}`);
      return cachedDetails;
    }

    const apiKey = googleApisKey.value();
    if (!apiKey) {
      throw new HttpsError(
        'failed-precondition',
        'GOOGLE_APIS_KEY is not set.',
      );
    }

    const url = `${PLACES_API_URL}/details/json?place_id=${placeId}&key=${apiKey}&language=iw&fields=place_id,name,formatted_address,geometry,photos,formatted_phone_number`;

    try {
      const response = await axios.get(url);
      const data = response.data;

      // ✅ Cache the result
      cacheDetails(placeId, data);

      return data;
    } catch (error) {
      throw new HttpsError('internal', 'Failed to call Google Places API.', error);
    }
  },
);

// --- Get Hubs for Place Function ---
/**
 * Find all hubs that use a specific venue (identified by Google placeId)
 * @param {string} placeId - Google Places API place_id
 * @return {Array} Array of hub objects with hubId, name, and logoUrl
 */
exports.getHubsForPlace = onCall(
  {
    secrets: [googleApisKey],
    invoker: 'public', // ✅ Changed from 'authenticated' to allow Firebase Auth users
    memory: '256MiB', // ✅ Optimized: Reduced from 512MB
  },
  async (request) => {
    // Validate authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }

    // ✅ Rate limit: 15 requests per minute
    await checkRateLimit(request.auth.uid, 'getHubsForPlace', 15, 1);

    const { placeId } = request.data;
    if (!placeId) {
      throw new HttpsError('invalid-argument', 'Missing \'placeId\' parameter.');
    }

    try {
      // 1. Find our internal venue doc using the Google placeId
      const venuesSnapshot = await db.collection('venues')
        .where('googlePlaceId', '==', placeId) // Venue model uses googlePlaceId, not placeId
        .limit(1)
        .get();

      if (venuesSnapshot.empty) {
        // No hubs are using this venue (because we don't even have it saved)
        return [];
      }

      const venueDoc = venuesSnapshot.docs[0];
      const ourVenueId = venueDoc.id;

      // 2. Find all hubs that use this internal venueId
      const hubsSnapshot = await db.collection('hubs')
        .where('venueIds', 'array-contains', ourVenueId)
        .get();

      if (hubsSnapshot.empty) {
        return [];
      }

      // 3. Return a light version of the hubs
      const hubs = hubsSnapshot.docs.map((doc) => ({
        hubId: doc.id,
        name: doc.data().name,
        logoUrl: doc.data().logoUrl || null,
      }));

      return hubs;
    } catch (error) {
      info(`Error finding hubs for placeId ${placeId}:`, error);
      throw new HttpsError('internal', 'Failed to find hubs for this venue.');
    }
  },
);

// Home Dashboard Data Function
// Returns weather and vibe data for the home screen
exports.getHomeDashboardData = onCall(
  {
    secrets: [googleApisKey],
    invoker: 'public', // ✅ Changed from 'authenticated' to allow Firebase Auth users
    memory: '256MiB', // ✅ Optimized: Reduced from 512MB
  },
  async (request) => {
    // Validate authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }

    // ✅ Rate limit: 5 requests per minute
    await checkRateLimit(request.auth.uid, 'getHomeDashboardData', 5, 1);

    const { lat, lon } = request.data;

    // Validate input
    if (lat === undefined || lon === undefined) {
      throw new HttpsError(
        'invalid-argument',
        'Missing \'lat\' or \'lon\' parameter.',
      );
    }

    info(`Getting home dashboard data for location: ${lat}, ${lon}`);

    try {
      const apiKey = googleApisKey.value();

      if (!apiKey) {
        throw new HttpsError(
          'failed-precondition',
          'GOOGLE_APIS_KEY is not set. Please configure it as a Firebase Secret.',
        );
      }

      // 1. Call Google Weather API
      const weatherUrl = `https://weather.googleapis.com/v1/currentConditions:lookup?key=${apiKey}`;

      let weatherData;
      let temperature = null;
      let conditionCode = 'clear';

      try {
        const weatherResponse = await axios.post(weatherUrl, {
          location: {
            latitude: lat,
            longitude: lon,
          },
          languageCode: 'iw',
        });

        if (weatherResponse.data && weatherResponse.data.currentConditions) {
          weatherData = weatherResponse.data.currentConditions;
          // Temperature might be in different units, convert to Celsius if needed
          temperature = weatherData.temperature;
          if (weatherData.temperatureUnit === 'FAHRENHEIT') {
            temperature = (temperature - 32) * 5 / 9;
          }
          // conditionCode might be in different formats, normalize it
          conditionCode = weatherData.conditionCode || weatherData.condition || 'clear';
        } else {
          info('Weather API returned unexpected format, using defaults');
        }
      } catch (weatherError) {
        info(`Error calling Weather API: ${weatherError.message}`);
        // Fallback to default values if API fails
        temperature = 22;
        conditionCode = 'clear';
      }

      // 2. Call Google Air Quality API
      const aqiUrl = `https://airquality.googleapis.com/v1/currentConditions:lookup?key=${apiKey}`;

      let aqiIndex = 40; // Default to good air quality

      try {
        const aqiResponse = await axios.post(aqiUrl, {
          location: {
            latitude: lat,
            longitude: lon,
          },
        });

        if (aqiResponse.data && aqiResponse.data.indexes && aqiResponse.data.indexes.length > 0) {
          // Get the main AQI index (usually the first one)
          const mainIndex = aqiResponse.data.indexes[0];
          aqiIndex = mainIndex.aqi || mainIndex.index || 40;
        } else {
          info('Air Quality API returned unexpected format, using default');
        }
      } catch (aqiError) {
        info(`Error calling Air Quality API: ${aqiError.message}`);
        // Fallback to default value if API fails
        aqiIndex = 40;
      }

      // 3. Generate vibe message using the helper function with real data
      const vibeMessage = getVibeMessage(
        temperature || 22,
        conditionCode,
        aqiIndex,
      );

      // 4. Return real data to the app
      return {
        vibeMessage: vibeMessage,
        temperature: temperature ? Math.round(temperature) : null,
        condition: conditionCode,
        aqiIndex: aqiIndex,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      info(`Error in getHomeDashboardData:`, error);
      // Return default values on error instead of throwing
      // This ensures the app still works even if APIs fail
      return {
        vibeMessage: 'יום טוב לכדורגל! ☀️',
        temperature: null,
        condition: 'clear',
        aqiIndex: null,
        timestamp: new Date().toISOString(),
      };
    }
  },
);

