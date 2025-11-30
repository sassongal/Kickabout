/* eslint-disable max-len */
/**
 * Unit Tests for Rate Limiting Module
 */

const { expect } = require('chai');
const sinon = require('sinon');
const { test, admin } = require('./setup');
const { checkRateLimit, resetRateLimit } = require('../rateLimit');

describe('Rate Limiting', () => {
  let firestoreStub;
  let transactionStub;
  let docStub;
  
  beforeEach(() => {
    // Stub Firestore
    firestoreStub = sinon.stub(admin, 'firestore');
    
    // Create mock transaction
    transactionStub = {
      get: sinon.stub(),
      set: sinon.stub(),
    };
    
    // Create mock document reference
    docStub = {
      collection: sinon.stub().returnsThis(),
      doc: sinon.stub().returnsThis(),
      delete: sinon.stub().resolves(),
    };
    
    firestoreStub.returns({
      collection: sinon.stub().returns(docStub),
      runTransaction: sinon.stub().callsFake((callback) => callback(transactionStub)),
    });
  });
  
  afterEach(() => {
    sinon.restore();
  });
  
  describe('checkRateLimit', () => {
    it('should allow requests under limit', async () => {
      // Mock document with empty requests array
      transactionStub.get.resolves({
        exists: false,
        data: () => ({ requests: [] }),
      });
      
      // Should not throw
      await checkRateLimit('testUser', 'searchVenues', 10, 1);
      
      expect(transactionStub.get.calledOnce).to.be.true;
      expect(transactionStub.set.calledOnce).to.be.true;
    });
    
    it('should block requests over limit', async () => {
      const now = Date.now();
      const recentRequests = Array(10).fill(now);
      
      // Mock document with full requests array
      transactionStub.get.resolves({
        exists: true,
        data: () => ({ requests: recentRequests }),
      });
      
      try {
        await checkRateLimit('testUser', 'searchVenues', 10, 1);
        // Should not reach here
        expect.fail('Should have thrown error');
      } catch (error) {
        expect(error.code).to.equal('resource-exhausted');
        expect(error.message).to.include('יותר מדי בקשות');
      }
    });
    
    it('should allow requests after time window expires', async () => {
      const now = Date.now();
      const oldRequests = Array(10).fill(now - 2 * 60 * 1000); // 2 minutes ago
      
      // Mock document with old requests
      transactionStub.get.resolves({
        exists: true,
        data: () => ({ requests: oldRequests }),
      });
      
      // Should not throw (old requests filtered out)
      await checkRateLimit('testUser', 'searchVenues', 10, 1);
      
      expect(transactionStub.get.calledOnce).to.be.true;
      expect(transactionStub.set.calledOnce).to.be.true;
    });
    
    it('should clean up old timestamps', async () => {
      const now = Date.now();
      const mixedRequests = [
        ...Array(5).fill(now - 2 * 60 * 1000), // 5 old
        ...Array(3).fill(now), // 3 recent
      ];
      
      transactionStub.get.resolves({
        exists: true,
        data: () => ({ requests: mixedRequests }),
      });
      
      await checkRateLimit('testUser', 'searchVenues', 10, 1);
      
      // Check that set was called with cleaned array
      const setCall = transactionStub.set.getCall(0);
      expect(setCall).to.exist;
      const savedData = setCall.args[1];
      expect(savedData.requests.length).to.equal(4); // 3 recent + 1 new
    });
    
    it('should fail open on system errors', async () => {
      // Simulate Firestore error
      transactionStub.get.rejects(new Error('Firestore error'));
      
      // Should not throw (fail-open strategy)
      await checkRateLimit('testUser', 'searchVenues', 10, 1);
      
      expect(transactionStub.get.calledOnce).to.be.true;
    });
  });
  
  describe('resetRateLimit', () => {
    it('should delete rate limit document', async () => {
      await resetRateLimit('testUser', 'searchVenues');
      
      expect(docStub.doc.called).to.be.true;
      expect(docStub.delete.calledOnce).to.be.true;
    });
  });
});

