# KATTRICK - EXECUTIVE SUMMARY

**Product Name:** Kattrick  
**Market:** Israel (Hebrew)  
**Platform:** Flutter Mobile (iOS/Android)  
**Monetization:** Ad-Based (Campaign Management)  
**Current Status:** Beta (500 users, 50 hubs)  
**Target (12 months):** 10,000 MAU  

---

## 🎯 PRODUCT VISION

**Mission:** Organize pickup football in Israel - 100% free forever.

**Unique Value:**
- ✅ Zero cost for users (ad-supported, not subscription)
- ✅ Hub-based communities (not individual games)
- ✅ Smart team balancing (rating-based algorithm)
- ✅ Multi-match session recording (Winner Stays format)
- ✅ Hebrew-first, Israel-focused

---

## 💰 MONETIZATION STRATEGY

**Revenue Model:** Ad-Based (NOT Subscriptions)

**Phase 1 (Months 1-6): AdMob Integration**
- Native ads in hub feed (every 5th post)
- Banner ads in game detail screens
- Target: ₪2,500/month at 5k MAU

**Phase 2 (Months 7-12): Direct Sales**
- Self-managed ad campaign platform
- Sell to local sports shops, gyms, venues
- CPM pricing: ₪30-₪40 per 1,000 impressions
- Target: ₪10,000/month at 10k MAU

**Phase 3 (Months 13+): Hybrid Model**
- 60% direct sales, 40% AdMob
- Target: ₪40,000/month at 20k MAU

**Revenue Calculator:**
| MAU | Impressions/User/Month | Total Impressions | CPM | Monthly Revenue |
|-----|------------------------|-------------------|-----|-----------------|
| 10,000 | 50 | 500,000 | ₪30 | ₪15,000 |
| 20,000 | 60 | 1,200,000 | ₪35 | ₪42,000 |

---

## 🏗️ ARCHITECTURE OVERVIEW

**Tech Stack:**
- **Mobile:** Flutter 3.6+ (Dart)
- **Backend:** Firebase (Firestore, Auth, Storage, Functions, FCM)
- **State Management:** Riverpod
- **Real-Time:** Firestore snapshots

**Key Design Decisions:**
- **Denormalization:** 90% read reduction (counter fields, embedded data)
- **Server-Managed State:** Veteran promotion, denormalized counters (Cloud Functions)
- **Offline-First:** Unlimited Firestore cache, optimistic UI updates
- **Security:** Firestore rules enforce all permissions (no client bypass)

**Recent Refactor (Dec 3, 2025):**
- Moved hub membership from maps → HubMember subcollection
- Eliminated god-object anti-pattern
- Enabled fine-grained permission control

---

## 📊 DATA MODEL SUMMARY

**Core Entities:**
- **User** (35 fields) - Profile, stats, preferences
- **Hub** (25 fields) - Community group identity
- **HubMember** (10 fields) - **NEW** - Per-user hub data
- **Game** (50 fields) - Game instance with teams, results
- **HubEvent** (25 fields) - Planned session (converts to Game)
- **Venue** (18 fields) - Football fields/locations
- **FeedPost** (20 fields) - Social posts with comments
- **GameSignup** (4 fields) - RSVP subcollection
- **ChatMessage** (9 fields) - Hub/game/private chat
- **Notification** (10 fields) - Push + in-app notifications
- **Poll** (14 fields) - Hub polls with voting

**Relationships:**
```
User ←→ HubMember ←→ Hub
  │                   ├─→ HubEvent → Game
  │                   ├─→ FeedPost → Comment
  │                   ├─→ ChatMessage
  │                   └─→ Poll
  ├─→ Game → GameSignup
  ├─→ Notification
  └─→ PrivateMessage
```

---

## 🔐 PERMISSION SYSTEM

**4-Tier Role Hierarchy:**

| Role | Who | Permissions |
|------|-----|-------------|
| **Manager** 👑 | Hub creator | Full control (edit hub, manage venues, delete hub) |
| **Moderator** ⭐ | Promoted by manager | Create events, manage members, moderate content |
| **Veteran** 🏆 | Auto-promoted after 60 days | Record results, invite players, view analytics |
| **Member** ⚽ | Default on join | Create games, chat, post in feed |
| **Guest** 👁️ | Not a member | View only (no actions) |

**Key Features:**
- ✅ Server-managed veteran promotion (Cloud Function runs daily at 2 AM UTC)
- ✅ Single source of truth: `HubPermissionsService`
- ✅ Firestore rules enforce permissions (no client bypass)
- ✅ Audit trails for all admin actions

---

## 🎮 GAME LIFECYCLE

**Flow:**
```
1. Manager creates HubEvent (Plan)
2. Members register ("I'm In")
3. Manager clicks "Open Game" → Converts to Game
4. Auto-confirmed signups for registered players
5. TeamMaker builds balanced teams (snake draft)
6. Manager records multi-match session (Winner Stays)
7. Game marked as completed
8. Player stats updated (wins, losses, goals)
```

**Key Innovations:**
- ✅ Event vs Game distinction (Plan vs Record)
- ✅ Multi-match session support (aggregate wins)
- ✅ Automatic team balancing (rating + position-aware)
- ✅ 2-hour game reminders (Cloud Function every 30 min)

---

## 🚀 ROADMAP

**3-Month (Dec 2025 - Feb 2026):**
- ✅ Fix critical bugs, polish onboarding
- ⏳ Launch closed beta (50-100 users)
- 📋 Integrate AdMob, test ad placements

**6-Month (Mar - Aug 2026):**
- Public launch (App Store + Google Play)
- Onboard 50 active hubs
- Build admin dashboard (analytics + campaign management)
- Launch first direct ad campaign (pilot)
- **Target: 5,000 MAU**

**12-Month (Sep - Dec 2026):**
- Scale ad revenue (5-10 direct advertisers)
- Launch tournament system
- Improve player analytics dashboard
- **Target: 10,000 MAU, ₪10,000/month revenue**

---

## 📱 SCREENS OVERVIEW

**86 Total Screens Across 9 Categories:**

1. **Authentication & Onboarding (9 screens)**
   - Sign In, Sign Up, Profile Setup Wizard (4 steps)

2. **Home & Navigation (5 screens)**
   - Home, My Hubs, Discover, Profile, Settings

3. **Hub Screens (14 screens)**
   - Hub Detail, Create/Edit Hub, Hub Settings, Members, Events, Feed, Chat, Polls

4. **Game Screens (12 screens)**
   - Game Detail, Create Game, Team Maker, Game Session, RSVP Management

5. **Event Screens (8 screens)**
   - Event Detail, Create Event, Edit Event, Event Management

6. **Social Screens (11 screens)**
   - Feed, Create Post, Post Detail, Comments, Recruiting Posts

7. **Communication Screens (7 screens)**
   - Private Messages, Inbox, Hub Chat, Game Chat

8. **Discovery & Search (6 screens)**
   - Discover Hubs, Discover Venues, Regional Feed, Search

9. **Profile & Settings (14 screens)**
   - View Profile, Edit Profile, Privacy Settings, Notification Preferences, Following

---

## 🎯 KEY METRICS (KPIs)

**Growth:**
- Daily Active Users (DAU)
- Monthly Active Users (MAU)
- DAU/MAU ratio (target: 30%+)
- New registrations/week
- Retention (D1, D7, D30)

**Engagement:**
- Games per user/month (target: 3+)
- Hub posts per user/month (target: 2+)
- Chat messages per user/month (target: 10+)
- Average session duration (target: 10+ min)

**Monetization (Future):**
- Ad impressions/user/day (target: 2-3)
- Ad CTR (target: 1.5-2.5%)
- ARPU (target: $1-2/month)

**Conversion Funnels:**
```
App Install → Account Created (85%)
→ Profile Completed (70%)
→ First Hub Joined (50%)
→ First Game Signup (35%)
→ First Game Attended (25%)
```

---

## ⚠️ CRITICAL GAPS

**Must-Have for Ad Model:**
- ✅ Admin Dashboard (Months 4-6) - **CRITICAL**
  - Ad campaign management
  - Analytics dashboard
  - User/content moderation

**Deferred Features:**
- 🔴 Tournament System (Months 9-12)
- 🔴 League System (12+ months)
- 🔴 Advanced Player Analytics (12+ months)
- 🔴 Web App/PWA (Low priority)
- 🔴 Multi-Language (Only if expanding beyond Israel)

**Technical Debt:**
- Image compression inconsistency
- Limited test coverage
- No automated content moderation

---

## 💡 FUTURE OPPORTUNITIES (18+ Months)

1. **B2B Offerings:** Sell to sports facilities (₪500-₪2k/month per facility)
2. **Merchandise Integration:** Commission on sports gear sales (10-15%)
3. **Live Match Streaming:** Ad-supported live broadcasts
4. **AI Features:** Scouting reports, injury prediction, optimal lineups
5. **International Expansion:** Europe, South America (36+ months)

---

## 📈 SUCCESS CRITERIA

**6-Month Success:**
- ✅ 5,000 MAU
- ✅ 50 active hubs (10+ members each)
- ✅ ₪2,500/month ad revenue
- ✅ 30%+ DAU/MAU ratio
- ✅ Admin dashboard launched

**12-Month Success:**
- ✅ 10,000 MAU
- ✅ 100 active hubs
- ✅ ₪10,000/month ad revenue
- ✅ 5-10 direct advertisers
- ✅ 50%+ D7 retention

**Key Risks:**
- ❌ Low user adoption (mitigation: aggressive hub onboarding)
- ❌ Low ad revenue (mitigation: optimize CPM, increase impressions/user)
- ❌ High churn (mitigation: improve onboarding, add social features)

---

## 📚 DOCUMENTATION

**Full PRD:** [PRD_KATTRICK_MASTER.md](PRD_KATTRICK_MASTER.md) (10,097 lines)

**Additional Docs:**
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Firestore schema
- [HUB_PERMISSIONS.md](HUB_PERMISSIONS.md) - Permission matrix (Hebrew)
- [POLLS_USER_GUIDE.md](POLLS_USER_GUIDE.md) - Poll feature guide

**Code References:**
- Backend: `/functions/src` (34 Cloud Functions)
- Models: `/lib/models` (35+ data models)
- Screens: `/lib/screens` (86 screens)
- Services: `/lib/services` (repositories, permissions, storage)

---

**Last Updated:** December 5, 2025  
**Version:** 1.0

This executive summary complements the master PRD. For complete implementation details, architecture specs, and edge cases, refer to the full PRD document.
