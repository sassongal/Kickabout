#!/usr/bin/env node

/**
 * Import ProTeams data to Firestore
 * Run with: node import_proteams.js
 */

const { initializeApp } = require('firebase/app');
const { getFirestore, collection, doc, setDoc } = require('firebase/firestore');
const fs = require('fs');

// Firebase configuration (from firebase_options.dart)
const firebaseConfig = {
  apiKey: "AIzaSyBRdNMJ6xNTuSJp7zDlG2f5gREkOzX9-2M",
  authDomain: "kickabout-ddc06.firebaseapp.com",
  projectId: "kickabout-ddc06",
  storageBucket: "kickabout-ddc06.firebasestorage.app",
  messagingSenderId: "821662798992",
  appId: "1:821662798992:web:db2a5a85ebd5f5c22a96f5"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Read the JSON data
const data = JSON.parse(fs.readFileSync('./proteams_import.json', 'utf8'));

async function importTeams() {
  console.log('🚀 Starting import...');

  let count = 0;
  const teams = data.proteams;

  for (const [teamId, teamData] of Object.entries(teams)) {
    try {
      const docRef = doc(db, 'proteams', teamId);
      await setDoc(docRef, teamData);
      count++;
      console.log(`  ✓ [${count}/${Object.keys(teams).length}] ${teamData.name}`);
    } catch (error) {
      console.error(`  ✗ Error importing ${teamId}:`, error.message);
    }
  }

  console.log(`\n✅ Successfully imported ${count} teams to Firestore!`);
  console.log('📍 Collection: proteams');
  process.exit(0);
}

importTeams().catch(err => {
  console.error('❌ Fatal error:', err);
  process.exit(1);
});
