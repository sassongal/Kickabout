# Hub Recruiting Posts + Join Request System - Implementation Status

## Overview
A system to allow Hub Managers to post "Looking for Players" announcements with player contact and join request capabilities.

## Completed ✅

### Phase 1: Data Models
- ✅ Updated `FeedPost` model with new fields:
  - `eventId` - Link to specific events
  - `isUrgent` - Show urgency badge
  - `recruitingUntil` - Deadline for recruiting
  - `neededPlayers` - Number of players needed
  - Added 'hub_recruiting' to type options

- ✅ Created `ContactMessage` model:
  - Complete model with all required fields
  - Freezed/JSON serialization setup
  - Stored in `/hubs/{hubId}/contactMessages/{messageId}`

- ✅ Ran build_runner to generate freezed/json files

### Phase 2: Create Recruiting Post Screen
- ✅ Created `CreateRecruitingPostScreen`:
  - Form with description, needed players, urgency toggle
  - Date picker for recruitment deadline
  - Dropdown to link to specific games (events TBD)
  - Photo upload placeholder (needs storage service integration)
  - Form validation
  - Permission checking using HubPermissions
  - Analytics tracking

### Phase 3: Repository Methods
- ✅ Added to `HubsRepository`:
  - `streamContactMessages()` - Stream messages for Hub Manager
  - `sendContactMessage()` - Player sends message to manager
  - `checkExistingContactMessage()` - Verify one message per post
  - `updateContactMessageStatus()` - Mark as read/replied

### Phase 4: Routing
- ✅ Added route `/hubs/:id/create-recruiting-post`
- ✅ Deferred import for lazy loading
- ✅ Added to app_router.dart

## In Progress 🔄

### Known Issues to Fix:
1. **SnackbarHelper API**: Current calls to `Snackbar Helper.show()` need to match actual API
   - Should likely be `SnackbarHelper.showSuccess()` / `showError()`

2. **AnalyticsService API**: Check actual method signature for logging events
   - Currently using: `logEvent('recruiting_post_created', {...})`

3. **OptimizedNetworkImage**: Widget usage needs import or alternative
   - Consider using `CachedNetworkImage` or custom widget

## TODO - High Priority 📋

### Phase 5: Feed UI Updates (Not Started)
**Files to modify:**
- `lib/screens/social/feed_screen.dart`
- Create `lib/widgets/feed/recruiting_post_card.dart`

**Requirements:**
1. Update feed post card widget to detect `type == 'hub_recruiting'`
2. Add special UI for recruiting posts:
   - ✅ Urgency badge (if `isUrgent == true`)
   - ✅ Needed players count display
   - ✅ Recruiting deadline display
   - 🔲 "Send Message" button (for non-members)
   - 🔲 "Request to Join" button (if linked to game/event)
3. Implement message dialog:
   - Single-message limit enforcement
   - 300 character limit
   - Validation

### Phase 6: Hub Inbox for Contact Messages (Not Started)
**File to create:**
- `lib/screens/hub/hub_inbox_screen.dart` (or modify existing)

**Requirements:**
1. Add "Contact Messages" tab
2. Create `_ContactMessageCard` widget:
   - Display sender avatar, name, time
   - Show message content
   - Show related post excerpt
   - Action buttons: Reply, Mark as Read, Call (if phone available)
3. Stream messages using `streamContactMessages()`
4. Navigation to private chat for replies

### Phase 7: Hub Detail Button (Not Started)
**File to modify:**
- `lib/screens/hub/hub_detail_screen.dart`

**Requirements:**
- Add "מחפש שחקנים" button in action row (near Analytics, Scouting, etc.)
- Only visible to managers (check `hubPermissions.canCreatePosts()`)
- Navigate to `/hubs/${hubId}/create-recruiting-post`

### Phase 8: Feed Filtering (Not Started)
**File to modify:**
- `lib/screens/social/feed_screen.dart`
- `lib/data/feed_repository.dart`

**Requirements:**
1. Add FilterChips at top of feed:
   - "הכל" (all)
   - "משחקים" (games)
   - "מחפשים שחקנים" (recruiting)
   - "הישגים" (achievements)
2. Update repository methods to accept optional `postType` filter
3. Update `streamRegionalFeed()` and `watchFeed()` methods

## TODO - Medium Priority 🔧

### Phase 9: Games/Events Join Requests
**Files to modify:**
- `lib/data/games_repository.dart`
- `lib/data/hubs_repository.dart` (for events)

**Methods needed:**
```dart
// In GamesRepository
Future<void> requestToJoinGame({
  required String gameId,
  required String userId,
});

Future<List<Game>> getUpcomingGamesForHub(String hubId);

// In HubsRepository (or EventsRepository if exists)
Future<void> requestToJoinEvent({
  required String hubId,
  required String eventId,
  required String userId,
});

Future<List<HubEvent>> getUpcomingEventsForHub(String hubId);
```

### Phase 10: Contact Dialog Implementation
**Implementation details:**
```dart
Future<void> _showContactDialog(FeedPost post) async {
  // 1. Check if user already sent message
  // 2. Show dialog with TextField (300 char limit)
  // 3. Call hubsRepo.sendContactMessage()
  // 4. Show success/error message
}

Future<void> _requestToJoinEvent(FeedPost post) async {
  // 1. Check if gameId or eventId exists
  // 2. Call appropriate repository method
  // 3. Show success/error message
}
```

## TODO - Low Priority (Backend) ⚙️

### Phase 11: Cloud Functions
**File:** `functions/index.js`

**Functions needed:**
1. `onRecruitingPostCreated`:
   - Trigger: Hub feed post created with type='hub_recruiting'
   - Action: Create regional feed post in `/feedPosts` collection
   - Send push notifications to nearby players

2. `onContactMessageCreated`:
   - Trigger: Contact message created
   - Action: Send push notification to Hub Manager

### Phase 12: Firestore Security Rules
**File:** `firestore.rules`

**Rules to add:**
```javascript
// Regional feed posts (read-only)
match /feedPosts/{postId} {
  allow read: if isAuthenticated();
  allow write: if false;  // Only Cloud Functions can write
}

// Contact messages
match /hubs/{hubId}/contactMessages/{messageId} {
  // Hub Manager can read all
  allow read: if isAuthenticated() && isHubManager(hubId);
  
  // Players can create ONE message per post
  allow create: if isAuthenticated() &&
                   request.resource.data.senderId == request.auth.uid &&
                   !exists(/databases/$(database)/documents/hubs/$(hubId)/contactMessages/$(request.auth.uid + '_' + request.resource.data.postId));
  
  // Hub Manager can update status
  allow update: if isAuthenticated() && 
                   isHubManager(hubId) &&
                   request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'updatedAt']);
}
```

### Phase 13: Firestore Indexes
**File:** `firestore.indexes.json`

**Indexes needed:**
```json
{
  "collectionGroup": "contactMessages",
  "fields": [
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
},
{
  "collectionGroup": "contactMessages",
  "fields": [
    {"fieldPath": "senderId", "order": "ASCENDING"},
    {"fieldPath": "postId", "order": "ASCENDING"}
  ]
},
{
  "collectionGroup": "feedPosts",
  "fields": [
    {"fieldPath": "region", "order": "ASCENDING"},
    {"fieldPath": "type", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```

## Implementation Notes 📝

### SnackbarHelper Fix Needed
The current implementation uses:
```dart
SnackbarHelper.show(context, 'message');
SnackbarHelper.show(context, 'message', isError: false);
```

Check actual signature in `lib/utils/snackbar_helper.dart` and update to match.

### Photo Upload Integration
Photo upload is currently a placeholder. To complete:
1. Check if `StorageService` exists in the project
2. Add method: `uploadFeedPhoto(String hubId, String userId, XFile image)`
3. Update `_pickImage()` method to use actual storage service

### Events Integration
The dropdown for linking events needs:
1. Check if `HubEvent` model exists
2. Implement `getUpcomingEventsForHub()` in appropriate repository
3. Add events to dropdown in `CreateRecruitingPostScreen`

## Testing Checklist 🧪

### Unit Tests
- [ ] FeedPost model serialization with new fields
- [ ] ContactMessage model serialization
- [ ] Repository methods (mock Firestore)

### Integration Tests
- [ ] Create recruiting post flow
- [ ] Send contact message with duplicate check
- [ ] Hub Manager inbox view
- [ ] Filter feed by post type

### E2E Tests
1. [ ] Hub Manager creates recruiting post
2. [ ] Player views post in regional feed
3. [ ] Player sends contact message (verify one-time limit)
4. [ ] Hub Manager receives notification
5. [ ] Hub Manager views message in inbox
6. [ ] Hub Manager replies via private chat
7. [ ] Player requests to join linked game
8. [ ] Hub Manager approves/rejects join request

## Deployment Steps 🚀

1. **Code Deployment**:
   ```bash
   flutter test
   flutter build appbundle --release  # Android
   flutter build ipa --release         # iOS
   ```

2. **Firestore Rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Firestore Indexes**:
   ```bash
   firebase deploy --only firestore:indexes
   ```

4. **Cloud Functions**:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions:onRecruitingPostCreated,functions:onContactMessageCreated
   ```

## Estimated Completion Time ⏱️

- **Completed**: ~3 hours
- **High Priority Remaining**: ~4-5 hours
- **Medium Priority**: ~2-3 hours
- **Low Priority (Backend)**: ~2 hours
- **Testing & Polish**: ~2 hours
- **Total**: ~13-15 hours

## Current Status Summary

✅ **Foundation Complete** (30%):
- Models updated and generated
- Repository methods implemented
- Create recruiting post screen built
- Routing configured

🔄 **In Progress** (20%):
- Minor fixes needed for SnackbarHelper, Analytics, OptimizedNetworkImage

📋 **TODO** (50%):
- Feed UI updates with recruiting post card
- Hub inbox screen for contact messages
- Feed filtering
- Join request flows
- Cloud Functions
- Security rules & indexes

---

**Next Steps:**
1. Fix SnackbarHelper API calls
2. Fix AnalyticsService API calls  
3. Implement recruiting post card in feed
4. Add hub inbox screen
5. Test end-to-end flow

**Recent Fixes (2025-11-28):**
- Fixed `FeedScreen` compilation errors (moved methods to correct scope)
- Deleted unused `OnboardingScreen`
- Ran `build_runner` to fix model errors
- Implemented Feed Filtering UI and logic (Phase 8)
- Fixed critical redirect loop in `AppRouter` (Welcome <-> Profile Setup)
- Improved `DiscoverVenuesScreen` UI (dropdown, selection confirmation)
- Fixed `HubDetailScreen` home venue saving logic (added to `venueIds`)
