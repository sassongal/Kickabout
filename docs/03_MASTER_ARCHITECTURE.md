# 🏗️ Kattrick - Master Architecture
## Complete System Design & Technical Architecture

> **Last Updated:** January 2025  
> **Version:** 2.0  
> **Architecture Pattern:** Clean Architecture + Micro-Sharding

## Overview

Kattrick uses a **Firebase-First** architecture optimized for:
- Scalability (100K+ users)
- Low cost (< ₪100/month for 1K users)
- Real-time updates
- Offline-first mobile experience

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER (Flutter)                    │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (UI)                                     │
│  ├─ Screens & Widgets (Material 3)                          │
│  └─ State Management (Riverpod 2.x)                         │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer (Business Logic)                              │
│  ├─ Use Cases                                               │
│  ├─ Entities (Freezed Models)                               │
│  └─ Repository Interfaces                                    │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Implementation)                                 │
│  ├─ Repositories (Firestore, Storage)                       │
│  ├─ Services (Auth, FCM, Maps)                              │
│  └─ Local Storage (Hive/SQLite)                             │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                   FIREBASE BACKEND                           │
├─────────────────────────────────────────────────────────────┤
│  Firebase Auth                                               │
│  ├─ Anonymous, Email, Google, Apple                          │
│  └─ Custom Claims (roles)                                    │
├─────────────────────────────────────────────────────────────┤
│  Cloud Firestore (Database)                                 │
│  ├─ Collections: users, hubs, games, venues, posts...       │
│  ├─ Security Rules (role-based)                             │
│  └─ Indexes (optimized queries)                             │
├─────────────────────────────────────────────────────────────┤
│  Cloud Functions v2 (Serverless)                            │
│  ├─ Triggers (onCreate, onUpdate, onDelete)                 │
│  ├─ Scheduled (cron jobs)                                    │
│  └─ Callable (secure APIs)                                   │
├─────────────────────────────────────────────────────────────┤
│  Firebase Storage                                            │
│  ├─ User/Hub/Game images                                     │
│  └─ Auto-resize (Cloud Function)                             │
├─────────────────────────────────────────────────────────────┤
│  Firebase Cloud Messaging (FCM)                              │
│  └─ Push notifications (topic-based)                         │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                 EXTERNAL SERVICES                            │
├─────────────────────────────────────────────────────────────┤
│  Google Maps Platform                                        │
│  ├─ Maps SDK (Android/iOS/Web)                              │
│  ├─ Places API (venue search)                               │
│  └─ Geocoding API                                            │
└─────────────────────────────────────────────────────────────┘
```

## Core Principles

### 1. Offline-First
- Firestore persistence enabled
- Local cache for recent data
- Sync when online

### 2. Real-Time Updates
- Firestore snapshots (live data)
- FCM for instant notifications
- WebSocket for chat

### 3. Micro-Sharding
- Hubs as shards (isolated communities)
- Scales horizontally
- No cross-Hub queries (fast!)

### 4. Denormalization
- Store computed values
- Reduce reads
- Accept write overhead

## Data Flow

### Example: Creating a Game

```
User (Flutter App)
  ↓
Riverpod Provider (createGameProvider)
  ↓
Game Repository (createGame method)
  ↓
Firestore (games collection write)
  ↓
Cloud Function (onGameCreated trigger)
  ├─ Create feed post
  ├─ Send FCM to Hub members
  └─ Update Hub stats
  ↓
Firestore (posts collection write)
  ↓
Flutter App (snapshot listener)
  ↓
UI Updates (new game appears)
```

## Security Architecture

### Authentication Flow
1. User signs in (Firebase Auth)
2. Get ID token
3. Attach to all requests
4. Functions validate token
5. Firestore Rules check permissions

### Role-Based Access Control

```
Owner → Full Hub control
Manager → Create games, manage members
Veteran → Start game recording
Player → Join games, post
```

## Scalability Strategy

See **14_SCALABILITY_COST.md** for full details.

**Key Points:**
- Firestore subcollections (unbounded growth)
- Pagination (limit queries)
- Caching (reduce reads)
- Denormalization (fast reads)
- Batching (reduce writes)

## Technology Stack

**Frontend:**
- Flutter 3.x
- Dart 3.x
- Riverpod 2.x
- Freezed
- GoRouter

**Backend:**
- Firebase Auth
- Cloud Firestore
- Cloud Functions v2 (TypeScript)
- Firebase Storage
- FCM

**External:**
- Google Maps Platform
- Firebase Analytics

## Related Documents

- **04_DATA_MODEL.md** - Detailed data schema
- **05_BACKEND_COMPLETE.md** - Backend implementation
- **06_FRONTEND_COMPLETE.md** - Frontend patterns
- **14_SCALABILITY_COST.md** - Scaling strategy
