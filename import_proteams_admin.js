#!/usr/bin/env node

/**
 * Import ProTeams data to Firestore using Admin SDK
 * This script uses Firebase Admin SDK with full privileges
 *
 * Setup:
 * 1. Install dependencies: npm install firebase-admin
 * 2. Set environment variable: export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
 * 3. Run: node import_proteams_admin.js
 *
 * Alternative - Use Application Default Credentials:
 * 1. Login: gcloud auth application-default login
 * 2. Run: node import_proteams_admin.js
 */

const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
// This will use GOOGLE_APPLICATION_CREDENTIALS env var or Application Default Credentials
admin.initializeApp({
  projectId: 'kickabout-ddc06'
});

const db = admin.firestore();

// Read the JSON data
const data = JSON.parse(fs.readFileSync('./proteams_import.json', 'utf8'));

async function importTeams() {
  console.log('🚀 Starting import with Firebase Admin SDK...');
  console.log(`📊 Found ${Object.keys(data.proteams).length} teams to import\n`);

  let successCount = 0;
  let errorCount = 0;
  const teams = data.proteams;

  // Use batch for better performance
  const batch = db.batch();
  const teamEntries = Object.entries(teams);

  teamEntries.forEach(([teamId, teamData]) => {
    const docRef = db.collection('proteams').doc(teamId);
    batch.set(docRef, teamData);
  });

  try {
    await batch.commit();
    successCount = teamEntries.length;

    console.log('\n✅ Batch import successful!');
    console.log(`   Imported ${successCount} teams to Firestore`);
    console.log('📍 Collection: proteams');

    // Display summary
    const premierCount = Object.values(teams).filter(t => t.league === 'premier').length;
    const nationalCount = Object.values(teams).filter(t => t.league === 'national').length;
    console.log(`\n📈 Summary:`);
    console.log(`   ⚽ Premier League: ${premierCount} teams`);
    console.log(`   ⚽ National League: ${nationalCount} teams`);
    console.log(`   ✓ Total: ${successCount} teams`);

    process.exit(0);
  } catch (error) {
    console.error('❌ Batch import failed:', error.message);
    console.error('\nTroubleshooting:');
    console.error('1. Make sure you have authenticated:');
    console.error('   gcloud auth application-default login');
    console.error('2. Or set service account key:');
    console.error('   export GOOGLE_APPLICATION_CREDENTIALS="path/to/key.json"');
    console.error('3. Verify project ID is correct: kickabout-ddc06');
    process.exit(1);
  }
}

importTeams().catch(err => {
  console.error('❌ Fatal error:', err);
  process.exit(1);
});
