# Database Schema Documentation

## Overview

This document describes the optimized Firestore database schema for the Kickadoor application. The schema follows best practices for NoSQL databases, including strategic denormalization, atomic operations, and efficient querying.

## Design Principles

1. **Denormalization**: Frequently accessed data (like user names, hub names) is duplicated in related documents to reduce read operations.
2. **Atomicity**: Multi-document updates use Firestore Transactions to ensure data consistency.
3. **Security**: Comprehensive Firestore Security Rules validate all read/write operations.
4. **Scalability**: Indexes are defined for all complex queries to ensure performance at scale.

---

## Collections

### 1. Users Collection: `/users/{userId}`

**Purpose**: Store user profile information and denormalized data.

**Schema**:
```typescript
{
  uid: string,                    // User ID (document ID)
  name: string,                    // Display name
  email: string,                   // Email address
  photoUrl?: string,              // Profile photo URL
  phoneNumber?: string,           // Phone number
  city?: string,                  // City of residence
  availabilityStatus: string,     // 'available' | 'busy' | 'notAvailable'
  createdAt: Timestamp,           // Account creation time
  hubIds: string[],               // Denormalized: List of hub IDs user belongs to
  currentRankScore: number,       // Denormalized: Current average rating (calculated by Cloud Function)
  preferredPosition: string,      // Preferred playing position
  totalParticipations: number,    // Total games participated
  location?: GeoPoint,            // User location (optional)
  geohash?: string,              // Geohash for location queries
}
```

**Subcollections**:
- `/users/{userId}/fcm_tokens/{tokenId}` - FCM push notification tokens
- `/users/{userId}/following/{followingId}` - Users this user follows
- `/users/{userId}/followers/{followerId}` - Users following this user
- `/users/{userId}/gamification/{doc}` - Gamification data (server-only writes)

**Security Rules**:
- Read: Any authenticated user
- Create/Update/Delete: Only the user themselves

**Denormalization**:
- `hubIds`: Maintained via Transactions when joining/leaving hubs
- `currentRankScore`: Updated automatically by `onRatingSnapshotCreated` Cloud Function

---

### 2. Hubs Collection: `/hubs/{hubId}`

**Purpose**: Store hub (group) information and settings.

**Schema**:
```typescript
{
  hubId: string,                  // Hub ID (document ID)
  name: string,                   // Hub name
  description?: string,           // Hub description
  createdBy: string,              // User ID of creator
  createdAt: Timestamp,          // Creation time
  memberIds: string[],           // List of member user IDs
  settings: {                     // Hub settings
    ratingMode: 'basic' | 'advanced',
    // ... other settings
  },
  roles: {                        // userId -> role mapping
    [userId: string]: 'manager' | 'moderator' | 'member'
  },
  location?: GeoPoint,            // Primary location (deprecated, use venues)
  geohash?: string,              // Geohash for location queries
  radius?: number,                // Radius in km
  venueIds: string[],            // IDs of venues where this hub plays
  gameCount?: number,            // Denormalized: Total games created (updated by Cloud Function)
  lastActivity?: Timestamp,      // Denormalized: Last activity time
}
```

**Subcollections**:
- `/hubs/{hubId}/feed/posts/items/{postId}` - Feed posts
  - `/hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}` - Comments on posts
- `/hubs/{hubId}/chat/messages/{messageId}` - Chat messages

**Security Rules**:
- Read: Any authenticated user
- Create: Any authenticated user
- Update: Hub managers (or moderators for memberIds/roles only)
- Delete: Hub managers only

**Denormalization**:
- `gameCount`: Updated by `onGameCreated` Cloud Function
- `lastActivity`: Updated by `onGameCreated` and `onHubMessageCreated` Cloud Functions

---

### 3. Games Collection: `/games/{gameId}`

**Purpose**: Store game/match information.

**Schema**:
```typescript
{
  gameId: string,                 // Game ID (document ID)
  createdBy: string,              // User ID of creator
  hubId: string,                  // Hub this game belongs to
  gameDate: Timestamp,            // Game date/time
  location?: string,              // Legacy text location
  locationPoint?: GeoPoint,      // Geographic location
  geohash?: string,              // Geohash for location queries
  venueId?: string,              // Reference to venue (not denormalized)
  teamCount: number,             // 2, 3, or 4 teams
  status: GameStatus,             // 'teamSelection' | 'inProgress' | 'completed' | ...
  photoUrls: string[],           // URLs of game photos
  createdAt: Timestamp,          // Creation time
  updatedAt: Timestamp,          // Last update time
  isRecurring: boolean,          // Is this a recurring game?
  parentGameId?: string,         // ID of parent recurring game
  recurrencePattern?: string,    // 'weekly' | 'biweekly' | 'monthly'
  recurrenceEndDate?: Timestamp, // When to stop creating recurring games
  // Denormalized fields
  createdByName?: string,         // Denormalized from users/{createdBy}.name
  createdByPhotoUrl?: string,    // Denormalized from users/{createdBy}.photoUrl
  hubName?: string,              // Denormalized from hubs/{hubId}.name (optional)
}
```

**Subcollections**:
- `/games/{gameId}/signups/{userId}` - Player signups
- `/games/{gameId}/teams/{teamId}` - Team assignments
- `/games/{gameId}/events/{eventId}` - Game events (goals, assists, etc.)

**Security Rules**:
- Read: Any authenticated user
- Create: Hub members only
- Update: Game creator or hub manager
- Delete: Game creator or hub manager

**Denormalization**:
- `createdByName`, `createdByPhotoUrl`: Updated by `onGameCreated` Cloud Function
- `hubName`: Optional, updated by `onGameCreated` Cloud Function

---

### 4. Feed Posts: `/hubs/{hubId}/feed/posts/items/{postId}`

**Purpose**: Store social feed posts within a hub.

**Schema**:
```typescript
{
  postId: string,                 // Post ID (document ID)
  hubId: string,                  // Hub this post belongs to
  authorId: string,               // User ID of author
  type: string,                   // 'game' | 'achievement' | 'rating' | 'post' | 'game_created'
  content?: string,               // Post content
  text?: string,                  // Alternative to content (used by onGameCreated)
  gameId?: string,               // Related game ID
  achievementId?: string,         // Related achievement ID
  likes: string[],               // User IDs who liked this post
  likeCount: number,              // Denormalized: Count of likes (for sorting)
  commentsCount: number,          // Denormalized: Count of comments
  photoUrls: string[],           // URLs of photos/videos
  createdAt: Timestamp,          // Creation time
  // Denormalized fields
  hubName?: string,              // Denormalized from hubs/{hubId}.name
  hubLogoUrl?: string,           // Denormalized from hubs/{hubId}.logoUrl
  authorName?: string,           // Denormalized from users/{authorId}.name
  authorPhotoUrl?: string,       // Denormalized from users/{authorId}.photoUrl
  entityId?: string,             // ID of related entity (gameId, etc.)
}
```

**Subcollections**:
- `/hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}` - Comments

**Security Rules**:
- Read: Hub members only
- Create: Hub members only
- Update/Delete: Post author or hub moderators

**Denormalization**:
- All denormalized fields updated by `onGameCreated` and `onCommentCreated` Cloud Functions

---

### 5. Chat Messages: `/hubs/{hubId}/chat/messages/{messageId}`

**Purpose**: Store chat messages within a hub.

**Schema**:
```typescript
{
  messageId: string,              // Message ID (document ID)
  hubId: string,                 // Hub this message belongs to
  authorId: string,              // User ID of author
  text: string,                  // Message text
  readBy: string[],             // User IDs who read this message
  createdAt: Timestamp,         // Creation time
  // Denormalized fields
  senderId?: string,            // Alias for authorId (used by Functions)
  senderName?: string,           // Denormalized from users/{authorId}.name
  senderPhotoUrl?: string,       // Denormalized from users/{authorId}.photoUrl
}
```

**Security Rules**:
- Read: Hub members only
- Create: Hub members only
- Update/Delete: Message author or hub moderators

**Denormalization**:
- All denormalized fields updated by `onHubMessageCreated` Cloud Function

---

### 6. Comments: `/hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}`

**Purpose**: Store comments on feed posts.

**Schema**:
```typescript
{
  commentId: string,             // Comment ID (document ID)
  postId: string,                // Post this comment belongs to
  hubId: string,                 // Hub this comment belongs to
  authorId: string,              // User ID of author
  text: string,                  // Comment text
  likes: string[],              // User IDs who liked this comment
  createdAt: Timestamp,         // Creation time
  // Denormalized fields
  authorName?: string,           // Denormalized from users/{authorId}.name
  authorPhotoUrl?: string,      // Denormalized from users/{authorId}.photoUrl
}
```

**Security Rules**:
- Read: Hub members only
- Create: Hub members only
- Update/Delete: Comment author or hub moderators

**Denormalization**:
- All denormalized fields updated by `onCommentCreated` Cloud Function

---

### 7. Game Signups: `/games/{gameId}/signups/{userId}`

**Purpose**: Store player signups for games.

**Schema**:
```typescript
{
  playerId: string,              // User ID (document ID)
  signedUpAt: Timestamp,        // Signup time
  status: SignupStatus,         // 'pending' | 'in' | 'out' | 'maybe'
}
```

**Security Rules**:
- Read: Any authenticated user
- Create: User can only create their own signup
- Update: User themselves or hub manager
- Delete: User themselves or hub manager

---

### 8. Ratings: `/ratings/{userId}/history/{ratingId}`

**Purpose**: Store rating snapshots for players.

**Schema**:
```typescript
{
  ratingId: string,             // Rating ID (document ID)
  gameId: string,               // Game this rating is for
  playerId: string,             // User ID being rated
  basicScore?: number,          // Basic rating (1-10) if ratingMode is 'basic'
  defense: number,              // Advanced rating categories (1-10)
  passing: number,
  shooting: number,
  dribbling: number,
  physical: number,
  leadership: number,
  teamPlay: number,
  consistency: number,
  submittedBy: string,          // User ID who submitted the rating
  submittedAt: Timestamp,       // Submission time
  isVerified: boolean,          // Whether rating is verified
}
```

**Security Rules**:
- Read: Any authenticated user
- Create: Any authenticated user
- Update/Delete: Immutable (only server can update/delete)

**Note**: The `currentRankScore` in the user document is automatically calculated and updated by the `onRatingSnapshotCreated` Cloud Function.

---

### 9. Notifications: `/notifications/{notificationId}`

**Purpose**: Store user notifications.

**Schema**:
```typescript
{
  notificationId: string,       // Notification ID (document ID)
  userId: string,               // User ID this notification is for
  type: string,                 // 'game' | 'message' | 'like' | 'comment' | 'signup'
  title: string,                // Notification title
  body: string,                 // Notification body
  data?: {                      // Additional data
    [key: string]: any
  },
  read: boolean,                // Whether notification is read
  createdAt: Timestamp,        // Creation time
}
```

**Security Rules**:
- Read: User can only read their own notifications
- Create: Server-only (Cloud Functions)
- Update/Delete: User can only update/delete their own notifications

---

### 10. Private Messages: `/private_messages/{conversationId}`

**Purpose**: Store private message conversations.

**Schema**:
```typescript
{
  conversationId: string,       // Conversation ID (document ID)
  participantIds: string[],     // User IDs participating in conversation
  lastMessage?: string,         // Denormalized: Last message text
  lastMessageAt?: Timestamp,    // Denormalized: Last message time
  // ... other fields
}
```

**Subcollections**:
- `/private_messages/{conversationId}/messages/{messageId}` - Messages in conversation

**Security Rules**:
- Read/Write: Only participants

---

### 11. Venues: `/venues/{venueId}`

**Purpose**: Store venue/field information.

**Schema**:
```typescript
{
  venueId: string,              // Venue ID (document ID)
  hubId: string,                // Hub this venue belongs to
  name: string,                  // Venue name
  description?: string,          // Venue description
  location: GeoPoint,            // Exact location
  address?: string,              // Human-readable address
  googlePlaceId?: string,        // Google Places API ID
  amenities: string[],           // e.g., ["parking", "showers", "lights"]
  surfaceType: string,          // 'grass' | 'artificial' | 'concrete'
  maxPlayers: number,            // Max players per team (default 11)
  createdAt: Timestamp,        // Creation time
  updatedAt: Timestamp,         // Last update time
  createdBy?: string,            // User ID who added this venue
  isActive: boolean,             // Can be deactivated without deleting
}
```

**Security Rules**:
- Read: Any authenticated user
- Create: Hub managers only
- Update/Delete: Hub managers only

---

## Cloud Functions

### 1. `onGameCreated`
**Trigger**: When a game document is created in `/games/{gameId}`

**Actions**:
- Denormalizes `createdByName` and `createdByPhotoUrl` into the game document
- Creates a feed post in `/hubs/{hubId}/feed/posts/items/{postId}` with denormalized data
- Updates hub `gameCount` and `lastActivity`

### 2. `onHubMessageCreated`
**Trigger**: When a message is created in `/hubs/{hubId}/chat/messages/{messageId}`

**Actions**:
- Denormalizes `senderName` and `senderPhotoUrl` into the message document
- Updates hub `lastActivity`
- Sends push notifications to hub members (except sender)

### 3. `onCommentCreated`
**Trigger**: When a comment is created in `/hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}`

**Actions**:
- Denormalizes `authorName` and `authorPhotoUrl` into the comment document
- Increments post `commentCount`
- Sends push notification to post author (if not commenting on own post)

### 4. `onRatingSnapshotCreated`
**Trigger**: When a rating snapshot is created in `/ratings/{userId}/history/{ratingId}`

**Actions**:
- Calculates average rating from last 10 games
- Updates user `currentRankScore` (denormalized)

### 5. `onVenueChanged`
**Trigger**: When a venue is created/updated/deleted in `/venues/{venueId}`

**Actions**:
- Updates all hubs that use this venue (removes/adds venue from `venueIds` array)

---

## Indexes

All indexes are defined in `firestore.indexes.json`. Key indexes include:

1. **Hubs by creator**: `hubs` collection, fields: `createdBy` (ASC), `createdAt` (DESC)
2. **Games by hub**: `games` collection, fields: `hubId` (ASC), `gameDate` (DESC)
3. **Games by creator**: `games` collection, fields: `createdBy` (ASC), `gameDate` (DESC)
4. **Rating history**: `ratings/{userId}/history` subcollection, fields: `submittedAt` (DESC)
5. **Signups by status**: `games/{gameId}/signups` subcollection, fields: `status` (ASC), `signedUpAt` (ASC)

---

## Best Practices

1. **Always use Transactions** for multi-document updates (e.g., adding/removing hub members)
2. **Denormalize frequently accessed data** (user names, hub names) to reduce read operations
3. **Use Cloud Functions** for complex business logic and automatic denormalization
4. **Validate all writes** in Security Rules to ensure data integrity
5. **Index all complex queries** to ensure performance at scale
6. **Use server timestamps** (`FieldValue.serverTimestamp()`) for `createdAt` and `updatedAt` fields

---

## Migration Notes

When migrating existing data:
1. Run Cloud Functions to populate denormalized fields
2. Update client code to use denormalized fields instead of fetching related documents
3. Ensure all indexes are deployed before running queries
4. Test Security Rules thoroughly before deploying to production

---

## Future Improvements

1. **Composite Indexes**: Add composite indexes for complex queries (e.g., games by hub and status)
2. **Batch Operations**: Use Firestore Batches for bulk updates (e.g., updating all hub members)
3. **Caching**: Consider caching frequently accessed data (e.g., user profiles) in the client
4. **Archiving**: Implement archiving strategy for old games/ratings to reduce document count

