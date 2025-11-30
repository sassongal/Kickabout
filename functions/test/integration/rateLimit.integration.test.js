/* eslint-disable max-len */
/**
 * Integration Tests for Rate Limiting Module
 * Run with Firebase Emulators
 */

const { expect } = require('chai');
const admin = require('firebase-admin');
const { checkRateLimit, resetRateLimit } = require('../../rateLimit');

// Initialize Admin for testing
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'demo-test-project',
  });
}

// Set Firestore to use emulator
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

describe('Rate Limiting Integration Tests', () => {
  const testUserId = 'testUser123';
  const testAction = 'searchVenues';
  
  beforeEach(async () => {
    // Clean up before each test
    await resetRateLimit(testUserId, testAction);
  });
  
  after(async () => {
    // Cleanup
    await admin.app().delete();
  });
  
  it('should allow requests under limit', async () => {
    // Make 5 requests (limit is 10)
    for (let i = 0; i < 5; i++) {
      await checkRateLimit(testUserId, testAction, 10, 1);
    }
    
    // All should succeed (no error thrown)
    expect(true).to.be.true;
  });
  
  it('should block 11th request when limit is 10', async () => {
    // Make 10 requests successfully
    for (let i = 0; i < 10; i++) {
      await checkRateLimit(testUserId, testAction, 10, 1);
    }
    
    // 11th request should fail
    try {
      await checkRateLimit(testUserId, testAction, 10, 1);
      expect.fail('Should have thrown error');
    } catch (error) {
      expect(error.code).to.equal('resource-exhausted');
      expect(error.message).to.include('יותר מדי בקשות');
    }
  });
  
  it('should reset after time window', async () => {
    // This test requires waiting or mocking time
    // For now, we'll just verify the reset function works
    await checkRateLimit(testUserId, testAction, 10, 1);
    await resetRateLimit(testUserId, testAction);
    
    // Should allow new requests after reset
    await checkRateLimit(testUserId, testAction, 10, 1);
    expect(true).to.be.true;
  });
  
  it('should track different actions separately', async () => {
    const action1 = 'searchVenues';
    const action2 = 'getPlaceDetails';
    
    // Fill limit for action1
    for (let i = 0; i < 10; i++) {
      await checkRateLimit(testUserId, action1, 10, 1);
    }
    
    // action2 should still work
    await checkRateLimit(testUserId, action2, 10, 1);
    expect(true).to.be.true;
  });
  
  it('should track different users separately', async () => {
    const user1 = 'user1';
    const user2 = 'user2';
    
    // Fill limit for user1
    for (let i = 0; i < 10; i++) {
      await checkRateLimit(user1, testAction, 10, 1);
    }
    
    // user2 should still work
    await checkRateLimit(user2, testAction, 10, 1);
    expect(true).to.be.true;
    
    // Cleanup
    await resetRateLimit(user1, testAction);
    await resetRateLimit(user2, testAction);
  });
});

