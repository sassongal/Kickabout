# 💾 Kattrick - Complete Data Model
## Firestore Collections, Fields & Relationships

> **Last Updated:** January 2025  
> **Version:** 2.0  
> **Database:** Cloud Firestore

## Collections Overview

Kattrick uses **7 main collections**:

1. **users** - User profiles
2. **hubs** - Football communities
3. **games** - Game events
4. **venues** - Football fields
5. **posts** - Social feed content
6. **ads** - Advertisements (planned)
7. **hub_polls** - Community polls (planned)

Plus **subcollections** for scalability.

---

## 1. Users Collection

**Path:** `users/{userId}`

### Fields

```javascript
{
  // Identity
  id: string,                    // User ID (same as Auth UID)
  email: string,                 // Email address
  displayName: string,           // Display name
  photoUrl: string?,             // Profile photo URL
  bio: string?,                  // Short bio
  
  // NEW: Missing fields (from Gap Analysis)
  dateOfBirth: Timestamp,        // 🟡 TO BE ADDED
  blockedUserIds: string[],      // 🟡 TO BE ADDED
  
  // Hubs
  hubIds: string[],              // Hubs user is member of
  managerHubIds: string[],       // Hubs user manages
  
  // Stats
  gamesPlayed: number,           // Total games
  goalsScored: number,           // Total goals
  assists: number,               // Total assists
  
  // Gamification
  xp: number,                    // Experience points
  level: number,                 // Player level
  badges: string[],              // Earned badges
  
  // Settings
  notificationsEnabled: boolean,
  language: 'he' | 'en',
  
  // Metadata
  createdAt: Timestamp,
  updatedAt: Timestamp,
  lastActiveAt: Timestamp
}
```

### Subcollections

#### users/{userId}/fcm_tokens/{tokenId}

```javascript
{
  token: string,                 // FCM token
  platform: 'android' | 'ios' | 'web',
  createdAt: Timestamp,
  lastUsed: Timestamp
}
```

### Indexes

```json
{
  "collectionGroup": "users",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "lastActiveAt", "order": "DESCENDING" }
  ]
}
```

---

## 2. Hubs Collection

**Path:** `hubs/{hubId}`

### Fields

```javascript
{
  // Identity
  id: string,
  name: string,
  description: string,
  imageUrl: string?,
  
  // Location
  venueId: string,               // Primary venue
  venueIds: string[],            // All venues
  city: string,
  
  // Ownership
  ownerId: string,
  managerIds: string[],
  
  // ⚠️ SCALABILITY ISSUE: Arrays
  // These should move to subcollections
  members: HubMember[],          // 🔴 Move to subcollection
  memberIds: string[],           // 🔴 Remove (use subcollection)
  
  // Stats (denormalized)
  memberCount: number,
  gamesCount: number,
  activeMembersCount: number,
  
  // Settings
  isPublic: boolean,
  maxMembers: number,
  
  // NEW fields
  bannedUserIds: string[],       // 🟡 TO BE ADDED
  activityScore: number,         // 🟡 TO BE ADDED
  
  // Metadata
  createdAt: Timestamp,
  lastActivityAt: Timestamp
}
```

### Subcollections (Planned)

#### hubs/{hubId}/members/{userId}

```javascript
{
  userId: string,
  role: 'owner' | 'manager' | 'veteran' | 'player',
  joinedAt: Timestamp,
  lastActiveAt: Timestamp,
  status: 'active' | 'banned'
}
```

### Indexes

```json
{
  "collectionGroup": "hubs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "city", "order": "ASCENDING" },
    { "fieldPath": "lastActivityAt", "order": "DESCENDING" }
  ]
}
```

---

## 3. Games Collection

**Path:** `games/{gameId}`

### Fields

```javascript
{
  // Identity
  id: string,
  hubId: string,
  organizerId: string,
  
  // Schedule
  scheduledAt: Timestamp,
  startedAt: Timestamp?,
  completedAt: Timestamp?,
  
  // Status
  status: 'pending' | 'active' | 'completed' | 'cancelled' | 'archived_not_played',
  
  // Location
  venueId: string,
  venueName: string,
  venueAddress: string,
  venueLocation: GeoPoint,
  
  // Participants
  participants: string[],        // User IDs
  participantCount: number,      // Denormalized
  maxParticipants: number,
  
  // NEW: Attendance
  attendanceConfirmations: {     // 🟡 TO BE ADDED
    [userId]: 'confirmed' | 'declined' | 'pending'
  },
  
  // Teams
  teamA: string[],
  teamB: string[],
  teamsLocked: boolean,          // 🟡 TO BE ADDED
  
  // Results
  scoreA: number?,
  scoreB: number?,
  mvpId: string?,
  
  // Metadata
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Subcollections

#### games/{gameId}/stats/{userId}

```javascript
{
  userId: string,
  team: 'A' | 'B',
  goals: number,
  assists: number,
  saves: number,
  yellowCards: number,
  redCards: number,
  rating: number?
}
```

### Indexes

```json
{
  "collectionGroup": "games",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "hubId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "scheduledAt", "order": "DESCENDING" }
  ]
}
```

---

## 4. Venues Collection

**Path:** `venues/{venueId}`

### Fields

```javascript
{
  // Identity
  id: string,
  name: string,
  address: string,
  location: GeoPoint,
  placeId: string,               // Google Maps Place ID
  
  // Details
  type: 'outdoor' | 'indoor' | 'futsal',
  surface: 'grass' | 'artificial' | 'concrete',
  capacity: number?,
  
  // Pricing
  priceRange: '₪' | '₪₪' | '₪₪₪',
  
  // Stats
  gamesCount: number,
  rating: number?,
  
  // User-submitted
  isVerified: boolean,
  submittedBy: string?,
  
  // Metadata
  createdAt: Timestamp
}
```

---

## 5. Posts Collection

**Path:** `posts/{postId}`

### Fields

```javascript
{
  // Identity
  id: string,
  authorId: string,
  hubId: string,
  
  // Content
  text: string,
  imageUrls: string[],
  
  // Type
  type: 'post' | 'game_created' | 'game_completed',
  relatedGameId: string?,
  
  // Engagement
  likesCount: number,            // Denormalized
  commentsCount: number,         // Denormalized
  likedBy: string[],             // ⚠️ Could scale issue
  
  // Metadata
  createdAt: Timestamp
}
```

### Subcollections

#### posts/{postId}/comments/{commentId}

```javascript
{
  id: string,
  authorId: string,
  text: string,
  createdAt: Timestamp
}
```

---

## 6. Ads Collection (Planned)

**Path:** `ads/{adId}`

### Fields

```javascript
{
  // Identity
  id: string,
  title: string,
  description: string,
  imageUrl: string,
  linkUrl: string,
  
  // Targeting
  regions: string[],
  ageGroups: string[],
  
  // Budget
  budget: number,
  spent: number,
  cpm: number,                   // Cost per 1000 impressions
  
  // Stats
  impressions: number,
  clicks: number,
  ctr: number,                   // Click-through rate
  
  // Status
  status: 'pending' | 'active' | 'paused' | 'completed',
  
  // Metadata
  createdAt: Timestamp,
  startDate: Timestamp,
  endDate: Timestamp
}
```

---

## 7. Hub Polls Collection (Planned)

**Path:** `hub_polls/{pollId}`

### Fields

```javascript
{
  // Identity
  id: string,
  hubId: string,
  creatorId: string,
  
  // Poll
  question: string,
  options: PollOption[],         // { text, voteCount, voterIds }
  
  // Settings
  multipleChoice: boolean,
  expiresAt: Timestamp,
  
  // Status
  status: 'active' | 'closed',
  totalVotes: number,
  
  // Metadata
  createdAt: Timestamp
}
```

---

## Relationships Diagram

```
users
  ├─ hubIds[] → hubs
  └─ fcm_tokens (subcollection)

hubs
  ├─ ownerId → users
  ├─ members[] → users (⚠️ move to subcollection)
  └─ venueIds[] → venues

games
  ├─ hubId → hubs
  ├─ organizerId → users
  ├─ venueId → venues
  ├─ participants[] → users
  └─ stats (subcollection)

posts
  ├─ authorId → users
  ├─ hubId → hubs
  ├─ relatedGameId → games
  └─ comments (subcollection)

ads
  └─ regions[] (cities)

hub_polls
  ├─ hubId → hubs
  └─ creatorId → users
```

---

## Security Rules Summary

See **05_BACKEND_COMPLETE.md** for full rules.

**Key Rules:**
- Users can read their own data
- Hub members can read Hub data
- Only managers can create games
- Only post authors can delete posts

---

## Migration Plan

See **12_KNOWN_ISSUES.md** for migration scripts.

**Critical Migrations:**
1. Hub members array → subcollection
2. FCM token field → subcollection
3. Add dateOfBirth field
4. Add bannedUserIds field

---

## Related Documents

- **03_MASTER_ARCHITECTURE.md** - Overall architecture
- **05_BACKEND_COMPLETE.md** - Backend implementation
- **12_KNOWN_ISSUES.md** - Migration scripts
