/**
 * Test Setup - Initialize Firebase Admin for testing
 */

const admin = require('firebase-admin');
const test = require('firebase-functions-test')();

// Initialize Firebase Admin with test project
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'test-project',
  });
}

// Export test utilities
module.exports = {
  test,
  admin,
};

