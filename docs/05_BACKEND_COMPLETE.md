# ⚙️ Kattrick - Complete Backend Guide
## Firebase Functions, Firestore Rules, Indexes & Services

> **Last Updated:** January 2025  
> **Version:** 2.0  
> **Backend:** Firebase (Functions v2, Firestore, Storage, FCM)

## Overview

Complete guide to Kattrick's Firebase backend infrastructure.

## Cloud Functions (15+ Functions)

### Scheduled Functions
- `dailyReminders` - Send game reminders (Daily 8 AM)
- `weeklyDigest` - Hub activity digest (Weekly)
- `dailyGamificationSync` - Update XP/levels (Daily 2 AM)

### Firestore Triggers
- `onGameCreated` - Create feed post when game created
- `onGameCompleted` - Update stats when game ends
- `onHubCreated` - Initialize Hub data
- `onHubMessageCreated` - Send FCM notifications for chat
- And more...

### Callable Functions
- `searchVenues` - Google Places search (⚠️ needs auth fix!)
- `getPlaceDetails` - Venue details
- `getHomeDashboardData` - Dashboard data

## Firestore Security Rules

See `/firestore.rules` in project root.

**Key Rules:**
- Users can read their own data
- Hub members can read Hub content
- Only managers can create games
- Role-based permissions

## Firestore Indexes

See `/firestore.indexes.json` in project root.

**Essential Indexes:**
- Games by Hub + scheduled date
- Posts by Hub + created date
- Users by last active

## Firebase Storage

**Structure:**
```
/users/{userId}/profile.jpg
/hubs/{hubId}/cover.jpg
/games/{gameId}/photos/{photoId}.jpg
```

**Image Resize:** Auto-resize on upload (Cloud Function)

## FCM Notifications

**Topics:**
- `hub_{hubId}` - All Hub members
- `game_{gameId}` - Game participants

## Related Documents
- **03_MASTER_ARCHITECTURE.md**
- **04_DATA_MODEL.md**
- **12_KNOWN_ISSUES.md**
