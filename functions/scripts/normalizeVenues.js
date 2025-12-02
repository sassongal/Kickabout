#!/usr/bin/env node
/**
 * Script to normalize all venues in the database
 * 
 * This script:
 * 1. Assigns venueId to all venues that don't have one
 * 2. Normalizes all venue data fields according to the Dart _normalizeVenueData logic
 * 3. Generates geohash for venues missing it
 * 4. Fixes data type issues and sets default values
 * 
 * Usage:
 *   node scripts/normalizeVenues.js
 */

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');

// Initialize Firebase Admin SDK
initializeApp({
  projectId: 'kickabout-ddc06',
});
const db = getFirestore();

// Geohash implementation (translated from Dart)
const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';
const BITS = [16, 8, 4, 2, 1];

function encodeGeohash(latitude, longitude, precision = 8) {
  let latMin = -90.0, latMax = 90.0;
  let lonMin = -180.0, lonMax = 180.0;
  let even = true;
  let bit = 0;
  let ch = 0;
  let geohash = '';

  while (geohash.length < precision) {
    if (even) {
      const mid = (lonMin + lonMax) / 2;
      if (longitude >= mid) {
        ch |= BITS[bit];
        lonMin = mid;
      } else {
        lonMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (latitude >= mid) {
        ch |= BITS[bit];
        latMin = mid;
      } else {
        latMax = mid;
      }
    }

    even = !even;
    if (bit < 4) {
      bit++;
    } else {
      geohash += BASE32[ch];
      bit = 0;
      ch = 0;
    }
  }

  return geohash;
}

// Helper functions for normalization
function normalizeStringField(data, key, defaultValue, allowedValues = null) {
  if (!(key in data) || data[key] == null) {
    return defaultValue;
  }
  const value = data[key];
  if (typeof value !== 'string') {
    return defaultValue;
  }
  if (value === '') {
    return defaultValue;
  }
  if (allowedValues && !allowedValues.includes(value)) {
    console.log(`⚠️  Invalid value for ${key}: ${value}, using default: ${defaultValue}`);
    return defaultValue;
  }
  return value;
}

function normalizeOptionalString(data, key) {
  if (!(key in data) || data[key] == null) {
    return null;
  }
  const value = data[key];
  if (typeof value !== 'string') {
    return null;
  }
  return value === '' ? null : value;
}

function normalizeListField(data, key, defaultValue) {
  if (!(key in data) || data[key] == null) {
    return defaultValue;
  }
  const value = data[key];
  if (!Array.isArray(value)) {
    return defaultValue;
  }
  try {
    return value;
  } catch (e) {
    console.log(`⚠️  Could not convert ${key} to List: ${e}`);
    return defaultValue;
  }
}

function normalizeIntField(data, key, defaultValue, min = null, max = null) {
  if (!(key in data) || data[key] == null) {
    return defaultValue;
  }
  let value = data[key];
  if (typeof value !== 'number') {
    return defaultValue;
  }
  // Convert to int
  value = Math.round(value);
  if (min !== null && value < min) {
    return min;
  }
  if (max !== null && value > max) {
    return max;
  }
  return value;
}

function normalizeBoolField(data, key, defaultValue) {
  if (!(key in data) || data[key] == null) {
    return defaultValue;
  }
  const value = data[key];
  if (typeof value !== 'boolean') {
    return defaultValue;
  }
  return value;
}

function normalizeDateTimeField(data, key, fallbackToNow = false) {
  if (!(key in data) || data[key] == null) {
    if (fallbackToNow) {
      return FieldValue.serverTimestamp();
    }
    throw new Error(`Missing required field: ${key}`);
  }
  const value = data[key];
  
  // If it's already a Firestore Timestamp, keep it
  if (value && typeof value.toDate === 'function') {
    return value;
  }
  
  // If it's a Date object, convert to Timestamp
  if (value instanceof Date) {
    return Timestamp.fromDate(value);
  }
  
  // If it's a string, try to parse it
  if (typeof value === 'string') {
    try {
      let date;
      // Try ISO format first
      if (value.includes('T') || value.includes('Z')) {
        // Handle timezone issues
        if (value.includes('T') && !value.includes('Z') && !value.includes('+') && !value.includes('-', 10)) {
          date = new Date(value + 'Z');
        } else {
          date = new Date(value);
        }
      } else if (value.includes(' ')) {
        // Try format: "2025-11-29 02:57:49.459"
        const isoString = value.replace(' ', 'T');
        date = new Date(isoString + 'Z');
      } else {
        date = new Date(value);
      }
      
      // Convert Date to Firestore Timestamp
      return Timestamp.fromDate(date);
    } catch (e) {
      console.log(`⚠️  Could not parse DateTime string "${value}" for field ${key}: ${e}`);
      if (fallbackToNow) {
        return FieldValue.serverTimestamp();
      }
      throw new Error(`Invalid DateTime string format for field: ${key} (value: ${value})`);
    }
  }
  
  // If it's a number (milliseconds since epoch)
  if (typeof value === 'number') {
    try {
      return Timestamp.fromMillis(value);
    } catch (e) {
      console.log(`⚠️  Could not parse DateTime from milliseconds ${value} for field ${key}: ${e}`);
      if (fallbackToNow) {
        return FieldValue.serverTimestamp();
      }
      throw new Error(`Invalid DateTime milliseconds for field: ${key}`);
    }
  }
  
  // Fallback
  if (fallbackToNow) {
    console.log(`⚠️  Unknown DateTime format for field ${key}: ${typeof value}, using serverTimestamp()`);
    return FieldValue.serverTimestamp();
  }
  throw new Error(`Invalid DateTime format for field: ${key} (type: ${typeof value})`);
}

// Main normalization function (translated from Dart _normalizeVenueData)
function normalizeVenueData(data, venueId) {
  const normalized = { ...data, venueId: venueId };

  // Required String fields
  normalized.hubId = normalizeStringField(data, 'hubId', '');
  normalized.name = normalizeStringField(data, 'name', 'מגרש ללא שם');

  // Optional String fields
  normalized.description = normalizeOptionalString(data, 'description');
  normalized.address = normalizeOptionalString(data, 'address');
  normalized.googlePlaceId = normalizeOptionalString(data, 'googlePlaceId');
  normalized.externalId = normalizeOptionalString(data, 'externalId');
  normalized.createdBy = normalizeOptionalString(data, 'createdBy');

  // List fields
  normalized.amenities = normalizeListField(data, 'amenities', []);

  // String with defaults and allowed values
  normalized.surfaceType = normalizeStringField(
    data,
    'surfaceType',
    'grass',
    ['grass', 'artificial', 'concrete', 'unknown']
  );
  normalized.source = normalizeStringField(
    data,
    'source',
    'manual',
    ['manual', 'osm', 'google']
  );

  // Int fields with defaults
  normalized.maxPlayers = normalizeIntField(data, 'maxPlayers', 11, 5, 22);
  normalized.hubCount = normalizeIntField(data, 'hubCount', 0, 0);
  // venueNumber will be assigned later in the script, but we normalize it here
  normalized.venueNumber = normalizeIntField(data, 'venueNumber', 0, 0);

  // Bool fields with defaults
  normalized.isActive = normalizeBoolField(data, 'isActive', true);
  normalized.isMain = normalizeBoolField(data, 'isMain', false);
  normalized.isPublic = normalizeBoolField(data, 'isPublic', true);

  // DateTime fields - always convert strings to Timestamp
  try {
    if (data.createdAt && typeof data.createdAt === 'string') {
      // Force conversion from string to Timestamp
      normalized.createdAt = normalizeDateTimeField(data, 'createdAt');
    } else {
      normalized.createdAt = normalizeDateTimeField(data, 'createdAt');
    }
  } catch (e) {
    console.log(`⚠️  Error normalizing createdAt for venue ${venueId}: ${e.message}`);
    normalized.createdAt = FieldValue.serverTimestamp();
  }
  
  try {
    if (data.updatedAt && typeof data.updatedAt === 'string') {
      // Force conversion from string to Timestamp
      normalized.updatedAt = normalizeDateTimeField(data, 'updatedAt', true);
    } else {
      normalized.updatedAt = normalizeDateTimeField(data, 'updatedAt', true);
    }
  } catch (e) {
    console.log(`⚠️  Error normalizing updatedAt for venue ${venueId}: ${e.message}`);
    normalized.updatedAt = FieldValue.serverTimestamp();
  }

  // Required GeoPoint - check if location exists
  if (!normalized.location || normalized.location === null) {
    throw new Error(`Venue ${venueId} is missing required location field`);
  }

  // Ensure geohash exists for location-based queries
  if (!normalized.geohash || normalized.geohash === null) {
    try {
      const location = normalized.location;
      let lat, lng;
      
      // Handle Firestore GeoPoint object
      if (location.latitude !== undefined && location.longitude !== undefined) {
        lat = location.latitude;
        lng = location.longitude;
      } else if (location._latitude !== undefined && location._longitude !== undefined) {
        // Handle internal Firestore GeoPoint structure
        lat = location._latitude;
        lng = location._longitude;
      } else if (Array.isArray(location) && location.length === 2) {
        // Handle array format [lat, lng]
        lat = location[0];
        lng = location[1];
      } else {
        throw new Error(`Invalid location format for venue ${venueId}`);
      }
      
      normalized.geohash = encodeGeohash(lat, lng);
      console.log(`✅ Generated geohash for venue ${venueId}: ${normalized.geohash}`);
    } catch (e) {
      console.log(`⚠️  Could not generate geohash for venue ${venueId}: ${e.message}`);
    }
  }

  return normalized;
}

async function normalizeVenues() {
  console.log('\n🔧 Starting venue normalization...\n');

  try {
    // Get all venues - we'll sort them by createdAt if available, otherwise by venueId
    const venuesSnapshot = await db.collection('venues').get();
    console.log(`📊 Found ${venuesSnapshot.size} venues to process\n`);

    if (venuesSnapshot.empty) {
      console.log('⚠️  No venues found in database\n');
      return { success: true, updated: 0, skipped: 0, errors: 0 };
    }

    // Sort venues by createdAt (if available) or venueId for consistent ordering
    const sortedDocs = venuesSnapshot.docs.sort((a, b) => {
      const aData = a.data();
      const bData = b.data();
      
      // Try to sort by createdAt first
      const aCreatedAt = aData.createdAt;
      const bCreatedAt = bData.createdAt;
      
      if (aCreatedAt && bCreatedAt) {
        // Both have createdAt - compare them
        if (aCreatedAt.toDate && bCreatedAt.toDate) {
          return aCreatedAt.toDate().getTime() - bCreatedAt.toDate().getTime();
        } else if (aCreatedAt instanceof Date && bCreatedAt instanceof Date) {
          return aCreatedAt.getTime() - bCreatedAt.getTime();
        }
      }
      
      // Fallback to venueId for consistent ordering
      return a.id.localeCompare(b.id);
    });

    // Assign venueNumber sequentially (1, 2, 3, ...)
    let venueNumber = 1;
    const venuesWithNumbers = [];
    
    for (const doc of sortedDocs) {
      const data = doc.data();
      const currentVenueNumber = data.venueNumber || 0;
      
      // If venue doesn't have a number, assign the next sequential number
      if (currentVenueNumber === 0 || currentVenueNumber == null) {
        venuesWithNumbers.push({
          doc: doc,
          venueNumber: venueNumber++,
          needsNumber: true
        });
      } else {
        // Venue already has a number, keep it but update venueNumber counter
        venuesWithNumbers.push({
          doc: doc,
          venueNumber: currentVenueNumber,
          needsNumber: false
        });
        // Update counter to be higher than existing numbers
        if (currentVenueNumber >= venueNumber) {
          venueNumber = currentVenueNumber + 1;
        }
      }
    }

    console.log(`📝 Assigned venue numbers: ${venueNumber - 1} new numbers assigned\n`);

    let updated = 0;
    let skipped = 0;
    let errors = 0;
    const BATCH_SIZE = 500; // Firestore batch limit
    let batch = db.batch();
    let batchCount = 0;

    for (const venueInfo of venuesWithNumbers) {
      const doc = venueInfo.doc;
      try {
        const venueId = doc.id;
        const data = doc.data();
        
        // Check if venueId field exists, if not add it
        const needsVenueId = !data.venueId || data.venueId !== venueId;
        
        // Normalize the data
        const normalized = normalizeVenueData(data, venueId);
        
        // Add venueNumber to normalized data
        normalized.venueNumber = venueInfo.venueNumber;
        
        // Check if update is needed
        let needsUpdate = needsVenueId || venueInfo.needsNumber;
        
        // ALWAYS check if DateTime fields are strings (need conversion to Timestamp)
        // This is critical - strings must be converted to Timestamp for the app to work
        const dateTimeFields = ['createdAt', 'updatedAt'];
        for (const key of dateTimeFields) {
          if (data[key] && typeof data[key] === 'string') {
            needsUpdate = true;
            console.log(`📝 Venue ${venueId} has ${key} as string, will convert to Timestamp`);
            break;
          }
        }
        
        // Always check for differences, especially for DateTime fields
        if (!needsUpdate) {
          for (const key in normalized) {
            if (key === 'venueId') continue;
            const oldValue = data[key];
            const newValue = normalized[key];
            
            // Special handling for Timestamp objects
            if (key === 'createdAt' || key === 'updatedAt') {
              // If old value is string and new value is Timestamp, needs update
              if (typeof oldValue === 'string' && newValue && typeof newValue.toDate === 'function') {
                needsUpdate = true;
                console.log(`📝 Venue ${venueId}: ${key} is string, converting to Timestamp`);
                break;
              }
              // If old value is Timestamp but new value is different type, needs update
              if (oldValue && typeof oldValue.toDate === 'function' && 
                  (!newValue || typeof newValue.toDate !== 'function')) {
                needsUpdate = true;
                console.log(`📝 Venue ${venueId}: ${key} type mismatch, updating`);
                break;
              }
              // If both are Timestamps, compare their milliseconds
              if (oldValue && typeof oldValue.toDate === 'function' && 
                  newValue && typeof newValue.toDate === 'function') {
                // Skip comparison - if we got here, they're both Timestamps and probably fine
                continue;
              }
            }
            
            // Deep comparison for objects/arrays (but skip Timestamps)
            if (key !== 'createdAt' && key !== 'updatedAt') {
              if (JSON.stringify(oldValue) !== JSON.stringify(newValue)) {
                needsUpdate = true;
                break;
              }
            }
          }
        }

        if (needsUpdate) {
          // Always update updatedAt
          normalized.updatedAt = FieldValue.serverTimestamp();
          
          // Prepare update object (exclude venueId as it's the document ID)
          const updateData = { ...normalized };
          delete updateData.venueId;
          
          batch.update(doc.ref, updateData);
          batchCount++;
          updated++;

          if (batchCount >= BATCH_SIZE) {
            await batch.commit();
            console.log(`✅ Committed batch: ${updated} venues updated so far...`);
            batch = db.batch();
            batchCount = 0;
          }
        } else {
          skipped++;
        }
      } catch (e) {
        errors++;
        console.log(`❌ Error processing venue ${doc.id}: ${e.message}`);
        if (e.stack) {
          console.log(`   Stack: ${e.stack.split('\n')[0]}`);
        }
      }
    }

    // Commit remaining batch
    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Committed final batch`);
    }

    console.log('\n📊 Normalization Summary:');
    console.log(`   ✅ Updated: ${updated}`);
    console.log(`   ⏭️  Skipped: ${skipped}`);
    console.log(`   ❌ Errors: ${errors}`);
    console.log(`   📝 Total: ${venuesSnapshot.size}\n`);

    return {
      success: true,
      updated,
      skipped,
      errors,
      total: venuesSnapshot.size,
    };
  } catch (error) {
    console.error(`\n❌ Error normalizing venues:`, error.message);
    if (error.code) {
      console.error(`   Error Code: ${error.code}`);
    }
    if (error.stack) {
      console.error(`\nStack trace:\n${error.stack}`);
    }
    throw error;
  }
}

// Main execution
normalizeVenues()
  .then((result) => {
    if (result.success) {
      console.log('🎉 Venue normalization completed successfully!\n');
      process.exit(0);
    } else {
      console.error('\n❌ Normalization completed with errors\n');
      process.exit(1);
    }
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });
