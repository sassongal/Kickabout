# Complete Firestore Database Schema Documentation

## Overview

This document describes the complete, production-ready Firestore database schema for the Kickabout (Kickadoor) Flutter application. The schema follows best practices for NoSQL databases, including strategic denormalization, atomic operations, and efficient querying.

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
  name: string,                  // Display name (full name or nickname)
  firstName?: string,            // First name (optional)
  lastName?: string,             // Last name (optional)
  email: string,                 // Email address
  photoUrl?: string,             // Profile photo URL
  phoneNumber?: string,          // Phone number (unique)
  city?: string,                 // City of residence
  birthDate?: Timestamp,         // Date of birth (optional)
  availabilityStatus: string,    // 'available' | 'busy' | 'notAvailable'
  createdAt: Timestamp,          // Account creation time
  hubIds: string[],              // Denormalized: List of hub IDs user belongs to
  currentRankScore: number,      // Denormalized: Current average rating (calculated by Cloud Function)
  preferredPosition: string,     // Preferred playing position (e.g., 'Midfielder')
  playingStyle?: string,        // 'goalkeeper' | 'defensive' | 'offensive'
  totalParticipations: number,   // Total games participated
  location?: GeoPoint,           // User location (optional)
  geohash?: string,              // Geohash for location queries
  region?: string,               // אזור: 'צפון' | 'מרכז' | 'דרום' | 'ירושלים'
  favoriteTeamId?: string,        // Favorite football team ID (optional)
  facebookProfileUrl?: string,   // Facebook profile URL (optional)
  instagramProfileUrl?: string,  // Instagram profile URL (optional)
  privacySettings: {             // Privacy settings
    hideFromSearch: boolean,
    hideEmail: boolean,
    hidePhone: boolean,
    hideCity: boolean,
    hideStats: boolean,
    hideRatings: boolean,
  },
  followerCount: number,        // Denormalized: Count of followers (updated by onFollowCreated)
}
```

**Subcollections**:
- `/users/{userId}/fcm_tokens/tokens` - FCM push notification tokens (document with `tokens` array field)
- `/users/{userId}/following/{followingId}` - Users this user follows (document with `followerId` and `followerName`)
- `/users/{userId}/followers/{followerId}` - Users following this user (document with `followerId` and `followerName`)
- `/users/{userId}/gamification/stats` - Gamification data (server-only writes)

**Security Rules**:
- Read: Any authenticated user
- Create/Update/Delete: Only the user themselves

**Denormalization**:
- `hubIds`: Maintained via Transactions when joining/leaving hubs
- `currentRankScore`: Updated automatically by `onRatingSnapshotCreated` Cloud Function
- `followerCount`: Updated automatically by `onFollowCreated` Cloud Function

---

### 2. Hubs Collection: `/hubs/{hubId}`

**Purpose**: Store hub (group) information and settings.

**Schema**:
```typescript
{
  hubId: string,                 // Hub ID (document ID)
  name: string,                  // Hub name
  description?: string,          // Hub description
  createdBy: string,             // User ID of creator
  createdAt: Timestamp,         // Creation time
  memberIds: string[],          // List of member user IDs
  memberJoinDates: {            // Map of userId -> Timestamp (when each member joined)
    [userId: string]: Timestamp
  },
  settings: {                    // Hub settings
    ratingMode: 'basic' | 'advanced',
    joinRequestsEnabled: boolean, // Whether non-members can request to join
  },
  roles: {                       // userId -> role mapping
    [userId: string]: 'admin' | 'manager' | 'moderator' | 'member' | 'veteran'
  },
  location?: GeoPoint,           // Primary location (deprecated, use venues)
  geohash?: string,              // Geohash for location queries
  radius?: number,               // Radius in km
  venueIds: string[],            // IDs of venues where this hub plays
  mainVenueId?: string,          // ID of the main/home venue (required for hub address)
  primaryVenueId?: string,        // ID of the primary venue (for map display) - denormalized
  primaryVenueLocation?: GeoPoint, // Location of primary venue - denormalized
  profileImageUrl?: string,      // Hub profile picture URL
  logoUrl?: string,              // Hub logo URL (used in feed posts)
  hubRules?: string,             // Rules and guidelines for the hub
  region?: string,               // אזור: 'צפון' | 'מרכז' | 'דרום' | 'ירושלים'
  // Denormalized fields (updated by Cloud Functions, not written by client)
  gameCount?: number,            // Denormalized: Total games created (updated by onGameCreated)
  lastActivity?: Timestamp,      // Denormalized: Last activity time (updated by Cloud Functions)
}
```

**Subcollections**:
- `/hubs/{hubId}/feed/posts/items/{postId}` - Feed posts
  - `/hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}` - Comments on posts
- `/hubs/{hubId}/chat/{messageId}` - Chat messages (legacy path, use chatMessages)
- `/hubs/{hubId}/chatMessages/{messageId}` - Chat messages (preferred path)
- `/hubs/{hubId}/events/{eventId}` - Hub events (created by managers)

**Security Rules**:
- Read: Any authenticated user
- Create: Any authenticated user
- Update/Delete: Hub managers/moderators only

**Denormalization**:
- `gameCount`: Updated by `onGameCreated` Cloud Function
- `lastActivity`: Updated by `onGameCreated` and `onHubMessageCreated` Cloud Functions

---

### 3. Games Collection: `/games/{gameId}`

**Purpose**: Store game/match information.

**Schema**:
```typescript
{
  gameId: string,                // Game ID (document ID)
  createdBy: string,              // User ID of creator
  hubId: string,                  // Hub this game belongs to
  gameDate: Timestamp,            // Game date/time
  location?: string,              // Legacy text location
  locationPoint?: GeoPoint,        // Geographic location
  geohash?: string,               // Geohash for location queries
  venueId?: string,               // Reference to venue (not denormalized)
  teamCount: number,              // 2, 3, or 4 teams
  status: GameStatus,             // 'teamSelection' | 'teamsFormed' | 'inProgress' | 'completed' | 'statsInput'
  photoUrls: string[],            // URLs of game photos
  createdAt: Timestamp,           // Creation time
  updatedAt: Timestamp,           // Last update time
  isRecurring: boolean,           // Is this a recurring game?
  parentGameId?: string,          // ID of parent recurring game
  recurrencePattern?: string,     // 'weekly' | 'biweekly' | 'monthly'
  recurrenceEndDate?: Timestamp,  // When to stop creating recurring games
  teams: Team[],                  // List of teams created in TeamMaker
  teamAScore?: number,           // Score for team A (first team)
  teamBScore?: number,           // Score for team B (second team)
  durationInMinutes?: number,     // Duration of the game in minutes
  gameEndCondition?: string,      // Condition for game end (e.g., "first to 5 goals", "time limit")
  region?: string,                // אזור: 'צפון' | 'מרכז' | 'דרום' | 'ירושלים' (copied from Hub)
  // Denormalized fields
  createdByName?: string,         // Denormalized from users/{createdBy}.name
  createdByPhotoUrl?: string,     // Denormalized from users/{createdBy}.photoUrl
  hubName?: string,              // Denormalized from hubs/{hubId}.name (optional)
}
```

**Subcollections**:
- `/games/{gameId}/signups/{userId}` - Player signups
- `/games/{gameId}/teams/{teamId}` - Team assignments
- `/games/{gameId}/events/{eventId}` - Game events (goals, assists, etc.)
- `/games/{gameId}/chatMessages/{messageId}` - Game chat messages

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
  gameId?: string,                // Related game ID
  achievementId?: string,         // Related achievement ID
  likes: string[],                // User IDs who liked this post
  likeCount: number,              // Denormalized: Count of likes (for sorting)
  commentCount: number,          // Denormalized: Count of comments (primary field)
  commentsCount: number,         // Denormalized: Count of comments (alias for backward compatibility)
  photoUrls: string[],            // URLs of photos/videos
  createdAt: Timestamp,           // Creation time
  region?: string,                // אזור: 'צפון' | 'מרכז' | 'דרום' | 'ירושלים' (for regional feed filtering)
  // Denormalized fields
  hubName?: string,               // Denormalized from hubs/{hubId}.name
  hubLogoUrl?: string,           // Denormalized from hubs/{hubId}.logoUrl
  authorName?: string,            // Denormalized from users/{authorId}.name
  authorPhotoUrl?: string,        // Denormalized from users/{authorId}.photoUrl
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

### 5. Regional Feed Posts: `/feedPosts/{postId}`

**Purpose**: Store regional feed posts (automatically created by Cloud Functions when games complete).

**Schema**:
```typescript
{
  postId: string,                 // Post ID (document ID)
  hubId: string,                  // Hub this post belongs to
  authorId: string,               // User ID of author
  type: string,                   // 'game_completed'
  text: string,                   // Post text
  gameId?: string,                // Related game ID
  likes: string[],                 // User IDs who liked this post
  likeCount: number,              // Denormalized: Count of likes
  commentCount: number,           // Denormalized: Count of comments
  photoUrls: string[],            // URLs of photos/videos
  createdAt: Timestamp,           // Creation time
  region: string,                 // אזור: 'צפון' | 'מרכז' | 'דרום' | 'ירושלים' (required for filtering)
  // Denormalized fields
  hubName?: string,               // Denormalized from hubs/{hubId}.name
  hubLogoUrl?: string,           // Denormalized from hubs/{hubId}.logoUrl
  authorName?: string,            // Denormalized from users/{authorId}.name
  authorPhotoUrl?: string,        // Denormalized from users/{authorId}.photoUrl
  entityId?: string,             // ID of related entity (gameId, etc.)
}
```

**Security Rules**:
- Read: Any authenticated user
- Write: Server-only (Cloud Functions)

---

### 6. Comments: `/hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}`

**Purpose**: Store comments on feed posts.

**Schema**:
```typescript
{
  commentId: string,             // Comment ID (document ID)
  postId: string,                 // Post this comment belongs to
  hubId: string,                  // Hub this comment belongs to
  authorId: string,               // User ID of author
  text: string,                   // Comment text
  likes: string[],                // User IDs who liked this comment
  createdAt: Timestamp,           // Creation time
  // Denormalized fields
  authorName?: string,            // Denormalized from users/{authorId}.name
  authorPhotoUrl?: string,       // Denormalized from users/{authorId}.photoUrl
}
```

**Security Rules**:
- Read: Hub members only
- Create: Hub members only
- Update/Delete: Comment author or hub moderators

**Denormalization**:
- All denormalized fields updated by `onCommentCreated` Cloud Function

---

### 7. Chat Messages: `/hubs/{hubId}/chat/{messageId}` (Legacy) and `/hubs/{hubId}/chatMessages/{messageId}` (Preferred)

**Purpose**: Store chat messages within a hub.

**Schema**:
```typescript
{
  messageId: string,              // Message ID (document ID)
  hubId: string,                  // Hub this message belongs to
  authorId: string,               // User ID of author
  text: string,                   // Message text
  readBy: string[],              // User IDs who read this message
  createdAt: Timestamp,           // Creation time
  // Denormalized fields
  senderId?: string,             // Alias for authorId (used by Functions)
  senderName?: string,            // Denormalized from users/{authorId}.name
  senderPhotoUrl?: string,        // Denormalized from users/{authorId}.photoUrl
}
```

**Security Rules**:
- Read: Hub members only
- Create: Hub members only
- Update/Delete: Message author or hub moderators

**Denormalization**:
- All denormalized fields updated by `onHubMessageCreated` Cloud Function

---

### 8. Game Chat Messages: `/games/{gameId}/chatMessages/{messageId}`

**Purpose**: Store chat messages within a game.

**Schema**:
```typescript
{
  messageId: string,              // Message ID (document ID)
  gameId: string,                 // Game this message belongs to
  senderId: string,               // User ID of sender
  text: string,                   // Message text
  createdAt: Timestamp,           // Creation time
}
```

**Security Rules**:
- Read: Game participants only (users who signed up)
- Create: Game participants only
- Update/Delete: Message sender or hub moderators

---

### 9. Game Signups: `/games/{gameId}/signups/{userId}`

**Purpose**: Store player signups for games.

**Schema**:
```typescript
{
  playerId: string,               // User ID (document ID)
  signedUpAt: Timestamp,          // Signup time
  status: SignupStatus,           // 'pending' | 'confirmed'
}
```

**Security Rules**:
- Read: Any authenticated user
- Create: User can only create their own signup
- Update: User themselves or hub manager
- Delete: User themselves or hub manager

---

### 10. Teams: `/games/{gameId}/teams/{teamId}`

**Purpose**: Store team assignments for games.

**Schema**:
```typescript
{
  teamId: string,                // Team ID (document ID)
  name: string,                   // Team name
  playerIds: string[],            // List of player user IDs
  totalScore: number,             // Total team score
  color?: string,                 // Team color
}
```

**Security Rules**:
- Read: Any authenticated user
- Write: Hub managers only

---

### 11. Game Events: `/games/{gameId}/events/{eventId}`

**Purpose**: Store game events (goals, assists, saves, etc.).

**Schema**:
```typescript
{
  eventId: string,                // Event ID (document ID)
  type: EventType,                // 'goal' | 'assist' | 'save' | 'card' | 'mvpVote'
  playerId: string,                // User ID of player
  timestamp: Timestamp,           // Event timestamp
  metadata: {                     // Additional event data
    [key: string]: any
  },
}
```

**Security Rules**:
- Read: Any authenticated user
- Create/Update/Delete: Hub managers only

---

### 12. Hub Events: `/hubs/{hubId}/events/{eventId}`

**Purpose**: Store hub events (tournaments, training, etc.) created by hub managers.

**Schema**:
```typescript
{
  eventId: string,                // Event ID (document ID)
  hubId: string,                   // Hub this event belongs to
  createdBy: string,               // User ID of creator
  title: string,                   // Event title
  description?: string,           // Event description
  eventDate: Timestamp,           // Event date/time
  createdAt: Timestamp,            // Creation time
  updatedAt: Timestamp,            // Last update time
  registeredPlayerIds: string[],   // Players who registered
  status: string,                  // 'upcoming' | 'ongoing' | 'completed' | 'cancelled'
  location?: string,              // Event location (text)
  locationPoint?: GeoPoint,        // Event location (geographic)
  geohash?: string,                // Geohash for location queries
}
```

**Security Rules**:
- Read: Hub members only
- Create: Hub managers only
- Update/Delete: Hub managers only

---

### 13. Ratings: `/ratings/{userId}/history/{ratingId}`

**Purpose**: Store rating snapshots for players.

**Schema**:
```typescript
{
  ratingId: string,               // Rating ID (document ID)
  gameId: string,                  // Game this rating is for
  playerId: string,                // User ID being rated
  basicScore?: number,             // Basic rating (1-10) if ratingMode is 'basic'
  defense: number,                 // Advanced rating categories (1-10)
  passing: number,
  shooting: number,
  dribbling: number,
  physical: number,
  leadership: number,
  teamPlay: number,
  consistency: number,
  submittedBy: string,             // User ID who submitted the rating
  submittedAt: Timestamp,          // Submission time
  isVerified: boolean,             // Whether rating is verified
}
```

**Security Rules**:
- Read: Any authenticated user
- Create: Any authenticated user
- Update/Delete: Immutable (only server can update/delete)

**Note**: The `currentRankScore` in the user document is automatically calculated and updated by the `onRatingSnapshotCreated` Cloud Function.

---

### 14. Notifications: `/notifications/{userId}/items/{notificationId}`

**Purpose**: Store user notifications.

**Schema**:
```typescript
{
  notificationId: string,          // Notification ID (document ID)
  userId: string,                  // User ID this notification is for (part of path)
  type: string,                    // 'game_reminder' | 'message' | 'like' | 'comment' | 'signup' | 'new_follower' | 'hub_chat' | 'new_comment' | 'new_game'
  title: string,                   // Notification title
  body: string,                    // Notification body
  data?: {                         // Additional data
    [key: string]: any
  },
  read: boolean,                   // Whether notification is read (not 'isRead')
  entityId?: string,               // ID of related entity (gameId, hubId, etc.)
  hubId?: string,                  // Hub ID if notification is hub-related
  createdAt: Timestamp,            // Creation time
}
```

**Security Rules**:
- Read: User can only read their own notifications
- Create: Server-only (Cloud Functions)
- Update/Delete: User can only update/delete their own notifications

---

### 15. Private Messages: `/private_messages/{conversationId}`

**Purpose**: Store private message conversations.

**Schema**:
```typescript
{
  conversationId: string,          // Conversation ID (document ID)
  participantIds: string[],        // User IDs participating in conversation
  lastMessage?: string,            // Denormalized: Last message text
  lastMessageAt?: Timestamp,       // Denormalized: Last message time
  unreadCount: {                   // Map of userId -> unread count
    [userId: string]: number
  },
}
```

**Subcollections**:
- `/private_messages/{conversationId}/messages/{messageId}` - Messages in conversation

**Security Rules**:
- Read/Write: Only participants

---

### 16. Private Message Messages: `/private_messages/{conversationId}/messages/{messageId}`

**Purpose**: Store individual messages in private conversations.

**Schema**:
```typescript
{
  messageId: string,               // Message ID (document ID)
  conversationId: string,          // Conversation ID
  senderId: string,                // User ID of sender (not 'authorId')
  text: string,                     // Message text
  read: boolean,                   // Whether message is read
  createdAt: Timestamp,             // Creation time
}
```

**Security Rules**:
- Read: Only participants
- Create: Only participants
- Update/Delete: Immutable (messages cannot be edited or deleted)

---

### 17. Venues: `/venues/{venueId}`

**Purpose**: Store venue/field information.

**Schema**:
```typescript
{
  venueId: string,                 // Venue ID (document ID)
  hubId: string,                   // Hub this venue belongs to
  name: string,                    // Venue name
  description?: string,            // Venue description
  location: GeoPoint,              // Exact location
  address?: string,                // Human-readable address
  googlePlaceId?: string,          // Google Places API ID (not 'placeId')
  isMain: boolean,                 // Whether this is the main/home venue for a hub
  amenities: string[],             // e.g., ["parking", "showers", "lights"]
  surfaceType: string,             // 'grass' | 'artificial' | 'concrete'
  maxPlayers: number,              // Max players per team (default 11)
  createdAt: Timestamp,            // Creation time
  updatedAt: Timestamp,            // Last update time
  createdBy?: string,              // User ID who added this venue
  isActive: boolean,               // Can be deactivated without deleting
  isPublic: boolean,               // Whether this is a public venue
  hubCount: number,                // Number of hubs using this venue (denormalized)
  geohash?: string,                // Geohash for location queries
}
```

**Security Rules**:
- Read: Any authenticated user
- Create: Hub managers only
- Update/Delete: Hub managers only

---

## Enums

### GameStatus
```typescript
enum GameStatus {
  'teamSelection',    // Teams are being selected
  'teamsFormed',      // Teams have been formed
  'inProgress',       // Game is currently in progress
  'completed',        // Game has been completed
  'statsInput',        // Stats are being input
}
```

### SignupStatus
```typescript
enum SignupStatus {
  'pending',          // Signup is pending confirmation
  'confirmed',        // Signup is confirmed
}
```

### EventType
```typescript
enum EventType {
  'goal',             // Goal scored
  'assist',           // Assist made
  'save',             // Save made (goalkeeper)
  'card',             // Card received (yellow/red)
  'mvpVote',          // MVP vote
}
```

### Hub Roles
```typescript
type HubRole = 'admin' | 'manager' | 'moderator' | 'member' | 'veteran';
```

### Availability Status
```typescript
type AvailabilityStatus = 'available' | 'busy' | 'notAvailable';
```

### Feed Post Types
```typescript
type FeedPostType = 'game' | 'achievement' | 'rating' | 'post' | 'game_created' | 'game_completed';
```

### Notification Types
```typescript
type NotificationType = 
  | 'game_reminder' 
  | 'message' 
  | 'like' 
  | 'comment' 
  | 'signup' 
  | 'new_follower' 
  | 'hub_chat' 
  | 'new_comment' 
  | 'new_game';
```

### Hub Event Status
```typescript
type HubEventStatus = 'upcoming' | 'ongoing' | 'completed' | 'cancelled';
```

### Regions
```typescript
type Region = 'צפון' | 'מרכז' | 'דרום' | 'ירושלים';
```

---

## Cloud Functions

### 1. `onGameCreated`
**Trigger**: When a game document is created in `/games/{gameId}`

**Actions**:
- Denormalizes `createdByName` and `createdByPhotoUrl` into the game document
- Creates a feed post in `/hubs/{hubId}/feed/posts/items/{postId}` with denormalized data
- Updates hub `gameCount` and `lastActivity`

### 2. `onHubMessageCreated`
**Trigger**: When a message is created in `/hubs/{hubId}/chat/{messageId}` or `/hubs/{hubId}/chatMessages/{messageId}`

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

### 5. `onFollowCreated`
**Trigger**: When a follow relationship is created in `/users/{followedId}/followers/{followerId}`

**Actions**:
- Increments `followerCount` on the followed user's document
- Sends push notification to the followed user

### 6. `onVenueChanged`
**Trigger**: When a venue is created/updated/deleted in `/venues/{venueId}`

**Actions**:
- On delete: Removes venue from all hubs' `venueIds` arrays
- On create/update: No automatic updates (hubs track `venueIds` array, not full venue objects)

### 7. `onGameCompleted`
**Trigger**: When a game status changes to 'completed' in `/games/{gameId}`

**Actions**:
- Calculates player statistics from game events
- Updates gamification stats for each player
- Updates user `totalParticipations`
- Creates regional feed post in `/feedPosts/{postId}` if game has a region

### 8. `addSuperAdminToHub`
**Trigger**: When a hub is created in `/hubs/{hubId}`

**Actions**:
- Automatically adds Super Admin (gal@joya-tech.net) to every newly created hub with 'admin' role

### 9. `sendGameReminder`
**Trigger**: Scheduled function (every 30 minutes)

**Actions**:
- Finds games starting in 1-2 hours
- Sends push notifications to confirmed signups
- Creates notification documents

### 10. `notifyHubOnNewGame`
**Type**: Callable function

**Actions**:
- Sends push notifications to all hub members when a new game is created

### 11. `searchVenues`
**Type**: Callable function

**Actions**:
- Searches Google Places API for venues

### 12. `getPlaceDetails`
**Type**: Callable function

**Actions**:
- Gets detailed information about a Google Place

### 13. `getHubsForPlace`
**Type**: Callable function

**Actions**:
- Finds all hubs that use a specific venue (identified by Google placeId)

### 14. `getHomeDashboardData`
**Type**: Callable function

**Actions**:
- Returns weather and air quality data for the home screen
- Generates vibe message based on conditions

---

## Indexes

All indexes are defined in `firestore.indexes.json`. Key indexes include:

1. **Venues by geohash**: `venues` collection, fields: `geohash` (ASC), `isActive` (ASC), `hubId` (ASC)
2. **Hubs by geohash**: `hubs` collection, fields: `geohash` (ASC), `createdAt` (DESC)
3. **Hubs by member**: `hubs` collection, fields: `memberIds` (arrayContains), `createdAt` (DESC)
4. **Hubs by creator**: `hubs` collection, fields: `createdBy` (ASC), `createdAt` (DESC)
5. **Games by hub**: `games` collection, fields: `hubId` (ASC), `gameDate` (DESC)
6. **Games by hub and status**: `games` collection, fields: `hubId` (ASC), `status` (ASC), `gameDate` (ASC)
7. **Games by creator**: `games` collection, fields: `createdBy` (ASC), `gameDate` (DESC)
8. **Venues by hub**: `venues` collection, fields: `hubId` (ASC), `isActive` (ASC), `name` (ASC)
9. **Signups by status**: `signups` collection group, fields: `status` (ASC), `signedUpAt` (ASC)
10. **Notifications by read**: `items` collection group, fields: `read` (ASC), `createdAt` (DESC)
11. **Users by hub and rating**: `users` collection, fields: `hubIds` (arrayContains), `currentRankScore` (DESC)
12. **Users by hub and points**: `users` collection, fields: `hubIds` (arrayContains), `gamification.points` (DESC)
13. **Private messages by participant**: `private_messages` collection, fields: `participantIds` (arrayContains), `lastMessageAt` (DESC)
14. **Regional feed posts**: `feedPosts` collection, fields: `region` (ASC), `createdAt` (DESC)

**Note**: Single-field indexes (like `submittedAt` for rating history) are automatically created by Firestore and don't need to be explicitly defined.

---

## Relations

### User → Player → Hubs → Games

1. **User** belongs to multiple **Hubs** (via `hubIds` array)
2. **User** has **Player** profile (stored in user document)
3. **Hub** has multiple **Members** (via `memberIds` array)
4. **Hub** has multiple **Games** (via `hubId` in game document)
5. **Game** has multiple **Signups** (via subcollection)
6. **Game** has multiple **Teams** (via subcollection)
7. **Game** has multiple **Events** (via subcollection)
8. **User** has **Rating History** (via subcollection)
9. **Hub** has **Feed Posts** (via subcollection)
10. **Feed Post** has **Comments** (via subcollection)
11. **User** has **Notifications** (via subcollection)
12. **User** has **Gamification** stats (via subcollection)
13. **User** follows other **Users** (via subcollections)
14. **Users** have **Private Conversations** (via `private_messages` collection)
15. **Hub** has **Venues** (via `venueIds` array)

---

## Best Practices

1. **Always use Transactions** for multi-document updates (e.g., adding/removing hub members)
2. **Denormalize frequently accessed data** (user names, hub names) to reduce read operations
3. **Use Cloud Functions** for complex business logic and automatic denormalization
4. **Validate all writes** in Security Rules to ensure data integrity
5. **Index all complex queries** to ensure performance at scale
6. **Use server timestamps** (`FieldValue.serverTimestamp()`) for `createdAt` and `updatedAt` fields
7. **Use consistent field names** across models and Firestore documents
8. **Document all enums** with their allowed values
9. **Keep denormalized fields in sync** using Cloud Functions

---

## Migration Notes

When migrating existing data:
1. Run Cloud Functions to populate denormalized fields
2. Update client code to use denormalized fields instead of fetching related documents
3. Ensure all indexes are deployed before running queries
4. Test Security Rules thoroughly before deploying to production
5. Update models to match Firestore schema exactly (e.g., `participantIds` not `participants`, `senderId` not `authorId` for private messages)

---

## Field Name Consistency

### Important Field Name Mappings:
- **Private Messages**: Use `senderId` (not `authorId`) in Firestore
- **Private Messages**: Use `participantIds` (not `participants`) in Firestore
- **Notifications**: Use `read` (not `isRead`) in Firestore
- **Chat Messages**: Use `authorId` in hub chat, `senderId` in game chat
- **Venues**: Use `googlePlaceId` (not `placeId`) in Firestore

---

## Security Assumptions

1. All users must be authenticated to access the app
2. Users can only modify their own data (except for hub managers/moderators)
3. Hub managers/moderators have elevated permissions within their hubs
4. Cloud Functions run with admin privileges and can write to any collection
5. FCM tokens are stored securely in user subcollections
6. Private messages are only accessible to conversation participants
7. Notifications are only accessible to the user they belong to

---

## Future Improvements

1. **Composite Indexes**: Add composite indexes for complex queries (e.g., games by hub and status)
2. **Batch Operations**: Use Firestore Batches for bulk updates (e.g., updating all hub members)
3. **Caching**: Consider caching frequently accessed data (e.g., user profiles) in the client
4. **Archiving**: Implement archiving strategy for old games/ratings to reduce document count
5. **Analytics**: Add analytics events for user actions
6. **Search**: Implement full-text search for users, hubs, and posts

---

## Version History

- **v1.0** (Current): Complete schema with all collections, subcollections, fields, enums, and indexes documented
- Fixed inconsistencies: `participantIds` vs `participants`, `senderId` vs `authorId` for private messages
- Added missing fields: `entityId` and `hubId` to notifications
- Added missing indexes: private_messages and feedPosts
