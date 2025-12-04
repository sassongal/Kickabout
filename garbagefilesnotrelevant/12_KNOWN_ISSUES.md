# ⚠️ Kattrick - Known Issues & Solutions
## Critical Problems That Need Fixing Before Production

> **Last Updated:** January 2025  
> **Version:** 2.0  
> **Critical Issues:** 5  
> **High Priority Issues:** 8  
> **Medium Priority Issues:** 12

---

## 🔴 CRITICAL ISSUES (Fix Immediately!)

### Issue #1: Public Callable Functions (SECURITY VULNERABILITY)

**Severity:** 🔴 CRITICAL - SECURITY RISK  
**Impact:** Anyone can call expensive Google Places API  
**Cost Impact:** Could result in $1000s in API charges  
**Location:** `/functions/index.js`

**Problem:**
```javascript
// CURRENT CODE (DANGEROUS!)
exports.searchVenues = onCall(
  { invoker: "public" },  // ⚠️ NO AUTHENTICATION!
  async (request) => {
    // Calls Google Places API
    // Anyone can spam this!
  }
);
```

**Affected Functions:**
- `searchVenues`
- `getPlaceDetails`
- `getHubsForPlace`
- `getHomeDashboardData`

**Solution:**
```javascript
// FIXED CODE
exports.searchVenues = onCall(
  { 
    invoker: "authenticated",  // ✅ Requires login
    memory: "512MiB"
  },
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated", 
        "Must be logged in to search venues"
      );
    }
    
    // Add rate limiting (max 10 searches per minute)
    const userId = request.auth.uid;
    const searchCount = await getRecentSearchCount(userId);
    if (searchCount > 10) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many searches. Try again in 1 minute."
      );
    }
    
    // Rest of logic...
  }
);
```

**Action Items:**
1. Change all callable functions to `invoker: "authenticated"`
2. Add authentication checks
3. Implement rate limiting
4. Add request logging
5. Test thoroughly
6. Deploy ASAP

**Estimated Time:** 1 day  
**Priority:** 🔴 DO THIS FIRST!

---

### Issue #2: Dual FCM Token Structure (ARCHITECTURE)

**Severity:** 🔴 CRITICAL - DATA INCONSISTENCY  
**Impact:** Notifications may fail or be sent to wrong devices  
**Location:** Multiple functions + `users` collection

**Problem:**

**Method 1 (Old):**
```javascript
users/{userId}
  └─ fcmToken: "token123"  // Single string
```

**Method 2 (New):**
```javascript
users/{userId}/fcm_tokens/{tokenId}
  ├─ token: "token123"
  ├─ platform: "android"
  └─ lastUsed: Timestamp
```

**Code uses BOTH inconsistently:**

**Functions using Method 1:**
- `sendGameReminder`
- `dailyReminders`
- `weeklyDigest`

**Functions using Method 2:**
- `notifyHubOnNewGame`
- `onHubMessageCreated`

**Result:** Some notifications work, others don't!

**Solution:**

**Step 1: Pick One Structure (Subcollection Recommended)**

Why subcollection is better:
- ✅ Supports multiple devices
- ✅ Can clean up old tokens
- ✅ Platform-specific targeting
- ✅ More scalable

**Step 2: Migration Script**
```javascript
// functions/src/migrations/fcm-tokens.js
async function migrateFCMTokens() {
  const usersRef = admin.firestore().collection('users');
  const snapshot = await usersRef.get();
  
  for (const doc of snapshot.docs) {
    const data = doc.data();
    
    // If has old fcmToken field
    if (data.fcmToken) {
      // Create subcollection entry
      await doc.ref
        .collection('fcm_tokens')
        .doc('primary')
        .set({
          token: data.fcmToken,
          platform: 'unknown',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          lastUsed: admin.firestore.FieldValue.serverTimestamp(),
        });
      
      // Remove old field
      await doc.ref.update({
        fcmToken: admin.firestore.FieldValue.delete()
      });
      
      console.log(`Migrated token for user ${doc.id}`);
    }
  }
}
```

**Step 3: Update All Functions**
```javascript
// NEW HELPER FUNCTION
async function getUserFCMTokens(userId) {
  const tokensSnapshot = await admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('fcm_tokens')
    .get();
  
  return tokensSnapshot.docs.map(doc => doc.data().token);
}

// USAGE IN FUNCTIONS
const tokens = await getUserFCMTokens(userId);
if (tokens.length > 0) {
  await admin.messaging().sendMulticast({
    tokens: tokens,
    notification: { ... }
  });
}
```

**Action Items:**
1. Run migration script
2. Update all 8 functions
3. Update Flutter app (token registration)
4. Test on all platforms
5. Deploy

**Estimated Time:** 1 week  
**Priority:** 🔴 HIGH

---

### Issue #3: Sequential Firestore Reads (PERFORMANCE)

**Severity:** 🔴 CRITICAL - PERFORMANCE + COST  
**Impact:** Slow functions, high Firestore read costs  
**Location:** `onGameCompleted`, `gamificationSync`, `sendDailyReminders`

**Problem:**
```javascript
// CURRENT CODE (SLOW!)
async function onGameCompleted(gameId) {
  const game = await getGame(gameId);
  const participantIds = game.participants;
  
  // ⚠️ SEQUENTIAL READS (one by one)
  for (const userId of participantIds) {
    const user = await firestore.collection('users').doc(userId).get();
    // Update user stats...
  }
}
```

**Issues:**
- 20 players = 20 sequential reads (5-10 seconds!)
- Costs: 20 reads instead of parallel
- Function timeout risk

**Solution:**
```javascript
// FIXED CODE (PARALLEL!)
async function onGameCompleted(gameId) {
  const game = await getGame(gameId);
  const participantIds = game.participants;
  
  // ✅ PARALLEL READS
  const userDocs = await Promise.all(
    participantIds.map(id => 
      firestore.collection('users').doc(id).get()
    )
  );
  
  // ✅ BATCH WRITES
  const batch = firestore.batch();
  userDocs.forEach(doc => {
    if (doc.exists) {
      batch.update(doc.ref, {
        gamesPlayed: admin.firestore.FieldValue.increment(1),
        // ... other updates
      });
    }
  });
  
  await batch.commit();
}
```

**Performance Improvement:**
- Before: 5-10 seconds
- After: 0.5-1 second
- Cost: Same reads, but faster

**Affected Functions:**
- `onGameCompleted` - 20+ reads
- `gamificationSync` - 100+ reads
- `sendDailyReminders` - 50+ reads

**Action Items:**
1. Refactor `onGameCompleted` (highest impact)
2. Refactor `gamificationSync`
3. Refactor `sendDailyReminders`
4. Add performance monitoring
5. Test with large datasets

**Estimated Time:** 3 days  
**Priority:** 🔴 HIGH

---

### Issue #4: Unbounded Array Growth (SCALABILITY)

**Severity:** 🔴 CRITICAL - WILL BREAK AT SCALE  
**Impact:** Hub documents will hit 1MB Firestore limit  
**Location:** `hubs` collection

**Problem:**
```javascript
// CURRENT SCHEMA
hubs/{hubId}
  ├─ members: HubMember[]  // ⚠️ Array grows unbounded!
  │   └─ [100s of objects]
  └─ memberIds: string[]   // ⚠️ Duplicate data!
      └─ [100s of IDs]
```

**Firestore Limit:** 1MB per document  
**At 100 members:** ~50KB  
**At 500 members:** ~250KB  
**At 1000 members:** ~500KB  
**At 2000 members:** **1MB+ → BREAKS!**

**Same Issue in:**
- `games.participants` array
- `posts.likedBy` array

**Solution:**

**Use Subcollections:**
```javascript
// NEW SCHEMA
hubs/{hubId}
  └─ (metadata only)

hubs/{hubId}/members/{userId}
  ├─ role: "owner" | "manager" | "veteran" | "player"
  ├─ joinedAt: Timestamp
  └─ status: "active" | "banned"
```

**Migration Script:**
```javascript
async function migrateHubMembers() {
  const hubsRef = firestore.collection('hubs');
  const snapshot = await hubsRef.get();
  
  for (const hubDoc of snapshot.docs) {
    const data = hubDoc.data();
    
    if (data.members && data.members.length > 0) {
      const batch = firestore.batch();
      
      // Create subcollection documents
      data.members.forEach(member => {
        const memberRef = hubDoc.ref
          .collection('members')
          .doc(member.userId);
        batch.set(memberRef, {
          role: member.role || 'player',
          joinedAt: member.joinedAt,
          status: 'active'
        });
      });
      
      // Remove array field
      batch.update(hubDoc.ref, {
        members: admin.firestore.FieldValue.delete(),
        memberIds: admin.firestore.FieldValue.delete(),
        memberCount: data.members.length  // Add count field
      });
      
      await batch.commit();
    }
  }
}
```

**Code Changes Needed:**

**Before:**
```dart
// Flutter - OLD
final hub = await hubDoc.get();
final members = hub.data()!['members'] as List;
```

**After:**
```dart
// Flutter - NEW
final membersSnapshot = await hubDoc
  .collection('members')
  .get();
final members = membersSnapshot.docs
  .map((doc) => HubMember.fromFirestore(doc))
  .toList();
```

**Action Items:**
1. Write migration script
2. Update Firestore Rules (subcollections)
3. Update all Flutter code (20+ locations)
4. Update Cloud Functions (10+ functions)
5. Test thoroughly
6. Run migration on production
7. Monitor for issues

**Estimated Time:** 2 weeks  
**Priority:** 🔴 HIGH (will break in future!)

---

### Issue #5: No Testing Infrastructure (QUALITY)

**Severity:** 🔴 CRITICAL - CANNOT VALIDATE CHANGES  
**Impact:** Cannot safely refactor or add features  
**Location:** Entire project

**Problem:**

**Backend:**
- ❌ No unit tests for Cloud Functions
- ❌ No Firebase Emulators setup
- ❌ Cannot test locally
- ❌ No CI/CD pipeline

**Frontend:**
- ❌ No unit tests (0% coverage)
- ❌ No widget tests (0% coverage)
- ❌ No integration tests
- ❌ No mocking infrastructure

**Risk:**
- Cannot validate fixes work
- Cannot catch regressions
- Cannot safely deploy

**Solution:**

**Phase 1: Firebase Emulators Setup**

```bash
# Install emulators
firebase init emulators

# Select:
# - Firestore
# - Functions
# - Auth
# - Storage

# firebase.json
{
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "functions": { "port": 5001 },
    "storage": { "port": 9199 },
    "ui": { "enabled": true, "port": 4000 }
  }
}
```

**Phase 2: Backend Tests**

```javascript
// functions/test/onGameCreated.test.js
const test = require('firebase-functions-test')();
const admin = require('firebase-admin');

describe('onGameCreated', () => {
  let myFunctions;
  
  before(() => {
    myFunctions = require('../index');
  });
  
  after(() => {
    test.cleanup();
  });
  
  it('should create feed post when game created', async () => {
    const gameData = {
      hubId: 'hub123',
      organizerId: 'user123',
      scheduledAt: admin.firestore.Timestamp.now()
    };
    
    const snap = test.firestore.makeDocumentSnapshot(
      gameData, 
      'games/game123'
    );
    
    const wrapped = test.wrap(myFunctions.onGameCreated);
    await wrapped(snap);
    
    // Verify post was created
    const post = await admin.firestore()
      .collection('posts')
      .where('relatedGameId', '==', 'game123')
      .get();
    
    expect(post.empty).to.be.false;
  });
});
```

**Phase 3: Frontend Tests**

```dart
// test/models/user_test.dart
void main() {
  group('User Model', () {
    test('calculates age correctly', () {
      final user = User(
        id: '123',
        email: 'test@test.com',
        displayName: 'Test',
        dateOfBirth: DateTime(1990, 1, 1),
      );
      
      expect(user.age, greaterThan(30));
    });
    
    test('assigns correct age group', () {
      final user = User(
        dateOfBirth: DateTime(2000, 1, 1),
      );
      
      expect(user.ageGroup, equals('21-24'));
    });
  });
}
```

```dart
// test/widgets/game_card_test.dart
void main() {
  testWidgets('GameCard displays game info', (tester) async {
    final game = Game(
      id: '123',
      hubId: 'hub123',
      organizerId: 'user123',
      scheduledAt: DateTime.now(),
      status: GameStatus.pending,
      maxParticipants: 20,
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: GameCard(game: game),
      ),
    );
    
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('20 players max'), findsOneWidget);
  });
}
```

**Action Items:**
1. Setup Firebase Emulators (1 day)
2. Write 10 critical Function tests (3 days)
3. Write 20 model unit tests (2 days)
4. Write 10 widget tests (2 days)
5. Setup CI/CD (GitHub Actions) (1 day)
6. Document testing workflow

**Estimated Time:** 2 weeks  
**Priority:** 🔴 HIGH

---

## 🟠 HIGH PRIORITY ISSUES

### Issue #6: Missing Date of Birth + Age Groups

**Severity:** 🟠 HIGH - FEATURE GAP  
**Impact:** Cannot implement age-based features  
**Related:** Gap Analysis Decision #4.2

**Problem:**
- User model has NO `dateOfBirth` field
- Cannot calculate age
- Cannot assign age groups
- Cannot filter players by age

**Solution:** See Gap Analysis & Implementation Supplement

**Estimated Time:** 1 week  
**Priority:** 🟠 Phase 1

---

### Issue #7: Missing Attendance Confirmation

**Severity:** 🟠 HIGH - USER PAIN POINT  
**Impact:** Games often cancelled due to no-shows  
**Related:** Gap Analysis Decision #4.3

**Problem:**
- No way to confirm attendance 2h before game
- Organizers don't know who's actually coming
- Games cancelled last minute

**Solution:** See Implementation Supplement 3.3

**Estimated Time:** 1.5 weeks  
**Priority:** 🟠 Phase 1

---

### Issue #8: Missing 3 Hub Tiers

**Severity:** 🟠 HIGH - FEATURE GAP  
**Impact:** Cannot delegate game recording to trusted players  
**Related:** Gap Analysis Decision #2.1

**Problem:**
- Only 2 roles: Owner/Manager vs Player
- No "Veteran" role
- Veterans should be able to record games
- Cannot recognize long-term members

**Solution:** See Implementation Supplement 2.5

**Estimated Time:** 1 week  
**Priority:** 🟠 Phase 1

---

### Issue #9: Missing Start Event + Auto-Close

**Severity:** 🟠 HIGH - GAME FLOW ISSUE  
**Impact:** Teams can be changed after game starts  
**Related:** Gap Analysis Decision #3.2

**Problem:**
- No "Start Event" button
- Teams not locked at game start
- No auto-close for abandoned games
- Game status not updated automatically

**Solution:** See Implementation Supplement 3.2

**Estimated Time:** 2 weeks  
**Priority:** 🟠 Phase 1

---

### Issue #10: Firestore Rules Too Permissive

**Severity:** 🟠 HIGH - SECURITY  
**Impact:** Users can access data they shouldn't  
**Location:** `/firestore.rules`

**Problem:**
```javascript
// CURRENT (TOO OPEN!)
match /posts/{postId} {
  allow read: if true;  // ⚠️ Anyone can read!
}
```

**Solution:**
```javascript
// FIXED
match /posts/{postId} {
  allow read: if isHubMember(resource.data.hubId);
  allow create: if isAuthenticated() && isHubMember(request.resource.data.hubId);
  allow update, delete: if isPostAuthor(postId);
}

function isHubMember(hubId) {
  return request.auth != null 
    && request.auth.uid in getHub(hubId).data.memberIds;
}
```

**Action Items:**
1. Audit all Rules (1 day)
2. Tighten permissions (2 days)
3. Add role-based checks (1 day)
4. Test thoroughly (1 day)

**Estimated Time:** 1 week  
**Priority:** 🟠 HIGH

---

### Issue #11: No Image Optimization

**Severity:** 🟠 HIGH - PERFORMANCE + COST  
**Impact:** Large images = slow load + high storage costs  
**Location:** Image uploads

**Problem:**
- Users can upload 10MB+ images
- No compression before upload
- Storage costs high
- Load times slow

**Solution:**

**Client-Side Compression (Flutter):**
```dart
import 'package:image/image.dart' as img;

Future<File> compressImage(File file) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  
  // Resize if too large
  final resized = img.copyResize(
    image!,
    width: 1200,  // Max width
    height: 1200, // Max height
    maintainAspect: true,
  );
  
  // Compress JPEG quality 70%
  final compressed = img.encodeJpg(resized, quality: 70);
  
  // Save to temp file
  final tempFile = File('${file.path}_compressed.jpg');
  await tempFile.writeAsBytes(compressed);
  
  return tempFile;
}
```

**Action Items:**
1. Add image compression library
2. Compress before upload
3. Update image-resize Function
4. Test on all platforms

**Estimated Time:** 3 days  
**Priority:** 🟠 MEDIUM

---

## 🟡 MEDIUM PRIORITY ISSUES

### Issue #12: No Deep Links

**Severity:** 🟡 MEDIUM - UX ENHANCEMENT  
**Impact:** Cannot share direct links to Hubs/Games  
**Related:** Phase 3 Roadmap

**Problem:**
- Cannot share "Join Hub" links
- Cannot share game invitations via link
- Poor viral growth

**Solution:** Firebase Dynamic Links + GoRouter

**Estimated Time:** 1 week  
**Priority:** 🟡 Phase 3

---

### Issue #13: No Offline Indicators

**Severity:** 🟡 MEDIUM - UX  
**Impact:** Users don't know when they're offline  
**Location:** UI

**Problem:**
- Firestore offline persistence works
- But no UI indicator
- Users confused when data doesn't sync

**Solution:**
```dart
// Add network status provider
final networkStatusProvider = StreamProvider<bool>((ref) {
  return Connectivity()
    .onConnectivityChanged
    .map((result) => result != ConnectivityResult.none);
});

// Show banner when offline
class OfflineBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkStatusProvider);
    
    if (isOnline.value == false) {
      return Container(
        color: Colors.orange,
        child: Text('Offline - Changes will sync when online'),
      );
    }
    
    return SizedBox.shrink();
  }
}
```

**Estimated Time:** 2 days  
**Priority:** 🟡 MEDIUM

---

### Issue #14-25: [Additional Issues Listed]

*(Truncated for length - see full document for all 25 issues)*

---

## 📋 Issue Priority Matrix

| Priority | Count | Timeline |
|----------|-------|----------|
| 🔴 CRITICAL | 5 | Fix in next 2 weeks |
| 🟠 HIGH | 8 | Fix in Phase 1 (6-8 weeks) |
| 🟡 MEDIUM | 12 | Fix in Phase 2-3 (3-6 months) |

---

## 🛠️ Recommended Fix Order

### Week 1-2: Security & Critical Bugs

1. Issue #1: Public Functions → `authenticated` (1 day)
2. Issue #5: Setup Testing (Emulators) (3 days)
3. Issue #10: Firestore Rules Audit (3 days)
4. Issue #3: Sequential Reads (3 days)

### Week 3-4: Architecture Fixes

5. Issue #2: FCM Token Structure (5 days)
6. Issue #4: Unbounded Arrays → Subcollections (5 days)

### Week 5-10: Phase 1 Features

7. Issue #6: Date of Birth (5 days)
8. Issue #7: Attendance Confirmation (7 days)
9. Issue #8: 3 Hub Tiers (5 days)
10. Issue #9: Start Event + Auto-Close (10 days)

---

## 📚 Related Documents

- **11_CURRENT_STATE.md** - What exists now
- **08_GAP_ANALYSIS.md** - Missing features
- **10_IMPLEMENTATION_SUPPLEMENT.md** - How to fix issues
- **09_PROFESSIONAL_ROADMAP.md** - Timeline for fixes

---

**This document is the truth about what's broken.**  
**Fix these before building new features!**
