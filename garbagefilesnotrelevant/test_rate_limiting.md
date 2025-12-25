# 🧪 Rate Limiting - Testing Guide

## Overview
Rate limiting has been implemented and deployed. Follow this guide to test it.

## Deployed Rate Limits

| Function | Max Requests | Window | Notes |
|----------|--------------|--------|-------|
| `searchVenues` | 10 | 1 minute | Google Places search |
| `getPlaceDetails` | 20 | 1 minute | Venue details lookup |
| `getHubsForPlace` | 15 | 1 minute | Find hubs using venue |
| `getHomeDashboardData` | 5 | 1 minute | Dashboard weather/vibe |
| `startGameEarly` | 3 | 1 minute | Start game button |

---

## Manual Testing Steps

### Test 1: searchVenues Rate Limit

```bash
# Run the app
flutter run

# In the app:
1. Go to Map screen
2. Search for venues 15 times rapidly (keep typing and searching)
3. Expected:
   - First 10 searches → ✅ Work fine
   - Next 5 searches → ❌ Show warning: "יותר מדי חיפושים ברגע אחד"
4. Wait 1 minute
5. Try again → ✅ Should work
```

### Test 2: getPlaceDetails Rate Limit

```bash
# In the app:
1. Go to Map screen
2. Tap on different venue markers 25 times rapidly
3. Expected:
   - First 20 taps → ✅ Show venue details
   - Next 5 taps → ❌ Show warning
4. Wait 1 minute
5. Try again → ✅ Should work
```

### Test 3: startGameEarly Rate Limit

```bash
# In the app:
1. Create 5 games (or use existing ones)
2. Try to start them all within 1 minute
3. Expected:
   - First 3 starts → ✅ Work
   - Next 2 starts → ❌ Show warning
4. Wait 1 minute
5. Try again → ✅ Should work
```

---

## Automated Testing (Optional)

Create a test script to verify rate limiting:

```javascript
// functions/test/rateLimit.test.js
const { checkRateLimit, resetRateLimit } = require('../rateLimit');
const admin = require('firebase-admin');

describe('Rate Limiting', () => {
  beforeEach(async () => {
    // Reset rate limits before each test
    await resetRateLimit('testUser', 'searchVenues');
  });

  test('should allow requests under limit', async () => {
    // Make 10 requests (limit is 10)
    for (let i = 0; i < 10; i++) {
      await expect(
        checkRateLimit('testUser', 'searchVenues', 10, 1)
      ).resolves.not.toThrow();
    }
  });

  test('should block 11th request', async () => {
    // Make 10 requests
    for (let i = 0; i < 10; i++) {
      await checkRateLimit('testUser', 'searchVenues', 10, 1);
    }

    // 11th request should fail
    await expect(
      checkRateLimit('testUser', 'searchVenues', 10, 1)
    ).rejects.toThrow('resource-exhausted');
  });

  test('should reset after time window', async () => {
    // Make 10 requests
    for (let i = 0; i < 10; i++) {
      await checkRateLimit('testUser', 'searchVenues', 10, 1);
    }

    // Wait for window to expire (mock time or wait actual time)
    // In real test, you'd mock Date.now()
    
    // After 1 minute, should allow again
    await expect(
      checkRateLimit('testUser', 'searchVenues', 10, 1)
    ).resolves.not.toThrow();
  });
});
```

---

## Monitoring Rate Limits

### Check Logs in Firebase Console

```bash
# Watch rate limit logs
firebase functions:log --only searchVenues --project kickabout-ddc06

# Look for:
# - "Rate limit exceeded" (when user hits limit)
# - "Rate limit check" (normal operation)
```

### Check Firestore Data

```bash
# Open Firestore Console
open https://console.firebase.google.com/project/kickabout-ddc06/firestore/data

# Navigate to:
_rate_limits/
  {userId}/
    actions/
      searchVenues → See requests array and timestamps
```

---

## Expected Behavior

### ✅ Normal Operation:
- User makes requests
- Counter increments in Firestore
- Old timestamps cleaned up
- Logs show "Rate limit check" every 5-10 requests

### ⚠️ When Limit Exceeded:
- User gets friendly error message
- Log shows "Rate limit exceeded"
- User can retry after window expires
- No service disruption

### 🚨 If Rate Limiter Fails:
- System fails open (allows request)
- Error logged
- User not blocked
- Admin alerted

---

## Firestore Structure

```
_rate_limits/
  {userId}/
    actions/
      searchVenues:
        requests: [1638360000000, 1638360010000, ...]  // timestamps
        lastUpdated: Timestamp
        action: "searchVenues"
        userId: "{userId}"
```

---

## Cleanup

Rate limit data is automatically cleaned:
- Only keeps recent requests (max 2x limit)
- Old timestamps filtered out on each check
- No manual cleanup needed

---

## Success Criteria

- [ ] Can make requests up to limit
- [ ] Get friendly error on exceeding limit
- [ ] Can retry after window expires
- [ ] Logs show rate limit activity
- [ ] No service disruption if rate limiter fails
- [ ] Firestore data looks correct

---

**Status:** ✅ Deployed and ready for testing
**Next Step:** Run manual tests above, then move to Testing Infrastructure

