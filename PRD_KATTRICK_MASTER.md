# KATTRICK - MASTER PRODUCT REQUIREMENTS DOCUMENT

**Product Name:** Kattrick (powered by Kickabout platform)
**Version:** 1.0
**Market:** Israel (Hebrew)
**Platform:** Flutter Mobile (iOS/Android)
**Document Version:** 1.0.0
**Last Updated:** December 5, 2025
**Status:** Production-Ready with Growth Roadmap

---

## DOCUMENT PURPOSE

This is the **MASTER BLUEPRINT** for the Kattrick mobile application. It serves as the single source of truth for:
- Product managers defining features
- Engineers implementing functionality
- Designers creating user experiences
- QA teams testing edge cases
- Stakeholders understanding product vision
- AI agents assisting with development

**No developer should ever need to ask questions** - everything is documented here with extreme detail.

---

# TABLE OF CONTENTS

1. [Product Vision](#1-product-vision)
2. [Target Users & Personas](#2-target-users--personas)
3. [High-Level Product Pillars](#3-high-level-product-pillars)
4. [Complete Feature Inventory](#4-complete-feature-inventory)
5. [Screen-by-Screen Documentation](#5-screen-by-screen-documentation)
6. [Full Backend Architecture](#6-full-backend-architecture)
7. [Data Models (Complete)](#7-data-models-complete)
8. [Membership & Permissions System](#8-membership--permissions-system)
9. [Game & Event Logic](#9-game--event-logic)
10. [Social & Recruiting Flow](#10-social--recruiting-flow)
11. [Chat System](#11-chat-system)
12. [Notifications System](#12-notifications-system)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Edge Cases & Failure Modes](#14-edge-cases--failure-modes)
15. [Analytics & Metrics](#15-analytics--metrics)
16. [Monetization Strategy](#16-monetization-strategy)
17. [Roadmap & Future Opportunities](#17-roadmap--future-opportunities)
18. [Technical Specifications](#18-technical-specifications)
19. [Security & Privacy](#19-security--privacy)
20. [Admin Dashboard Vision](#20-admin-dashboard-vision)

---

# 1. PRODUCT VISION

## 1.1 What is Kattrick?

Kattrick is Israel's premier social football management platform that transforms casual pickup games into organized, competitive experiences. Inspired by the legendary Hattrick football management game, Kattrick brings the same strategic depth and community spirit to real-world football.

**Core Value Proposition:**
"From Pickup to Pro: Organize games, build communities, track performance, and grow the beautiful game in Israel."

## 1.2 Target Market

**Primary Market:** Israel
**Language:** Hebrew (RTL support)
**Regions:** North (צפון), Center (מרכז), South (דרום), Jerusalem (ירושלים)
**Sport Focus:** Football/Soccer (expandable to other sports)

**Current Phase:** Israeli market penetration
**Future Expansion:** Remain Israel-focused for now, international expansion deferred

## 1.3 Mission Statement

**Long-Term Mission (5+ years):**
"Become the operating system for grassroots football in Israel, powering every pickup game, amateur league, and football community from Eilat to the Golan Heights."

**Short-Term MVP Goals (6-12 months):**
1. **100 Active Hubs** across all Israeli regions
2. **10,000 Active Players** organizing games weekly
3. **1,000 Games per Week** tracked on platform
4. **50,000 MAU** (Monthly Active Users) for ad monetization viability
5. **Community-Led Growth** - viral hub creation and player recruitment

## 1.4 Product Positioning

**Category:** Social Sports Management + Community Platform
**Competition:** WhatsApp groups, Facebook events, Teamgate, Plai
**Differentiation:**

| Feature | Kattrick | WhatsApp Groups | Teamgate | Plai |
|---------|----------|-----------------|----------|------|
| Hub Community | ✅ Deep | ❌ Flat | ⚠️ Limited | ⚠️ Limited |
| Auto Team Maker | ✅ AI-powered | ❌ Manual | ⚠️ Basic | ✅ Yes |
| Membership Tiers | ✅ 4-tier (Manager/Moderator/Veteran/Member) | ❌ Admin only | ⚠️ 2-tier | ❌ None |
| Multi-Match Sessions | ✅ Winner Stays | ❌ No | ❌ No | ❌ No |
| Regional Discovery | ✅ Geohash-based | ❌ No | ⚠️ Limited | ⚠️ Limited |
| Veteran Promotion | ✅ Automatic (60 days) | ❌ No | ❌ No | ❌ No |
| Performance Analytics | ✅ Hub-specific stats | ❌ No | ⚠️ Basic | ⚠️ Basic |
| Hebrew/RTL | ✅ Native | ⚠️ Partial | ✅ Yes | ❌ English only |
| Monetization | 🎯 Ads (planned) | ❌ Free | 💰 Subscription | 💰 Subscription |

**Positioning Statement:**
"For Israeli football players who want more than just a WhatsApp group, Kattrick is the community platform that turns casual pickups into organized, competitive experiences with AI-powered team balancing, veteran recognition, and performance tracking—all powered by community contributions, not paywalls."

## 1.5 Design Philosophy

**Theme:** "Football Meets AI" - Hattrick-Inspired
**Visual Identity:**
- **Primary Color:** Blue (#1976D2) - Hattrick heritage
- **Secondary Color:** Green (#4CAF50) - Grass/pitch
- **Accent:** Purple (#9C27B0) - Energy/competition
- **Typography:** Orbitron (headings) + Inter (body)
- **Mode:** Dark theme with light backgrounds (Hattrick style)
- **Language:** RTL Hebrew with futuristic UI elements

---

# 2. TARGET USERS & PERSONAS

## 2.1 Primary Personas

### Persona 1: The Organizer (Hub Manager)
**Name:** Yossi, 34
**Location:** Tel Aviv
**Occupation:** Tech worker
**Football Background:** Played competitively in youth, now organizes weekly games

**Goals:**
- Create a stable group of 20-30 regular players
- Reduce no-shows and last-minute cancellations
- Keep games competitive with balanced teams
- Build a community beyond just playing football
- Track who's reliable (veterans) vs new members

**Frustrations:**
- WhatsApp groups get chaotic with 50+ people
- Always the same 3 people organizing everything
- Hard to track who actually shows up
- Manual team selection takes 15 minutes every game
- No way to recognize loyal players

**Kattrick Usage:**
- Creates hub "Yossi's Wednesday Night Football"
- Promotes 2 trusted friends to Moderators
- Uses auto-team maker for every game
- Tracks veteran status (automatic after 60 days)
- Rates players 1-7 for better team balance
- Runs "Winner Stays" sessions with 5+ matches

**Engagement Loop:**
- Checks app 3-4x per week
- Creates events every Sunday for Wednesday games
- Monitors attendance 24h before game
- Records results immediately after games
- Responds to join requests within 24h

**Success Metrics:**
- Hub has 40+ active members
- 85%+ attendance rate
- 3 moderators helping manage
- 15+ veteran players recognized
- 2 games per week consistently

### Persona 2: The Veteran Player (Active Member)
**Name:** Amit, 28
**Location:** Haifa
**Occupation:** Engineer
**Football Background:** Amateur player, never misses a game

**Goals:**
- Play 2-3 times per week consistently
- Improve skills and get recognition
- Connect with other serious players
- Earn veteran status in favorite hubs
- Track personal performance over time

**Frustrations:**
- Treated the same as unreliable players
- No credit for 2+ years of consistent attendance
- Can't see own stats (goals, wins, games played)
- Hard to find new games when traveling
- No way to prove skill level to new hubs

**Kattrick Usage:**
- Member of 3 hubs (home, work area, weekend)
- Achieved veteran status in 2 hubs (60+ days)
- Can record game results as veteran
- Views hub-specific stats regularly
- Discovers new hubs when traveling for work

**Engagement Loop:**
- Opens app daily to check upcoming games
- RSVPs within 1 hour of event creation
- Confirms attendance 2 hours before game
- Checks leaderboard weekly
- Invites 1-2 friends per month

**Success Metrics:**
- Veteran in 2+ hubs
- 90%+ attendance rate
- 50+ games played lifetime
- Manager rating 5.5+ (out of 7)
- Following 20+ players

### Persona 3: The Moderator (Community Builder)
**Name:** Chen, 31
**Location:** Jerusalem
**Occupation:** Teacher
**Football Background:** Organized school teams, community-focused

**Goals:**
- Help hub manager with daily operations
- Welcome new members and maintain culture
- Moderate chat and resolve conflicts
- Create engaging events (tournaments, socials)
- Grow hub to 50+ active members

**Frustrations:**
- No authority in WhatsApp groups unless admin
- Can't remove toxic players without manager
- Want to create events but need manager permission
- Hard to track which new members are good fit
- No tools to identify inactive members

**Kattrick Usage:**
- Moderator role in 1 main hub
- Creates 2-3 events per month
- Approves join requests daily
- Moderates hub chat (delete inappropriate messages)
- Bans disruptive players (manager reviews)
- Views analytics to identify inactive members

**Engagement Loop:**
- Checks app twice daily (morning, evening)
- Responds to join requests within 4 hours
- Creates poll for next event date
- Monitors chat for conflicts
- Sends recruiting posts to regional feed

**Success Metrics:**
- 10+ events created per season
- 95%+ join request response rate <24h
- Hub growth 5+ new members per month
- 0 chat conflicts escalated to manager
- 20+ recruiting posts shared

### Persona 4: The Casual Player (New Member)
**Name:** David, 24
**Location:** Ra'anana
**Occupation:** Student
**Football Background:** Recreational player, looking for games

**Goals:**
- Find games near university/home
- Meet new people through football
- Play once a week without commitment
- Learn from better players
- Get invited to established groups

**Frustrations:**
- Don't know anyone in the area
- WhatsApp groups require referrals
- Hard to find skill-appropriate games
- Nervous about joining established groups
- Don't want to commit to every week

**Kattrick Usage:**
- Browses regional discover feed
- Requests to join 2-3 hubs
- RSVPs to 1-2 games per month
- Lurks in hub chat, rarely posts
- Follows veteran players for tips

**Engagement Loop:**
- Opens app weekly to find games
- RSVPs to games 1-2 days before
- Confirms attendance morning of game
- Doesn't check stats or analytics
- Occasionally likes posts in feed

**Success Metrics:**
- Joined 1-2 hubs successfully
- Played 5+ games in first 3 months
- Attendance rate 60%+ (learning commitment)
- Progressing toward member → veteran (6 months)
- Made 2-3 football friends

### Persona 5: The Recruiter (Growing Hub)
**Name:** Tal, 29
**Location:** Beer Sheva
**Occupation:** Sales manager
**Football Background:** Former club player, building South region community

**Goals:**
- Grow new hub from 5 to 50 members in 6 months
- Attract quality players to remote region
- Create buzz and FOMO in community
- Partner with local venues for sponsorship
- Build reputation as go-to South region hub

**Frustrations:**
- Hard to reach players outside existing network
- No viral sharing mechanism
- Can't showcase hub quality to prospects
- Limited discovery in small cities
- Competing with established Tel Aviv hubs

**Kattrick Usage:**
- Creates urgent recruiting posts 2x per week
- Shares games to regional feed with photos
- Tags venue location for discoverability
- Uses invite codes for referral tracking
- Posts action photos after every game

**Engagement Loop:**
- Creates recruiting content 3x per week
- Responds to all discovery inquiries <2h
- Hosts "trial" games for new players
- Celebrates milestones (10 members, 50 games)
- Cross-promotes with other South hubs

**Success Metrics:**
- Hub growth 10+ new members per month
- 50%+ of new members from discovery (not referrals)
- 30%+ retention after 3 months
- 100+ regional feed impressions per post
- Venue partnership secured

### Persona 6: The Admin (Platform Operations)
**Name:** Gal (Product Owner)
**Location:** Remote
**Occupation:** Founder/Developer
**Football Background:** Product visionary

**Goals:**
- Monitor platform health (uptime, errors)
- Moderate reported content/users
- Analyze usage patterns for improvements
- Manage ad campaigns and partnerships
- Support hub managers with issues

**Frustrations:**
- No centralized dashboard for metrics
- Manual intervention for bans/refunds
- Hard to identify growth opportunities
- Limited visibility into hub health
- Reactive rather than proactive

**Kattrick Usage (Current):**
- Mobile app with super admin permissions
- Firebase Console for backend monitoring
- Manual database queries for analytics
- Cloud Functions logs for debugging
- Direct message support to managers

**Kattrick Usage (Future - Admin Dashboard):**
- Web dashboard for operations
- Real-time metrics (DAU, MAU, games/week)
- Content moderation queue
- Ad campaign management
- Hub health scores and interventions

**Engagement Loop:**
- Daily health check (10 minutes)
- Weekly deep analytics review
- Monthly strategic planning
- Ad-hoc support requests
- Quarterly product roadmap updates

**Success Metrics:**
- 99.9% uptime
- <24h response to critical issues
- 50%+ YoY user growth
- 10%+ ad fill rate (future)
- 80+ NPS from hub managers

## 2.2 Anti-Personas (Out of Scope)

### Anti-Persona 1: The Professional Club Manager
**Why:** Kattrick is for grassroots/amateur football. Professional clubs need CRM, payment processing, league management—not our focus.

### Anti-Persona 2: The Tournament Organizer
**Why:** Large-scale tournaments (100+ teams) need bracket management, complex scheduling—deferred to future roadmap.

### Anti-Persona 3: The International Player (Non-Hebrew)
**Why:** Israeli market focus. No English/Arabic localization planned for 12+ months.

### Anti-Persona 4: The Stats Nerd
**Why:** Users wanting FIFA-level analytics (heat maps, pass accuracy, xG) are out of scope. We track basic stats only.

---

# 3. HIGH-LEVEL PRODUCT PILLARS

Kattrick is built on **12 foundational pillars** that guide all feature development:

## Pillar 1: Community-First Architecture
**Philosophy:** Hubs are the center of gravity, not individual games.

**Key Features:**
- Hub creation and management
- Membership tiers (Manager/Moderator/Veteran/Member)
- Automatic veteran recognition (60 days)
- Hub-specific player ratings
- Hub identity (logo, rules, culture)

**Success Metric:** 80%+ of games created within hubs (not standalone)

---

## Pillar 2: Intelligent Team Balancing
**Philosophy:** AI-powered fairness eliminates organizer bias and arguments.

**Key Features:**
- Snake draft algorithm with position awareness
- Manager ratings (1-7 scale) for hub-specific skill
- Balance score (0-100) transparency
- Manual override for special cases
- Role-based balance (GK, DEF, MID, ATT)

**Success Metric:** 85%+ team maker usage for 10+ player games

---

## Pillar 3: Veteran Recognition & Progression
**Philosophy:** Loyalty deserves rewards, trust builds community.

**Key Features:**
- Automatic veteran status after 60 days (server-managed)
- Veterans can record game results
- Veterans can invite new players
- Veterans see hub analytics
- Visual badges and recognition

**Success Metric:** 30%+ of active hub members are veterans

---

## Pillar 4: Multi-Match Session Support
**Philosophy:** Modern football is "Winner Stays," not single games.

**Key Features:**
- Multi-match recording (3-10 matches per session)
- Team color persistence across matches
- Aggregate win tracking
- Session-level MVP selection
- Flexible match duration (default 12 min)

**Success Metric:** 40%+ of recorded games use multi-match

---

## Pillar 5: Regional Discovery
**Philosophy:** Players find games through location, not just social networks.

**Key Features:**
- Geohash-based proximity search
- Regional feed (North/Center/South/Jerusalem)
- Venue-based discovery
- Recruiting posts with urgency
- Map view of hubs and games

**Success Metric:** 25%+ new hub members from discovery (not referrals)

---

## Pillar 6: Real-Time Coordination
**Philosophy:** No-shows kill games; confirmation culture saves them.

**Key Features:**
- 2-hour game reminders (FCM push)
- Attendance confirmation required
- Waitlist with auto-promotion
- Hub chat for last-minute changes
- Organizer attendance monitoring dashboard

**Success Metric:** 80%+ attendance confirmation rate, <15% no-shows

---

## Pillar 7: Performance Tracking
**Philosophy:** Players improve when they see progress.

**Key Features:**
- Hub-specific stats (wins, losses, goals, assists)
- Manager ratings (team balance)
- Games played milestones
- Position-specific tracking
- Hub leaderboards

**Success Metric:** 50%+ of players view stats monthly

---

## Pillar 8: Social Engagement
**Philosophy:** Community happens between games, not just during.

**Key Features:**
- Hub feed (posts, photos, achievements)
- Comments and likes
- Private messaging
- Following system
- Recruiting posts
- Polls (event dates, rule changes)

**Success Metric:** 2+ social interactions per game played

---

## Pillar 9: Mobile-First Experience
**Philosophy:** Football happens on the field, not at a desktop.

**Key Features:**
- Flutter native iOS/Android
- Offline-first Firestore caching
- Fast load times (<2s cold start)
- RTL Hebrew language
- Dark theme optimized for outdoor use
- One-handed operation for common tasks

**Success Metric:** 95%+ mobile usage, <5% web

---

## Pillar 10: Viral Growth Mechanics
**Philosophy:** Great products grow through sharing, not ads.

**Key Features:**
- Invite codes for tracking referrals
- Share game photos to regional feed
- Hub discovery algorithm
- New player onboarding flow
- Recruiting post amplification

**Success Metric:** 1.3+ viral coefficient (each user invites 1.3 others)

---

## Pillar 11: Trust & Safety
**Philosophy:** Toxic players destroy communities; moderation must be fast.

**Key Features:**
- Manager/moderator ban powers
- Soft-delete (ban, not delete data)
- Audit trails for all mod actions
- User blocking
- Content moderation (delete posts/comments)
- Firestore rules enforce permissions

**Success Metric:** <1% of users banned, <0.1% appeals

---

## Pillar 12: Ad-Powered Sustainability
**Philosophy:** Free for players, monetized through engaged attention.

**Key Features (Planned):**
- Native ad placements (feed, game detail, profiles)
- Campaign management dashboard
- Targeting by region, hub size, player demographics
- Performance metrics (impressions, CTR, conversions)
- Partnership opportunities (venues, brands)

**Success Metric (Future):** $0.10+ ARPU (Average Revenue Per User) per month

---

# 4. COMPLETE FEATURE INVENTORY

This section catalogs **every feature** currently in the Kattrick platform, organized by category.

## 4.1 Authentication & Onboarding

### ✅ Email/Password Authentication
- **File:** `lib/screens/auth/auth_screen.dart`
- **Status:** Production
- **Functionality:**
  - Email/password sign up
  - Email/password sign in
  - Password reset via email
  - Firebase Auth backend
- **UX Flow:** Welcome → Auth → Profile Setup → Home
- **Edge Cases:** Duplicate email shows clear error, weak passwords rejected

### ✅ Google Sign-In
- **File:** `lib/services/auth_service.dart`
- **Status:** Production
- **Functionality:**
  - One-tap Google OAuth
  - Auto-fill profile from Google account
  - iOS and Android support
- **Integration:** Firebase Auth + Google Sign-In plugin

### ✅ Apple Sign-In
- **File:** `lib/services/auth_service.dart`
- **Status:** Production (iOS only)
- **Functionality:**
  - Required for App Store approval
  - Privacy-focused (hides email option)
  - Auto-fill profile from Apple ID
- **Integration:** Firebase Auth + Sign in with Apple plugin

### ✅ Profile Setup Wizard
- **File:** `lib/screens/profile/profile_setup_wizard.dart`
- **Status:** Production
- **Functionality:**
  - Multi-step wizard (name, birthdate, position, city, photo)
  - Age gate (13+ required)
  - Preferred position selection (GK/DEF/MID/ATT)
  - Optional: social links (Facebook, Instagram)
  - Privacy settings introduction
- **Validation:**
  - Name required
  - BirthDate required (must be 13+)
  - Position required
  - City optional
- **Completion Check:** `User.isProfileComplete` flag
- **Redirect:** Incomplete profile → `/profile/setup` on auth

### ✅ Welcome Screen (First Launch)
- **File:** `lib/screens/welcome/welcome_screen.dart`
- **Status:** Production
- **Functionality:**
  - Onboarding slides explaining app features
  - "Get Started" CTA to auth
  - Only shown once (stored in shared preferences)
- **UX Flow:** Splash → Welcome (first time) → Auth

### 🔴 MISSING: Phone Number Verification
- **Status:** Not implemented
- **Rationale:** Not required for MVP, adds friction
- **Future:** SMS verification for trust/safety (Phase 2)

### 🔴 MISSING: Social Profile Import
- **Status:** Not implemented
- **Rationale:** Manual profile works, import is nice-to-have
- **Future:** Auto-fill from Facebook/Instagram public profiles

---

## 4.2 Hub Management

### ✅ Hub Creation
- **File:** `lib/screens/hub/create_hub_screen.dart`
- **Status:** Production
- **Functionality:**
  - Name, description, rules (Hebrew)
  - Main venue selection (required)
  - Logo/profile image upload
  - Privacy toggle (public/private)
  - Region selection (North/Center/South/Jerusalem)
  - Payment link (PayBox/Bit)
- **Creator Benefits:**
  - Automatically becomes Manager
  - Cannot be removed or demoted
  - Full permissions forever
- **Validation:**
  - Name required (3-50 chars)
  - Main venue required
  - Region required
- **Post-Creation:**
  - Creator added to `User.hubIds`
  - `HubMember` doc created with `role: manager, status: active`
  - Cloud Function adds super admin (gal@joya-tech.net)

### ✅ Hub Detail Screen (Tabbed Interface)
- **File:** `lib/screens/hub/hub_detail_screen.dart`
- **Status:** Production
- **Tabs:**
  1. **Feed** - Social posts, recruiting, achievements
  2. **Events** - Upcoming and past events
  3. **Players** - Member list with search/filter
  4. **Chat** - Group messaging
- **Header:**
  - Hub name, logo, member count
  - Join/Leave button (context-aware)
  - Settings gear icon (manager only)
- **FAB (Floating Action Button):**
  - Manager: Create Event, Create Game, Invite Players
  - Moderator: Create Event, Create Game
  - Veteran: Create Game
  - Member: Create Game
- **Permissions:**
  - Guest: Read-only feed and events
  - Member+: Full access to all tabs

### ✅ Hub Settings
- **File:** `lib/screens/hub/hub_settings_screen.dart`
- **Status:** Production
- **Permissions:** Manager only
- **Sections:**
  1. **Basic Info:** Name, description, region, rules
  2. **Branding:** Logo, profile image
  3. **Venues:** Add/remove playing locations, set main venue
  4. **Privacy:** Public/private toggle, join approval required
  5. **Payment:** PayBox/Bit link for member fees
  6. **Moderation:** View banned users, manage join requests
  7. **Danger Zone:** Delete hub (confirmation required)
- **Validation:**
  - Name cannot be empty
  - Main venue required (at least 1 venue)
  - Delete requires typing hub name

### ✅ Hub Members List
- **File:** `lib/screens/hub/hub_players_list_screen.dart`
- **Status:** Production (Recently refactored with HubMember subcollection)
- **Functionality:**
  - Infinite scroll pagination (20 per page)
  - Search by name, email, city, position
  - Sort by: rating, name, position, tenure (days since joined)
  - Manager rating mode (1-7 scale for team balance)
  - Role badges (Manager/Moderator/Veteran)
  - Veteran indicator (60+ days)
- **Actions (Manager/Moderator):**
  - Rate player (1-7, manager only)
  - Change role (manager only)
  - Remove member
  - Ban member (with reason)
- **Data Source:** `/hubs/{hubId}/members` subcollection
- **Performance:** Firestore query with pagination, cached locally

### ✅ Manage Roles Screen
- **File:** `lib/screens/hub/manage_roles_screen.dart`
- **Status:** Production
- **Permissions:** Manager only
- **Functionality:**
  - Promote members to Moderator
  - Demote moderators to Member
  - Cannot change Creator role
  - Veteran status shown but not editable (server-managed)
- **Validation:**
  - Must have at least 1 manager (creator)
  - Cannot demote self if only manager
- **Audit:** Updates `HubMember.updatedBy` field

### ✅ Join Requests Management
- **File:** `lib/screens/hub/hub_manage_requests_screen.dart`
- **Status:** Production
- **Permissions:** Manager/Moderator
- **Functionality:**
  - View pending join requests (for private hubs)
  - Approve/reject with one tap
  - View requester profile before decision
  - Rejection reason optional
- **UX Flow:**
  - Request → Pending → Approved (added as Member) OR Rejected (notified)
- **Notifications:**
  - Requester notified on approval
  - Requester notified on rejection (generic message)

### ✅ Hub Discovery
- **File:** `lib/screens/location/discover_hubs_screen.dart`
- **Status:** Production
- **Functionality:**
  - Browse public hubs by region
  - Search by name
  - Filter by activity level (games per week)
  - Sort by: member count, recent activity, distance
  - Map view of nearby hubs
- **Discovery Algorithm:**
  - Geohash-based proximity search (10km radius)
  - Exclude hubs user already joined
  - Show recruiting hubs first
- **Actions:**
  - Join public hub (instant)
  - Request to join private hub (approval required)
  - View hub detail as guest

### ✅ Hub Analytics
- **File:** `lib/screens/hub/hub_analytics_screen.dart`
- **Status:** Production
- **Permissions:** Manager/Moderator/Veteran
- **Metrics:**
  - Total members, active members (played in 30 days)
  - Total games, games per week trend
  - Average attendance rate
  - Veteran count and percentage
  - Most active players (by games played)
  - Most reliable players (by attendance %)
  - Player position distribution (GK/DEF/MID/ATT)
- **Visualizations:**
  - Member growth chart (last 90 days)
  - Games per week bar chart
  - Attendance rate pie chart
- **Data Source:** Aggregated from Firestore queries

### ✅ Hub Rules & Guidelines
- **File:** `lib/screens/hub/hub_rules_screen.dart`
- **Status:** Production
- **Functionality:**
  - Display hub rules in formatted text
  - Markdown support (bold, lists, links)
  - Shown on join request flow
- **Use Cases:**
  - Payment policy (e.g., "₪20 per game via Bit")
  - Behavioral rules (e.g., "No cleats on artificial turf")
  - RSVP policy (e.g., "Cancel 24h before or sit out next game")

### ✅ Banned Users List
- **File:** `lib/screens/hub/banned_users_screen.dart`
- **Status:** Production
- **Permissions:** Manager/Moderator
- **Functionality:**
  - View all banned members with ban reason
  - Unban user (restores to Member status)
  - View ban date and who banned them
- **Data Source:** `HubMember` with `status: banned`
- **Soft-Delete:** Banned users preserved for audit, not deleted

### ✅ Hub Invitations (Invite Codes)
- **File:** `lib/screens/hub/hub_invitations_screen.dart`
- **Status:** Production
- **Permissions:** Manager/Moderator/Veteran
- **Functionality:**
  - Generate unique invite code (6-char alphanumeric)
  - Share via WhatsApp, SMS, copy link
  - Track invites sent vs accepted
  - Expire codes after 30 days
- **Invite Flow:**
  - Veteran generates code → shares → new user joins via `/join/{code}` → veteran credited
- **Gamification:** Track successful invites per user (future leaderboard)

### ✅ Join by Invite Code
- **File:** `lib/screens/hub/join_by_invite_screen.dart`
- **Status:** Production
- **Functionality:**
  - Enter 6-char code or scan QR (future)
  - View hub preview before joining
  - Instant join (no approval for valid codes)
- **Validation:**
  - Code must exist and not be expired
  - User cannot already be member
  - User cannot be banned from hub

### 🔴 MISSING: Hub Templates
- **Status:** Not implemented
- **Rationale:** Every hub is unique, no clear template patterns yet
- **Future:** Pre-made templates (e.g., "Corporate League," "Weekend Warriors")

### 🔴 MISSING: Hub Roles Custom Permissions
- **Status:** Partially implemented (Hub.permissions map exists but underutilized)
- **Rationale:** 4-tier role system covers 95% of cases
- **Future:** Custom permissions per user (e.g., "User X can create events despite being Member")

### 🔴 MISSING: Hub Insights Dashboard
- **Status:** Basic analytics exist, advanced insights missing
- **Rationale:** MVP doesn't need predictive analytics
- **Future:** Churn risk, growth trajectory, engagement scores

---

## 4.3 Game & Event System

### ✅ Event Creation (Hub Events)
- **File:** `lib/screens/hub/create_hub_event_screen.dart`
- **Status:** Production
- **Permissions:** Manager/Moderator
- **Functionality:**
  - Title, description, date/time
  - Venue selection (from hub venues)
  - Team count (2-5 teams)
  - Game type (3v3 to 11v11)
  - Max participants (default 15, required)
  - Duration per match (default 12 min)
  - Notify hub members toggle
  - Show in community feed toggle
  - Attendance reminder toggle
- **Post-Creation:**
  - Event appears in hub Events tab
  - Push notification to hub members (if enabled)
  - Regional feed post (if enabled)
- **Event Model:** `HubEvent` stored in `/hubs/{hubId}/events/items/{eventId}`

### ✅ Event RSVP & Registration
- **Flow:** Hub Detail → Events Tab → Event → RSVP Button
- **Status:** Production
- **Functionality:**
  - "Join" button for members
  - "Leave" button to cancel
  - Waitlist if event is full (maxParticipants reached)
  - Auto-promotion from waitlist when spot opens
- **Notifications:**
  - Organizer notified on each signup
  - User notified when moved from waitlist to confirmed
- **Data Model:** `registeredPlayerIds` array in `HubEvent`

### ✅ Event Management Screen (Team Maker + Recording)
- **File:** `lib/screens/events/event_management_screen.dart`
- **Status:** Production (Recently enhanced)
- **Permissions:** Manager/Moderator
- **Tabs:**
  1. **Team Maker** - Generate balanced teams
  2. **Record Session** - Log multi-match results
  3. **Analytics** - Session summary (future)
- **Use Cases:**
  - Pre-game: Generate teams from registered players
  - During game: Quick team adjustments
  - Post-game: Record all match results

### ✅ Team Generator (AI-Powered)
- **File:** `lib/screens/event/team_generator_config_screen.dart`
- **Logic:** `lib/logic/team_maker.dart`
- **Status:** Production (Best-in-class)
- **Algorithm:**
  1. **Sort players by rating** (HubMember.managerRating, 1-7 scale)
  2. **Snake draft** across N teams (e.g., Team 1 → 2 → 3 → 3 → 2 → 1)
  3. **Position balance** (ensure each team has GK, DEF, MID, ATT)
  4. **Local swap optimization** (improve balance via player swaps)
  5. **Balance score** (0-100, displayed to organizer)
- **Inputs:**
  - Number of teams (2-5)
  - Players per side (optional, e.g., 5v5 = 5 per side)
  - Registered players list (from event)
- **Outputs:**
  - `TeamCreationResult` with teams and balance score
  - Teams assigned colors (Blue, Red, Green, Yellow, Orange)
- **UX:**
  - "Generate Teams" button
  - Preview teams with balance score
  - "Regenerate" button (randomize tie-breaks)
  - "Manual Edit" to swap players
  - "Save Teams" persists to `event.teams`
- **Balance Score Display:**
  - 90-100: Excellent (green)
  - 70-89: Good (yellow)
  - <70: Poor (red) - consider regenerating

### ✅ Team Generator Results Screen
- **File:** `lib/screens/event/team_generator_result_screen.dart`
- **Status:** Production
- **Functionality:**
  - Display generated teams with colors
  - Show each player's rating and position
  - Display balance score
  - Manual player swaps (drag-and-drop)
  - Regenerate teams button
  - Save and continue to session

### ✅ Multi-Match Game Session
- **File:** `lib/screens/event/game_session_screen.dart`
- **Status:** Production (Unique feature)
- **Use Cases:**
  - Winner Stays format
  - Best-of-3
  - Round robin (3-4 teams)
- **Functionality:**
  - Start session from event
  - Record each match separately
  - Track team colors across matches
  - Input scores per match
  - Select goal scorers and assists (optional)
  - Aggregate wins displayed in real-time
  - MVP voting at end of session
- **Data Model:**
  - `event.matches` array of `MatchResult`
  - `event.aggregateWins` map (e.g., `{Blue: 6, Red: 4, Green: 2}`)
- **Example Session:**
  ```
  Match 1: Blue 5-3 Red (12 min)
  Match 2: Blue 4-4 Green (12 min)
  Match 3: Red 6-2 Green (12 min)
  Match 4: Blue 5-4 Red (12 min)

  Final: Blue (14 points), Red (10), Green (6)
  MVP: Player X (Blue) - 4 goals, 2 assists
  ```

### ✅ Game Recording Screen (Single Game)
- **File:** `lib/screens/game/game_recording_screen.dart`
- **Status:** Production
- **Permissions:** Manager/Moderator/Veteran
- **Functionality:**
  - Input final scores per team
  - Select goal scorers (multi-select)
  - Select assists (multi-select)
  - MVP vote (single select)
  - Optional: match duration override
  - Save to Firestore + trigger Cloud Function
- **Validations:**
  - Scores must be non-negative integers
  - Goal scorers count should match total goals (warning if not)
  - MVP must be in confirmed players list
- **Post-Recording:**
  - Game status → `completed`
  - Cloud Function `onGameCompleted` triggers
  - Player stats updated (wins, losses, goals, assists)
  - Community feed post created
  - Notifications sent to participants

### ✅ Standalone Game Creation
- **File:** `lib/screens/game/create_game_screen.dart`
- **Status:** Production
- **Functionality:**
  - Create game outside hub context (public pickup)
  - All event creation fields plus:
    - Visibility (private/public/recruiting)
    - Targeting criteria (age range, skill level)
    - Requires approval toggle
    - Min/max players
  - Associated with hub (optional)
- **Use Cases:**
  - One-off pickup game
  - Public game for recruiting
  - Corporate event
  - Tournament match (future)

### ✅ Game Detail Screen
- **File:** `lib/screens/game/game_detail_screen.dart`
- **Status:** Production
- **Sections:**
  1. **Header:** Game title, date, venue, organizer
  2. **Teams:** If formed, display teams with colors
  3. **Attendees:** Confirmed players (avatars)
  4. **Scores:** If completed, show final score/matches
  5. **Chat:** Game-specific messaging
  6. **Actions:**
     - RSVP (Join/Leave)
     - Confirm Attendance (2h before game)
     - Navigate to Team Maker
     - Navigate to Recording (after game)
- **Permissions:**
  - Organizer: Edit, Cancel, Record Results
  - Manager/Moderator: Edit, Cancel, Record Results
  - Veteran: Record Results (if participated)
  - Member: RSVP, Chat
  - Guest: View only

### ✅ Game List Screen
- **File:** `lib/screens/game/game_list_screen.dart`
- **Status:** Production
- **Filters:**
  - My Games (where I'm confirmed)
  - Hub Games (for selected hub)
  - All Games (discovery feed)
- **Sort:**
  - Upcoming (default)
  - Recent (past games)
  - Popular (most participants)
- **Display:**
  - Card layout with game photo
  - Date, time, venue
  - Organizer name and hub
  - Confirmed count / max capacity
  - Status badge (Recruiting, Full, In Progress, Completed)

### ✅ Game Calendar View
- **File:** `lib/screens/game/game_calendar_screen.dart`
- **Status:** Production
- **Functionality:**
  - Month calendar with game dots
  - Day view shows all games for selected date
  - Filter by hub
  - Color-coded by status (upcoming/completed)
- **Use Cases:**
  - Players planning weekly schedule
  - Organizers avoiding conflicts

### ✅ All Events Screen (Combined)
- **File:** `lib/screens/game/all_events_screen.dart`
- **Status:** Production
- **Functionality:**
  - Unified view of hub events + standalone games
  - Filter: Upcoming, This Week, Past
  - Sort: Date, Hub
  - Search by name, venue
- **Data Sources:**
  - HubEvents from user's hubs
  - Games where user is confirmed
  - Public recruiting games nearby

### ✅ Attendance Confirmation
- **File:** `lib/screens/game/confirm_attendance_screen.dart`
- **Status:** Production
- **Trigger:** Push notification 2 hours before game
- **Functionality:**
  - "I'm Coming" button (green, large)
  - "Can't Make It" button (red)
  - Reason field for cancellation (optional)
- **Notifications:**
  - Organizer notified on cancellation
  - Waitlist player promoted if spot opens

### ✅ Attendance Monitoring (Organizer)
- **File:** `lib/screens/game/attendance_monitoring_screen.dart`
- **Status:** Production
- **Permissions:** Organizer, Manager, Moderator
- **Functionality:**
  - Real-time attendance status per player:
    - ✅ Confirmed (green)
    - ⏳ Pending (yellow)
    - ❌ Cancelled (red)
  - Contact unconfirmed players (WhatsApp/call)
  - Promote from waitlist manually
  - Cancel game if threshold not met (e.g., <8 players)
- **Display:**
  - Progress bar: X/Y confirmed
  - List of players with status icons
  - Last confirmed timestamp per player

### ✅ Log Past Game (Retroactive Recording)
- **File:** `lib/screens/game/log_past_game_screen.dart`
- **Status:** Production
- **Use Cases:**
  - Record game that happened before Kattrick adoption
  - Fix missing data from pre-platform games
  - Bulk import for established hubs
- **Functionality:**
  - Select past date
  - Select participants (from hub members)
  - Input scores, goal scorers
  - No RSVP/attendance tracking (historical)
- **Validation:**
  - Date must be in past (<30 days recommended)
  - At least 4 participants required

### ✅ Game Chat
- **File:** `lib/screens/game/game_chat_screen.dart`
- **Status:** Production
- **Functionality:**
  - Real-time messaging for game participants
  - Only confirmed players can send messages
  - Organizer can delete messages
  - Last message shown in game detail
- **Use Cases:**
  - "I'm 10 min late"
  - "Did anyone bring a ball?"
  - "Game moved to Field 2"
- **Data Model:** `/games/{gameId}/chatMessages/{messageId}`
- **Permissions:** Confirmed players read/write, organizer delete

### ✅ Recurring Games
- **Fields:** `Game.isRecurring`, `recurrencePattern`, `recurrenceEndDate`
- **Status:** Production (data model complete, UI partial)
- **Functionality:**
  - Mark game as recurring (weekly, biweekly, monthly)
  - Generate child games automatically (Cloud Function or client)
  - Link parent/child via `parentGameId`
- **UI State:** Pattern defined, auto-generation needs Cloud Function (TODO)

### 🔴 MISSING: Game Templates
- **Status:** Not implemented
- **Rationale:** Most games are event-based, templates are nice-to-have
- **Future:** "Copy Previous Game" button

### 🔴 MISSING: Tournament Brackets
- **Status:** Not implemented
- **Rationale:** Deferred to Phase 2 (complex bracket logic)
- **Future:** Elimination, group stage, knockout tournaments

### 🔴 MISSING: League Standings
- **Status:** Not implemented
- **Rationale:** Leagues require season structure, fixtures, points system
- **Future:** Multi-week league management

### 🔴 MISSING: Referee Assignment
- **Status:** Not implemented
- **Rationale:** Amateur games self-referee
- **Future:** Paid referee booking for semi-pro games

---

## 4.4 Social Features

### ✅ Hub Feed
- **File:** `lib/screens/social/feed_screen.dart`
- **Status:** Production
- **Functionality:**
  - Chronological feed of hub posts
  - Post types: Text, Photos (up to 4), Recruiting, Achievement
  - Like button (heart icon)
  - Comment button (opens post detail)
  - Share button (future)
- **Feed Algorithm:**
  - Chronological (newest first)
  - No algorithmic ranking yet
  - Filter: All, Photos Only, Recruiting Only
- **Actions:**
  - Member+: Create post, like, comment
  - Guest: Read only

### ✅ Create Post
- **File:** `lib/screens/social/create_post_screen.dart`
- **Status:** Production
- **Permissions:** Hub members (not guests)
- **Functionality:**
  - Text input (500 char max)
  - Upload 1-4 photos (compressed)
  - Tag location/venue (optional)
  - Notify hub members toggle
- **Validations:**
  - Text or photo required (not both empty)
  - File size <5MB per photo
  - Auto-compress images to 1920px width
- **Post-Creation:**
  - Appears in hub feed immediately
  - Push notification to hub members (if enabled)
  - Denormalized author name/photo

### ✅ Create Recruiting Post
- **File:** `lib/screens/social/create_recruiting_post_screen.dart`
- **Status:** Production
- **Permissions:** Manager/Moderator/Veteran
- **Functionality:**
  - All standard post fields plus:
    - "Urgent" badge (red)
    - "Recruiting until" date/time
    - "Needed players" count
    - Target audience (skill level, age range)
  - Automatically posted to regional feed
- **Use Cases:**
  - "Need 2 more defenders for tonight's game!"
  - "Looking for experienced goalkeeper for new hub"
- **Amplification:**
  - Regional feed (North/Center/South/Jerusalem)
  - Push notification to nearby users (future)

### ✅ Post Detail Screen
- **File:** `lib/screens/social/post_detail_screen.dart`
- **Status:** Production
- **Functionality:**
  - Full post display (no truncation)
  - All photos in gallery swiper
  - Like list (show who liked)
  - Comment thread (nested not supported)
  - Share options (future)
- **Comment Section:**
  - Create comment (text input at bottom)
  - Delete own comment
  - Delete any comment (manager/moderator)
  - Denormalized commenter name/photo
- **Data Model:**
  - Post: `/hubs/{hubId}/feed/posts/items/{postId}`
  - Comments: `/hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}`

### ✅ Community Activity Feed
- **File:** `lib/screens/activity/community_activity_feed_screen.dart`
- **Status:** Production
- **Functionality:**
  - Regional feed across all hubs
  - Filter by region (North/Center/South/Jerusalem)
  - Post types: Game completed, Recruiting, Achievement
  - Discover new hubs and players
- **Feed Content:**
  - Game results with scores and MVP
  - Recruiting posts from nearby hubs
  - Player achievements (first goal, 50 games played)
- **Discovery Mechanism:**
  - Tap hub name → Hub detail (guest view)
  - Tap player name → Player profile
  - "Join Hub" button in posts

### ✅ Hub Chat
- **File:** `lib/screens/social/hub_chat_screen.dart`
- **Status:** Production
- **Permissions:** Hub members (not guests)
- **Functionality:**
  - Real-time group messaging (Firestore snapshots)
  - Message ordering (oldest first)
  - Sender name and avatar
  - Timestamp (relative, e.g., "2h ago")
  - Delete message (own message or moderator)
  - Read receipts (future)
- **Data Model:** `/hubs/{hubId}/chatMessages/{messageId}`
- **Denormalization:**
  - `senderName`, `senderPhotoUrl` cached for fast display
  - Cloud Function `onHubMessageCreated` updates denormalized fields

### ✅ Private Messaging (1-on-1)
- **Files:**
  - `lib/screens/social/messages_list_screen.dart` (inbox)
  - `lib/screens/social/private_chat_screen.dart` (conversation)
- **Status:** Production
- **Functionality:**
  - Send direct messages to any user
  - Conversation list with last message preview
  - Unread count badge
  - Real-time message delivery
  - Block user (messages no longer delivered)
- **Data Model:**
  - Conversation: `/private_messages/{conversationId}` (participantIds)
  - Messages: `/private_messages/{conversationId}/messages/{messageId}`
- **Privacy:**
  - Only conversation participants can read
  - Cannot message blocked users
  - Firestore rules enforce participant-only access

### ✅ Notifications Inbox
- **File:** `lib/screens/social/notifications_screen.dart`
- **Status:** Production
- **Functionality:**
  - Chronological list of notifications (newest first)
  - Read/unread status (bold for unread)
  - Notification types:
    - Game reminder (2h before game)
    - New message (hub chat, private message)
    - Like, comment on post
    - New follower
    - RSVP signup to your game
    - Join request to your hub
  - Tap notification → Navigate to entity (game, post, profile)
  - Mark as read (swipe or tap)
  - Mark all as read button
- **Data Model:** `/notifications/{userId}/items/{notificationId}`
- **Badge Count:**
  - Unread count shown on home tab
  - Synced via Firestore real-time listener

### ✅ Following System
- **Files:**
  - `lib/screens/social/following_screen.dart` (who you follow)
  - `lib/screens/social/followers_screen.dart` (who follows you)
- **Status:** Production
- **Functionality:**
  - Follow any user
  - Unfollow any user
  - View follower/following counts on profile
  - Follower count denormalized (Cloud Function updates)
- **Data Model:**
  - Following: `/users/{userId}/following/{followingId}`
  - Followers: `/users/{userId}/followers/{followerId}`
- **Notifications:**
  - User notified when someone follows them
  - No notification on unfollow (privacy)

### ✅ User Blocking
- **File:** `lib/screens/profile/blocked_users_screen.dart`
- **Status:** Production
- **Functionality:**
  - Block user (from profile or chat)
  - Blocked users cannot:
    - Send private messages
    - Comment on your posts
    - See your profile (future - not enforced yet)
  - Unblock user
  - Blocked user list with avatars
- **Data Model:** `User.blockedUserIds` array
- **Firestore Rules:**
  - Cannot create private message if blocked
  - Cannot create comment if blocked (checked in rules)

### ✅ Polls (Hub Voting)
- **Files:**
  - `lib/screens/hub/create_poll_screen.dart`
  - `lib/screens/hub/poll_detail_screen.dart`
- **Status:** Production
- **Permissions:** Manager/Moderator create, all members vote
- **Poll Types:**
  - Single choice
  - Multiple choice (checkboxes)
  - Rating (1-5 stars)
- **Functionality:**
  - Create poll with 2-10 options
  - Set expiration date
  - Allow multiple votes (toggle)
  - Show results before voting (toggle)
  - Anonymous voting (toggle)
  - Auto-close poll at expiration (Cloud Function)
- **Voting:**
  - Vote once (or multiple if enabled)
  - Change vote before poll closes
  - Results shown as percentages + counts
- **Use Cases:**
  - "What time works for next game? 6pm/7pm/8pm"
  - "Should we switch to new venue? Yes/No"
  - "Rate last game (1-5)"

### 🔴 MISSING: Post Reporting
- **Status:** Not implemented
- **Rationale:** Moderation handled by managers/moderators manually
- **Future:** Report button → queue for moderators

### 🔴 MISSING: Hashtags
- **Status:** Not implemented
- **Rationale:** Search/discovery not mature enough for hashtags
- **Future:** #TelAviv #DefendersWanted for discovery

### 🔴 MISSING: Mentions (@username)
- **Status:** Not implemented
- **Rationale:** Nice-to-have, not critical
- **Future:** @username mentions with notifications

### 🔴 MISSING: Post Editing
- **Status:** Not implemented (only delete)
- **Rationale:** Edit history tracking needed for trust
- **Future:** Edit with "edited" badge + history

---

## 4.5 Player Profiles & Stats

### ✅ Player Profile Screen (Futuristic Design)
- **File:** `lib/screens/profile/player_profile_screen_futuristic.dart`
- **Status:** Production
- **Sections:**
  1. **Header:**
     - Avatar, name, preferred position
     - City, region
     - Social links (Facebook, Instagram) if `showSocialLinks` enabled
     - Follow/Unfollow button
     - Edit button (own profile only)
  2. **Stats Card:**
     - Total games played
     - Win rate (wins / total)
     - Goals, assists
     - Hubs joined
     - Veteran in X hubs
  3. **Hubs Tab:**
     - List of hubs user is member of
     - Role badge (Manager/Moderator/Veteran)
     - Days since joined each hub
  4. **Performance Tab:**
     - Position breakdown (games played per position)
     - Hub-specific stats (navigate to hub stats screen)
     - Form factor (recent performance trend - future)
  5. **Activity Feed:**
     - Recent games played (last 10)
     - Recent posts/comments
- **Privacy:**
  - Respect `User.privacySettings` (hide email, phone, stats, etc.)
  - Blocked users see minimal profile

### ✅ Edit Profile
- **File:** `lib/screens/profile/edit_profile_screen.dart`
- **Status:** Production
- **Editable Fields:**
  - Display name, first name, last name
  - Avatar (upload or crop existing)
  - Birthdate (cannot change after set, shown as age)
  - Preferred position (GK/DEF/MID/ATT)
  - City, region
  - Social links (Facebook, Instagram)
  - Show social links toggle
  - Availability status (available/busy/not available)
- **Validations:**
  - Name cannot be empty
  - Birthdate must be 13+ years ago
  - Valid URLs for social links
- **Avatar Upload:**
  - Image picker (camera or gallery)
  - Crop to square
  - Compress to 512x512
  - Upload to Firebase Storage
  - Update `User.photoUrl`

### ✅ Hub-Specific Stats
- **File:** `lib/screens/profile/hub_stats_screen.dart`
- **Status:** Production
- **Functionality:**
  - Stats for single hub (not global)
  - Games played in hub
  - Win/loss/draw in hub
  - Goals, assists in hub
  - Manager rating (1-7, visible to player)
  - Attendance rate in hub
  - Role and veteran status
- **Use Cases:**
  - Player sees how they perform in specific hub
  - Manager reviews player contribution before rating

### ✅ Performance Breakdown
- **File:** `lib/screens/profile/performance_breakdown_screen.dart`
- **Status:** Production
- **Visualizations:**
  - Pie chart: Games by position (GK/DEF/MID/ATT)
  - Line chart: Goals per game (last 20 games)
  - Bar chart: Win rate by hub
  - Heatmap: Days of week most active (future)
- **Filters:**
  - Last 30 days / 90 days / All time
  - By hub
  - By position

### ✅ Privacy Settings
- **File:** `lib/screens/profile/privacy_settings_screen.dart`
- **Status:** Production
- **Toggles:**
  - Hide from search (not discoverable in player search)
  - Hide email (visible only to hub managers)
  - Hide phone (visible only to hub managers)
  - Hide city (not shown on profile)
  - Hide stats (games/wins/goals not public)
  - Hide ratings (manager ratings not shown)
- **Defaults:** All false (public profile)
- **Data Model:** `User.privacySettings` map

### ✅ Notification Preferences
- **File:** `lib/screens/profile/notification_settings_screen.dart`
- **Status:** Production
- **Categories:**
  1. **Games:**
     - Game reminders (2h before)
     - New game created in hub
     - Signup confirmation
     - Attendance confirmation
  2. **Social:**
     - Likes on posts
     - Comments on posts
     - New follower
  3. **Communication:**
     - Hub chat messages
     - Private messages
     - Mentions (future)
- **Toggles:** Individual per notification type
- **Defaults:** All enabled except "likes" (too noisy)
- **Data Model:** `User.notificationPreferences` map

### ✅ Blocked Users Management
- **File:** `lib/screens/profile/blocked_users_screen.dart`
- **Status:** Production (documented above in Social section)

### ✅ Settings Screen
- **File:** `lib/screens/profile/settings_screen.dart`
- **Status:** Production
- **Options:**
  - Edit Profile
  - Privacy Settings
  - Notification Preferences
  - Blocked Users
  - Language (Hebrew only for now)
  - Theme (Dark only for now)
  - About (version, credits)
  - Terms of Service (link)
  - Privacy Policy (link)
  - Contact Support (email)
  - Logout
  - Delete Account (confirmation required)
- **Delete Account:**
  - Soft-delete (mark inactive, preserve data)
  - Remove from all hubs
  - Anonymize posts/comments (future)

### 🔴 MISSING: Player Skill Badges
- **Status:** Not implemented
- **Rationale:** No skill assessment system yet
- **Future:** Verified badges (e.g., "Goalkeeper," "Team Captain," "Veteran of 3+ hubs")

### 🔴 MISSING: Player Endorsements
- **Status:** Not implemented
- **Rationale:** Peer validation system deferred
- **Future:** Players endorse each other (e.g., "Great teammate," "Excellent passer")

### 🔴 MISSING: Player Video Highlights
- **Status:** Not implemented
- **Rationale:** Video storage/streaming infrastructure needed
- **Future:** Upload goal clips, best moments

---

## 4.6 Discovery & Maps

### ✅ Discover Hubs
- **File:** `lib/screens/location/discover_hubs_screen.dart`
- **Status:** Production (documented above in Hub Management)

### ✅ Map View of Hubs
- **File:** `lib/screens/location/map_screen.dart`
- **Status:** Production
- **Functionality:**
  - Google Maps integration
  - Hubs displayed as markers (cluster if dense)
  - Tap marker → Hub preview card
  - Current location button
  - Search address bar
  - Filter: All hubs / My hubs / Recruiting
- **Performance:**
  - Loads hubs within viewport only (Firestore geohash query)
  - Marker clustering for 10+ hubs in small area
- **Use Cases:**
  - Find hubs near new home/office
  - Explore football density in region

### ✅ Map Picker (Location Selection)
- **File:** `lib/screens/location/map_picker_screen.dart`
- **Status:** Production
- **Use Cases:**
  - Set hub location during creation
  - Set venue location
  - Set custom game location
- **Functionality:**
  - Map with draggable pin
  - Search address autocomplete (Google Places)
  - "Use Current Location" button
  - Confirm selection returns GeoPoint

### ✅ Discover Venues
- **File:** `lib/screens/venues/discover_venues_screen.dart`
- **Status:** Production
- **Functionality:**
  - Browse public venues (football pitches)
  - Search by name or address
  - Filter: Grass / Artificial / Indoor
  - Sort: Distance, rating (future), popularity
  - Map view toggle
- **Venue Sources:**
  - User-created venues (public)
  - OpenStreetMap football pitches (synced via Cloud Function)
  - Google Places "football pitch" (future)
- **Data Model:** `Venue` with `isPublic: true`

### ✅ Venue Search & Autocomplete
- **File:** `lib/screens/venue/venue_search_screen.dart`
- **Status:** Production
- **Functionality:**
  - Google Places Autocomplete API
  - Type query → get suggestions
  - Select venue → returns place details
  - "Create Manual Venue" fallback if not found
- **Use Cases:**
  - Hub creation (select main venue)
  - Event creation (select venue)
  - Add new venue to hub

### ✅ Create Manual Venue
- **File:** `lib/screens/venue/create_manual_venue_screen.dart`
- **Status:** Production
- **Functionality:**
  - Name, address (freeform text)
  - Location (map picker)
  - Surface type (grass/artificial/concrete)
  - Max players (default 11)
  - Amenities (parking, showers, lights) - checkboxes
  - Public/Private toggle
  - Photo upload (future)
- **Post-Creation:**
  - Venue saved to `/venues/{venueId}`
  - Associated with hub via `Venue.hubId`
  - Denormalized to hub if primary venue

### ✅ Players Map (Discovery)
- **File:** `lib/screens/players/players_map_screen.dart`
- **Status:** Production
- **Functionality:**
  - Show active players on map (if location shared)
  - Filter by position (GK/DEF/MID/ATT)
  - Filter by availability status
  - Tap player → View profile
- **Privacy:**
  - Respects `User.location` field
  - Hidden if `privacySettings.hideFromSearch` enabled
- **Use Cases:**
  - Discover players in new neighborhood
  - Recruit for local hub

### 🔴 MISSING: Venue Ratings/Reviews
- **Status:** Not implemented
- **Rationale:** Venue quality is subjective, focus on quantity first
- **Future:** 5-star ratings, reviews (pitch quality, parking, etc.)

### 🔴 MISSING: Venue Photos
- **Status:** Data model exists (`Venue.photoUrls`), UI not implemented
- **Rationale:** Manual photo upload per venue is tedious
- **Future:** Auto-fetch from Google Places, user-contributed gallery

---

## 4.7 Gamification & Rankings

### ✅ Regional Leaderboards
- **File:** `lib/screens/gamification/leaderboard_screen.dart`
- **Status:** Production
- **Leaderboard Types:**
  1. **Hub Leaderboard** - Top players in single hub
  2. **Regional Leaderboard** - Top players in North/Center/South/Jerusalem
  3. **Global Leaderboard** - Top players nationwide
- **Ranking Criteria:**
  - Games played (participation)
  - Win rate (wins / total games)
  - Goals scored
  - Assists
  - Manager rating (avg across hubs)
  - Attendance rate
- **Filters:**
  - Last 30 days / Last season / All time
  - By position (GK/DEF/MID/ATT)
- **Display:**
  - Top 100 players
  - User's rank highlighted
  - Profile link on tap

### ✅ Veteran Recognition System
- **Status:** Production (Core Pillar #3)
- **Functionality:**
  - Automatic veteran promotion after 60 days (Cloud Function `promoteVeterans`)
  - Veteran badge on profile and hub members list
  - Veterans get expanded permissions (record results, invite players, view analytics)
  - `HubMember.veteranSince` timestamp (server-managed)
- **Notification:**
  - User notified when promoted to veteran (future)
  - Celebration post in hub feed (future)

### ✅ Achievements & Badges (Backend Only)
- **Service:** `lib/services/gamification_service.dart` (DEPRECATED)
- **Cloud Function:** `functions/src/gamification.js`
- **Status:** Backend complete, UI partial
- **Achievement Types:**
  - First game played
  - 10 games played
  - 50 games played
  - 100 games played (Century Club)
  - First goal scored
  - Hat trick (3 goals in one game)
  - Clean sheet (goalkeeper, no goals conceded)
  - Perfect attendance (10 games, 100% on time)
  - Hub founder (created hub)
  - Veteran (60 days in hub)
- **Data Model:** `/users/{userId}/gamification/stats`
- **UI:** Badges display planned but not implemented yet

### ✅ Hub Activity Score
- **Field:** `Hub.activityScore`
- **Status:** Data model exists, calculation not finalized
- **Factors:**
  - Games per week
  - Member growth rate
  - Veteran percentage
  - Post engagement (likes, comments)
  - Attendance rate
- **Use Case:** Hub discovery ranking (most active hubs first)

### 🔴 MISSING: Global Skill Rating (Elo/TrueSkill)
- **Status:** Not implemented
- **Current:** Manager rating (1-7) is hub-specific
- **Rationale:** Global skill rating requires cross-hub match data, deferred
- **Future:** Elo-based rating for matchmaking, tournaments

### 🔴 MISSING: Leaderboard Prizes/Rewards
- **Status:** Not implemented
- **Rationale:** No monetization or prize fulfillment yet
- **Future:** Monthly/seasonal prizes (football gear, venue credits)

### 🔴 MISSING: Streaks (Attendance)
- **Status:** Not implemented
- **Rationale:** Engagement mechanic deferred
- **Future:** "X weeks in a row" streak badges

### 🔴 MISSING: Team Leaderboards
- **Status:** Not implemented
- **Rationale:** No persistent teams concept yet (teams are per-game)
- **Future:** Club system with team rankings

---

## 4.8 Admin & Operations

### ✅ Admin Dashboard (Mobile)
- **File:** `lib/screens/admin/admin_dashboard_screen.dart`
- **Status:** Production (basic)
- **Permissions:** Super admin only (hard-coded email)
- **Functionality:**
  - View total users, hubs, games
  - View recent errors (Crashlytics link)
  - View Cloud Functions status
  - Generate dummy data (test environments)
  - Manual data fixes (ban user, delete hub)
- **UI:** Simple list of actions, no charts yet

### ✅ Generate Dummy Data
- **File:** `lib/screens/admin/generate_dummy_data_screen.dart`
- **Script:** `lib/scripts/generate_dummy_data.dart`
- **Status:** Production
- **Use Cases:**
  - Populate test environment
  - Create team balance scenario for QA
  - Demo mode for screenshots
- **Scenarios:**
  1. **Basic Hub** - 1 hub, 10 users, 5 games
  2. **Team Balance Scenario** - 1 hub, 15 users (rated), 1 event ready for team maker
  3. **Full Ecosystem** - 5 hubs, 50 users, 20 games, social posts
- **Button:** Purple button "Create Team Balance Scenario"

### ✅ Super Admin Auto-Add
- **Cloud Function:** `functions/src/hubs.js:addSuperAdminToHub`
- **Status:** Production
- **Functionality:**
  - Automatically adds super admin (gal@joya-tech.net) to every new hub as Manager
  - Allows monitoring and support without manual join
- **Trigger:** On hub creation (`onCreate`)

### ✅ Auth Status Screen (Debug)
- **File:** `lib/screens/debug/auth_status_screen.dart`
- **Status:** Production
- **Functionality:**
  - Display current user UID
  - Display Firebase Auth state
  - Display custom claims (future)
  - Test Firestore connection
  - Test Cloud Functions connection

### ✅ Error Monitoring (Crashlytics)
- **Service:** `lib/services/error_handler_service.dart`
- **Status:** Production
- **Functionality:**
  - Catch unhandled exceptions
  - Log to Firebase Crashlytics (non-web)
  - Include user context (UID, hub ID, screen)
  - Fatal vs non-fatal errors
- **Integration:** Firebase Crashlytics SDK

### ✅ Analytics Tracking
- **Service:** `lib/services/analytics_service.dart`
- **Status:** Production
- **Events Tracked:**
  - Screen views (auto)
  - Hub creation
  - Game creation
  - RSVP
  - Post creation
  - Team maker usage
  - Result recording
- **User Properties:**
  - Hub count
  - Games played
  - Veteran status
- **Integration:** Firebase Analytics

### ✅ Remote Config
- **Service:** `lib/services/remote_config_service.dart`
- **Status:** Production
- **Flags:**
  - `enable_recruiting_posts` (bool)
  - `max_photos_per_post` (int, default 4)
  - `veteran_days_threshold` (int, default 60)
  - `enable_polls` (bool)
  - `maintenance_mode` (bool)
- **Fetch:** On app start + every 12h

### 🔴 MISSING: Web Admin Dashboard
- **Status:** Not implemented
- **Rationale:** Mobile app sufficient for current scale
- **Future:** Web dashboard for:
  - Real-time metrics (DAU, MAU, games/week)
  - Content moderation queue
  - User support (view profiles, ban users)
  - Hub health monitoring (inactive hubs, churn risk)
  - Ad campaign management
  - Financial reporting

### 🔴 MISSING: Moderation Queue
- **Status:** Not implemented
- **Rationale:** Manual moderation by hub managers sufficient
- **Future:** Centralized queue for reported content (posts, comments, profiles)

### 🔴 MISSING: A/B Testing Framework
- **Status:** Not implemented
- **Rationale:** Remote Config flags exist but no A/B test orchestration
- **Future:** Firebase A/B Testing or custom solution

---

## 4.9 Additional Features

### ✅ Weather Integration
- **File:** `lib/screens/weather/weather_detail_screen.dart`
- **Service:** `lib/services/weather_service.dart`
- **Status:** Production
- **Functionality:**
  - Fetch weather forecast for game location
  - Display temperature, precipitation, wind
  - 3-hour forecast (6 intervals)
  - Weather API: Open-Meteo (free, no API key)
- **Use Cases:**
  - Check weather before confirming attendance
  - Organizer decides to cancel game due to rain

### ✅ Scouting System
- **File:** `lib/screens/hub/scouting_screen.dart`
- **Service:** `lib/services/scouting_service.dart`
- **Status:** Production
- **Permissions:** Manager/Moderator/Veteran
- **Functionality:**
  - Search for players in region
  - Filter by position, availability
  - View player profile preview
  - Invite to hub (direct message or invite code)
- **Scouting Score:**
  - Games played
  - Attendance rate
  - Average rating
  - Active status
- **Use Cases:**
  - Recruit experienced goalkeeper
  - Find players in new region

### ✅ Venue Management
- **Status:** Production (documented above in Discovery section)
- **Repository:** `lib/data/venues_repository.dart`
- **Functions:**
  - Create venue
  - Update venue
  - Delete venue (soft-delete)
  - List venues by hub
  - Search nearby venues (geohash)

### ✅ Payment Link Integration
- **Field:** `Hub.paymentLink`
- **Status:** Production (simple link storage)
- **Supported:** PayBox, Bit (Israeli payment platforms)
- **Functionality:**
  - Manager adds payment link in hub settings
  - Displayed to members on RSVP
  - No in-app payment processing (external link)
- **Future:** In-app payment with Stripe/PayPal

### ✅ Invite by WhatsApp
- **Status:** Production (deep link integration)
- **Functionality:**
  - Generate invite link: `kattrick://join/{inviteCode}`
  - Share via WhatsApp, SMS, copy
  - Recipient opens app → auto-join hub
- **Tracking:** Invite code links to inviter UID

### ✅ Profile Avatar Upload
- **Status:** Production
- **Service:** `lib/services/storage_service.dart`
- **Functionality:**
  - Image picker (camera or gallery)
  - Crop to square (1:1 aspect ratio)
  - Compress to 512x512 (reduce size)
  - Upload to Firebase Storage `/avatars/{uid}.jpg`
  - Update `User.photoUrl` with public URL
- **Validation:**
  - Max file size 5MB before upload
  - JPEG/PNG only

### ✅ Photo Uploads (Posts, Games)
- **Status:** Production
- **Service:** `lib/services/storage_service.dart`
- **Functionality:**
  - Upload 1-4 photos per post
  - Upload game photos post-match
  - Image compression to 1920px width
  - Gallery swiper for viewing
- **Storage Path:** `/uploads/{hubId}/{postId}/{imageId}.jpg`

### ✅ Offline Support
- **Status:** Production (Firestore persistence)
- **Functionality:**
  - Unlimited offline cache (Firestore)
  - Reads work offline (cached data)
  - Writes queued and retried when online
  - User notified if critical action requires connection
- **Edge Cases:**
  - No "offline mode" toggle needed
  - Automatic reconnection handling

### 🔴 MISSING: Multi-Language Support
- **Status:** Hebrew only
- **Rationale:** Israeli market focus
- **Future:** Arabic (Israeli Arabs), English (tourists, expats)

### 🔴 MISSING: Dark/Light Theme Toggle
- **Status:** Dark theme only
- **Rationale:** Consistent brand, simplifies design
- **Future:** User preference toggle

### 🔴 MISSING: Export Data (GDPR)
- **Status:** Not implemented
- **Rationale:** Not required for Israeli privacy laws yet
- **Future:** Export user data as JSON (EU expansion)

---

# (CONTINUED IN NEXT MESSAGE DUE TO LENGTH...)


# 5. SCREEN-BY-SCREEN DOCUMENTATION

This section provides exhaustive documentation for every screen in Kattrick, organized by flow.

## 5.1 Authentication & Onboarding Flow

### Splash Screen
**File:** `lib/screens/splash/splash_screen.dart`  
**Route:** `/splash`  
**Auth Required:** No  

**Purpose:** App initialization and routing logic

**UI Elements:**
- Kattrick logo (animated fade-in)
- Loading spinner
- App version number (bottom)

**Logic:**
```dart
1. Check if user has seen welcome screen (SharedPreferences)
2. Check Firebase Auth state
3. If authenticated:
   a. Load user document from Firestore
   b. Check if profile is complete
   c. If incomplete → /profile/setup
   d. If complete → / (home)
4. If not authenticated:
   a. If first launch → /welcome
   b. If returning → /auth
```

**Loading Time:** <2 seconds (cached Firestore data)

**Error States:**
- Firebase initialization failed → Show limited mode banner
- Network timeout → Retry with exponential backoff
- User document missing → Force profile setup

---

### Welcome Screen (Onboarding)
**File:** `lib/screens/welcome/welcome_screen.dart`  
**Route:** `/welcome`  
**Auth Required:** No  
**Shown:** First launch only

**Purpose:** Introduce Kattrick value proposition

**UI Elements:**
- **Slide 1:** "Organize Games" - Team maker preview
- **Slide 2:** "Build Communities" - Hub system preview
- **Slide 3:** "Track Performance" - Stats preview
- **Slide 4:** "Join Thousands" - Regional map preview
- Skip button (top right)
- Next/Previous buttons
- "Get Started" CTA button (final slide)

**Flow:**
1. User swipes through slides or taps Next
2. Can skip anytime → /auth
3. Final slide → "Get Started" → /auth
4. Mark welcome as seen in SharedPreferences

**A/B Test Opportunity:** Test 3-slide vs 5-slide onboarding (retention impact)

---

### Auth Screen (Unified)
**File:** `lib/screens/auth/auth_screen.dart`  
**Route:** `/auth`  
**Auth Required:** No

**Purpose:** Single authentication screen (no separate login/register)

**UI Modes:**
1. **Default (Login):** Email/password fields, "Sign In" button, "Forgot Password" link, "Don't have an account? Sign Up" link
2. **Sign Up Mode:** Email/password/confirm password fields, "Create Account" button, "Already have account? Sign In" link

**Social Auth Buttons:**
- Google Sign-In (Android + iOS)
- Apple Sign-In (iOS only, required for App Store)
- Future: Facebook (if requested)

**Validation:**
- Email: Valid format, @domain.com
- Password: Min 8 chars, 1 uppercase, 1 number (Firebase default)
- Confirm Password: Must match password

**Error Handling:**
- "Email already in use" → Switch to login mode
- "Invalid credentials" → Show error, suggest password reset
- "Network error" → Retry button

**Success Flow:**
- Email/Password Sign Up → /profile/setup (new user)
- Email/Password Sign In → / (returning user with complete profile)
- Google/Apple Sign In → Check if profile exists → /profile/setup or /

---

### Profile Setup Wizard
**File:** `lib/screens/profile/profile_setup_wizard.dart`  
**Route:** `/profile/setup`  
**Auth Required:** Yes  
**Forced:** If `User.isProfileComplete == false`

**Purpose:** Complete mandatory profile fields

**Steps (4 screens):**

**Step 1: Basic Info**
- Display Name (prefilled from auth if available)
- First Name
- Last Name
- "Continue" button (disabled until filled)

**Step 2: Birthdate (Age Gate)**
- Date picker (scrollable year/month/day)
- Age calculated and displayed
- Validation: Must be 13+ years old
- Error: "You must be 13 or older to use Kattrick"
- **Critical:** Cannot skip, enforced for legal compliance

**Step 3: Football Info**
- Preferred Position: Goalkeeper, Defender, Midfielder, Attacker (single select cards)
- City (dropdown, Israeli cities + "Other")
- Region: North, Center, South, Jerusalem (auto-filled from city)

**Step 4: Optional**
- Profile Photo (camera/gallery picker, skippable)
- Social Links: Facebook URL, Instagram URL (skippable)
- "Show social links on profile" toggle (default: false)

**Completion:**
- Set `User.isProfileComplete = true`
- Redirect to / (home)
- Show success message: "Welcome to Kattrick!"

**Progress Indicator:** 1/4, 2/4, 3/4, 4/4 dots at top

**Edge Cases:**
- User presses back → Confirm exit dialog: "Profile setup is required to continue"
- User closes app mid-setup → Resume on step 1 next launch

---

## 5.2 Home & Discovery Flow

### Home Screen (Futuristic Dashboard)
**File:** `lib/screens/home_screen_futuristic_figma.dart`  
**Route:** `/`  
**Auth Required:** Yes  
**Default Landing:** After successful auth with complete profile

**Purpose:** Central hub for all user activity

**Layout (Scrollable):**

**1. Header Section:**
- User avatar (top left)
- Notification bell icon with badge count (top right)
- Settings gear icon (top right)
- Welcome message: "Welcome back, [DisplayName]"
- Current weather widget (if location enabled)

**2. Quick Stats Card:**
- Upcoming games count (next 7 days)
- Hubs joined
- Games played (lifetime)
- Veteran in X hubs

**3. Upcoming Games Section:**
- Title: "Your Next Games"
- Horizontal scroll list of game cards (next 5 games)
- Each card: Date, time, hub name, venue, confirmed count
- "View All" button → /games

**4. Hubs Section:**
- Title: "Your Hubs"
- Grid of hub cards (2 columns)
- Each card: Hub logo, name, member count, unread chat count badge
- "Discover Hubs" button → /discover-hubs

**5. Community Activity:**
- Title: "What's Happening"
- Feed preview (last 5 posts from user's hubs)
- Like/comment buttons (inline)
- "View Feed" button → /community

**6. Actions FAB (Floating Action Button):**
- Plus icon (main button)
- Expands to:
  - Create Game
  - Create Hub (if not manager of 3+ hubs)
  - Discover Hubs
  - Find Players

**Bottom Navigation (Persistent):**
- Home (active)
- Games
- Community
- Profile

**Data Loading:**
- Parallel Firestore queries:
  - User document (cached)
  - Upcoming games (next 7 days where user is confirmed)
  - User's hubs (from `User.hubIds`)
  - Community feed preview (last 5 posts)
- Loading skeleton UI while data loads
- Error state: "Failed to load, tap to retry"

**Permissions:** All authenticated users, no special role required

---

### Community Screen
**File:** `lib/screens/community/community_screen.dart`  
**Route:** `/community`  
**Tab:** Community (bottom nav)

**Purpose:** Regional feed across all hubs

**Tabs (Top):**
1. **For You:** Personalized feed (user's hubs + nearby hubs)
2. **Regional:** All public posts in user's region
3. **Recruiting:** Urgent recruiting posts only

**Filters (Dropdown):**
- All Regions
- North
- Center
- South
- Jerusalem

**Feed Items:**
- Post cards (text + up to 4 photos)
- Game result cards (scores, MVP, photos)
- Achievement cards (milestones)
- Recruiting cards (urgent badge, deadline)

**Actions per Post:**
- Like (heart icon, count)
- Comment (comment icon, count) → Opens post detail
- Share (future)

**Infinite Scroll:**
- Load 20 posts initially
- Load next 20 when scrolled to 80% (pagination)

**Empty State:**
- "No activity yet in your region"
- "Create a post or join more hubs"

---

## 5.3 Hub Management Flow

### Hub List Screen
**File:** `lib/screens/hub/hub_list_screen.dart`  
**Route:** `/hubs`  
**Tab:** Games → My Hubs (sub-tab)

**Purpose:** Browse user's joined hubs

**Layout:**
- List of hub cards (vertical scroll)
- Each card:
  - Hub logo, name
  - Role badge (Manager/Moderator/Veteran/Member)
  - Member count
  - Unread messages badge (red dot)
  - Last activity timestamp
  - Tap → /hubs/{hubId}

**Sort Options (Dropdown):**
- Recent Activity (default)
- Alphabetical
- Member Count

**Actions:**
- "Create Hub" button (top right)
- "Discover Hubs" button (bottom)

**Data Source:** User's hubs from `User.hubIds`, fetch hub documents

---

### Create Hub Screen
**File:** `lib/screens/hub/create_hub_screen.dart`  
**Route:** `/hubs/create`  
**Permissions:** All authenticated users (limit 3 managed hubs)

**Purpose:** Create new football hub

**Form Fields:**

**1. Basic Info (Page 1/3):**
- Hub Name* (required, 3-50 chars, Hebrew/English)
- Description (optional, 500 chars max)
- Region* (dropdown: North, Center, South, Jerusalem)
- Hub Rules (optional, markdown supported)
- "Next" button

**2. Venue (Page 2/3):**
- Search venue (Google Places autocomplete)
- OR "Create Manual Venue" button
- Main Venue* (required, must select 1+)
- Additional Venues (optional, can add multiple)
- "Next" button

**3. Settings (Page 3/3):**
- Privacy: Public / Private (toggle)
  - Public: Anyone can join
  - Private: Requires approval
- Logo Upload (optional, square image)
- Payment Link (optional, PayBox/Bit URL)
- "Create Hub" button

**Validation:**
- Name cannot be empty
- Region required
- Main venue required
- If private, must have payment link or explanation

**Post-Creation:**
1. Hub document created in Firestore
2. Creator added as Manager (role: manager, status: active)
3. Cloud Function adds super admin
4. Navigate to /hubs/{hubId}
5. Show toast: "Hub created! Invite players to get started"

**Edge Cases:**
- User already manages 3 hubs → Error: "You can manage up to 3 hubs. Archive one to create new."
- Duplicate hub name in region → Warning: "Hub with similar name exists, continue?"

---

### Hub Detail Screen
**File:** `lib/screens/hub/hub_detail_screen.dart`  
**Route:** `/hubs/{hubId}`  
**Permissions:** Guest can view (limited), Member+ can interact

**Purpose:** Central hub for all hub activity

**Header:**
- Hub logo (large, circular)
- Hub name
- Member count
- Region badge
- Settings gear icon (manager only)
- Join/Leave button (context-aware):
  - Guest: "Request to Join" (private) or "Join" (public)
  - Member: "Leave Hub" (confirmation dialog)

**Tabs (Horizontal Swipe):**

**1. Feed Tab:**
- Hub social feed (posts, photos, recruiting)
- Create Post FAB (members only)
- Infinite scroll
- Like/comment inline

**2. Events Tab:**
**File:** `lib/screens/hub/hub_events_tab.dart`  
- List of hub events (upcoming first, then past)
- Filter: Upcoming / This Week / Past
- Sort: Date (ascending for upcoming, descending for past)
- Each event card:
  - Title, date, time
  - Registered count / max participants
  - Status badge (Upcoming/Ongoing/Completed/Cancelled)
  - RSVP button (members)
  - "Manage" button (manager/moderator)
- "Create Event" FAB (manager/moderator only)
- Empty state: "No events yet. Managers can create the first event!"

**3. Players Tab:**
- Hub members list (see dedicated screen below)
- Search bar
- Filter/sort options
- Tap player → player profile

**4. Chat Tab:**
- Group chat (see dedicated screen below)
- Only members can send
- All can read

**FAB (Context-Aware):**
- Manager: "Create Event", "Create Game", "Invite Players"
- Moderator: "Create Event", "Create Game"
- Veteran: "Create Game"
- Member: "Create Game"
- Guest: No FAB

**Data Loading:**
- Hub document (with membership check)
- User's HubMember document (for role/status)
- Tab data loaded lazily (when tab selected)

---

### Hub Settings Screen
**File:** `lib/screens/hub/hub_settings_screen.dart`  
**Route:** `/hubs/{hubId}/settings`  
**Permissions:** Manager only

**Purpose:** Configure hub settings

**Sections (Scrollable):**

**1. Basic Info:**
- Edit name, description, rules
- Change region (warning: affects discovery)
- "Save Changes" button

**2. Branding:**
- Upload/change hub logo
- Upload/change profile image
- "Save" button

**3. Venues:**
- List of hub venues (cards)
- Set main venue (radio select)
- Add venue button → venue search
- Remove venue (if not main)
- Edit venue (name, surface type)

**4. Privacy & Membership:**
- Public/Private toggle
- "Require join approval" toggle (even for public)
- "Allow members to invite" toggle (default: veterans only)

**5. Payment:**
- Payment link (PayBox/Bit)
- Instructions: "Add your payment link for member fees"
- "Save" button

**6. Moderation:**
- View banned users button → /hubs/{hubId}/banned
- Manage join requests button → /hubs/{hubId}/requests (if private)
- Manage roles button → /hubs/{hubId}/manage-roles

**7. Advanced:**
- Hub ID (read-only, copyable)
- Created date
- Total games played
- Last activity

**8. Danger Zone (Red):**
- Archive hub (soft-delete, reversible)
- Delete hub (permanent, requires typing hub name)

**Validation:**
- Name cannot be empty
- Must have at least 1 venue
- Payment link must be valid URL (if provided)

**Auto-Save:** Changes saved immediately on blur (per field)

---

### Hub Players List Screen
**File:** `lib/screens/hub/hub_players_list_screen.dart`  
**Route:** `/hubs/{hubId}/players`  
**Permissions:** All members (read), Manager/Moderator (actions)

**Purpose:** Browse and manage hub members

**Header:**
- Member count
- Search bar (name, email, city, position)
- Filter icon (opens filter modal)
- Sort icon (opens sort modal)

**Filter Modal:**
- Role: All, Manager, Moderator, Veteran, Member
- Position: All, GK, DEF, MID, ATT
- Status: Active only (default), Include left/banned

**Sort Modal:**
- Rating (high to low) - manager only
- Name (A-Z)
- Position
- Tenure (days since joined, high to low)
- Games Played (high to low)

**Member List (Infinite Scroll):**
- Each member card:
  - Avatar
  - Name
  - Role badge (color-coded)
  - Veteran badge (if applicable, with days)
  - Manager rating (stars, 1-7, manager only)
  - Position icon
  - Days since joined (e.g., "in hub for 45 days")
  - Tap → Player profile
  - Long press → Actions menu (manager/moderator)

**Actions Menu (Manager/Moderator):**
- Rate Player (manager only) → Opens rating dialog (1-7 slider)
- Change Role (manager only) → Opens role selection dialog
- Remove from Hub → Confirmation dialog
- Ban from Hub → Requires reason

**Manager Rating Dialog:**
**File:** `lib/widgets/dialogs/set_player_rating_dialog.dart`  
- Title: "Rate [Player Name] for Team Balance"
- Explanation: "1 = Beginner, 7 = Elite. Used for team generation."
- Slider: 1-7 (0.5 increments)
- Current rating shown
- "Save" button
- Updates `HubMember.managerRating`

**Pagination:**
- Load 20 members initially
- Load next 20 on scroll

**Data Source:** `/hubs/{hubId}/members` subcollection (Firestore query with filters/sort)

**Performance:**
- Firestore index required for complex queries (role + tenure)
- Local caching for fast subsequent loads

---

### Manage Roles Screen
**File:** `lib/screens/hub/manage_roles_screen.dart`  
**Route:** `/hubs/{hubId}/manage-roles`  
**Permissions:** Manager only

**Purpose:** Assign moderator roles

**Layout:**
- List of members grouped by role:
  - **Managers** (creator always first, cannot be changed)
  - **Moderators** (with "Demote" button)
  - **Veterans** (read-only, server-managed)
  - **Members** (with "Promote to Moderator" button)

**Promote to Moderator Flow:**
1. Tap "Promote" on member card
2. Confirmation dialog: "Promote [Name] to Moderator? They will be able to manage members, create events, and moderate chat."
3. On confirm: Update `HubMember.role = moderator`, `updatedBy = currentUserId`
4. Show toast: "[Name] is now a Moderator"
5. Send notification to promoted user

**Demote Moderator Flow:**
1. Tap "Demote" on moderator card
2. Confirmation dialog: "Demote [Name] to Member? They will lose moderator permissions."
3. On confirm: Update `HubMember.role = member`
4. Show toast: "[Name] is now a Member"

**Rules:**
- Cannot change creator role (always Manager)
- Cannot demote self if only manager
- Veteran status shown but not editable (server-managed after 60 days)

---

### Hub Manage Join Requests
**File:** `lib/screens/hub/hub_manage_requests_screen.dart`  
**Route:** `/hubs/{hubId}/requests`  
**Permissions:** Manager/Moderator  
**Shown:** Only for private hubs

**Purpose:** Approve/reject join requests

**List:**
- Pending requests (newest first)
- Each request card:
  - User avatar
  - User name
  - City, position
  - Games played (platform-wide)
  - Requested date
  - "View Profile" button
  - "Approve" button (green)
  - "Reject" button (red)

**Approve Flow:**
1. Tap "Approve"
2. User added to hub as Member
3. `HubMember` created with `role: member, status: active`
4. User notified: "You've been accepted to [Hub Name]"
5. Request removed from list

**Reject Flow:**
1. Tap "Reject"
2. (Optional) Rejection reason dialog
3. User notified: "Your request to join [Hub Name] was declined"
4. Request removed from list
5. User cannot re-request for 30 days (future)

**Empty State:**
- "No pending requests"
- "Join requests will appear here"

---

### Hub Analytics Screen
**File:** `lib/screens/hub/hub_analytics_screen.dart`  
**Route:** `/hubs/{hubId}/analytics`  
**Permissions:** Manager/Moderator/Veteran

**Purpose:** Hub health and engagement metrics

**Sections:**

**1. Overview Cards:**
- Total Members
- Active Members (played in last 30 days)
- Total Games
- Games per Week (avg last 4 weeks)
- Attendance Rate (avg)
- Veteran Percentage

**2. Member Growth Chart:**
- Line chart: Last 90 days
- X-axis: Date
- Y-axis: Member count
- Tooltip: Date, count, delta from previous day

**3. Game Activity Chart:**
- Bar chart: Last 12 weeks
- X-axis: Week
- Y-axis: Games played
- Color-coded: Completed (green), Cancelled (red)

**4. Top Players:**
- Table: Most Active (games played)
- Table: Most Reliable (attendance %)
- Table: Top Scorers (goals)
- Table: Top Assists

**5. Position Distribution:**
- Pie chart: GK, DEF, MID, ATT
- Shows balance (ideal: 10% GK, 30% DEF, 30% MID, 30% ATT)

**6. Engagement Metrics:**
- Avg players per game
- Avg RSVP time (hours before game)
- No-show rate
- Waitlist conversion rate

**Data Source:**
- Aggregated from Firestore queries (no pre-computed)
- Queries: hub members, games, signups
- Performance: Cache for 1 hour (Firebase Remote Config)

**Future:** Real-time dashboard with Cloud Function aggregations

---

### Scouting Screen
**File:** `lib/screens/hub/scouting_screen.dart`  
**Route:** `/hubs/{hubId}/scouting`  
**Permissions:** Manager/Moderator/Veteran

**Purpose:** Discover and recruit players

**Search Filters:**
- Position: All, GK, DEF, MID, ATT
- Region: All, North, Center, South, Jerusalem
- Availability: Available only
- Skill Level: All, Beginner (0-3 rating), Intermediate (3-5), Advanced (5-7)
- Distance: Within 5km / 10km / 20km / Any

**Results List:**
- Player cards with:
  - Avatar
  - Name, age
  - Position, city
  - Games played (platform-wide)
  - Average rating (if public)
  - Availability status
  - Distance from hub (if location enabled)
  - "Invite" button

**Invite Flow:**
1. Tap "Invite" on player card
2. Choose invite method:
   - Send invite code (via app DM)
   - Share WhatsApp invite link
   - Copy invite link
3. Track invite sent (future: conversion tracking)

**Scouting Score (Hidden from UI, backend sorting):**
- Games played: 30%
- Attendance rate: 25%
- Average rating: 20%
- Active status: 15%
- Distance proximity: 10%

**Privacy Respect:**
- Hides players with `privacySettings.hideFromSearch = true`
- Respects location privacy
- No contact info shown (must invite via app)

---

## 5.4 Game & Event Flow

### Create Hub Event Screen
**File:** `lib/screens/hub/create_hub_event_screen.dart`  
**Route:** `/hubs/{hubId}/events/create`  
**Permissions:** Manager/Moderator

**Purpose:** Create hub-managed event (pre-game planning)

**Form (Scrollable):**

**1. Basic Info:**
- Title* (e.g., "Wednesday Night Football", 50 chars max)
- Description (optional, 500 chars max)
- Event Date & Time* (date/time picker)

**2. Game Settings:**
- Team Count* (2-5 teams, default 3)
- Game Type* (dropdown: 3v3, 4v4, 5v5, 6v6, 7v7, 8v8, 9v9, 10v10, 11v11, default 5v5)
- Duration per Match (default 12 minutes, adjustable 5-30 min)
- Max Participants* (default 15, based on game type × team count)

**3. Location:**
- Select Venue* (from hub venues, dropdown)
- OR "Use Custom Location" (map picker)

**4. Options:**
- Notify hub members (toggle, default ON)
- Show in community feed (toggle, default OFF)
- Enable attendance reminder (toggle, default ON)

**Validation:**
- Title required
- Date must be in future
- Max participants must be ≥ teamCount × (gameType number)
- Venue required

**Post-Creation:**
1. `HubEvent` document created in `/hubs/{hubId}/events/items/{eventId}`
2. If "Notify members" ON:
   - Push notification to all active hub members
   - Title: "[Hub Name] - New Event"
   - Body: "[Title] on [Date]"
3. If "Show in community feed" ON:
   - Create regional feed post
4. Navigate to Event Detail screen
5. Show toast: "Event created! Players can now sign up"

---

### Event Management Screen
**File:** `lib/screens/events/event_management_screen.dart` (and `/event/event_management_screen.dart`)  
**Route:** `/hubs/{hubId}/events/{eventId}/manage`  
**Permissions:** Manager/Moderator

**Purpose:** Manage event lifecycle (team generation → game recording)

**Header:**
- Event title
- Date, time, venue
- Registered players count / max
- Status badge (Upcoming/Ongoing/Completed)

**Tabs:**

**Tab 1: Registered Players**
- List of registered players (avatar, name, position)
- Checkboxes to select/deselect for team generation
- "Select All" / "Deselect All"
- Actions:
  - Remove player (with reason)
  - Move to waitlist
  - Send reminder (individual)

**Tab 2: Team Generator**
- "Generate Balanced Teams" button
- If teams already generated:
  - Show teams with colors
  - Balance score displayed
  - "Regenerate" button
  - "Edit Teams" button (manual swaps)
- Navigate to Team Generator Config Screen

**Tab 3: Start Session (Future)**
- "Start Game Session" button (opens game recording)
- Disabled until teams are generated
- Shows estimated end time based on match count

**Actions (Bottom):**
- Edit Event (change date, venue, max participants)
- Cancel Event (with reason, notifies all registered)
- Delete Event (if no signups, confirmation required)

---

### Team Generator Config Screen
**File:** `lib/screens/event/team_generator_config_screen.dart`  
**Route:** `/events/{eventId}/team-maker/config`  
**Permissions:** Manager/Moderator

**Purpose:** Configure team generation parameters

**Configuration Form:**

**1. Player Selection:**
- List of confirmed players (from event registeredPlayerIds)
- Checkboxes to include/exclude
- Shows each player's:
  - Name, avatar
  - Position (GK/DEF/MID/ATT)
  - Manager rating (1-7)
  - Games played in hub
- "Select All" / "Deselect All" buttons

**2. Team Settings:**
- Number of Teams (2-5, dropdown, default from event)
- Players Per Side (optional, e.g., 5 for 5v5, auto-calculated if not provided)
- Balance Priority (dropdown):
  - Skill Balance (default, uses manager rating)
  - Position Balance (ensures GK, DEF, MID, ATT per team)
  - Mixed (both skill and position)

**3. Advanced (Collapsible):**
- Lock Players to Teams (future: pre-assign certain players)
- Ensure Veteran Distribution (toggle, default OFF)
- Randomize Tie-Breaks (toggle, default ON)

**Actions:**
- "Generate Teams" button → Calls `TeamMaker.createBalancedTeams()`
- Navigate to Team Generator Result Screen

**Algorithm Used:**
**File:** `lib/logic/team_maker.dart`  
1. Sort players by rating (descending)
2. Snake draft across teams (Team 1 → 2 → 3 → 3 → 2 → 1)
3. Check position balance (each team should have at least 1 GK if 11v11, 1 DEF, 1 MID, 1 ATT)
4. Local swap optimization (try swapping players to improve balance)
5. Calculate balance score (0-100 based on rating variance)
6. Return `TeamCreationResult` with teams and score

---

### Team Generator Result Screen
**File:** `lib/screens/event/team_generator_result_screen.dart`  
**Route:** `/events/{eventId}/team-maker/result`  
**Permissions:** Manager/Moderator

**Purpose:** Review and adjust generated teams

**UI Layout:**

**Header:**
- Balance Score: 87/100 (color-coded: green 90-100, yellow 70-89, red <70)
- "Excellent Balance" / "Good Balance" / "Poor Balance" message

**Teams Display:**
- Each team in colored card (Blue, Red, Green, Yellow, Orange)
- Team Name (editable inline)
- Player list:
  - Avatar, name
  - Position badge
  - Rating (stars, 1-7)
  - Drag handle (for manual swaps)
- Team Average Rating (calculated)
- Team Position Distribution (e.g., "1 GK, 2 DEF, 2 MID, 2 ATT")

**Actions:**
- Drag player from one team to another (manual swap)
- Tap player → Quick swap menu (select target team)
- "Regenerate" button (randomize tie-breaks, new snake draft)
- "Save Teams" button → Persist to `event.teams`, navigate back to Event Management
- "Cancel" button → Discard changes, navigate back

**Validation:**
- Cannot save with team size variance >2 (e.g., Team 1 has 5, Team 2 has 8 = invalid)
- Warning if balance score <70: "Teams are imbalanced. Consider regenerating."

**Auto-Save:** Teams auto-saved as draft on manual swaps (restore if user leaves and returns)

---

### Game Session Screen (Multi-Match Recording)
**File:** `lib/screens/event/game_session_screen.dart`  
**Route:** `/events/{eventId}/session`  
**Permissions:** Manager/Moderator/Veteran

**Purpose:** Record multi-match session (Winner Stays, Best-of-3, etc.)

**Header:**
- Session title (from event)
- Current time elapsed (timer)
- Match count (e.g., "Match 3 of 5")
- "End Session" button (confirmation required)

**Current Match Card:**
- Team A vs Team B (color-coded)
- Score input (number pickers, + / - buttons)
- Goal scorers (multi-select from team players)
- Assists (multi-select from team players)
- Match duration (default 12 min, editable)
- "Complete Match" button

**Completed Matches List:**
- Chronological list of finished matches
- Each match card:
  - Team A [Score] - [Score] Team B
  - Duration
  - Goal scorers listed
  - "Edit" button (manager only)

**Aggregate Standings:**
- Table showing team rankings
- Columns: Team, Wins, Losses, Draws, Goals For, Goals Against, Points (3 for win, 1 for draw)
- Sorted by points (descending)

**Actions:**
- "Next Match" button (after completing current)
- "Finalize Session" button (after all matches)
  - Opens MVP selection modal
  - Confirms final scores
  - Triggers Cloud Function `onGameCompleted`
  - Updates player stats (wins, losses, goals, assists)
  - Creates community feed post
- "Cancel Session" button (confirmation, warns data loss)

**Session Types:**
1. **Fixed Match Count:** (e.g., Best-of-3)
   - Pre-defined number of matches
   - Session ends when all matches completed
2. **Winner Stays:** (default)
   - Infinite matches until organizer ends
   - Winning team stays, losing team rotates out
   - Aggregate wins tracked
3. **Round Robin:** (if 3-4 teams)
   - Each team plays every other team once
   - Fixed schedule displayed upfront

**Data Model:** Saves to `event.matches` array (each match is `MatchResult` object)

---

### Create Game Screen (Standalone)
**File:** `lib/screens/game/create_game_screen.dart`  
**Route:** `/games/create`  
**Permissions:** All hub members (if associated with hub), or anyone (if public)

**Purpose:** Create standalone game (not hub event)

**Form (Similar to Create Event, with additions):**

**1. Basic Info:**
- Game Title*
- Description
- Date & Time*
- Hub (dropdown of user's hubs, optional for public games)

**2. Game Type:**
- Team Count (2-5)
- Game Type (3v3 to 11v11)
- Visibility* (new field):
  - **Private:** Hub members only
  - **Public:** Anyone can join
  - **Recruiting:** Public + shown in regional feed

**3. Location:**
- Venue (if hub selected)
- Custom Location (map picker)

**4. Capacity:**
- Min Players to Play* (e.g., 8 for 5v5, 2 teams × 4 players min)
- Max Players* (hard cap)
- Requires Approval (toggle, default OFF for public)

**5. Targeting (if Public/Recruiting):**
- Age Range (13-18, 18-25, 25-35, 35-50, 50+, multiple select)
- Skill Level (Beginner, Intermediate, Advanced)
- Gender (future: Male, Female, Mixed)

**6. Options:**
- Recurring (toggle)
  - If ON: Select pattern (Weekly, Biweekly, Monthly)
  - End date (when to stop creating recurrences)
- Enable Attendance Reminder (toggle, default ON)
- Show in Community Feed (toggle, default OFF unless Recruiting)

**Validation:**
- Title, date, visibility required
- Min players ≤ max players
- If public/recruiting, location must be set (for discovery)

**Post-Creation:**
1. `Game` document created
2. If recurring: Generate child games (Cloud Function or client-side)
3. If recruiting: Create regional feed post
4. If hub-associated: Notify hub members (if enabled)
5. Creator auto-added as confirmed
6. Navigate to Game Detail
7. Show toast: "Game created! Share with friends"

---

### Game Detail Screen
**File:** `lib/screens/game/game_detail_screen.dart`  
**Route:** `/games/{gameId}`  
**Permissions:** Read (all), Write (confirmed players + manager)

**Purpose:** View and interact with game

**Header:**
- Game title
- Date, time (with countdown if future)
- Venue name + address
- Weather icon (tap → weather detail)
- Organizer avatar + name
- Status badge (Recruiting/Upcoming/Full/In Progress/Completed)

**Actions (Context-Aware):**
- **Not Signed Up:**
  - "Join Game" button (green, large)
    - If requires approval → "Request to Join"
    - If full → "Join Waitlist"
  - "Share" button (WhatsApp, copy link)
- **Signed Up (Pending):**
  - "Cancel RSVP" button (red)
  - Status: "Waiting for approval"
- **Confirmed:**
  - "Confirm Attendance" button (2h before game)
  - "Cancel" button (with reason)
  - Status: "You're confirmed!"
- **Organizer/Manager:**
  - "Edit Game" button (pencil icon)
  - "Manage Attendance" button (see attendance_monitoring_screen)
  - "Start Team Maker" button (if >10 players)
  - "Record Results" button (after game date)
  - "Cancel Game" button (with notification to all)

**Tabs:**

**Tab 1: Info**
- Description (full text)
- Hub name (if associated) + link
- Location map (tap → Google Maps)
- Game rules (if any)
- Capacity: X/Y confirmed

**Tab 2: Attendees**
- Confirmed players (avatar grid)
- Pending approvals (if organizer)
- Waitlist (if full)
- Tap player → view profile
- Organizer can approve/reject from here

**Tab 3: Teams (if formed)**
- Display teams with colors
- Player list per team
- Position distribution

**Tab 4: Results (if completed)**
- Final scores
- Goal scorers, assists
- MVP
- Match-by-match breakdown (if session)
- Aggregate wins (if session)
- Photos (if uploaded)

**Tab 5: Chat**
- Game-specific chat (see game_chat_screen below)
- Only confirmed players can send messages
- Real-time updates

**Notifications:**
- Push notification when approved/rejected
- Push notification 2h before game (if attendance reminder enabled)
- Push notification when moved from waitlist to confirmed

---

### Game Chat Screen
**File:** `lib/screens/game/game_chat_screen.dart`  
**Route:** `/games/{gameId}/chat`  
**Permissions:** Read (all confirmed), Write (confirmed only)

**Purpose:** Game-specific messaging

**UI Layout:**
- Message list (scrollable, oldest at top)
- Each message:
  - Sender avatar (small)
  - Sender name
  - Message text
  - Timestamp (relative, e.g., "5 min ago")
  - Delete icon (own message or organizer)
- Text input field (bottom, with send button)
- "Typing..." indicator (future)

**Actions:**
- Send message (Enter or send button)
- Delete own message (swipe left)
- Delete any message (organizer/manager, swipe left)
- Tap sender avatar → view profile

**Data Source:** `/games/{gameId}/chatMessages/{messageId}` (Firestore real-time snapshots)

**Denormalization:** `senderName`, `senderPhotoUrl` cached via Cloud Function `onGameChatMessage`

**Empty State:**
- "No messages yet. Say hi!"
- First message auto-sends: "[User] created this game" (system message)

---

### Confirm Attendance Screen
**File:** `lib/screens/game/confirm_attendance_screen.dart`  
**Route:** `/games/{gameId}/confirm-attendance`  
**Trigger:** Push notification 2h before game, or manual navigation

**Purpose:** Final attendance confirmation

**UI Layout:**
- Game title, date, time
- Venue name
- "Are you coming?" (large text)
- "Yes, I'm Coming" button (green, full width)
- "Sorry, Can't Make It" button (red, full width)
- Optional reason field (if cancelling)
- "I'll decide later" link (dismisses, no action)

**Yes Flow:**
1. Tap "Yes, I'm Coming"
2. Update `GameSignup.status = confirmed` (if not already)
3. Show toast: "Great! See you there"
4. Close screen
5. Organizer notified of confirmation

**No Flow:**
1. Tap "Sorry, Can't Make It"
2. Show reason dialog (optional text field): "Help us improve: Why can't you make it?"
3. Update `GameSignup.status = cancelled`
4. Remove from `Game.confirmedPlayerIds`
5. Show toast: "You've been removed. We'll miss you!"
6. If waitlist exists: Promote next player, notify them
7. Organizer notified of cancellation with reason

**Edge Cases:**
- User already cancelled → Show "You've already cancelled"
- Game already started → Show "Game is in progress, can't change attendance"
- User not confirmed → Show error "You're not signed up for this game"

---

### Attendance Monitoring Screen (Organizer)
**File:** `lib/screens/game/attendance_monitoring_screen.dart`  
**Route:** `/games/{gameId}/attendance`  
**Permissions:** Organizer, Hub Manager, Hub Moderator

**Purpose:** Track who's coming in real-time

**Header:**
- Game title
- Countdown to game start
- Confirmed count / target count
- Progress bar (visual)
- Status badge (color-coded):
  - Green: "Ready to Play" (≥ min players)
  - Yellow: "Needs More Players" (< min players)
  - Red: "Below Minimum" (< 50% of min)

**Player List:**
- Each player card:
  - Avatar
  - Name
  - Attendance status:
    - ✅ **Confirmed** (green) - user tapped "I'm Coming" in last 2h
    - ⏳ **Pending** (yellow) - signed up but no recent confirmation
    - ❌ **Cancelled** (red) - user cancelled
    - 🕒 **No Response** (gray) - signed up but didn't respond to reminder
  - Last confirmed timestamp (e.g., "2h ago")
  - Contact buttons:
    - WhatsApp icon (tap → open WhatsApp chat)
    - Phone icon (tap → call)
- Sort: Confirmed first, then pending, then cancelled

**Actions:**
- "Send Reminder to All" button (sends push notification)
- "Send Reminder to Pending" button (only unconfirmed)
- "Promote from Waitlist" button (if spots available)
- "Cancel Game" button (if below minimum, confirmation required)

**Auto-Refresh:** Real-time updates via Firestore snapshots (every status change reflects immediately)

**Notifications:**
- Organizer gets push when player confirms/cancels
- Organizer gets summary 1h before game: "X/Y confirmed, Y pending"

---

### Game Recording Screen
**File:** `lib/screens/game/game_recording_screen.dart`  
**Route:** `/games/{gameId}/record`  
**Permissions:** Organizer, Hub Manager/Moderator, Veteran (if participated)

**Purpose:** Record single-game results (not session)

**Form:**

**1. Scores:**
- Team A Name (editable, default "Team Blue")
- Team A Score (number picker, 0-99)
- Team B Name (editable, default "Team Red")
- Team B Score (number picker, 0-99)

**2. Goal Scorers (Optional):**
- Multi-select list of confirmed players
- Each player can be selected multiple times (multiple goals)
- Shows total goals selected vs total score (validation warning if mismatch)

**3. Assists (Optional):**
- Multi-select list of confirmed players
- Each player can be selected multiple times

**4. MVP (Optional):**
- Single-select list of confirmed players
- Radio buttons or search/select

**5. Match Duration:**
- Default from game settings (e.g., 90 min)
- Editable (numeric input)

**6. Photos (Optional):**
- Upload 1-4 photos from gallery
- Compress to 1920px width
- Show thumbnails

**Actions:**
- "Save Results" button (green, large)
- "Cancel" button (discard changes, confirmation dialog)

**Validation:**
- Scores required (can be 0-0 draw)
- Goal scorers count should match total goals (warning, not blocking)
- MVP must be in confirmed players list
- Match duration must be >0

**Post-Save:**
1. Update `Game.status = completed`
2. Save scores, goal scorers, assists, MVP to Game document
3. Trigger Cloud Function `onGameCompleted`:
   - Update player stats (User.wins, losses, goals, assists)
   - Update hub stats (Hub.gameCount, lastActivity)
   - Create community feed post (if `showInCommunityFeed = true`)
   - Award achievements (badges)
4. Navigate to Game Detail (Results tab)
5. Show toast: "Results saved! Thanks for playing"

**Edge Cases:**
- Game already has results → Show confirmation: "Overwrite existing results?"
- User tries to record future game → Error: "Can't record results for future games"

---

### Log Past Game Screen
**File:** `lib/screens/game/log_past_game_screen.dart`  
**Route:** `/games/log-past`  
**Permissions:** Hub Manager/Moderator

**Purpose:** Retroactively record games from before Kattrick adoption

**Form:**

**1. Basic Info:**
- Game Date* (date picker, must be in past, max 180 days ago)
- Game Type (3v3 to 11v11)
- Venue (from hub venues)

**2. Participants:**
- Multi-select hub members
- Shows name, avatar, position
- Must select at least 4 participants

**3. Results:**
- Same as Game Recording Screen (scores, goal scorers, assists, MVP)

**4. Notes:**
- Freeform text field (500 chars)
- Explain context (e.g., "Pre-season friendly, not official")

**Validation:**
- Date must be in past
- At least 4 participants
- Scores required

**Post-Save:**
1. Create `Game` document with `loggedAsHistorical = true` flag
2. Update player stats (wins, losses, goals, assists)
3. Do NOT create community feed post (historical)
4. Do NOT send notifications (historical)
5. Navigate to Game Detail
6. Show toast: "Past game logged successfully"

**Use Cases:**
- Established hub migrating from WhatsApp/Excel
- Bulk import historical data (future: CSV upload)

---

### Team Maker Screen (Standalone)
**File:** `lib/screens/game/team_maker_screen.dart`  
**Route:** `/games/{gameId}/team-maker`  
**Permissions:** Organizer, Hub Manager/Moderator

**Purpose:** Quick team generation for standalone game (not event)

**Flow:**
1. Select confirmed players (checkboxes)
2. Configure team settings (number of teams, balance priority)
3. Generate teams (same algorithm as event team maker)
4. Review and adjust
5. Save teams to `Game.teams`

**Differences from Event Team Maker:**
- Pulls from `Game.confirmedPlayerIds` (not event registrations)
- Saves directly to Game document (not event)
- Simpler UI (less configuration options)

---

### Game Calendar View
**File:** `lib/screens/game/game_calendar_screen.dart`  
**Route:** `/games/calendar`  
**Tab:** Games → Calendar (sub-tab)

**Purpose:** Visualize games on calendar

**UI Layout:**
- Month view (calendar grid)
- Dots on dates with games (color-coded by status):
  - Blue: Upcoming
  - Green: Completed
  - Red: Cancelled
- Tap date → Bottom sheet with games for that date
- Swipe left/right to change month
- "Today" button to jump to current date

**Bottom Sheet (Date Selected):**
- List of games on selected date
- Each game card:
  - Title, time
  - Hub name
  - Confirmed count / max
  - Status badge
  - Tap → Game Detail

**Filters (Top Bar):**
- All Games
- My Games (where I'm confirmed)
- Hub Games (filter by hub dropdown)

**Data Source:**
- Firestore query: `gameDate >= startOfMonth && gameDate <= endOfMonth`
- Sorted by date, then time

---

### All Events Screen (Combined)
**File:** `lib/screens/game/all_events_screen.dart`  
**Route:** `/events/all`  
**Tab:** Games → All Events (sub-tab)

**Purpose:** Unified view of hub events + standalone games

**Filters (Chips):**
- Upcoming (default)
- This Week
- Past
- By Hub (dropdown)

**Sort Options:**
- Date (ascending for upcoming, descending for past)
- Hub
- Participants (high to low)

**List:**
- Combined list of `HubEvent` + `Game` (where user is hub member)
- Each card shows:
  - Type badge (Event or Game)
  - Title, date, time
  - Hub name/logo
  - Participants count
  - Status badge
  - Tap → Event/Game Detail

**Search Bar:**
- Search by title, venue name

**Data Source:**
- Fetch user's hub events (from all hubs in `User.hubIds`)
- Fetch user's games (where confirmed or created)
- Merge and sort by date

---

## 5.5 Social & Communication Flow

### Hub Feed (Within Hub Detail)
**Location:** Hub Detail Screen → Feed Tab  
**File:** `lib/screens/social/feed_screen.dart`  
**Permissions:** Read (all), Write (hub members)

**Purpose:** Hub-specific social feed

**Feed Items:**
- Posts (text, photos)
- Recruiting posts (with urgent badge)
- Game created posts (auto-generated by Cloud Function)
- Game completed posts (with scores, MVP)
- Achievement posts (player milestones)
- Poll posts (with voting UI inline)

**Each Post Card:**
- Author avatar, name
- Post timestamp (relative, e.g., "3h ago")
- Content text (truncated if >300 chars, "Read More" expands)
- Photos (1-4, swipeable gallery)
- Like button (heart icon) + count
- Comment button + count
- Share button (future)
- Delete button (own post or manager/moderator)

**Actions:**
- Tap like button → Toggle like, update `FeedPost.likes` array
- Tap comment button → Navigate to Post Detail screen
- Tap "Read More" → Expand truncated text inline
- Tap photo → Full-screen photo viewer (swipeable)
- Long press post → Context menu (Delete, Report - future)

**Infinite Scroll:**
- Load 20 posts initially
- Load next 20 on scroll to bottom (pagination via Firestore `startAfter`)

**Empty State:**
- "No posts yet in this hub"
- "Be the first to post!" (with "Create Post" button)

**Real-Time Updates:**
- Firestore snapshots (new posts appear at top without refresh)
- Badge on feed tab shows unread count (future)

---

### Create Post Screen
**File:** `lib/screens/social/create_post_screen.dart`  
**Route:** `/hubs/{hubId}/feed/create`  
**Permissions:** Hub members (not guests)

**Purpose:** Create social post

**Form:**

**1. Text Input:**
- Multi-line text field (500 chars max)
- Character counter (bottom right)
- Placeholder: "What's on your mind?"
- Auto-focus on open

**2. Photo Picker:**
- "Add Photos" button (camera icon)
- Select 1-4 photos from gallery or camera
- Show thumbnails with remove (X) button
- Compress to 1920px width on upload

**3. Options (Toggles):**
- Notify hub members (default OFF, to reduce noise)
- Tag location (future: select venue)

**Actions:**
- "Post" button (top right, disabled until text OR photo added)
- Back button (confirmation if text entered: "Discard post?")

**Validation:**
- Text or photo required (at least one)
- Max 500 chars for text
- Max 4 photos
- Max 5MB per photo (before compression)

**Post-Creation:**
1. Upload photos to Firebase Storage: `/uploads/{hubId}/posts/{postId}/{imageId}.jpg`
2. Create `FeedPost` document in `/hubs/{hubId}/feed/posts/items/{postId}`
3. If "Notify members" ON:
   - Cloud Function sends push notification to active hub members (exclude author)
   - Notification: "[Author] posted in [Hub Name]"
4. Denormalize author data (Cloud Function `onFeedPostCreated`)
5. Navigate back to hub feed
6. Show toast: "Posted!"

**Edge Cases:**
- Network error during upload → Retry with exponential backoff
- Photo compression fails → Show error, allow re-select

---

### Create Recruiting Post Screen
**File:** `lib/screens/social/create_recruiting_post_screen.dart`  
**Route:** `/hubs/{hubId}/feed/create-recruiting`  
**Permissions:** Manager/Moderator/Veteran

**Purpose:** Create recruiting post with amplification

**Form (Extends Create Post):**

**All Create Post fields, PLUS:**

**1. Recruiting Options:**
- Mark as Urgent (toggle, shows red badge)
- Recruiting Until (date/time picker, required)
- Needed Players (number input, e.g., "Need 3 more defenders")
- Positions Needed (multi-select: GK, DEF, MID, ATT)

**2. Targeting (Optional):**
- Age Range (13-18, 18-25, 25-35, 35+, multiple select)
- Skill Level (Beginner, Intermediate, Advanced)

**3. Distribution:**
- Post to Hub Feed (always ON)
- Post to Regional Feed (toggle, default ON for recruiting posts)

**Validation:**
- Text required (recruiting posts must explain need)
- "Recruiting Until" must be in future
- "Needed Players" must be >0

**Post-Creation (Enhanced):**
1. All standard post creation steps
2. If "Post to Regional Feed" ON:
   - Create duplicate post in `/feedPosts/{postId}` (global collection)
   - Set `type = 'hub_recruiting'`, `isUrgent`, `recruitingUntil`, `neededPlayers`
   - Viewable by all users in same region (discovery feed)
3. Cloud Function sends notifications to nearby users (future)
4. Show toast: "Recruiting post created and shared regionally!"

**Use Cases:**
- "Need 2 more players for tonight's game!"
- "New hub looking for experienced goalkeeper"
- "Last-minute defender needed for tournament"

---

### Post Detail Screen
**File:** `lib/screens/social/post_detail_screen.dart`  
**Route:** `/hubs/{hubId}/posts/{postId}`  
**Permissions:** Read (all hub members), Write (members)

**Purpose:** View post with full comments

**Layout:**

**1. Post Card (Full):**
- Same as feed card but no truncation
- All photos visible in full gallery
- Like button + full list of likers (tap count → show list modal)
- Share button (copy link, WhatsApp share)
- Delete button (own post or manager/moderator)

**2. Comments Section:**
- Title: "Comments" (X comments)
- Sort: Chronological (oldest first) or Most Liked (future)
- Each comment:
  - Author avatar (small), name
  - Comment text (no char limit for display, but 500 max on create)
  - Timestamp (relative)
  - Like button + count (mini heart icon)
  - Delete button (own comment or manager/moderator)
- Nested replies not supported (flat thread only)

**3. Add Comment Input (Bottom):**
- Text input field (500 chars max)
- Character counter
- Send button (paper plane icon)
- Auto-focus on open

**Actions:**
- Add comment → Create `Comment` in `/hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}`
- Cloud Function `onCommentCreated`:
  - Increment `FeedPost.commentCount`
  - Denormalize author data
  - Notify post author (if not self-commenting)
- Delete comment (own or moderator) → Confirmation dialog, decrement commentCount
- Like comment → Update `Comment.likes` array (future)

**Empty State (Comments):**
- "No comments yet. Be the first to comment!"

**Real-Time Updates:**
- Comments appear without refresh (Firestore snapshots)

---

### Community Activity Feed Screen
**File:** `lib/screens/activity/community_activity_feed_screen.dart`  
**Route:** `/community` or `/activity`  
**Tab:** Community (bottom nav)

**Purpose:** Regional discovery feed (across all hubs)

**Tabs (Top):**
1. **For You:** Personalized (user's hubs + nearby hubs with similar activity)
2. **Regional:** All public posts in user's region
3. **Recruiting:** Urgent recruiting posts only

**Filters (Dropdown):**
- All Regions (default if viewing "Regional" tab)
- North (צפון)
- Center (מרכז)
- South (דרום)
- Jerusalem (ירושלים)

**Feed Items (From `/feedPosts` collection):**
- Game completed posts (with scores, MVP, photos)
- Recruiting posts (urgent badge, deadline, needed players)
- Hub created posts (future)
- Player achievement posts (e.g., "100 games played")

**Each Feed Card:**
- Hub logo, name (tap → Hub Detail as guest)
- Post type badge (Game/Recruiting/Achievement)
- Content text
- Photos (if any)
- Like/comment counts (read-only for now, future: enable cross-hub interaction)
- Timestamp
- Distance from user (if location enabled, e.g., "5 km away")
- "View Hub" button → Hub Detail

**Discovery Algorithm (For You Tab):**
- Posts from user's hubs (weight: 50%)
- Posts from nearby hubs (within 10km, weight: 30%)
- Posts from hubs with similar activity patterns (weight: 20%)
- Sorted by: Engagement (likes + comments) × Recency

**Infinite Scroll:**
- Load 20 posts initially
- Load next 20 on scroll

**Empty State:**
- "No activity in your region yet"
- "Create a hub or join existing ones to see updates"

**Use Cases:**
- Discover new hubs when moving to new area
- Find players for immediate games (recruiting posts)
- See highlights from other hubs for inspiration

---

### Hub Chat Screen
**File:** `lib/screens/social/hub_chat_screen.dart`  
**Route:** `/hubs/{hubId}/chat` (tab within Hub Detail)  
**Permissions:** Read (all hub members), Write (active members only)

**Purpose:** Group chat for hub members

**UI Layout:**
- Chat header: Hub name, member count online (future)
- Message list (scrollable, latest at bottom)
- Each message:
  - Sender avatar (left for others, right for self)
  - Sender name (hidden if previous message from same sender within 5 min)
  - Message text (supports line breaks, no markdown)
  - Timestamp (shown on tap or long-press)
  - Read receipts (future: show who read)
  - Delete icon (own message or moderator)
- Text input field (bottom, with send button)
- Typing indicator: "3 people typing..." (future)

**Message Input:**
- Multi-line support (shift+Enter for new line, Enter to send on mobile)
- Max 1000 chars (longer than post comments)
- Emoji picker button (future)
- Attach photo button (future: send photos in chat)

**Actions:**
- Send message → Create `ChatMessage` in `/hubs/{hubId}/chatMessages/{messageId}`
- Cloud Function `onHubMessageCreated`:
  - Denormalize `senderName`, `senderPhotoUrl`
  - Send push notification to all active members (exclude sender)
  - Update `HubMember.lastActiveAt` for sender
  - Update `Hub.lastActivity`
- Delete message (swipe left or long-press) → Confirmation dialog (moderator only for others' messages)
- Tap message → Show full timestamp + sender profile link

**Real-Time Updates:**
- Firestore snapshots (messages appear instantly)
- Auto-scroll to bottom when new message arrives (if user is near bottom)

**Chat Rules:**
- Only active members can send (`HubMember.status = active`)
- Banned members can read (for transparency) but not send
- Moderators can delete any message (moderation)
- Messages are never truly deleted (soft-delete with `isDeleted` flag for audit)

**Empty State:**
- "No messages yet in this hub"
- "Start the conversation!" (with example messages: "Hi everyone!", "When's the next game?")

**Performance:**
- Limit query to last 100 messages initially
- Load older messages on scroll to top ("Load More" button)
- Local caching for offline read

---

### Private Messages List Screen
**File:** `lib/screens/social/messages_list_screen.dart`  
**Route:** `/messages`  
**Tab:** Messages (bottom nav or home screen)

**Purpose:** Inbox for 1-on-1 conversations

**List:**
- Each conversation card:
  - Other user's avatar
  - Other user's name
  - Last message preview (truncated to 50 chars)
  - Last message timestamp (relative, e.g., "2h ago")
  - Unread count badge (red, if >0)
  - Tap → Open Private Chat screen

**Sort:**
- Most recent first (by `Conversation.lastMessageAt`)

**Actions:**
- Swipe left → Delete conversation (confirmation dialog)
- Tap "New Message" FAB → Search users, select, navigate to chat

**Search Bar:**
- Search by other user's name
- Filter: All / Unread

**Empty State:**
- "No messages yet"
- "Start a conversation with a player"

**Data Source:**
- `/private_messages` where `participantIds` contains `currentUserId`
- Real-time snapshots (new messages appear without refresh)

---

### Private Chat Screen (1-on-1)
**File:** `lib/screens/social/private_chat_screen.dart`  
**Route:** `/messages/{conversationId}`  
**Permissions:** Participants only

**Purpose:** 1-on-1 messaging

**UI Layout:**
- Chat header: Other user's avatar, name, online status (future)
- Message list (same as hub chat, but 2 participants only)
- Text input field (bottom)
- "Block User" option (3-dot menu, top right)

**Message Input:**
- Same as hub chat (multi-line, max 1000 chars)

**Actions:**
- Send message → Create `PrivateMessage` in `/private_messages/{conversationId}/messages/{messageId}`
- Update `Conversation.lastMessage`, `lastMessageAt`, `unreadCount` for other user
- Push notification to other user (if not in chat)
- Block user → Add to `User.blockedUserIds`, hide conversation, no future messages

**Blocked User Handling:**
- If blocked by other user → Cannot send messages, show banner: "You cannot message this user"
- If you blocked other user → Cannot send/receive messages, show "Unblock to chat"

**Read Receipts (Future):**
- Show "Seen" indicator when other user reads message
- Update `PrivateMessage.read = true` when viewed

**Empty State:**
- "Start the conversation!"
- Conversation history preserved (no deletion unless both users delete)

---

### Notifications Inbox
**File:** `lib/screens/social/notifications_screen.dart`  
**Route:** `/notifications`  
**Tab:** Notifications icon (top right, home screen)

**Purpose:** View all app notifications

**List:**
- Each notification card:
  - Icon (context-aware: game, message, like, comment, etc.)
  - Title (bold)
  - Body text
  - Timestamp (relative)
  - Read/unread status (bold for unread)
  - Tap → Navigate to related entity (game, post, profile, etc.)
- Sort: Newest first

**Notification Types:**
1. **Game Reminder:** "⚽ Game starting in 2 hours" → Navigate to Game Detail
2. **Hub Chat:** "[User] sent a message in [Hub]" → Navigate to Hub Chat
3. **Private Message:** "[User] sent you a message" → Navigate to Private Chat
4. **Like:** "[User] liked your post" → Navigate to Post Detail
5. **Comment:** "[User] commented on your post" → Navigate to Post Detail
6. **New Follower:** "[User] is now following you" → Navigate to User Profile
7. **RSVP:** "[User] signed up for your game" → Navigate to Game Detail
8. **Join Request:** "[User] wants to join [Hub]" → Navigate to Manage Requests
9. **New Game:** "New game in [Hub]: [Title]" → Navigate to Game Detail

**Actions:**
- Tap notification → Mark as read, navigate
- Swipe left → Delete notification
- "Mark All as Read" button (top right)

**Badge Count:**
- Unread count shown on notification bell icon (home screen)
- Updated in real-time via Firestore listener

**Empty State:**
- "No notifications"
- "You'll be notified about games, messages, and activity"

**Data Source:** `/notifications/{userId}/items/{notificationId}` (real-time snapshots)

---

### Following/Followers Screens
**Files:**
- `lib/screens/social/following_screen.dart` (who you follow)
- `lib/screens/social/followers_screen.dart` (who follows you)

**Routes:**
- `/profile/{uid}/following`
- `/profile/{uid}/followers`

**Permissions:** Public (all users can view)

**Purpose:** Social graph

**List:**
- Each user card:
  - Avatar
  - Name
  - City, position (if public)
  - Games played (if public)
  - "Following" badge (if you follow them)
  - "Follows You" badge (if they follow you)
  - Tap → User Profile
  - "Unfollow" button (if on Following screen and it's your profile)

**Actions:**
- Follow user (from profile screen)
- Unfollow user (confirmation dialog)
- Navigate to user profile

**Data Source:**
- Following: `/users/{userId}/following/{followingId}`
- Followers: `/users/{userId}/followers/{followerId}`

**Empty State:**
- Following: "You're not following anyone yet"
- Followers: "No followers yet. Share your profile to gain followers!"

---

### Blocked Users Screen
**File:** `lib/screens/profile/blocked_users_screen.dart`  
**Route:** `/profile/{uid}/blocked`  
**Permissions:** Own profile only

**Purpose:** Manage blocked users

**List:**
- Each blocked user card:
  - Avatar (grayed out)
  - Name
  - "Blocked on [Date]"
  - "Unblock" button

**Actions:**
- Unblock user → Remove from `User.blockedUserIds`, show toast: "Unblocked [Name]"
- Tap user → Show profile (read-only, cannot message or interact)

**Empty State:**
- "No blocked users"
- "You can block users from their profile or chat"

**Data Source:** `User.blockedUserIds` array (fetch user documents)

---

## 5.6 Profile & Settings Flow

### Player Profile Screen (Futuristic)
**File:** `lib/screens/profile/player_profile_screen_futuristic.dart`  
**Route:** `/profile/{uid}`  
**Permissions:** Public (all authenticated users)

**Purpose:** View player profile and stats

**Header:**
- Large avatar (center)
- Display name
- City, region
- Preferred position badge
- Age (calculated from birthdate)
- Social links (Facebook, Instagram) if `showSocialLinks = true`
- "Edit Profile" button (own profile only)
- "Follow" / "Unfollow" button (other users)
- "Message" button (opens private chat)
- "Block User" option (3-dot menu, top right)

**Stats Card:**
- Total Games Played
- Win Rate (percentage)
- Goals Scored
- Assists
- Hubs Joined
- Veteran in X Hubs

**Tabs:**

**Tab 1: Overview**
- Bio/About (future: add custom bio field)
- Stats summary (above)
- Recent games (last 5, with result badges)

**Tab 2: Hubs**
- List of hubs user is member of
- Each hub card:
  - Hub logo, name
  - Role badge (Manager/Moderator/Veteran/Member)
  - Days since joined (e.g., "in hub for 45 days")
  - Veteran badge (if applicable)
  - Tap → Hub Detail

**Tab 3: Stats**
- Games by position (pie chart: GK, DEF, MID, ATT)
- Win/Loss/Draw (bar chart)
- Goals per game (line chart, last 20 games)
- Attendance rate (percentage)
- "View Detailed Stats" button → Performance Breakdown screen

**Tab 4: Activity**
- Recent activity feed (games, posts, comments)
- Chronological list

**Privacy Respected:**
- Hide email/phone if `privacySettings.hideEmail/hidePhone = true`
- Hide stats if `privacySettings.hideStats = true` → Show message: "Stats are private"
- Hide from search if `privacySettings.hideFromSearch = true` (not indexed)

**Blocked User View:**
- If viewing profile of user you blocked → Limited view, "You blocked this user"
- If user blocked you → Cannot message, cannot see activity feed

---

### Edit Profile Screen
**File:** `lib/screens/profile/edit_profile_screen.dart`  
**Route:** `/profile/{uid}/edit`  
**Permissions:** Own profile only

**Purpose:** Update profile information

**Form (Scrollable):**

**1. Avatar:**
- Current avatar (large, circular)
- "Change Photo" button → Image picker (camera/gallery) → Crop → Upload
- "Remove Photo" button (sets default avatar)

**2. Basic Info:**
- Display Name (text input)
- First Name (text input)
- Last Name (text input)
- Birthdate (date picker, read-only after set, shows age)
- City (dropdown, Israeli cities)
- Region (auto-filled from city, read-only)

**3. Football Info:**
- Preferred Position (dropdown: GK, DEF, MID, ATT)
- Favorite Team (search Israeli/international teams, future)

**4. Social Links:**
- Facebook URL (text input, URL validation)
- Instagram URL (text input, URL validation)
- Show Social Links on Profile (toggle, default OFF)

**5. Status:**
- Availability Status (dropdown: Available, Busy, Not Available)
- "Available" means open to game invites

**Actions:**
- "Save Changes" button (bottom, sticky)
- "Cancel" button (back navigation)

**Validation:**
- Display name required
- URLs must be valid (if provided)
- Birthdate cannot be changed (enforcement for age gate)

**Auto-Save:**
- Changes saved on field blur (per field)
- Show toast: "Profile updated"

**Edge Cases:**
- Avatar upload fails → Retry with smaller image
- Network error → Changes queued locally, retry on reconnect

---

### Settings Screen
**File:** `lib/screens/profile/settings_screen.dart`  
**Route:** `/profile/settings`  
**Permissions:** Own profile only

**Purpose:** App settings and account management

**Sections (List):**

**1. Account:**
- Edit Profile → `/profile/{uid}/edit`
- Privacy Settings → `/profile/{uid}/privacy`
- Notification Preferences → `/profile/{uid}/notifications`
- Blocked Users → `/profile/{uid}/blocked`

**2. Preferences:**
- Language (Hebrew only for now, future: English, Arabic)
- Theme (Dark only for now, future: Light/Dark toggle)

**3. About:**
- App Version (display only, e.g., "v1.0.5")
- Terms of Service (link to website)
- Privacy Policy (link to website)

**4. Support:**
- Contact Support (opens email to support@kattrick.com)
- Report a Bug (email with device info pre-filled)
- FAQ (link to help center, future)

**5. Account Management (Red Section):**
- Logout → Confirmation dialog, sign out
- Delete Account → Confirmation dialog, requires typing "DELETE", soft-delete

**Logout Flow:**
1. Tap "Logout"
2. Confirmation dialog: "Are you sure you want to log out?"
3. On confirm: Firebase Auth sign out
4. Clear local cache (Firestore, SharedPreferences)
5. Navigate to `/auth`

**Delete Account Flow:**
1. Tap "Delete Account"
2. Warning dialog: "This will permanently delete your account and data. Are you sure?"
3. Require typing "DELETE" (exact match)
4. On confirm: Mark `User.isActive = false`, remove from hubs, anonymize posts (future)
5. Firebase Auth delete user
6. Navigate to `/auth`
7. (Actual deletion deferred 30 days for recovery)

---

### Privacy Settings Screen
**File:** `lib/screens/profile/privacy_settings_screen.dart`  
**Route:** `/profile/{uid}/privacy`  
**Permissions:** Own profile only

**Purpose:** Control data visibility

**Toggles:**

**1. Profile Visibility:**
- Hide from Search (if ON: not discoverable in player search, scouting)
- Hide Email (if ON: email not shown on profile, only to hub managers)
- Hide Phone (if ON: phone not shown, only to hub managers)
- Hide City (if ON: city not shown on profile)

**2. Stats Visibility:**
- Hide Stats (if ON: games/wins/goals not public, only to you and hub managers)
- Hide Ratings (if ON: manager ratings not shown publicly)

**3. Activity Visibility (Future):**
- Hide Activity Feed (only show to followers)
- Hide Following/Followers List (only show counts)

**Data Model:** `User.privacySettings` map (each toggle is boolean)

**Defaults:** All OFF (public profile)

**Info Text:**
- "Hub managers can always see your stats and contact info for coordination"
- "Blocking a user prevents all interaction"

**Auto-Save:** Changes saved immediately on toggle (optimistic UI update)

---

### Notification Settings Screen
**File:** `lib/screens/profile/notification_settings_screen.dart`  
**Route:** `/profile/{uid}/notifications`  
**Permissions:** Own profile only

**Purpose:** Control push notification preferences

**Categories (Collapsible Sections):**

**1. Games:**
- Game Reminders (2h before game) - Toggle
- New Game Created in Hub - Toggle
- RSVP Confirmation - Toggle
- Attendance Confirmation Request - Toggle
- Game Cancelled - Toggle

**2. Social:**
- Likes on Posts - Toggle
- Comments on Posts - Toggle
- New Follower - Toggle
- Mentions (future) - Toggle

**3. Communication:**
- Hub Chat Messages - Toggle
- Private Messages - Toggle
- Join Requests (managers only) - Toggle

**Data Model:** `User.notificationPreferences` map (each toggle is boolean)

**Defaults:**
- Game reminders: ON
- Game created: ON
- Comments: ON
- Likes: OFF (too noisy)
- All communication: ON

**Master Toggle (Top):**
- "Enable All Notifications" → Turn all on/off at once

**Info Text:**
- "You can still see in-app notifications even if push is disabled"
- "Some critical notifications (e.g., game cancelled) cannot be disabled"

**Auto-Save:** Changes saved immediately on toggle

**Platform Permissions:**
- If device-level notifications disabled → Show warning: "Notifications are disabled in device settings. Tap to open settings."

---

### Performance Breakdown Screen
**File:** `lib/screens/profile/performance_breakdown_screen.dart`  
**Route:** `/profile/{uid}/performance`  
**Permissions:** Own profile or hub managers

**Purpose:** Detailed performance analytics

**Filters (Top Bar):**
- Time Period: Last 30 Days / Last 90 Days / All Time
- Hub: All Hubs / [Specific Hub]
- Position: All Positions / GK / DEF / MID / ATT

**Sections:**

**1. Summary Cards:**
- Games Played (with trend arrow)
- Win Rate (percentage)
- Goals per Game (average)
- Assists per Game (average)

**2. Position Analysis:**
- Pie Chart: Games by position
- Table: Win rate by position
- Insight: "You win most as Midfielder (65% win rate)"

**3. Performance Trends:**
- Line Chart: Goals over time (last 20 games)
- Line Chart: Win rate over time (rolling 10-game average)

**4. Hub Performance:**
- Table: Stats per hub (games, win rate, goals, rating)
- Sort by: Win Rate, Games Played, Rating

**5. Consistency:**
- Attendance Rate: X% (games confirmed ÷ games signed up)
- Average RSVP Time: X hours before game
- No-Show Rate: X%

**6. Peer Comparison (Future):**
- Percentile rank in hub (e.g., "Top 20% in goals")
- Comparison to average player in hub

**Data Source:**
- Aggregated from Firestore queries (games, signups, events)
- Cached for 1 hour (expensive queries)

**Export (Future):**
- "Export Stats" button → Download CSV

---

### Hub-Specific Stats Screen
**File:** `lib/screens/profile/hub_stats_screen.dart`  
**Route:** `/profile/{uid}/hub-stats/{hubId}`  
**Permissions:** Public (if stats not hidden)

**Purpose:** Performance within single hub

**Header:**
- Hub logo, name
- Role badge (Manager/Moderator/Veteran/Member)
- Days since joined
- Veteran badge (if applicable)

**Stats:**
- Games Played in Hub
- Win/Loss/Draw in Hub
- Goals, Assists in Hub
- Manager Rating (1-7, stars)
- Attendance Rate in Hub
- Average RSVP Time

**Comparison:**
- "Your Rank in Hub: #X of Y members (by games played)"
- "Your Win Rate: X% (Hub Average: Y%)"

**Data Source:**
- Firestore query: games where `hubId = X` and user participated
- HubMember document for rating and membership data

---

## 5.7 Discovery & Maps Flow

### Discover Hubs Screen
**File:** `lib/screens/location/discover_hubs_screen.dart`  
**Route:** `/discover-hubs` or `/hubs/discover`  
**Permissions:** All authenticated users

**Purpose:** Find and join new hubs

**Layout:**

**Tabs (Top):**
1. **Nearby:** Geohash-based proximity (within 10km)
2. **By Region:** Filter by North/Center/South/Jerusalem
3. **Popular:** Sorted by member count or activity

**Filters (Chips):**
- Public Hubs Only (default)
- Recruiting (hubs with recruiting posts)
- Active (games in last 7 days)

**Search Bar:**
- Search by hub name

**Hub List (Cards):**
- Each hub card:
  - Hub logo
  - Hub name
  - Region badge
  - Member count
  - Games per week (avg)
  - Distance from user (if location enabled, e.g., "3 km away")
  - Recruiting badge (if has active recruiting posts)
  - "View Hub" button → Hub Detail (as guest)
  - "Join" button (if public) or "Request to Join" (if private)

**Sort Options (Dropdown):**
- Distance (ascending)
- Member Count (descending)
- Activity (games per week, descending)
- Newest First

**Join Flow:**
1. Tap "Join" on public hub
2. Confirmation dialog: "Join [Hub Name]? You'll be added as a Member."
3. On confirm: Add user to hub (HubsRepository.joinHub)
4. Show toast: "You've joined [Hub Name]!"
5. Navigate to Hub Detail

**Request to Join Flow (Private Hubs):**
1. Tap "Request to Join"
2. Optional message to managers (text field, 200 chars)
3. On submit: Create join request
4. Show toast: "Request sent! You'll be notified when reviewed."
5. Manager gets notification

**Data Source:**
- Nearby: Firestore geohash query (10km radius)
- By Region: Filter by `Hub.region`
- Popular: Query sorted by `Hub.memberCount` or `Hub.activityScore`

**Empty State:**
- "No hubs found in your area"
- "Create the first hub!" (with "Create Hub" button)

---

### Map View of Hubs
**File:** `lib/screens/location/map_screen.dart`  
**Route:** `/map`  
**Permissions:** All authenticated users

**Purpose:** Visualize hubs on map

**UI Layout:**
- Google Maps (full screen)
- Hub markers (custom icon: football pin)
- User location marker (blue dot)
- Clustering (if 10+ hubs in small area)

**Marker Tap:**
- Opens bottom sheet with hub preview:
  - Hub logo, name
  - Member count
  - Distance from user
  - "View Hub" button → Hub Detail
  - "Get Directions" button → Google Maps navigation

**Filters (Floating Chip Bar, Top):**
- All Hubs
- My Hubs Only
- Recruiting Hubs Only

**Actions (Floating Buttons, Bottom Right):**
- Current Location button (center map on user)
- Layers button (future: show games, players, venues)

**Data Loading:**
- Load hubs within map viewport bounds (Firestore geoqueries)
- Update markers as user pans/zooms
- Performance: Limit to 100 markers (show "Zoom in to see more" message if >100)

**Tap Empty Area:**
- No action (future: "Create hub here" option)

---

### Map Picker Screen
**File:** `lib/screens/location/map_picker_screen.dart`  
**Route:** `/map-picker`  
**Permissions:** All authenticated users  
**Shown:** As modal/dialog when setting location (hub creation, venue creation, game creation)

**Purpose:** Select location on map

**UI Layout:**
- Google Maps (full screen)
- Draggable pin (center, always visible)
- Selected address displayed (top card, updates as pin moves)
- Search bar (top) → Google Places Autocomplete

**Search Flow:**
1. User types in search bar
2. Google Places Autocomplete suggests addresses
3. User selects address
4. Map animates to location, pin placed

**Drag Flow:**
1. User drags pin to desired location
2. Reverse geocode to get address (Google Geocoding API)
3. Update address card

**Actions (Bottom):**
- "Use Current Location" button (center on GPS)
- "Confirm Location" button → Returns GeoPoint and address, close modal
- "Cancel" button → Close without selecting

**Returned Data:**
- `GeoPoint(latitude, longitude)`
- `address` (formatted string, e.g., "123 Rothschild Blvd, Tel Aviv")
- `geohash` (computed client-side for proximity queries)

**Use Cases:**
- Setting hub location during creation
- Setting custom venue location
- Setting custom game location (if not using venue)

---

### Discover Venues Screen
**File:** `lib/screens/venues/discover_venues_screen.dart`  
**Route:** `/venues/discover`  
**Permissions:** All authenticated users

**Purpose:** Browse public venues (football pitches)

**Layout:**

**Search Bar:**
- Search by name or address
- Google Places Autocomplete integration

**Filters (Chips):**
- Surface Type: All, Grass, Artificial, Concrete, Indoor
- Amenities: All, Parking, Showers, Lights, Changing Rooms
- Distance: Within 5km, 10km, 20km, Any

**Venue List (Cards):**
- Each venue card:
  - Venue name
  - Address
  - Surface type badge
  - Amenities icons (parking, showers, lights)
  - Distance from user (if location enabled)
  - Used by X hubs (count)
  - "View on Map" button
  - "Use This Venue" button (if creating hub/game)

**Sort Options (Dropdown):**
- Distance (ascending)
- Popularity (hub count, descending)
- Alphabetical

**Map Toggle (Top Right):**
- Switch to map view (shows all venues as markers)

**Data Source:**
- `/venues` collection where `isPublic = true`
- Firestore geohash query for distance filter
- Index required: `isPublic, geohash, surfaceType`

**Use Cases:**
- Finding venue during hub creation
- Finding venue during game creation
- Discovering new places to play

---

### Venue Search Screen (Autocomplete)
**File:** `lib/screens/venue/venue_search_screen.dart`  
**Route:** `/venues/search`  
**Permissions:** All authenticated users  
**Shown:** As modal during hub/game creation

**Purpose:** Quick venue search with Google Places

**UI Layout:**
- Search bar (auto-focus)
- Google Places Autocomplete suggestions (list)
- Each suggestion:
  - Venue name (primary text)
  - Address (secondary text)
  - Distance (if location enabled)
  - Tap → Select venue

**Search Logic:**
1. User types query (e.g., "Yarkon Park")
2. Google Places Autocomplete API called (types: `["stadium", "park", "establishment"]`)
3. Results displayed in real-time
4. User taps suggestion → Returns place details (name, address, GeoPoint)

**Actions (Bottom):**
- "Can't Find It? Create Manual Venue" link → Create Manual Venue screen

**Returned Data:**
- `venueName`
- `address`
- `location` (GeoPoint)
- `googlePlaceId`

**Edge Cases:**
- No results for query → Show "Can't find it? Create manual venue"
- Network error → Show "Search unavailable, create manual venue"

---

### Create Manual Venue Screen
**File:** `lib/screens/venue/create_manual_venue_screen.dart`  
**Route:** `/venues/create-manual`  
**Permissions:** All authenticated users

**Purpose:** Add custom venue not in Google Places

**Form:**

**1. Basic Info:**
- Venue Name* (required)
- Address* (freeform text, required)
- Location* (map picker button)

**2. Details:**
- Surface Type* (dropdown: Grass, Artificial, Concrete, Indoor)
- Max Players (number input, default 11)
- Amenities (checkboxes):
  - Parking
  - Showers
  - Changing Rooms
  - Lights (for night games)
  - Refreshments (kiosk/vending)

**3. Visibility:**
- Public Venue (toggle, default OFF)
  - If ON: Visible to all users in Discover Venues
  - If OFF: Only visible to hub members

**4. Photos (Future):**
- Upload 1-4 photos of venue

**Validation:**
- Name, address, location required
- Surface type required
- Max players must be >0

**Post-Creation:**
1. Create `Venue` document in `/venues/{venueId}`
2. Associate with hub (if created during hub creation: add to `Hub.venueIds`)
3. Return venue data to calling screen
4. Show toast: "Venue created!"

**Use Cases:**
- Venue not in Google Places (e.g., neighborhood park without name)
- Private venue (e.g., corporate campus field)
- New venue not yet indexed by Google

---

### Players Map Screen
**File:** `lib/screens/players/players_map_screen.dart`  
**Route:** `/players/map`  
**Permissions:** All authenticated users

**Purpose:** Discover active players on map

**UI Layout:**
- Google Maps (full screen)
- Player markers (custom icon: person pin, color-coded by position)
- User location marker (blue dot)

**Marker Tap:**
- Opens bottom sheet with player preview:
  - Avatar, name
  - Position, city
  - Games played
  - Availability status
  - "View Profile" button
  - "Message" button

**Filters (Floating Chip Bar, Top):**
- All Positions
- Goalkeepers
- Defenders
- Midfielders
- Attackers
- Available Only (show only users with `isActive = true`)

**Privacy:**
- Only shows players with `User.location` set and `privacySettings.hideFromSearch = false`
- Distance displayed (e.g., "2 km away")

**Data Source:**
- `/users` collection where `location` exists and `privacySettings.hideFromSearch = false`
- Firestore geohash query for viewport bounds
- Limit to 50 players (show "Zoom in to see more")

**Use Cases:**
- Find players in new neighborhood
- Recruit for hub
- Discover local football community

---

## 5.8 Admin & Debug Flow

### Admin Dashboard Screen
**File:** `lib/screens/admin/admin_dashboard_screen.dart`  
**Route:** `/admin/dashboard`  
**Permissions:** Super admin only (hard-coded email check)

**Purpose:** Platform operations and monitoring

**Sections (Cards):**

**1. Platform Stats:**
- Total Users (count)
- Total Hubs (count)
- Total Games (count)
- Total Games This Week (count)
- Active Users (last 7 days, count)

**2. Quick Actions:**
- Generate Dummy Data → `/admin/generate-dummy-data`
- View Crashlytics → External link
- View Firebase Console → External link
- View Cloud Functions Logs → External link

**3. System Health:**
- Last Cloud Function Run (timestamp)
- Last Error (if any, with link to Crashlytics)
- Firestore Usage (MB)
- Storage Usage (GB)

**4. Manual Operations (Red Section):**
- Ban User (input UID, requires reason)
- Delete Hub (input hub ID, confirmation required)
- Refund Payment (future)
- Resolve Support Ticket (future)

**Data Source:**
- Firebase Admin SDK (callable Cloud Functions)
- Aggregated counts from Firestore

**Future:** Real-time dashboard with charts, anomaly detection

---

### Generate Dummy Data Screen
**File:** `lib/screens/admin/generate_dummy_data_screen.dart`  
**Route:** `/admin/generate-dummy-data`  
**Permissions:** Super admin only

**Purpose:** Populate test data

**Scenarios (Buttons):**

**1. Basic Hub (Green Button):**
- Creates: 1 hub, 10 users, 5 games
- Time: ~30 seconds

**2. Team Balance Scenario (Purple Button):**
- Creates: 1 hub with current user as manager, 14 users (varied ratings and positions), 1 event with 15 registered players
- Purpose: Test team maker algorithm immediately
- Time: ~15 seconds
- **File:** `lib/scripts/generate_dummy_data.dart` → `createTeamBalanceScenario()`
- **Documentation:** `lib/scripts/README_TEAM_BALANCE_SCENARIO_HE.md`

**3. Full Ecosystem (Red Button):**
- Creates: 5 hubs, 50 users, 20 games, 30 posts, 50 comments
- Time: ~2 minutes
- Warning: "This will create a lot of data. Proceed?"

**Output:**
- Progress indicator (loading spinner)
- Success message with summary:
  - "Created X users, Y hubs, Z games"
  - Links to created hubs

**Use Cases:**
- QA testing
- Demo mode
- Screenshot generation
- Performance testing

**Edge Cases:**
- Already in production → Show warning: "This is a production environment. Are you sure?"
- Rate limiting → Batch operations with delays

---

### Auth Status Screen (Debug)
**File:** `lib/screens/debug/auth_status_screen.dart`  
**Route:** `/debug/auth-status`  
**Permissions:** All authenticated users (debug only)

**Purpose:** Debug authentication issues

**Display:**
- Current User UID (copyable)
- Email
- Email Verified (boolean)
- Custom Claims (JSON, if any)
- Firebase Auth Token (truncated, copyable)
- Firestore Connection Status (connected/disconnected)
- Last Firestore Query Time (latency)
- Cloud Functions Connection Status (test ping)

**Actions:**
- "Refresh Token" button (force token refresh)
- "Test Firestore" button (write/read test document)
- "Test Cloud Function" button (call test function)
- "Copy All" button (copy all debug info as JSON)

**Use Cases:**
- Debugging authentication issues
- Verifying custom claims (future: role-based claims)
- Testing connectivity

---

## (CONTINUED IN NEXT MESSAGE...)


# 6. FULL BACKEND ARCHITECTURE

This section documents the complete backend infrastructure powering Kattrick.

## 6.1 Firebase Services Stack

### Firebase Core Services

**Firebase Authentication:**
- **Version:** Firebase Auth 5.3.1
- **Methods:** Email/Password, Google OAuth, Apple Sign-In
- **Custom Claims:** Role-based claims (future: hub roles synced to JWT)
- **Session Management:** Persistent login, automatic token refresh
- **Anonymous Sign-In:** Disabled (explicitly signed out on app start to enforce authentication)

**Cloud Firestore:**
- **Version:** Cloud Firestore 5.4.4
- **Mode:** Native mode (not Datastore)
- **Persistence:** Unlimited offline cache enabled (mobile only)
- **Real-Time:** Snapshots for live updates (chat, feed, notifications)
- **Transactions:** Used for atomic operations (hub membership, game signups)
- **Batch Writes:** Used for bulk operations (dummy data generation)
- **Indexes:** 25+ composite indexes (defined in `firestore.indexes.json`)

**Firebase Storage:**
- **Version:** Firebase Storage 12.3.4
- **Buckets:** Default bucket (all uploads)
- **Paths:**
  - `/avatars/{uid}.jpg` - User profile photos (512x512, compressed)
  - `/uploads/{hubId}/posts/{postId}/{imageId}.jpg` - Post photos (1920px width)
  - `/uploads/games/{gameId}/{imageId}.jpg` - Game photos
  - `/logos/{hubId}.jpg` - Hub logos (512x512)
- **Security:** Authenticated uploads only, public reads for public content
- **Compression:** Client-side before upload (image_compression package)

**Firebase Cloud Messaging (FCM):**
- **Version:** Firebase Messaging 15.0.0
- **Platforms:** iOS (APNs), Android (FCM), Web (future)
- **Token Management:** Stored in `/users/{uid}/fcm_tokens/tokens` (array of tokens, multi-device support)
- **Background Handler:** Registered in `main.dart`, handles notifications when app is closed
- **Deep Links:** Custom URL scheme `kattrick://` for notification navigation

**Firebase Analytics:**
- **Version:** Firebase Analytics 11.0.0
- **Events:** 30+ custom events (hub_created, game_created, rsvp, team_maker_used, etc.)
- **User Properties:** hub_count, games_played, veteran_status
- **Screen Tracking:** Automatic via GoRouter navigation observers

**Firebase Crashlytics:**
- **Version:** Firebase Crashlytics 4.0.0
- **Platform:** iOS/Android only (stub for web)
- **Fatal Crashes:** Auto-reported with stack traces
- **Non-Fatal Errors:** Manually logged via `ErrorHandlerService`
- **User Context:** UID, screen name, hub ID included in reports

**Firebase Remote Config:**
- **Version:** Firebase Remote Config 5.0.0
- **Fetch Interval:** 12 hours (default), forced on app start
- **Flags:**
  - `enable_recruiting_posts` (bool, default true)
  - `max_photos_per_post` (int, default 4)
  - `veteran_days_threshold` (int, default 60)
  - `enable_polls` (bool, default true)
  - `maintenance_mode` (bool, default false)
  - `min_app_version` (string, for forced updates)
- **A/B Testing:** Not used yet (future: Firebase A/B Testing integration)

**Firebase App Check:**
- **Version:** Firebase App Check 0.3.1
- **Mode:** Debug mode (allows development)
- **Providers:** Debug provider for dev, DeviceCheck (iOS) / Play Integrity (Android) for production
- **Purpose:** Prevent abuse of backend APIs (Cloud Functions, Firestore, Storage)

---

## 6.2 Cloud Functions Architecture

**Runtime:** Node.js 20 (Firebase Functions Gen 2)
**Region:** `us-central1` (default)
**Memory:** 256MB (default), 512MB for image processing
**Timeout:** 60s (default), 300s for scheduled functions

### Function Categories

#### 1. Game Functions (`functions/src/games.js`)

**`onGameCreated` (Trigger: onCreate)**
```javascript
exports.onGameCreated = functions.firestore
  .document('games/{gameId}')
  .onCreate(async (snap, context) => {
    const game = snap.data();
    
    // 1. Denormalize creator data
    const creator = await admin.firestore().doc(`users/${game.createdBy}`).get();
    await snap.ref.update({
      createdByName: creator.data().name,
      createdByPhotoUrl: creator.data().photoUrl || null,
    });
    
    // 2. If hub game, denormalize hub name
    if (game.hubId) {
      const hub = await admin.firestore().doc(`hubs/${game.hubId}`).get();
      await snap.ref.update({
        hubName: hub.data().name,
        region: hub.data().region,
      });
      
      // 3. Update hub stats
      await admin.firestore().doc(`hubs/${game.hubId}`).update({
        gameCount: admin.firestore.FieldValue.increment(1),
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // 4. Create feed post in hub
      await admin.firestore()
        .collection(`hubs/${game.hubId}/feed/posts/items`)
        .add({
          type: 'game_created',
          gameId: game.gameId,
          authorId: game.createdBy,
          authorName: creator.data().name,
          text: `${creator.data().name} created a new game: ${game.title || 'Untitled Game'}`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    
    // 5. If recruiting, create regional feed post
    if (game.visibility === 'recruiting' && game.region) {
      await admin.firestore().collection('feedPosts').add({
        type: 'game_recruiting',
        gameId: game.gameId,
        hubId: game.hubId,
        authorId: game.createdBy,
        text: game.description || `New game: ${game.title}`,
        region: game.region,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
```

**`onGameCompleted` (Trigger: onUpdate, status → completed)**
```javascript
exports.onGameCompleted = functions.firestore
  .document('games/{gameId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Only trigger if status changed to completed
    if (before.status !== 'completed' && after.status === 'completed') {
      const gameId = context.params.gameId;
      
      // 1. Fetch confirmed players
      const signupsSnapshot = await admin.firestore()
        .collection(`games/${gameId}/signups`)
        .where('status', '==', 'confirmed')
        .get();
      
      const confirmedPlayerIds = signupsSnapshot.docs.map(doc => doc.id);
      
      // 2. Update player stats (wins, losses, goals, assists)
      const batch = admin.firestore().batch();
      
      // Determine winners/losers from game.matches or game.teamAScore/teamBScore
      const winners = []; // playerIds on winning team
      const losers = [];  // playerIds on losing team
      const drawers = []; // if draw
      
      // ... logic to determine winners/losers based on teams and scores ...
      
      winners.forEach(playerId => {
        const userRef = admin.firestore().doc(`users/${playerId}`);
        batch.update(userRef, {
          wins: admin.firestore.FieldValue.increment(1),
          gamesPlayed: admin.firestore.FieldValue.increment(1),
          totalParticipations: admin.firestore.FieldValue.increment(1),
        });
      });
      
      losers.forEach(playerId => {
        const userRef = admin.firestore().doc(`users/${playerId}`);
        batch.update(userRef, {
          losses: admin.firestore.FieldValue.increment(1),
          gamesPlayed: admin.firestore.FieldValue.increment(1),
          totalParticipations: admin.firestore.FieldValue.increment(1),
        });
      });
      
      // 3. Update goals/assists from game events or goalScorerIds
      if (after.goalScorerIds) {
        after.goalScorerIds.forEach(playerId => {
          const userRef = admin.firestore().doc(`users/${playerId}`);
          batch.update(userRef, {
            goals: admin.firestore.FieldValue.increment(1),
          });
        });
      }
      
      // 4. Create community feed post (if showInCommunityFeed)
      if (after.showInCommunityFeed && after.region) {
        await admin.firestore().collection('feedPosts').add({
          type: 'game_completed',
          gameId: gameId,
          hubId: after.hubId,
          text: `Game completed: ${after.hubName || 'Pickup Game'} - ${after.teamAScore || 0} vs ${after.teamBScore || 0}`,
          region: after.region,
          mvpPlayerId: after.mvpPlayerId,
          mvpPlayerName: after.mvpPlayerName,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    }
  });
```

**`sendGameReminder` (Scheduled: every 30 minutes)**
```javascript
exports.sendGameReminder = functions.pubsub
  .schedule('every 30 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const twoHoursFromNow = new admin.firestore.Timestamp(
      now.seconds + 2 * 60 * 60,
      now.nanoseconds
    );
    const oneHourFromNow = new admin.firestore.Timestamp(
      now.seconds + 1 * 60 * 60,
      now.nanoseconds
    );
    
    // Find games starting in 1-2 hours that haven't sent reminder
    const gamesSnapshot = await admin.firestore()
      .collection('games')
      .where('gameDate', '>=', oneHourFromNow)
      .where('gameDate', '<=', twoHoursFromNow)
      .where('enableAttendanceReminder', '==', true)
      .where('reminderSent2Hours', '!=', true)
      .get();
    
    for (const gameDoc of gamesSnapshot.docs) {
      const game = gameDoc.data();
      
      // Fetch confirmed players
      const signupsSnapshot = await admin.firestore()
        .collection(`games/${gameDoc.id}/signups`)
        .where('status', '==', 'confirmed')
        .get();
      
      const playerIds = signupsSnapshot.docs.map(doc => doc.id);
      
      // Fetch FCM tokens in parallel
      const tokenPromises = playerIds.map(async playerId => {
        const tokensDoc = await admin.firestore()
          .doc(`users/${playerId}/fcm_tokens/tokens`)
          .get();
        return tokensDoc.exists ? tokensDoc.data().tokens || [] : [];
      });
      
      const tokenArrays = await Promise.all(tokenPromises);
      const allTokens = tokenArrays.flat();
      
      // Send multicast notification
      if (allTokens.length > 0) {
        await admin.messaging().sendEachForMulticast({
          tokens: allTokens,
          notification: {
            title: '⚽ משחק מתחיל בקרוב',
            body: `${game.title || 'משחק'} מתחיל בעוד שעתיים`,
          },
          data: {
            type: 'game_reminder',
            gameId: gameDoc.id,
          },
        });
      }
      
      // Mark reminder as sent
      await gameDoc.ref.update({
        reminderSent2Hours: true,
        reminderSent2HoursAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // Create in-app notifications
      for (const playerId of playerIds) {
        await admin.firestore()
          .collection(`notifications/${playerId}/items`)
          .add({
            type: 'game_reminder',
            title: '⚽ משחק מתחיל בקרוב',
            body: `${game.title || 'משחק'} מתחיל בעוד שעתיים`,
            entityId: gameDoc.id,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
      }
    }
  });
```

**`onGameSignupChanged` (Trigger: onWrite)**
```javascript
exports.onGameSignupChanged = functions.firestore
  .document('games/{gameId}/signups/{userId}')
  .onWrite(async (change, context) => {
    const gameId = context.params.gameId;
    const gameRef = admin.firestore().doc(`games/${gameId}`);
    
    // Count confirmed signups
    const confirmedSnapshot = await admin.firestore()
      .collection(`games/${gameId}/signups`)
      .where('status', '==', 'confirmed')
      .get();
    
    const confirmedCount = confirmedSnapshot.size;
    const confirmedPlayerIds = confirmedSnapshot.docs.map(doc => doc.id);
    
    // Update denormalized fields on game
    const game = (await gameRef.get()).data();
    const isFull = game.maxPlayers ? confirmedCount >= game.maxPlayers : false;
    
    await gameRef.update({
      confirmedPlayerCount: confirmedCount,
      confirmedPlayerIds: confirmedPlayerIds,
      isFull: isFull,
    });
  });
```

---

#### 2. Hub Functions (`functions/src/hubs.js`)

**`addSuperAdminToHub` (Trigger: onCreate)**
```javascript
exports.addSuperAdminToHub = functions.firestore
  .document('hubs/{hubId}')
  .onCreate(async (snap, context) => {
    const hubId = context.params.hubId;
    const superAdminEmail = 'gal@joya-tech.net';
    
    // Find super admin user
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('email', '==', superAdminEmail)
      .limit(1)
      .get();
    
    if (!usersSnapshot.empty) {
      const superAdminId = usersSnapshot.docs[0].id;
      
      // Add super admin as manager (HubMember)
      await admin.firestore()
        .doc(`hubs/${hubId}/members/${superAdminId}`)
        .set({
          hubId: hubId,
          userId: superAdminId,
          role: 'manager',
          status: 'active',
          joinedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedBy: 'system:addSuperAdminToHub',
        });
      
      // Add hub to super admin's hubIds
      await admin.firestore()
        .doc(`users/${superAdminId}`)
        .update({
          hubIds: admin.firestore.FieldValue.arrayUnion(hubId),
        });
    }
  });
```

---

#### 3. Membership Functions (`functions/src/membership/index.js`)

**`promoteVeterans` (Scheduled: daily at 2 AM UTC)**
```javascript
exports.promoteVeterans = functions.pubsub
  .schedule('0 2 * * *') // Cron: 2 AM daily
  .timeZone('UTC')
  .onRun(async (context) => {
    const VETERAN_THRESHOLD_DAYS = 60;
    const BATCH_SIZE = 500;
    
    const now = admin.firestore.Timestamp.now();
    const thresholdDate = new admin.firestore.Timestamp(
      now.seconds - (VETERAN_THRESHOLD_DAYS * 24 * 60 * 60),
      now.nanoseconds
    );
    
    // Query members eligible for promotion
    // Criteria: joinedAt <= 60 days ago, role == member, status == active, veteranSince == null
    const eligibleSnapshot = await admin.firestore()
      .collectionGroup('members')
      .where('status', '==', 'active')
      .where('role', '==', 'member')
      .where('joinedAt', '<=', thresholdDate)
      .where('veteranSince', '==', null)
      .get();
    
    console.log(`Found ${eligibleSnapshot.size} members eligible for veteran promotion`);
    
    // Batch update in groups of 500 (Firestore transaction limit)
    const batches = [];
    let batch = admin.firestore().batch();
    let count = 0;
    
    for (const memberDoc of eligibleSnapshot.docs) {
      batch.update(memberDoc.ref, {
        veteranSince: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: 'system:promoteVeterans',
      });
      
      count++;
      
      if (count >= BATCH_SIZE) {
        batches.push(batch.commit());
        batch = admin.firestore().batch();
        count = 0;
      }
    }
    
    if (count > 0) {
      batches.push(batch.commit());
    }
    
    await Promise.all(batches);
    
    console.log(`Promoted ${eligibleSnapshot.size} members to veteran`);
    
    // Log to system logs collection
    await admin.firestore().collection('_system_logs').add({
      type: 'veteran_promotion',
      count: eligibleSnapshot.size,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
```

**Trigger: `onMembershipChange` (Update hub.memberCount)**
```javascript
// File: functions/src/triggers/membershipCounters.js
exports.onMembershipChange = functions.firestore
  .document('hubs/{hubId}/members/{userId}')
  .onWrite(async (change, context) => {
    const hubId = context.params.hubId;
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;
    
    // Check if status changed (active vs not active)
    const wasActive = before && before.status === 'active';
    const isActive = after && after.status === 'active';
    
    let delta = 0;
    if (!wasActive && isActive) {
      delta = 1; // Join or reactivate
    } else if (wasActive && !isActive) {
      delta = -1; // Leave, ban, or delete
    }
    
    if (delta !== 0) {
      await admin.firestore().doc(`hubs/${hubId}`).update({
        memberCount: admin.firestore.FieldValue.increment(delta),
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
```

---

#### 4. Social Functions (`functions/src/social.js`)

**`onHubMessageCreated` (Trigger: onCreate)**
```javascript
exports.onHubMessageCreated = functions.firestore
  .document('hubs/{hubId}/chatMessages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const hubId = context.params.hubId;
    
    // 1. Denormalize sender data
    const sender = await admin.firestore().doc(`users/${message.authorId}`).get();
    await snap.ref.update({
      senderName: sender.data().name,
      senderPhotoUrl: sender.data().photoUrl || null,
    });
    
    // 2. Update hub lastActivity
    await admin.firestore().doc(`hubs/${hubId}`).update({
      lastActivity: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // 3. Update sender's lastActiveAt in HubMember
    await admin.firestore()
      .doc(`hubs/${hubId}/members/${message.authorId}`)
      .update({
        lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    
    // 4. Fetch FCM tokens of all active members (exclude sender)
    const membersSnapshot = await admin.firestore()
      .collection(`hubs/${hubId}/members`)
      .where('status', '==', 'active')
      .get();
    
    const memberIds = membersSnapshot.docs
      .map(doc => doc.id)
      .filter(id => id !== message.authorId);
    
    // Fetch tokens in parallel
    const tokenPromises = memberIds.map(async memberId => {
      const tokensDoc = await admin.firestore()
        .doc(`users/${memberId}/fcm_tokens/tokens`)
        .get();
      return tokensDoc.exists ? tokensDoc.data().tokens || [] : [];
    });
    
    const tokenArrays = await Promise.all(tokenPromises);
    const allTokens = tokenArrays.flat();
    
    // 5. Send push notifications
    if (allTokens.length > 0) {
      const hub = await admin.firestore().doc(`hubs/${hubId}`).get();
      
      await admin.messaging().sendEachForMulticast({
        tokens: allTokens,
        notification: {
          title: hub.data().name,
          body: `${sender.data().name}: ${message.text.substring(0, 50)}`,
        },
        data: {
          type: 'hub_chat',
          hubId: hubId,
          messageId: snap.id,
        },
      });
    }
  });
```

**`onCommentCreated` (Trigger: onCreate)**
```javascript
exports.onCommentCreated = functions.firestore
  .document('hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const comment = snap.data();
    const postId = context.params.postId;
    const hubId = context.params.hubId;
    
    // 1. Denormalize author data
    const author = await admin.firestore().doc(`users/${comment.authorId}`).get();
    await snap.ref.update({
      authorName: author.data().name,
      authorPhotoUrl: author.data().photoUrl || null,
    });
    
    // 2. Increment post commentCount
    const postRef = admin.firestore()
      .doc(`hubs/${hubId}/feed/posts/items/${postId}`);
    await postRef.update({
      commentCount: admin.firestore.FieldValue.increment(1),
    });
    
    // 3. Notify post author (if not self-commenting)
    const post = (await postRef.get()).data();
    if (post.authorId !== comment.authorId) {
      // Fetch post author's FCM tokens
      const tokensDoc = await admin.firestore()
        .doc(`users/${post.authorId}/fcm_tokens/tokens`)
        .get();
      
      const tokens = tokensDoc.exists ? tokensDoc.data().tokens || [] : [];
      
      if (tokens.length > 0) {
        await admin.messaging().sendEachForMulticast({
          tokens: tokens,
          notification: {
            title: 'תגובה חדשה',
            body: `${author.data().name} הגיב על הפוסט שלך`,
          },
          data: {
            type: 'comment',
            postId: postId,
            hubId: hubId,
          },
        });
      }
      
      // Create in-app notification
      await admin.firestore()
        .collection(`notifications/${post.authorId}/items`)
        .add({
          type: 'new_comment',
          title: 'תגובה חדשה',
          body: `${author.data().name} הגיב על הפוסט שלך`,
          entityId: postId,
          hubId: hubId,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
  });
```

---

## 6.3 Firestore Database Structure

### Root Collections

```
/users/{uid}
  - User profile, stats, preferences
  /fcm_tokens
    /tokens (document with tokens array field)
  /following/{followingId}
  /followers/{followerId}
  /gamification
    /stats (server-managed)

/hubs/{hubId}
  - Hub identity, settings
  /members/{userId}  ← NEW: HubMember subcollection (Dec 2025 refactor)
  /events/items/{eventId}
  /feed/posts/items/{postId}
    /comments/{commentId}
  /chatMessages/{messageId}
  /polls/{pollId}

/games/{gameId}
  - Game info, teams, matches
  /signups/{userId}
  /teams/{teamId}
  /events/{eventId}  (in-game events: goals, assists, cards)
  /chatMessages/{messageId}

/venues/{venueId}

/feedPosts/{postId}  ← Regional feed (global)

/notifications/{userId}/items/{notificationId}

/private_messages/{conversationId}
  /messages/{messageId}

/ratings/{userId}/history/{ratingId}  (deprecated, replaced by HubMember.managerRating)

/_system_logs/{logId}  (Cloud Function logs)
```

### Key Denormalized Fields

**Denormalization Strategy:** Duplicate frequently-accessed data to reduce read operations and improve performance. Cloud Functions keep denormalized fields in sync.

| Collection | Denormalized Fields | Source | Updated By |
|------------|---------------------|--------|------------|
| `Game` | `createdByName`, `createdByPhotoUrl`, `hubName` | `User`, `Hub` | `onGameCreated` |
| `Game` | `confirmedPlayerIds`, `confirmedPlayerCount`, `isFull` | `GameSignup` (count) | `onGameSignupChanged` |
| `Hub` | `memberCount` | `HubMember` (count where status=active) | `onMembershipChange` |
| `Hub` | `gameCount`, `lastActivity` | Aggregated | `onGameCreated`, `onHubMessageCreated` |
| `User` | `followerCount` | `Follower` (count) | `onFollowCreated` |
| `User` | `wins`, `losses`, `goals`, `assists`, `gamesPlayed` | `Game` (completed) | `onGameCompleted` |
| `FeedPost` | `authorName`, `authorPhotoUrl`, `hubName`, `hubLogoUrl` | `User`, `Hub` | `onFeedPostCreated` |
| `FeedPost` | `commentCount` | `Comment` (count) | `onCommentCreated` |
| `Comment` | `authorName`, `authorPhotoUrl` | `User` | `onCommentCreated` |
| `ChatMessage` | `senderName`, `senderPhotoUrl` | `User` | `onHubMessageCreated` |

**Benefits:**
- 90% reduction in read operations for UI (no N+1 queries)
- Faster page loads (single document read instead of multiple joins)
- Works offline (cached denormalized data)

**Trade-offs:**
- Eventual consistency (1-2 second delay on updates)
- Storage overhead (~10% increase)
- Complexity (Cloud Functions must keep data in sync)

---

## 6.4 Firestore Security Rules

**File:** `firestore.rules`  
**Philosophy:** Zero-trust model - every operation validated, deny by default

### Core Helper Functions

```javascript
// Check if user is authenticated
function isAuthenticated() {
  return request.auth != null;
}

// Check if user owns the document
function isOwner(userId) {
  return isAuthenticated() && request.auth.uid == userId;
}

// Get hub data
function getHubData(hubId) {
  return get(/databases/$(database)/documents/hubs/$(hubId)).data;
}

// Get user's HubMember document
function getMembership(hubId, userId) {
  let memberPath = /databases/$(database)/documents/hubs/$(hubId)/members/$(userId);
  return exists(memberPath) ? get(memberPath).data : null;
}

// Check if user is active hub member
function isActiveHubMember(hubId) {
  let hub = getHubData(hubId);
  let membership = getMembership(hubId, request.auth.uid);
  
  // Creator is always active, OR membership exists and status is active
  return isAuthenticated() && (
    hub.createdBy == request.auth.uid ||
    (membership != null && membership.status == 'active')
  );
}

// Check if user has specific role in hub
function hasRole(hubId, userId, allowedRoles) {
  let hub = getHubData(hubId);
  let membership = getMembership(hubId, userId);
  
  return (
    (hub.createdBy == userId && 'manager' in allowedRoles) ||
    (membership != null && 
     membership.status == 'active' && 
     membership.role in allowedRoles)
  );
}

// Specific role checks
function isHubManager(hubId) {
  return hasRole(hubId, request.auth.uid, ['manager']);
}

function isHubModerator(hubId) {
  return hasRole(hubId, request.auth.uid, ['manager', 'moderator']);
}

function isHubVeteran(hubId) {
  let membership = getMembership(hubId, request.auth.uid);
  return isActiveHubMember(hubId) && 
         (membership != null && membership.veteranSince != null);
}
```

### Key Rules

**Users Collection:**
```javascript
match /users/{userId} {
  allow read: if isAuthenticated();
  allow create: if isOwner(userId);
  allow update: if isOwner(userId);
  allow delete: if false; // Soft delete only (set isActive=false)
}
```

**Hubs Collection:**
```javascript
match /hubs/{hubId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated();
  allow update: if isHubManager(hubId);
  allow delete: if isHubManager(hubId);
  
  // HubMember subcollection
  match /members/{userId} {
    allow read: if isAuthenticated();
    allow create: if isAuthenticated() && 
                     (isOwner(userId) || isHubManager(hubId));
    allow update: if isHubManager(hubId) || isOwner(userId);
    allow delete: if isHubManager(hubId) || isOwner(userId);
  }
  
  // Feed posts
  match /feed/posts/items/{postId} {
    allow read: if isAuthenticated();
    allow create: if isActiveHubMember(hubId);
    allow update: if isOwner(resource.data.authorId) || isHubModerator(hubId);
    allow delete: if isOwner(resource.data.authorId) || isHubModerator(hubId);
    
    // Comments
    match /comments/{commentId} {
      allow read: if isAuthenticated();
      allow create: if isActiveHubMember(hubId);
      allow delete: if isOwner(resource.data.authorId) || isHubModerator(hubId);
    }
  }
  
  // Chat messages
  match /chatMessages/{messageId} {
    allow read: if isActiveHubMember(hubId);
    allow create: if isActiveHubMember(hubId);
    allow delete: if isOwner(resource.data.authorId) || isHubModerator(hubId);
  }
  
  // Hub events
  match /events/items/{eventId} {
    allow read: if isAuthenticated();
    allow create: if isHubModerator(hubId);
    allow update: if isHubModerator(hubId);
    allow delete: if isHubModerator(hubId);
  }
}
```

**Games Collection:**
```javascript
match /games/{gameId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated() && 
                   (resource.data.hubId == null || isActiveHubMember(resource.data.hubId));
  allow update: if isOwner(resource.data.createdBy) || 
                   (resource.data.hubId != null && isHubModerator(resource.data.hubId));
  allow delete: if isOwner(resource.data.createdBy) || 
                   (resource.data.hubId != null && isHubManager(resource.data.hubId));
  
  // Game signups
  match /signups/{userId} {
    allow read: if isAuthenticated();
    allow create: if isOwner(userId);
    allow update: if isOwner(userId) || 
                     (get(/databases/$(database)/documents/games/$(gameId)).data.createdBy == request.auth.uid);
    allow delete: if isOwner(userId);
  }
  
  // Game chat
  match /chatMessages/{messageId} {
    allow read: if isAuthenticated(); // TODO: restrict to confirmed players only
    allow create: if isAuthenticated(); // TODO: restrict to confirmed players only
    allow delete: if isOwner(resource.data.senderId);
  }
}
```

**Venues Collection:**
```javascript
match /venues/{venueId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated();
  allow update: if isOwner(resource.data.createdBy) || 
                   (resource.data.hubId != null && isHubManager(resource.data.hubId));
  allow delete: if isOwner(resource.data.createdBy) || 
                   (resource.data.hubId != null && isHubManager(resource.data.hubId));
}
```

**Notifications Collection:**
```javascript
match /notifications/{userId}/items/{notificationId} {
  allow read: if isOwner(userId);
  allow create: if false; // Only Cloud Functions can create
  allow update: if isOwner(userId); // Mark as read
  allow delete: if isOwner(userId);
}
```

**Private Messages:**
```javascript
match /private_messages/{conversationId} {
  allow read: if isAuthenticated() && 
                 request.auth.uid in resource.data.participantIds;
  allow create: if isAuthenticated() && 
                   request.auth.uid in request.resource.data.participantIds;
  
  match /messages/{messageId} {
    allow read: if isAuthenticated() && 
                   request.auth.uid in get(/databases/$(database)/documents/private_messages/$(conversationId)).data.participantIds;
    allow create: if isAuthenticated() && 
                     request.auth.uid in get(/databases/$(database)/documents/private_messages/$(conversationId)).data.participantIds;
  }
}
```

---

## 6.5 Required Firestore Indexes

**File:** `firestore.indexes.json`

### Composite Indexes (Must be created manually)

```json
{
  "indexes": [
    {
      "collectionGroup": "members",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "role", "order": "ASCENDING" },
        { "fieldPath": "joinedAt", "order": "ASCENDING" },
        { "fieldPath": "veteranSince", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "games",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "hubId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "gameDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "games",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "visibility", "order": "ASCENDING" },
        { "fieldPath": "region", "order": "ASCENDING" },
        { "fieldPath": "gameDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "games",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "gameDate", "order": "ASCENDING" },
        { "fieldPath": "enableAttendanceReminder", "order": "ASCENDING" },
        { "fieldPath": "reminderSent2Hours", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "hubs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "region", "order": "ASCENDING" },
        { "fieldPath": "isPrivate", "order": "ASCENDING" },
        { "fieldPath": "memberCount", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "hubs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "geohash", "order": "ASCENDING" },
        { "fieldPath": "lastActivity", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "venues",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isPublic", "order": "ASCENDING" },
        { "fieldPath": "geohash", "order": "ASCENDING" },
        { "fieldPath": "surfaceType", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "signups",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "signedUpAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "read", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "feedPosts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "region", "order": "ASCENDING" },
        { "fieldPath": "type", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Index Creation Command:**
```bash
firebase deploy --only firestore:indexes
```

**Performance Impact:**
- Without indexes: Queries fail with "requires index" error
- With indexes: Queries complete in <100ms for 10k documents

---

## 6.6 Data Consistency Patterns

### Pattern 1: Atomic Membership Operations

**Problem:** Adding user to hub requires updating 2 documents (Hub.memberIds, User.hubIds)
**Solution:** Firestore Transaction

```dart
Future<void> joinHub(String hubId, String userId) async {
  return _firestore.runTransaction((transaction) async {
    // Read phase
    final hubRef = _firestore.doc('hubs/$hubId');
    final userRef = _firestore.doc('users/$userId');
    final hubMemberRef = _firestore.doc('hubs/$hubId/members/$userId');
    
    final hubSnap = await transaction.get(hubRef);
    final userSnap = await transaction.get(userRef);
    
    // Validate
    if (!hubSnap.exists) throw Exception('Hub not found');
    if (!userSnap.exists) throw Exception('User not found');
    if (hubSnap.data()!['memberCount'] >= 50) throw Exception('Hub is full');
    
    // Write phase (all-or-nothing)
    transaction.set(hubMemberRef, {
      'hubId': hubId,
      'userId': userId,
      'role': 'member',
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    
    transaction.update(userRef, {
      'hubIds': FieldValue.arrayUnion([hubId]),
    });
    
    // NOTE: Hub.memberCount updated by Cloud Function trigger (onMembershipChange)
  });
}
```

### Pattern 2: Eventual Consistency for Denormalization

**Problem:** User changes name → must update denormalized name in 100+ posts
**Solution:** Accept eventual consistency, update via Cloud Function

```javascript
// Client updates user name
await _firestore.doc('users/$userId').update({'name': newName});

// Cloud Function (future implementation)
exports.onUserNameChanged = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    if (before.name !== after.name) {
      const userId = context.params.userId;
      const newName = after.name;
      
      // Update denormalized name in feed posts (batch writes)
      const postsSnapshot = await admin.firestore()
        .collectionGroup('items')
        .where('authorId', '==', userId)
        .get();
      
      const batches = [];
      let batch = admin.firestore().batch();
      let count = 0;
      
      for (const postDoc of postsSnapshot.docs) {
        batch.update(postDoc.ref, { authorName: newName });
        count++;
        
        if (count >= 500) {
          batches.push(batch.commit());
          batch = admin.firestore().batch();
          count = 0;
        }
      }
      
      if (count > 0) {
        batches.push(batch.commit());
      }
      
      await Promise.all(batches);
    }
  });
```

**Trade-off:** Posts show old name for 1-2 seconds until Cloud Function completes

### Pattern 3: Optimistic UI Updates

**Problem:** Liking a post requires round-trip to Firestore (~100ms)
**Solution:** Update UI immediately, rollback on error

```dart
Future<void> likePost(String hubId, String postId) async {
  final postRef = _firestore.doc('hubs/$hubId/feed/posts/items/$postId');
  
  // Optimistic update (UI shows liked immediately)
  final optimisticUpdate = {
    'likes': FieldValue.arrayUnion([_currentUserId]),
    'likeCount': FieldValue.increment(1),
  };
  
  try {
    await postRef.update(optimisticUpdate);
    // Success - UI already updated
  } catch (e) {
    // Rollback optimistic update
    final rollback = {
      'likes': FieldValue.arrayRemove([_currentUserId]),
      'likeCount': FieldValue.increment(-1),
    };
    await postRef.update(rollback);
    rethrow;
  }
}
```

---

## 6.7 Performance Optimizations

### Optimization 1: Query Pagination

**Problem:** Loading 10,000 games freezes UI
**Solution:** Paginate with `startAfter` cursor

```dart
static const int PAGE_SIZE = 20;
DocumentSnapshot? _lastDocument;

Future<List<Game>> loadNextPage() async {
  Query query = _firestore
      .collection('games')
      .where('hubId', isEqualTo: hubId)
      .orderBy('gameDate', descending: true)
      .limit(PAGE_SIZE);
  
  if (_lastDocument != null) {
    query = query.startAfterDocument(_lastDocument!);
  }
  
  final snapshot = await query.get();
  
  if (snapshot.docs.isNotEmpty) {
    _lastDocument = snapshot.docs.last;
  }
  
  return snapshot.docs.map((doc) => Game.fromJson(doc.data())).toList();
}
```

### Optimization 2: In-Memory Caching

**Service:** `lib/services/cache_service.dart`

```dart
class CacheService {
  final _cache = <String, _CacheEntry>{};
  
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value as T;
  }
  
  void set<T>(String key, T value, Duration ttl) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
  }
}

// Usage in repository
Future<Hub?> getHub(String hubId) async {
  // Check cache first
  final cached = _cacheService.get<Hub>('hub_$hubId');
  if (cached != null) return cached;
  
  // Fetch from Firestore
  final doc = await _firestore.doc('hubs/$hubId').get();
  if (!doc.exists) return null;
  
  final hub = Hub.fromJson(doc.data()!);
  
  // Cache for 1 hour
  _cacheService.set('hub_$hubId', hub, Duration(hours: 1));
  
  return hub;
}
```

**Cache TTLs:**
- Games: 5 minutes
- Hubs: 1 hour
- Users: 1 hour
- Comments: 5 minutes
- Static data (venues, regions): 24 hours

### Optimization 3: Denormalized Counters

**Problem:** Counting 10,000 confirmed signups per game is expensive
**Solution:** Maintain denormalized `confirmedPlayerCount` field

**Client (Optimistic):**
```dart
await _firestore.doc('games/$gameId').update({
  'confirmedPlayerCount': FieldValue.increment(1),
  'confirmedPlayerIds': FieldValue.arrayUnion([userId]),
});
```

**Server (Authoritative):**
```javascript
// Cloud Function recalculates on every signup change
exports.onGameSignupChanged = functions.firestore
  .document('games/{gameId}/signups/{userId}')
  .onWrite(async (change, context) => {
    const gameId = context.params.gameId;
    
    const confirmedSnapshot = await admin.firestore()
      .collection(`games/${gameId}/signups`)
      .where('status', '==', 'confirmed')
      .get();
    
    await admin.firestore().doc(`games/${gameId}`).update({
      confirmedPlayerCount: confirmedSnapshot.size,
      confirmedPlayerIds: confirmedSnapshot.docs.map(doc => doc.id),
    });
  });
```

**Performance Gain:** 90% faster (1 document read vs 10,000+ signup documents)

---

## 6.8 Monitoring & Observability

### Firebase Crashlytics

**Integration:** `lib/services/error_handler_service.dart`

```dart
class ErrorHandlerService {
  static Future<void> initialize() async {
    if (kIsWeb) return; // Not supported on web
    
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
  }) async {
    if (kIsWeb) return;
    
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
      information: context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
    );
  }
  
  static Future<void> setUserContext(String uid) async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(uid);
  }
}
```

**Metrics Tracked:**
- Fatal crashes (app killed)
- Non-fatal errors (caught exceptions)
- ANR (Application Not Responding) on Android
- Custom logs (e.g., "User failed to join hub: Hub full")

### Firebase Analytics

**Integration:** `lib/services/analytics_service.dart`

```dart
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }
  
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
  
  Future<void> setUserProperties({
    required int hubCount,
    required int gamesPlayed,
    required bool isVeteran,
  }) async {
    await _analytics.setUserProperty(name: 'hub_count', value: hubCount.toString());
    await _analytics.setUserProperty(name: 'games_played', value: gamesPlayed.toString());
    await _analytics.setUserProperty(name: 'veteran_status', value: isVeteran ? 'yes' : 'no');
  }
}
```

**Key Events Tracked:**
- `hub_created` - Hub creation (dimensions: region, is_private)
- `game_created` - Game creation (dimensions: team_count, visibility)
- `rsvp_confirmed` - User confirmed attendance
- `team_maker_used` - Team generation (dimensions: player_count, balance_score)
- `result_recorded` - Game results submitted
- `veteran_promoted` - User became veteran (server-side event)
- `post_created` - Feed post created
- `recruiting_post_shared` - Recruiting post shared to regional feed

### Cloud Function Logs

**Access:** Firebase Console → Functions → Logs

**Log Levels:**
- `console.log()` - Info (successful operations)
- `console.warn()` - Warnings (non-critical issues)
- `console.error()` - Errors (failures, exceptions)

**Structured Logging:**
```javascript
console.log(JSON.stringify({
  level: 'info',
  event: 'veteran_promotion',
  count: eligibleSnapshot.size,
  timestamp: Date.now(),
}));
```

**Log Retention:** 30 days (default), export to BigQuery for long-term analysis

---

## 6.9 Backup & Disaster Recovery

### Firestore Backup Strategy

**Automated Daily Backups:**
- **Enabled:** Yes (Firebase Console → Firestore → Backups)
- **Schedule:** Daily at 3 AM UTC
- **Retention:** 7 days
- **Location:** `us-central1` (same as Firestore region)

**Manual Export (On-Demand):**
```bash
gcloud firestore export gs://kattrick-backups/$(date +%Y%m%d) \
  --project=kickabout-production
```

**Restore Procedure:**
1. Create new Firestore instance (staging)
2. Import from backup:
   ```bash
   gcloud firestore import gs://kattrick-backups/20251205 \
     --project=kickabout-staging
   ```
3. Verify data integrity
4. Promote staging to production (blue-green deployment)

### Firebase Storage Backup

**Strategy:** Replicate to secondary bucket daily

```bash
gsutil -m rsync -r gs://kickabout-production.appspot.com \
                   gs://kickabout-backups-storage
```

**Retention:** 30 days (delete old backups with lifecycle policy)

---

## 6.10 Scalability Projections

### Current Scale (Dec 2025)
- **Users:** ~500 (beta)
- **Hubs:** ~50
- **Games/Week:** ~100
- **Firestore Reads:** ~50k/day
- **Firestore Writes:** ~5k/day
- **Storage:** ~2 GB

### Target Scale (12 months)
- **Users:** 10,000 active (MAU)
- **Hubs:** 500
- **Games/Week:** 2,000
- **Firestore Reads:** ~2M/day
- **Firestore Writes:** ~200k/day
- **Storage:** ~50 GB

### Scaling Strategy

**Firestore:**
- Current: Single region (`us-central1`)
- Future (if >50k concurrent users): Multi-region replication

**Cloud Functions:**
- Current: Default memory (256MB), default timeout (60s)
- Future: Increase memory to 512MB for image processing, increase timeout to 300s for batch operations

**Storage:**
- Current: Default bucket (free tier: 5 GB)
- Future (if >100 GB): Enable CDN (Cloud CDN) for faster image delivery

**Cost Projections (10k MAU):**
- Firestore: $150/month (reads + writes)
- Storage: $10/month (50 GB)
- Cloud Functions: $50/month (invocations)
- Firebase Hosting: $0 (static assets <10 GB)
- **Total Backend:** ~$210/month

**Revenue Needed (to break even):**
- $210 / 10,000 users = $0.021 ARPU/month
- Or: $0.10 ARPU/month for 50% margin → $1,000/month revenue

---

# 7. DATA MODELS

This section documents all 35+ data models in the Kattrick application with complete field specifications, validation rules, and relationships.

## 7.1 Core Entity Models

### User Model
**Firestore Path:** `/users/{uid}`
**File:** `lib/models/user.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `uid` | String | ✅ | - | Firebase Auth UID (immutable) |
| `name` | String | ✅ | - | Canonical name (used throughout app) |
| `email` | String | ✅ | - | Email address (from Firebase Auth) |
| `photoUrl` | String? | ❌ | null | Profile photo URL (512x512, stored in `/avatars/{uid}.jpg`) |
| `avatarColor` | String? | ❌ | null | Hex color for avatar background (e.g., "#FF5733") |
| `phoneNumber` | String? | ❌ | null | Phone number (Israeli format: +972...) |
| `city` | String? | ❌ | null | City of residence (Hebrew) |
| `displayName` | String? | ❌ | null | Custom nickname (independent from firstName/lastName) |
| `firstName` | String? | ❌ | null | First name (used for formal display) |
| `lastName` | String? | ❌ | null | Last name (used for formal display) |
| `birthDate` | DateTime | ✅ | - | **REQUIRED** - Date of birth (13+ age gate enforced) |
| `favoriteTeamId` | String? | ❌ | null | Favorite football team ID |
| `facebookProfileUrl` | String? | ❌ | null | Facebook profile URL |
| `instagramProfileUrl` | String? | ❌ | null | Instagram profile URL |
| `showSocialLinks` | bool | ❌ | false | Show social links to others |
| `availabilityStatus` | String | ❌ | 'available' | DEPRECATED - use `isActive` |
| `isActive` | bool | ❌ | true | Available for invites/games |
| `createdAt` | DateTime | ✅ | - | Account creation timestamp |
| `hubIds` | List\<String\> | ❌ | [] | List of hub IDs user is member of |
| `currentRankScore` | double | ❌ | 5.0 | **DEPRECATED** - Use `HubMember.managerRating` |
| `preferredPosition` | String | ❌ | 'Midfielder' | 'Goalkeeper', 'Defender', 'Midfielder', 'Attacker' |
| `totalParticipations` | int | ❌ | 0 | Total games played (for badges) |
| `gamesPlayed` | int | ❌ | 0 | Games played (compatibility field) |
| `location` | GeoPoint? | ❌ | null | User location (for proximity search) |
| `geohash` | String? | ❌ | null | Geohash for location (for efficient querying) |
| `region` | String? | ❌ | null | Region: צפון, מרכז, דרום, ירושלים |
| `isProfileComplete` | bool | ❌ | false | Profile completion flag |
| `followerCount` | int | ❌ | 0 | Denormalized follower count (Cloud Function managed) |
| `wins` | int | ❌ | 0 | Total wins (denormalized from game results) |
| `losses` | int | ❌ | 0 | Total losses (denormalized) |
| `draws` | int | ❌ | 0 | Total draws (denormalized) |
| `goals` | int | ❌ | 0 | Total goals scored (denormalized) |
| `assists` | int | ❌ | 0 | Total assists (denormalized) |
| `privacySettings` | Map | ❌ | {...} | Privacy controls (hideFromSearch, hideEmail, etc.) |
| `notificationPreferences` | Map | ❌ | {...} | Notification preferences (game_reminder, message, etc.) |
| `blockedUserIds` | List\<String\> | ❌ | [] | Blocked users |

**Extensions:**
- `displayName` getter: Prioritizes firstName + lastName, then name
- `age` getter: Calculates current age from birthDate
- `ageGroup` getter: Returns AgeGroup enum (13-17, 18-24, 25-34, 35-44, 45-54, 55+)
- `ageCategory` getter: Returns category (Kids, Young, Adults, Veterans, Legends)
- `meetsMinimumAge` getter: Validates 13+ requirement

**Validation Rules:**
- `birthDate` must be 13+ years ago
- `email` must be valid email format
- `phoneNumber` must match Israeli format (if provided)
- `photoUrl` must be HTTPS URL (if provided)

**Indexes Required:**
- `geohash` (ascending) + `isActive` (ascending) - for proximity search
- `region` (ascending) + `isActive` (ascending) - for regional discovery
- `hubIds` (array-contains) - for hub member queries

---

### Hub Model (REFACTORED Dec 2025)
**Firestore Path:** `/hubs/{hubId}`
**File:** `lib/models/hub.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `hubId` | String | ✅ | - | Unique hub identifier |
| `name` | String | ✅ | - | Hub name (Hebrew) |
| `description` | String? | ❌ | null | Hub description |
| `createdBy` | String | ✅ | - | Creator UID (always manager) |
| `createdAt` | DateTime | ✅ | - | Creation timestamp |
| `memberCount` | int | ❌ | 0 | **Denormalized** member count (Cloud Function managed) |
| `settings` | Map | ❌ | {...} | Hub settings (see below) |
| `permissions` | Map | ❌ | {} | Custom permission overrides (rare) |
| `location` | GeoPoint? | ❌ | null | **DEPRECATED** - use venues |
| `geohash` | String? | ❌ | null | Geohash for location |
| `radius` | double? | ❌ | null | Radius in km |
| `venueIds` | List\<String\> | ❌ | [] | IDs of venues where hub plays |
| `mainVenueId` | String? | ❌ | null | Main/home venue ID (required) |
| `primaryVenueId` | String? | ❌ | null | Primary venue for map display (denormalized) |
| `primaryVenueLocation` | GeoPoint? | ❌ | null | Primary venue location (denormalized) |
| `profileImageUrl` | String? | ❌ | null | Hub profile picture |
| `logoUrl` | String? | ❌ | null | Hub logo (for feed posts) |
| `hubRules` | String? | ❌ | null | Hub rules and guidelines |
| `region` | String? | ❌ | null | Region: צפון, מרכז, דרום, ירושלים |
| `isPrivate` | bool | ❌ | false | Requires "Request to Join" |
| `paymentLink` | String? | ❌ | null | PayBox/Bit payment link |
| `gameCount` | int? | ❌ | null | **Denormalized** game count (Cloud Function managed) |
| `lastActivity` | DateTime? | ❌ | null | **Denormalized** last activity (Cloud Function managed) |
| `activityScore` | double | ❌ | 0 | Activity score for ranking |

**Settings Map (`settings`):**
```dart
{
  'showManagerContactInfo': true,      // Show manager contact in hub profile
  'allowJoinRequests': true,            // Allow users to request to join
  'allowModeratorsToCreateGames': false // Allow moderators to open games from events
}
```

**Permissions Map (`permissions`):**
```dart
// Example: Allow specific user to create events even if not moderator
{
  'canCreateEvents': ['userId1', 'userId2']
}
```

**IMPORTANT CHANGES (Dec 3, 2025 Refactor):**
- ❌ **REMOVED:** `memberJoinDates`, `roles`, `managerRatings`, `bannedUserIds`
- ✅ **NOW IN:** `/hubs/{hubId}/members/{userId}` (HubMember subcollection)
- ✅ **KEPT:** `memberCount` (denormalized counter)

**Indexes Required:**
- `region` (ascending) + `isPrivate` (descending) + `activityScore` (descending) - for discovery
- `primaryVenueLocation` (geopoint) - for geospatial queries

---

### HubMember Model (NEW - Dec 2025)
**Firestore Path:** `/hubs/{hubId}/members/{userId}`
**File:** `lib/models/hub_member.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `hubId` | String | ✅ | - | Hub ID (from path) |
| `userId` | String | ✅ | - | User ID (from path) |
| `joinedAt` | DateTime | ✅ | - | When user joined hub |
| `role` | HubMemberRole | ❌ | member | Role enum: manager, moderator, veteran, member |
| `status` | HubMemberStatus | ❌ | active | Status enum: active, left, banned |
| `veteranSince` | DateTime? | ❌ | null | **SERVER-MANAGED** - Set by Cloud Function after 60 days |
| `managerRating` | double | ❌ | 0.0 | Manager's rating for this player (1-7 scale) |
| `lastActiveAt` | DateTime? | ❌ | null | Last activity in hub |
| `updatedAt` | DateTime? | ❌ | null | Last update timestamp |
| `updatedBy` | String? | ❌ | null | Who updated (userId or 'system:functionName') |
| `statusReason` | String? | ❌ | null | Reason for status change (for bans/kicks) |

**Role Enum (`HubMemberRole`):**
```dart
enum HubMemberRole {
  manager,    // Full control - hub creator or promoted
  moderator,  // Can manage content, players, create events
  veteran,    // Long-time member (60+ days), can record results
  member      // Regular member, can create games and participate
}
```

**Status Enum (`HubMemberStatus`):**
```dart
enum HubMemberStatus {
  active,   // Currently active member
  left,     // User chose to leave (soft-delete)
  banned    // Kicked/banned by manager
}
```

**Helpers:**
- `isVeteran`: Returns true if `veteranSince != null`
- `daysSinceJoined`: Calculates days since `joinedAt`
- `isActive`: Returns true if `status == active`
- `canPromoteToVeteran`: Returns true if eligible for veteran promotion

**Validation Rules:**
- Only ONE manager per hub (enforced by Firestore rules)
- `role` can only be changed by hub manager (or Cloud Function for veteran promotion)
- `veteranSince` can ONLY be set by Cloud Function (client writes rejected)
- `status` transitions: active ↔ left, active → banned (no reverse for banned without manager approval)

**Indexes Required:**
- `status` (ascending) + `role` (ascending) - for member queries
- `status` (ascending) + `veteranSince` (ascending) - for veteran promotion Cloud Function

---

### Game Model
**Firestore Path:** `/games/{gameId}`
**File:** `lib/models/game.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `gameId` | String | ✅ | - | Unique game identifier |
| `createdBy` | String | ✅ | - | Creator UID |
| `hubId` | String? | ❌ | null | Hub ID (null for public pickup games) |
| `eventId` | String? | ❌ | null | Event ID if game created from event |
| `gameDate` | DateTime | ✅ | - | Game date/time |
| `location` | String? | ❌ | null | **DEPRECATED** - Legacy text location |
| `locationPoint` | GeoPoint? | ❌ | null | Geographic location |
| `geohash` | String? | ❌ | null | Geohash for location |
| `venueId` | String? | ❌ | null | Venue reference |
| `teamCount` | int | ❌ | 2 | Number of teams (2, 3, or 4) |
| `status` | GameStatus | ❌ | teamSelection | See GameStatus enum below |
| `visibility` | GameVisibility | ❌ | private | private, public, recruiting |
| `targetingCriteria` | TargetingCriteria? | ❌ | null | Targeting for public games |
| `requiresApproval` | bool | ❌ | false | Force true for public games |
| `minPlayersToPlay` | int | ❌ | 10 | Minimum players to start |
| `maxPlayers` | int? | ❌ | null | Maximum capacity (hard cap) |
| `photoUrls` | List\<String\> | ❌ | [] | Game photos |
| `createdAt` | DateTime | ✅ | - | Creation timestamp |
| `updatedAt` | DateTime | ✅ | - | Last update timestamp |
| `isRecurring` | bool | ❌ | false | Is recurring game? |
| `parentGameId` | String? | ❌ | null | Parent recurring game ID |
| `recurrencePattern` | String? | ❌ | null | 'weekly', 'biweekly', 'monthly' |
| `recurrenceEndDate` | DateTime? | ❌ | null | When to stop recurring |
| `createdByName` | String? | ❌ | null | **Denormalized** creator name |
| `createdByPhotoUrl` | String? | ❌ | null | **Denormalized** creator photo |
| `hubName` | String? | ❌ | null | **Denormalized** hub name |
| `teams` | List\<Team\> | ❌ | [] | Teams created in TeamMaker |
| `legacyTeamAScore` | int? | ❌ | null | **DEPRECATED** - Use `matches` for session mode |
| `legacyTeamBScore` | int? | ❌ | null | **DEPRECATED** - Use `matches` for session mode |
| `matches` | List\<MatchResult\> | ❌ | [] | Multi-match session results |
| `aggregateWins` | Map\<String, int\> | ❌ | {} | Summary: {'Blue': 6, 'Red': 4} |
| `durationInMinutes` | int? | ❌ | null | Game duration |
| `gameEndCondition` | String? | ❌ | null | End condition (e.g., "first to 5") |
| `region` | String? | ❌ | null | Region (copied from Hub) |
| `showInCommunityFeed` | bool | ❌ | false | Show in community feed |
| `goalScorerIds` | List\<String\> | ❌ | [] | **Denormalized** goal scorer IDs |
| `goalScorerNames` | List\<String\> | ❌ | [] | **Denormalized** goal scorer names |
| `mvpPlayerId` | String? | ❌ | null | **Denormalized** MVP player ID |
| `mvpPlayerName` | String? | ❌ | null | **Denormalized** MVP player name |
| `venueName` | String? | ❌ | null | **Denormalized** venue name |
| `confirmedPlayerIds` | List\<String\> | ❌ | [] | **Denormalized** confirmed players |
| `confirmedPlayerCount` | int | ❌ | 0 | **Denormalized** confirmed count |
| `isFull` | bool | ❌ | false | **Denormalized** is game full |
| `maxParticipants` | int? | ❌ | null | Max participants (from events) |
| `enableAttendanceReminder` | bool | ❌ | true | Send 2h reminders |
| `reminderSent2Hours` | bool? | ❌ | null | Reminder sent flag (Cloud Function) |
| `reminderSent2HoursAt` | DateTime? | ❌ | null | When reminder sent |
| `auditLog` | List\<GameAuditEvent\> | ❌ | [] | Audit trail for admin actions |

**GameStatus Enum:**
```dart
enum GameStatus {
  teamSelection,  // Building teams
  waitingForPlayers,  // Waiting for enough players
  ready,  // Ready to start
  inProgress,  // Game in progress
  completed,  // Game finished
  cancelled  // Game cancelled
}
```

**GameVisibility Enum:**
```dart
enum GameVisibility {
  private,    // Hub members only
  public,     // Open to all
  recruiting  // Actively recruiting
}
```

**Subcollections:**
- `/games/{gameId}/signups/{userId}` - GameSignup documents
- `/games/{gameId}/chat/{messageId}` - ChatMessage documents

**Indexes Required:**
- `hubId` (ascending) + `gameDate` (descending) - for hub game list
- `status` (ascending) + `gameDate` (ascending) - for upcoming games
- `visibility` (ascending) + `region` (ascending) + `gameDate` (ascending) - for discovery
- `createdBy` (ascending) + `createdAt` (descending) - for user's games

---

### GameSignup Model
**Firestore Path:** `/games/{gameId}/signups/{userId}`
**File:** `lib/models/game_signup.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `playerId` | String | ✅ | - | User ID (from path) |
| `signedUpAt` | DateTime | ✅ | - | Signup timestamp |
| `status` | SignupStatus | ❌ | pending | pending, confirmed, rejected, cancelled |
| `adminActionReason` | String? | ❌ | null | Mandatory for rejections/kicks |

**SignupStatus Enum:**
```dart
enum SignupStatus {
  pending,    // Awaiting approval
  confirmed,  // Approved/confirmed
  rejected,   // Rejected by organizer
  cancelled   // Cancelled by player
}
```

**Validation Rules:**
- Only ONE signup per player per game (enforced by document ID)
- `adminActionReason` required when status changes to `rejected`
- Cannot change status from `rejected` to `confirmed` without manager approval

**Denormalization:**
- Confirmed signups trigger Cloud Function to update `Game.confirmedPlayerIds` and `Game.confirmedPlayerCount`

---

### HubEvent Model
**Firestore Path:** `/hubs/{hubId}/events/{eventId}`
**File:** `lib/models/hub_event.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `eventId` | String | ✅ | - | Unique event identifier |
| `hubId` | String | ✅ | - | Hub ID |
| `createdBy` | String | ✅ | - | Creator UID |
| `title` | String | ✅ | - | Event title |
| `description` | String? | ❌ | null | Event description |
| `eventDate` | DateTime | ✅ | - | Event date/time |
| `createdAt` | DateTime | ✅ | - | Creation timestamp |
| `updatedAt` | DateTime | ✅ | - | Last update timestamp |
| `registeredPlayerIds` | List\<String\> | ❌ | [] | Registered players |
| `waitingListPlayerIds` | List\<String\> | ❌ | [] | Waiting list |
| `status` | String | ❌ | 'upcoming' | upcoming, ongoing, completed, cancelled |
| `isStarted` | bool | ❌ | false | In-progress session flag |
| `startedAt` | DateTime? | ❌ | null | When manager started session |
| `location` | String? | ❌ | null | Location text |
| `locationPoint` | GeoPoint? | ❌ | null | Geographic location |
| `geohash` | String? | ❌ | null | Geohash |
| `venueId` | String? | ❌ | null | Venue reference |
| `teamCount` | int | ❌ | 3 | Number of teams |
| `gameType` | String? | ❌ | null | 3v3, 4v4, 5v5, etc. |
| `durationMinutes` | int? | ❌ | 12 | Match duration |
| `maxParticipants` | int | ❌ | 15 | Maximum participants |
| `notifyMembers` | bool | ❌ | false | Send notification to all members |
| `showInCommunityFeed` | bool | ❌ | false | Show in community feed |
| `enableAttendanceReminder` | bool | ❌ | true | Send 2h reminders |
| `teams` | List\<Team\> | ❌ | [] | Planned teams (manager-only) |
| `matches` | List\<MatchResult\> | ❌ | [] | Match results |
| `aggregateWins` | Map\<String, int\> | ❌ | {} | Aggregate wins |
| `gameId` | String? | ❌ | null | Reference to Game if converted |

**Event → Game Conversion:**
When manager clicks "Open Game" on an event:
1. Event is converted to Game
2. `gameId` is set on HubEvent
3. `eventId` is set on Game
4. `registeredPlayerIds` → auto-confirmed in Game signups

---

### Venue Model
**Firestore Path:** `/venues/{venueId}`
**File:** `lib/models/venue.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `venueId` | String | ✅ | - | Unique venue identifier |
| `venueNumber` | int | ❌ | 0 | Sequential number |
| `hubId` | String | ✅ | - | Owning hub ID |
| `name` | String | ✅ | - | Venue name (Hebrew) |
| `description` | String? | ❌ | null | Description |
| `location` | GeoPoint | ✅ | - | **REQUIRED** exact location |
| `address` | String? | ❌ | null | Human-readable address |
| `googlePlaceId` | String? | ❌ | null | Google Places API ID |
| `amenities` | List\<String\> | ❌ | [] | ["parking", "showers", "lights"] |
| `surfaceType` | String | ❌ | 'grass' | grass, artificial, concrete |
| `maxPlayers` | int | ❌ | 11 | Max players per team |
| `createdAt` | DateTime | ✅ | - | Creation timestamp |
| `updatedAt` | DateTime | ✅ | - | Update timestamp |
| `createdBy` | String? | ❌ | null | Creator UID |
| `isActive` | bool | ❌ | true | Can be deactivated |
| `isMain` | bool | ❌ | false | Is main/home venue |
| `hubCount` | int | ❌ | 0 | Number of hubs using venue |
| `isPublic` | bool | ❌ | true | Public venue |
| `source` | String | ❌ | 'manual' | 'manual' or 'osm' |
| `externalId` | String? | ❌ | null | OSM ID |

**Indexes Required:**
- `location` (geopoint) - for geospatial queries
- `hubId` (ascending) + `isActive` (ascending) - for hub venues

---

## 7.2 Social & Communication Models

### FeedPost Model
**Firestore Path:** `/hubs/{hubId}/feed/posts/items/{postId}` OR `/feedPosts/{postId}` (regional feed)
**File:** `lib/models/feed_post.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `postId` | String | ✅ | - | Unique post identifier |
| `hubId` | String | ✅ | - | Hub ID |
| `authorId` | String | ✅ | - | Author UID |
| `type` | String | ✅ | - | 'post', 'game_created', 'game', 'achievement', 'rating', 'hub_recruiting' |
| `content` | String? | ❌ | null | Post content |
| `text` | String? | ❌ | null | Alternative to content (Cloud Function) |
| `gameId` | String? | ❌ | null | Related game ID |
| `eventId` | String? | ❌ | null | Related event ID (recruiting) |
| `achievementId` | String? | ❌ | null | Achievement ID |
| `isUrgent` | bool | ❌ | false | Show "דחוף" badge |
| `recruitingUntil` | DateTime? | ❌ | null | Recruiting deadline |
| `neededPlayers` | int | ❌ | 0 | Players needed |
| `likes` | List\<String\> | ❌ | [] | User IDs who liked |
| `likeCount` | int | ❌ | 0 | **Denormalized** like count |
| `commentCount` | int | ❌ | 0 | **Denormalized** comment count |
| `commentsCount` | int | ❌ | 0 | Legacy alias for commentCount |
| `comments` | List\<String\> | ❌ | [] | **DEPRECATED** - use subcollection |
| `photoUrls` | List\<String\> | ❌ | [] | Photo URLs |
| `createdAt` | DateTime | ✅ | - | Creation timestamp |
| `hubName` | String? | ❌ | null | **Denormalized** hub name |
| `hubLogoUrl` | String? | ❌ | null | **Denormalized** hub logo |
| `authorName` | String? | ❌ | null | **Denormalized** author name |
| `authorPhotoUrl` | String? | ❌ | null | **Denormalized** author photo |
| `entityId` | String? | ❌ | null | Related entity ID |
| `region` | String? | ❌ | null | Region (for regional feed) |

**Subcollections:**
- `/hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}` - Comment documents

**Indexes Required:**
- `hubId` (ascending) + `createdAt` (descending) - for hub feed
- `region` (ascending) + `createdAt` (descending) - for regional feed
- `type` (ascending) + `isUrgent` (descending) + `createdAt` (descending) - for recruiting posts

---

### Comment Model
**Firestore Path:** `/hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}`
**File:** `lib/models/comment.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `commentId` | String | ✅ | - | Unique comment identifier |
| `postId` | String | ✅ | - | Parent post ID |
| `authorId` | String | ✅ | - | Author UID |
| `text` | String | ✅ | - | Comment text |
| `createdAt` | DateTime | ✅ | - | Creation timestamp |
| `authorName` | String? | ❌ | null | **Denormalized** author name |
| `authorPhotoUrl` | String? | ❌ | null | **Denormalized** author photo |

**Denormalization:**
- Cloud Function `onCommentCreated` increments `FeedPost.commentCount`

---

### ChatMessage Model
**Firestore Path:** `/hubs/{hubId}/chat/{messageId}` OR `/games/{gameId}/chat/{messageId}` OR `/private_messages/{conversationId}/messages/{messageId}`
**File:** `lib/models/chat_message.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `messageId` | String | ✅ | - | Unique message identifier |
| `senderId` | String | ✅ | - | Sender UID |
| `message` | String | ✅ | - | Message text |
| `timestamp` | DateTime | ✅ | - | Send timestamp |
| `type` | String | ❌ | 'text' | 'text', 'image', 'game', 'poll' |
| `senderName` | String? | ❌ | null | **Denormalized** sender name |
| `senderPhotoUrl` | String? | ❌ | null | **Denormalized** sender photo |
| `imageUrl` | String? | ❌ | null | Image URL (if type=image) |
| `gameId` | String? | ❌ | null | Game ID (if type=game) |
| `pollId` | String? | ❌ | null | Poll ID (if type=poll) |

**Denormalization:**
- Cloud Function `onHubMessageCreated` updates hub's `lastChatMessageAt` and sends notifications

---

### PrivateMessage Model
**Firestore Path:** `/private_messages/{conversationId}/messages/{messageId}`
**File:** `lib/models/private_message.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `messageId` | String | ✅ | - | Unique message identifier |
| `conversationId` | String | ✅ | - | Conversation ID (sorted UIDs) |
| `senderId` | String | ✅ | - | Sender UID |
| `recipientId` | String | ✅ | - | Recipient UID |
| `message` | String | ✅ | - | Message text |
| `timestamp` | DateTime | ✅ | - | Send timestamp |
| `read` | bool | ❌ | false | Read status |
| `readAt` | DateTime? | ❌ | null | When read |

**Conversation ID Format:** `{smallerUID}_{largerUID}` (ensures consistent ordering)

---

### Notification Model
**Firestore Path:** `/notifications/{userId}/items/{notificationId}`
**File:** `lib/models/notification.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `notificationId` | String | ✅ | - | Unique notification identifier |
| `userId` | String | ✅ | - | Recipient UID |
| `type` | String | ✅ | - | See types below |
| `title` | String | ✅ | - | Notification title |
| `body` | String | ✅ | - | Notification body |
| `data` | Map? | ❌ | null | Additional data |
| `read` | bool | ❌ | false | Read status |
| `createdAt` | DateTime | ✅ | - | Creation timestamp |
| `entityId` | String? | ❌ | null | Related entity ID |
| `hubId` | String? | ❌ | null | Hub ID (if hub-related) |

**Notification Types:**
- `game_reminder` - 2-hour game reminder
- `message` - New private message
- `like` - Post/comment liked
- `comment` - New comment on post
- `signup` - Game signup approved/rejected
- `new_follower` - New follower
- `hub_chat` - New hub chat message
- `new_comment` - New comment (duplicate of `comment`)
- `new_game` - New game created in hub

**Indexes Required:**
- `userId` (ascending) + `read` (ascending) + `createdAt` (descending) - for unread notifications

---

### Poll Model
**Firestore Path:** `/hubs/{hubId}/polls/{pollId}`
**File:** `lib/models/poll.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `pollId` | String | ✅ | - | Unique poll identifier |
| `hubId` | String | ✅ | - | Hub ID |
| `createdBy` | String | ✅ | - | Creator UID |
| `question` | String | ✅ | - | Poll question (Hebrew) |
| `options` | List\<PollOption\> | ✅ | - | Poll options |
| `type` | PollType | ✅ | - | singleChoice, multipleChoice, rating |
| `status` | PollStatus | ✅ | - | active, closed, archived |
| `createdAt` | DateTime | ✅ | - | Creation timestamp |
| `endsAt` | DateTime? | ❌ | null | End date (null = no deadline) |
| `closedAt` | DateTime? | ❌ | null | When closed |
| `totalVotes` | int | ❌ | 0 | Total votes |
| `voters` | List\<String\> | ❌ | [] | User IDs who voted |
| `allowMultipleVotes` | bool | ❌ | false | Allow voting multiple times |
| `showResultsBeforeVote` | bool | ❌ | false | Show results before voting |
| `isAnonymous` | bool | ❌ | false | Anonymous voting |
| `description` | String? | ❌ | null | Additional description |

**PollOption Nested Model:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `optionId` | String | ✅ | - | Option identifier |
| `text` | String | ✅ | - | Option text |
| `voteCount` | int | ❌ | 0 | Vote count |
| `voters` | List\<String\> | ❌ | [] | User IDs (if not anonymous) |
| `imageUrl` | String? | ❌ | null | Option image |

**PollVote Subcollection:**
**Path:** `/hubs/{hubId}/polls/{pollId}/votes/{voteId}`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `voteId` | String | ✅ | - | Vote identifier |
| `pollId` | String | ✅ | - | Poll ID |
| `userId` | String | ✅ | - | Voter UID |
| `selectedOptionIds` | List\<String\> | ✅ | - | Selected options |
| `votedAt` | DateTime | ✅ | - | Vote timestamp |
| `rating` | int? | ❌ | null | Rating (1-5) for rating polls |

---

## 7.3 Game Session Models

### Team Model
**File:** `lib/models/team.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `teamName` | String | ✅ | - | Team name (e.g., "Blue", "Red") |
| `players` | List\<String\> | ✅ | - | Player UIDs |
| `color` | String? | ❌ | null | Team color hex |

**Usage:**
- Embedded in `Game.teams` and `HubEvent.teams`
- Created by TeamMaker algorithm

---

### MatchResult Model
**File:** `lib/models/match_result.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `matchNumber` | int | ✅ | - | Match sequence number |
| `winnerTeam` | String | ✅ | - | Winning team name |
| `loserTeam` | String? | ❌ | null | Losing team name (null if draw) |
| `isDraw` | bool | ❌ | false | Is draw |
| `score` | String? | ❌ | null | Score (e.g., "5-3") |
| `timestamp` | DateTime | ✅ | - | Match completion timestamp |

**Usage:**
- Embedded in `Game.matches` and `HubEvent.matches`
- Supports multi-match sessions (Winner Stays format)

---

### GameAuditEvent Model
**File:** `lib/models/game_audit_event.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `action` | String | ✅ | - | 'approve', 'reject', 'kick', 'reschedule' |
| `performedBy` | String | ✅ | - | Admin UID |
| `targetUserId` | String? | ❌ | null | Affected user |
| `reason` | String? | ❌ | null | Action reason |
| `timestamp` | DateTime | ✅ | - | Action timestamp |

**Usage:**
- Embedded in `Game.auditLog`
- Tracks admin actions for compliance

---

## 7.4 Supporting Models

### TargetingCriteria Model
**File:** `lib/models/targeting_criteria.dart`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `minAge` | int? | ❌ | null | Minimum age |
| `maxAge` | int? | ❌ | null | Maximum age |
| `preferredPosition` | List\<String\>? | ❌ | null | Positions |
| `minSkillLevel` | int? | ❌ | null | Min skill (1-7) |
| `maxSkillLevel` | int? | ❌ | null | Max skill (1-7) |
| `region` | String? | ❌ | null | Region filter |

**Usage:**
- Embedded in `Game.targetingCriteria` for public recruiting games

---

### AgeGroup Enum
**File:** `lib/models/age_group.dart`

```dart
enum AgeGroup {
  teens,      // 13-17
  young,      // 18-24
  adults,     // 25-34
  mature,     // 35-44
  veteran,    // 45-54
  legend      // 55+
}
```

---

## 7.5 Data Model Relationships

```
User (1) ←→ (N) HubMember ←→ (1) Hub
  │                              │
  │                              ├─→ (N) HubEvent
  │                              │      │
  │                              │      └─→ (1) Game (converted)
  │                              │
  │                              ├─→ (N) FeedPost
  │                              │      └─→ (N) Comment
  │                              │
  │                              ├─→ (N) ChatMessage
  │                              │
  │                              └─→ (N) Poll
  │                                     └─→ (N) PollVote
  │
  ├─→ (N) Game (creator)
  │      ├─→ (N) GameSignup
  │      └─→ (N) ChatMessage
  │
  ├─→ (N) Notification
  │
  └─→ (N) PrivateMessage

Hub ←→ (N) Venue (many-to-many via venueIds)
```

---

## 7.6 Validation Summary

**Client-Side Validation:**
- Age 13+ enforcement on birthDate
- Email format validation
- Phone number format (Israeli)
- Required fields (name, email, birthDate, etc.)
- Image size limits (max 5MB before compression)
- Text length limits (name: 50 chars, description: 500 chars)

**Server-Side Validation (Firestore Rules):**
- Only hub creator can delete hub
- Only managers can assign roles
- Cannot set `veteranSince` from client
- Cannot modify denormalized fields (memberCount, gameCount, etc.)
- Cannot change other users' data
- Signup status transitions enforced

**Cloud Function Validation:**
- Veteran promotion only after 60 days
- Denormalized counters kept in sync
- Audit trails for admin actions

---

# 8. MEMBERSHIP & PERMISSIONS SYSTEM

This section documents Kattrick's comprehensive 4-tier role hierarchy and permission enforcement.

## 8.1 Role Hierarchy

**Firestore Path:** `/hubs/{hubId}/members/{userId}`

```
┌─────────────┐
│   Manager   │ (Full Control)
├─────────────┤
│  Moderator  │ (Content & Players)
├─────────────┤
│   Veteran   │ (Trusted Member, 60+ days)
├─────────────┤
│   Member    │ (Regular Member)
└─────────────┘
     Guest (No Membership)
```

### Role Definitions

**Manager:**
- **Who:** Hub creator (always manager) OR promoted by existing manager
- **Limit:** Only ONE manager per hub
- **Icon:** 👑 (crown emoji)
- **Hebrew:** מנהל

**Moderator:**
- **Who:** Promoted by manager
- **Limit:** No limit
- **Icon:** ⭐ (star emoji)
- **Hebrew:** מנחה

**Veteran:**
- **Who:** Automatically promoted after 60 days (server-managed)
- **Promotion:** Cloud Function runs daily at 2 AM UTC
- **Icon:** 🏆 (trophy emoji)
- **Hebrew:** שחקן ותיק

**Member:**
- **Who:** Default role on joining hub
- **Icon:** ⚽ (football emoji)
- **Hebrew:** חבר

**Guest:**
- **Who:** Not a member (no HubMember document OR status ≠ active)
- **Permissions:** None (view only)
- **Hebrew:** אורח

---

## 8.2 Permission Matrix

**File:** `lib/services/hub_permissions_service.dart`

| Capability | Manager | Moderator | Veteran | Member | Guest |
|------------|---------|-----------|---------|--------|-------|
| **Game/Event Permissions** |||||
| Create games | ✅ | ✅ | ✅ | ✅ | ❌ |
| Create events | ✅ | ✅ | ❌ | ❌ | ❌ |
| Record results | ✅ | ✅ | ✅ | ❌ | ❌ |
| Invite players | ✅ | ✅ | ✅ | ❌ | ❌ |
| View analytics | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Communication** |||||
| Send chat messages | ✅ | ✅ | ✅ | ✅ | ❌ |
| Moderate chat | ✅ | ✅ | ❌ | ❌ | ❌ |
| Create posts | ✅ | ✅ | ✅ | ✅ | ❌ |
| Delete posts | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Member Management** |||||
| Manage members | ✅ | ✅ | ❌ | ❌ | ❌ |
| Manage roles | ✅ | ❌ | ❌ | ❌ | ❌ |
| Ban members | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Hub Management** |||||
| Edit hub info | ✅ | ❌ | ❌ | ❌ | ❌ |
| Manage settings | ✅ | ❌ | ❌ | ❌ | ❌ |
| Delete hub | ✅ | ❌ | ❌ | ❌ | ❌ |
| Manage venues | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## 8.3 Veteran Promotion System

**Automated Promotion Logic:**

**Cloud Function:** `functions/src/scheduled/promoteVeterans.js`
**Schedule:** Daily at 2 AM UTC (via Pub/Sub cron)
**Threshold:** 60 days since `joinedAt`

```javascript
exports.promoteVeterans = functions.pubsub
  .schedule('0 2 * * *')
  .onRun(async (context) => {
    const VETERAN_THRESHOLD_DAYS = 60;
    const thresholdDate = new Date();
    thresholdDate.setDate(thresholdDate.getDate() - VETERAN_THRESHOLD_DAYS);

    // Query all eligible members
    const eligibleSnapshot = await admin.firestore()
      .collectionGroup('members')
      .where('status', '==', 'active')
      .where('role', '==', 'member')
      .where('joinedAt', '<=', admin.firestore.Timestamp.fromDate(thresholdDate))
      .where('veteranSince', '==', null)
      .get();

    // Batch update
    const batch = admin.firestore().batch();
    eligibleSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, {
        role: 'veteran',
        veteranSince: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: 'system:promoteVeterans',
      });
    });

    await batch.commit();
    console.log(`Promoted ${eligibleSnapshot.size} members to veteran`);
  });
```

**Key Points:**
- ✅ **SERVER-MANAGED ONLY** - Clients cannot set `veteranSince`
- ✅ Runs automatically every day
- ✅ Updates `role`, `veteranSince`, `updatedAt`, `updatedBy`
- ✅ Uses `collectionGroup('members')` query across all hubs
- ✅ Audit trail: `updatedBy = 'system:promoteVeterans'`

**Firestore Rule (Enforces Server-Only):**
```javascript
match /hubs/{hubId}/members/{userId} {
  allow update: if
    // User can update their own membership (leave)
    (request.auth.uid == userId &&
     request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'updatedAt']) &&
     request.resource.data.status == 'left')
    ||
    // Manager can update roles (but NOT veteranSince)
    (isHubManager(hubId, request.auth.uid) &&
     !request.resource.data.diff(resource.data).affectedKeys().hasAny(['veteranSince']));
}
```

---

## 8.4 Permission Enforcement

### Client-Side Enforcement

**Service:** `HubPermissionsService` (`lib/services/hub_permissions_service.dart`)

**Usage Example:**
```dart
final permissions = HubPermissions(
  hub: hub,
  membership: membership,
  userId: currentUserId,
);

// Check permissions
if (permissions.canCreateEvents) {
  // Show "Create Event" button
}

if (permissions.canManageRoles) {
  // Show role management UI
}

// Get effective role
final role = permissions.effectiveRole; // HubMemberRole.manager, etc.

// Check role hierarchy
if (permissions.isManager) {
  // Manager-only actions
}
```

**HubPermissions Class:**
```dart
class HubPermissions {
  final Hub hub;
  final HubMember? membership;
  final String userId;

  HubMemberRole get effectiveRole {
    // Creator is ALWAYS manager
    if (userId == hub.createdBy) return HubMemberRole.manager;

    // Check membership
    if (membership == null || membership!.status != HubMemberStatus.active) {
      return HubMemberRole.member; // Guest (blocked by isActive check)
    }

    return membership!.role;
  }

  bool get isActive {
    if (userId == hub.createdBy) return true;
    return membership?.isActive ?? false;
  }

  // Permission getters
  bool get canCreateGames => isActive && effectiveRole.canCreateGames;
  bool get canCreateEvents => isActive &&
    (effectiveRole.canCreateEvents || _hasCustomPermission('canCreateEvents'));
  bool get canRecordResults => isActive && effectiveRole.canRecordResults;
  // ... etc
}
```

### Server-Side Enforcement

**Firestore Security Rules:** `firestore.rules`

**Key Rules:**

```javascript
// Helper functions
function isHubMember(hubId, userId) {
  return exists(/databases/$(database)/documents/hubs/$(hubId)/members/$(userId)) &&
         get(/databases/$(database)/documents/hubs/$(hubId)/members/$(userId)).data.status == 'active';
}

function isHubManager(hubId, userId) {
  let hub = get(/databases/$(database)/documents/hubs/$(hubId));
  return hub.data.createdBy == userId || (
    exists(/databases/$(database)/documents/hubs/$(hubId)/members/$(userId)) &&
    get(/databases/$(database)/documents/hubs/$(hubId)/members/$(userId)).data.role == 'manager' &&
    get(/databases/$(database)/documents/hubs/$(hubId)/members/$(userId)).data.status == 'active'
  );
}

function isHubModerator(hubId, userId) {
  return isHubManager(hubId, userId) || (
    exists(/databases/$(database)/documents/hubs/$(hubId)/members/$(userId)) &&
    get(/databases/$(database)/documents/hubs/$(hubId)/members/$(userId)).data.role == 'moderator' &&
    get(/databases/$(database)/documents/hubs/$(hubId)/members/$(userId)).data.status == 'active'
  );
}

function isHubVeteran(hubId, userId) {
  return isHubModerator(hubId, userId) || (
    exists(/databases/$(database)/documents/hubs/$(hubId)/members/$(userId)) &&
    get(/databases/$(database)/documents/hubs/$(hubId)/members/$(userId)).data.role == 'veteran' &&
    get(/databases/$(database)/documents/hubs/$(hubId)/members/$(userId)).data.status == 'active'
  );
}

// Hub document rules
match /hubs/{hubId} {
  allow read: if true; // Public read
  allow create: if request.auth != null;
  allow update: if isHubManager(hubId, request.auth.uid);
  allow delete: if isHubManager(hubId, request.auth.uid);

  // Hub members subcollection
  match /members/{userId} {
    allow read: if isHubMember(hubId, request.auth.uid);
    allow create: if request.auth.uid == userId; // User can join
    allow update: if
      // User can leave
      (request.auth.uid == userId &&
       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'updatedAt']) &&
       request.resource.data.status == 'left')
      ||
      // Manager can update roles (but NOT veteranSince)
      (isHubManager(hubId, request.auth.uid) &&
       !request.resource.data.diff(resource.data).affectedKeys().hasAny(['veteranSince']));
    allow delete: if isHubManager(hubId, request.auth.uid);
  }

  // Events subcollection
  match /events/{eventId} {
    allow read: if isHubMember(hubId, request.auth.uid);
    allow create: if isHubModerator(hubId, request.auth.uid);
    allow update: if isHubModerator(hubId, request.auth.uid);
    allow delete: if isHubManager(hubId, request.auth.uid);
  }

  // Feed posts subcollection
  match /feed/posts/items/{postId} {
    allow read: if isHubMember(hubId, request.auth.uid);
    allow create: if isHubMember(hubId, request.auth.uid);
    allow update: if
      // Author can edit
      (request.auth.uid == resource.data.authorId) ||
      // Moderator can delete
      (isHubModerator(hubId, request.auth.uid));
    allow delete: if isHubModerator(hubId, request.auth.uid);
  }

  // Hub chat
  match /chat/{messageId} {
    allow read: if isHubMember(hubId, request.auth.uid);
    allow create: if isHubMember(hubId, request.auth.uid);
    allow update, delete: if isHubModerator(hubId, request.auth.uid);
  }
}

// Games collection
match /games/{gameId} {
  allow read: if true; // Public games visible to all
  allow create: if request.auth != null;
  allow update: if
    // Creator can update
    (request.auth.uid == resource.data.createdBy) ||
    // Hub moderator can update hub games
    (resource.data.hubId != null && isHubModerator(resource.data.hubId, request.auth.uid));
  allow delete: if
    (request.auth.uid == resource.data.createdBy) ||
    (resource.data.hubId != null && isHubManager(resource.data.hubId, request.auth.uid));

  // Game signups
  match /signups/{userId} {
    allow read: if true;
    allow create: if request.auth.uid == userId; // User can sign up
    allow update: if
      // User can cancel
      (request.auth.uid == userId && request.resource.data.status == 'cancelled') ||
      // Creator/moderator can approve/reject
      (get(/databases/$(database)/documents/games/$(gameId)).data.createdBy == request.auth.uid) ||
      (get(/databases/$(database)/documents/games/$(gameId)).data.hubId != null &&
       isHubModerator(get(/databases/$(database)/documents/games/$(gameId)).data.hubId, request.auth.uid));
    allow delete: if
      (request.auth.uid == userId) ||
      (get(/databases/$(database)/documents/games/$(gameId)).data.createdBy == request.auth.uid);
  }
}
```

---

## 8.5 Custom Permissions (Rare Overrides)

**Use Case:** Allow specific user to create events even if not moderator

**Hub Model Field:** `permissions` (Map<String, dynamic>)

**Example:**
```dart
// In Hub document
{
  "permissions": {
    "canCreateEvents": ["userId1", "userId2"]
  }
}
```

**Permission Check:**
```dart
bool get canCreateEvents =>
  isActive &&
  (effectiveRole.canCreateEvents || _hasCustomPermission('canCreateEvents'));

bool _hasCustomPermission(String permission) {
  final customPerms = hub.permissions[permission] as List?;
  return customPerms?.contains(userId) ?? false;
}
```

**UI:**
- Manager can add/remove custom permissions in Hub Settings
- Shown in "Advanced Permissions" section

---

## 8.6 Membership Lifecycle

### Join Hub Flow

```
1. User clicks "Join Hub" → HubsRepository.joinHub(hubId)
2. Check if hub.isPrivate:
   - If false: Create HubMember with status=active, role=member
   - If true: Create HubMember with status=pending (requires approval)
3. Cloud Function onMembershipChange:
   - Increment hub.memberCount (if status=active)
   - Update user.hubIds array
4. User sees hub in "My Hubs" tab
```

### Leave Hub Flow

```
1. User clicks "Leave Hub" → HubsRepository.leaveHub(hubId)
2. Update HubMember:
   - status = 'left'
   - updatedAt = now()
   - updatedBy = userId
3. Cloud Function onMembershipChange:
   - Decrement hub.memberCount
   - Remove hubId from user.hubIds
4. Hub removed from "My Hubs" tab
```

### Ban Member Flow

```
1. Manager/Moderator clicks "Ban User" → HubsRepository.banMember(hubId, userId, reason)
2. Update HubMember:
   - status = 'banned'
   - statusReason = reason
   - updatedAt = now()
   - updatedBy = managerUserId
3. Cloud Function onMembershipChange:
   - Decrement hub.memberCount
   - Remove hubId from user.hubIds
4. User cannot rejoin without manager approval
```

### Promote to Moderator Flow

```
1. Manager clicks "Promote to Moderator" → HubsRepository.updateMemberRole(hubId, userId, HubMemberRole.moderator)
2. Update HubMember:
   - role = 'moderator'
   - updatedAt = now()
   - updatedBy = managerUserId
3. No Cloud Function trigger (no denormalized fields affected)
4. User sees new permissions immediately
```

---

## 8.7 Permission Debugging

**Debug UI:** Auth Status Screen (`lib/screens/debug/auth_status_screen.dart`)

**Displays:**
- Current User UID
- Hub Membership Status (for selected hub)
- Effective Role
- Is Veteran? (Yes/No + Days since joined)
- All Permission Flags (canCreateGames, canRecordResults, etc.)

**HubPermissions Debug Info:**
```dart
Map<String, dynamic> toDebugInfo() {
  return {
    'userId': userId,
    'hubId': hub.hubId,
    'effectiveRole': effectiveRole.name,
    'isActive': isActive,
    'isCreator': userId == hub.createdBy,
    'membershipStatus': membership?.status.name,
    'isVeteran': isVeteran,
    'veteranSince': membership?.veteranSince?.toIso8601String(),
  };
}
```

---

# (CONTINUED - Section 9: Game & Event Logic...)



## 9. GAME & EVENT LOGIC

This section documents the complete lifecycle of games and events in Kattrick.

### 9.1 Event vs Game Distinction

**Key Concept:** Events are "Plans", Games are "Records"

| Aspect | HubEvent | Game |
|--------|----------|------|
| **Purpose** | Planning future session | Recording actual session |
| **Created By** | Manager/Moderator only | Any member |
| **Firestore Path** | `/hubs/{hubId}/events/{eventId}` | `/games/{gameId}` |
| **RSVP** | `registeredPlayerIds` (simple array) | `/games/{gameId}/signups/{userId}` (subcollection) |
| **Status Flow** | upcoming → ongoing → completed | teamSelection → ready → inProgress → completed |
| **Can Be Converted?** | ✅ Yes (Event → Game via "Open Game") | ❌ No (one-way only) |

**Workflow:**
```
1. Manager creates HubEvent (Plan)
2. Members register via "I'm In" button
3. Manager reviews attendance
4. Manager clicks "Open Game" (converts Event → Game)
5. Game created with auto-confirmed signups
6. TeamMaker builds teams
7. Manager records match results
8. Game marked as completed
```

---

### 9.2 Game Creation Flow

**Entry Points:**
1. **From Hub:** Hub Detail Screen → "Create Game" button
2. **From Event:** Event Detail Screen → "Open Game" button (manager/moderator only)
3. **Standalone:** Home Screen → "Create Pickup Game" (public game)

**Create Game Screen** (`lib/screens/game/create_game_screen.dart`)

**Required Fields:**
- Game Date/Time (DateTimePicker)
- Venue (select from hub's venues OR custom location)
- Team Count (2, 3, or 4 teams)
- Max Players (optional capacity limit)

**Optional Fields:**
- Description
- Duration (minutes)
- Game Type (3v3, 4v4, 5v5, etc.)
- Visibility (private, public, recruiting)
- Targeting Criteria (if public/recruiting)
- Enable Attendance Reminder (default: true)

**Validation:**
- gameDate must be in the future
- venue required (or custom location)
- maxPlayers must be >= minPlayersToPlay (10)

**Firestore Write:**
```dart
await _firestore.collection('games').doc(gameId).set({
  'gameId': gameId,
  'createdBy': currentUserId,
  'hubId': hubId,
  'gameDate': gameDate,
  'venueId': venueId,
  'teamCount': teamCount,
  'status': 'teamSelection',
  'visibility': visibility,
  'maxPlayers': maxPlayers,
  'enableAttendanceReminder': enableAttendanceReminder,
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**Cloud Function Trigger:** `onGameCreated`
- Denormalizes creator name/photo
- Denormalizes hub name
- Increments `hub.gameCount`
- Updates `hub.lastActivity`
- Creates feed post in hub
- Creates regional feed post (if recruiting)

---

### 9.3 Game Signup (RSVP) Flow

**Subcollection:** `/games/{gameId}/signups/{userId}`

**Signup Screen:** Game Detail Screen → "Join Game" button

**Signup Statuses:**
```dart
enum SignupStatus {
  pending,    // Awaiting approval (if requiresApproval=true)
  confirmed,  // Approved
  rejected,   // Rejected by organizer
  cancelled   // Cancelled by player
}
```

**Flow for requiresApproval=false (default):**
```
1. Player clicks "Join Game"
2. Create GameSignup with status='confirmed'
3. Cloud Function onGameSignupChanged:
   - Increment game.confirmedPlayerCount
   - Add userId to game.confirmedPlayerIds
   - Check if game.confirmedPlayerCount >= game.maxPlayers
     - If yes: Set game.isFull = true
4. Player sees "You're In!" confirmation
5. Notification sent to game creator
```

**Flow for requiresApproval=true (public games):**
```
1. Player clicks "Request to Join"
2. Create GameSignup with status='pending'
3. Notification sent to game creator
4. Creator reviews in "Manage Players" screen
5. Creator clicks "Approve" or "Reject"
6. Update GameSignup status
7. Cloud Function onGameSignupChanged updates denormalized fields
8. Notification sent to player
```

**Cancel Signup:**
```
1. Player clicks "Leave Game"
2. Update GameSignup status='cancelled'
3. Cloud Function decrements game.confirmedPlayerCount
4. Set game.isFull = false (if was full)
```

**Kick Player (Manager/Moderator):**
```
1. Manager clicks "Kick Player"
2. Show dialog: "Reason for kicking?" (required)
3. Update GameSignup:
   - status = 'rejected'
   - adminActionReason = reason
4. Add audit event to game.auditLog
5. Cloud Function updates denormalized fields
6. Notification sent to kicked player
```

---

### 9.4 TeamMaker Algorithm

**Screen:** Team Maker Screen (`lib/screens/game/team_maker_screen.dart`)

**Input:**
- List of confirmed players (from game.confirmedPlayerIds)
- Number of teams (game.teamCount)
- Player ratings (from HubMember.managerRating for hub games)

**Algorithm:** Snake Draft with Position Awareness

```dart
// Simplified pseudocode
List<Team> buildTeams(List<Player> players, int teamCount) {
  // 1. Sort players by rating (descending)
  players.sort((a, b) => b.rating.compareTo(a.rating));
  
  // 2. Separate goalkeepers
  final goalkeepers = players.where((p) => p.position == 'Goalkeeper').toList();
  final fieldPlayers = players.where((p) => p.position != 'Goalkeeper').toList();
  
  // 3. Distribute goalkeepers evenly
  final teams = List.generate(teamCount, (i) => Team(teamName: teamNames[i], players: []));
  for (int i = 0; i < goalkeepers.length; i++) {
    teams[i % teamCount].players.add(goalkeepers[i].uid);
  }
  
  // 4. Snake draft for field players
  int currentTeam = 0;
  bool reverse = false;
  
  for (final player in fieldPlayers) {
    teams[currentTeam].players.add(player.uid);
    
    if (reverse) {
      currentTeam--;
      if (currentTeam < 0) {
        currentTeam = 0;
        reverse = false;
      }
    } else {
      currentTeam++;
      if (currentTeam >= teamCount) {
        currentTeam = teamCount - 1;
        reverse = true;
      }
    }
  }
  
  // 5. Return balanced teams
  return teams;
}
```

**Team Balance Metrics:**
```dart
class TeamBalanceMetrics {
  final double avgRatingVariance; // Lower = more balanced
  final double positionDistribution; // How evenly positions distributed
  final int playerCountDiff; // Difference between largest and smallest team
  
  bool get isBalanced => avgRatingVariance < 0.5 && playerCountDiff <= 1;
}
```

**UI:**
- Automatic team builder (one tap)
- Manual drag-and-drop adjustment
- Swap players between teams
- "Shuffle" button (re-randomize)
- Balance score indicator (0-100%)

**Save Teams:**
```dart
await _firestore.collection('games').doc(gameId).update({
  'teams': teams.map((t) => t.toJson()).toList(),
  'status': 'ready', // Teams are set, ready to start
  'updatedAt': FieldValue.serverTimestamp(),
});
```

---

### 9.5 Multi-Match Session Recording

**Screen:** Game Session Screen (`lib/screens/event/game_session_screen.dart`)

**Supports:** Winner Stays format (3+ teams)

**Flow:**
```
1. Manager clicks "Start Session"
2. Show team selection (auto-filled from TeamMaker)
3. Select two teams for first match
4. Play match → Record winner (or draw)
5. Winner stays, loser rotates out, new team enters
6. Repeat until session ends
7. View aggregate wins summary
```

**Match Result Model:**
```dart
class MatchResult {
  final int matchNumber;         // 1, 2, 3, ...
  final String winnerTeam;       // "Blue"
  final String? loserTeam;       // "Red" (null if draw)
  final bool isDraw;             // false
  final String? score;           // "5-3" (optional)
  final DateTime timestamp;      // When match completed
}
```

**Recording a Match:**
```dart
// User clicks "Blue Wins 5-3"
final newMatch = MatchResult(
  matchNumber: session.matches.length + 1,
  winnerTeam: 'Blue',
  loserTeam: 'Red',
  isDraw: false,
  score: '5-3',
  timestamp: DateTime.now(),
);

await _firestore.collection('games').doc(gameId).update({
  'matches': FieldValue.arrayUnion([newMatch.toJson()]),
  'aggregateWins.Blue': FieldValue.increment(1),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**Aggregate Wins Display:**
```
┌─────────────────────────────┐
│  SESSION RESULTS            │
├─────────────────────────────┤
│  🥇 Blue Team: 6 wins       │
│  🥈 Red Team: 4 wins        │
│  🥉 Green Team: 2 wins      │
└─────────────────────────────┘
```

**Complete Session:**
```dart
await _firestore.collection('games').doc(gameId).update({
  'status': 'completed',
  'updatedAt': FieldValue.serverTimestamp(),
});
```

**Cloud Function Trigger:** `onGameCompleted`
- Updates player stats (wins, losses, gamesPlayed)
- Updates goals/assists (if goalScorerIds provided)
- Creates community feed post (if showInCommunityFeed=true)

---

### 9.6 Game Status State Machine

```
┌──────────────┐
│teamSelection │ (Initial state - building teams)
└──────┬───────┘
       │ Teams assigned
       ▼
┌──────────────┐
│    ready     │ (Teams ready, can start)
└──────┬───────┘
       │ Manager starts game
       ▼
┌──────────────┐
│ inProgress   │ (Game in progress)
└──────┬───────┘
       │ Manager records results
       ▼
┌──────────────┐
│  completed   │ (Final state - results recorded)
└──────────────┘

       OR
       │ Cancel game
       ▼
┌──────────────┐
│  cancelled   │
└──────────────┘
```

**State Transitions:**

| From | To | Trigger | Who |
|------|----|---------| ----|
| teamSelection | ready | Teams assigned | Manager/Creator |
| ready | inProgress | "Start Game" clicked | Manager/Creator |
| inProgress | completed | Results recorded | Manager/Creator |
| * | cancelled | "Cancel Game" clicked | Manager/Creator |

**UI Changes by Status:**

| Status | Game Detail Screen |
|--------|--------------------|
| teamSelection | Show "Build Teams" button (manager) |
| ready | Show "Start Game" button (manager) |
| inProgress | Show "Record Results" button (manager) |
| completed | Show final score, stats, MVP |
| cancelled | Show "Cancelled" badge, reason |

---

### 9.7 Recurring Games

**Create Recurring Game:**
```dart
final recurring = Game(
  // ... other fields
  isRecurring: true,
  recurrencePattern: 'weekly', // 'weekly', 'biweekly', 'monthly'
  recurrenceEndDate: DateTime(2026, 12, 31),
);
```

**Cloud Function:** `createRecurringGameInstances` (runs daily at 3 AM)
```javascript
// Pseudocode
for each game where isRecurring=true:
  if nextInstanceDate < recurrenceEndDate:
    create new Game with:
      - parentGameId = recurring.gameId
      - gameDate = nextInstanceDate
      - copy all settings from parent
```

**UI:**
- Parent game shows "Recurring" badge
- Child games show "Part of recurring series" + link to parent
- Manager can edit parent (applies to future instances)
- Manager can edit individual instance (override)

---

### 9.8 Game Reminders

**Cloud Function:** `sendGameReminder` (runs every 30 minutes)

**Logic:**
```javascript
// Find games starting in 1-2 hours that haven't sent reminder
const games = await firestore.collection('games')
  .where('gameDate', '>=', oneHourFromNow)
  .where('gameDate', '<=', twoHoursFromNow)
  .where('enableAttendanceReminder', '==', true)
  .where('reminderSent2Hours', '!=', true)
  .get();

for (const game of games.docs) {
  // Fetch confirmed players
  const signups = await firestore
    .collection(`games/${game.id}/signups`)
    .where('status', '==', 'confirmed')
    .get();
  
  const playerIds = signups.docs.map(doc => doc.id);
  
  // Fetch FCM tokens
  const tokens = await fetchFCMTokens(playerIds);
  
  // Send push notification
  await admin.messaging().sendEachForMulticast({
    tokens: tokens,
    notification: {
      title: '⚽ משחק מתחיל בקרוב',
      body: `${game.data().title || 'משחק'} מתחיל בעוד שעתיים`,
    },
    data: {
      type: 'game_reminder',
      gameId: game.id,
    },
  });
  
  // Mark reminder sent
  await game.ref.update({
    reminderSent2Hours: true,
    reminderSent2HoursAt: FieldValue.serverTimestamp(),
  });
  
  // Create in-app notifications
  for (const playerId of playerIds) {
    await firestore.collection(`notifications/${playerId}/items`).add({
      type: 'game_reminder',
      title: '⚽ משחק מתחיל בקרוב',
      body: `${game.data().title} מתחיל בעוד שעתיים`,
      entityId: game.id,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
}
```

**User Settings:**
- User can disable game reminders in Notification Preferences
- Checked before sending: `user.notificationPreferences.game_reminder == true`

---

### 9.9 Public/Recruiting Games

**Visibility Types:**
```dart
enum GameVisibility {
  private,    // Hub members only (default)
  public,     // Open to all users
  recruiting  // Actively recruiting (shown in regional feed)
}
```

**Recruiting Game Flow:**
```
1. Manager creates game with visibility='recruiting'
2. Sets targetingCriteria (optional filters)
3. Cloud Function onGameCreated:
   - Creates FeedPost in regional feed (/feedPosts)
   - Sets isUrgent flag (if needed soon)
   - Adds neededPlayers count
4. Users browse regional feed → see recruiting post
5. User clicks "Join" → creates GameSignup with status='pending'
6. Manager reviews and approves signups
```

**Targeting Criteria:**
```dart
class TargetingCriteria {
  final int? minAge;           // 18
  final int? maxAge;           // 35
  final List<String>? positions; // ['Midfielder', 'Attacker']
  final int? minSkillLevel;   // 3
  final int? maxSkillLevel;   // 6
  final String? region;        // 'מרכז'
}
```

**Regional Feed Query:**
```dart
// Firestore query
final recruitingPosts = await _firestore
  .collection('feedPosts')
  .where('type', '==', 'game_recruiting')
  .where('region', '==', userRegion)
  .orderBy('isUrgent', descending: true)
  .orderBy('createdAt', descending: true)
  .limit(20)
  .get();
```

---

## 10. SOCIAL & RECRUITING FLOW

### 10.1 Hub Feed Architecture

**Two Feed Types:**

1. **Hub Feed:** `/hubs/{hubId}/feed/posts/items/{postId}` (hub members only)
2. **Regional Feed:** `/feedPosts/{postId}` (public, filtered by region)

**Feed Post Types:**
- `post` - Regular text/photo post
- `game_created` - Auto-generated when game created
- `game` - Shared game results
- `achievement` - Player achievement (e.g., 100 games milestone)
- `rating` - Player rating change
- `hub_recruiting` - Hub recruiting new members

**Hub Feed Screen:** Tab in Hub Detail Screen

**Feed Query:**
```dart
final hubFeed = _firestore
  .collection('hubs/$hubId/feed/posts/items')
  .orderBy('createdAt', descending: true)
  .limit(20)
  .snapshots();
```

**Feed Post Card:**
```
┌─────────────────────────────────────┐
│ 👤 [User Photo] Yossi Cohen         │
│    Hub: Tel Aviv Football · 2h ago  │
├─────────────────────────────────────┤
│ Great game today! Thanks everyone   │
│ who showed up. 🔥                    │
│                                     │
│ [Photo 1] [Photo 2]                 │
├─────────────────────────────────────┤
│ ❤️ 12 likes · 💬 5 comments          │
│                                     │
│ [Like] [Comment] [Share]            │
└─────────────────────────────────────┘
```

---

### 10.2 Create Post Flow

**Entry Point:** Hub Feed → "+" button

**Create Post Screen:**
```
┌─────────────────────────────────────┐
│ Create Post                     [✓] │
├─────────────────────────────────────┤
│ What's on your mind?                │
│ ┌─────────────────────────────────┐ │
│ │ [Text input area]               │ │
│ │                                 │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [📷 Add Photos] [📍 Add Location]  │
│                                     │
│ Photo previews:                     │
│ [Image 1 ❌] [Image 2 ❌]            │
└─────────────────────────────────────┘
```

**Validation:**
- Max 4 photos per post (configurable via Remote Config)
- Max 500 characters text
- Photos compressed to max 1920px width before upload

**Firestore Write:**
```dart
final postId = _firestore.collection('hubs/$hubId/feed/posts/items').doc().id;

// Upload photos to Storage first
final photoUrls = await _uploadPhotos(photos, hubId, postId);

await _firestore.collection('hubs/$hubId/feed/posts/items').doc(postId).set({
  'postId': postId,
  'hubId': hubId,
  'authorId': currentUserId,
  'type': 'post',
  'content': content,
  'photoUrls': photoUrls,
  'likes': [],
  'likeCount': 0,
  'commentCount': 0,
  'createdAt': FieldValue.serverTimestamp(),
  // Denormalized fields (set by client, validated by rules)
  'authorName': currentUser.name,
  'authorPhotoUrl': currentUser.photoUrl,
  'hubName': hub.name,
  'hubLogoUrl': hub.logoUrl,
  'region': hub.region,
});
```

---

### 10.3 Comments System

**Subcollection:** `/hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}`

**Add Comment:**
```
User types comment → Clicks "Post"
```

```dart
await _firestore
  .collection('hubs/$hubId/feed/posts/items/$postId/comments')
  .add({
    'commentId': commentId,
    'postId': postId,
    'authorId': currentUserId,
    'text': commentText,
    'createdAt': FieldValue.serverTimestamp(),
    'authorName': currentUser.name,
    'authorPhotoUrl': currentUser.photoUrl,
  });
```

**Cloud Function:** `onCommentCreated`
```javascript
exports.onCommentCreated = functions.firestore
  .document('hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const postRef = snap.ref.parent.parent;
    
    // Increment comment count
    await postRef.update({
      commentCount: admin.firestore.FieldValue.increment(1),
    });
    
    // Send notification to post author
    const post = await postRef.get();
    const postAuthorId = post.data().authorId;
    const commentAuthor = snap.data().authorName;
    
    if (postAuthorId !== snap.data().authorId) { // Don't notify self
      await admin.firestore().collection(`notifications/${postAuthorId}/items`).add({
        type: 'comment',
        title: 'תגובה חדשה',
        body: `${commentAuthor} הגיב על הפוסט שלך`,
        entityId: context.params.postId,
        hubId: context.params.hubId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
```

**Comments UI:**
```
┌─────────────────────────────────────┐
│ Comments (5)                        │
├─────────────────────────────────────┤
│ 👤 David · 1h ago                   │
│    Great post!                      │
├─────────────────────────────────────┤
│ 👤 Sarah · 45m ago                  │
│    When is the next game?           │
├─────────────────────────────────────┤
│ [Add a comment...]                  │
└─────────────────────────────────────┘
```

---

### 10.4 Recruiting Posts

**Create Recruiting Post:**

Hub Detail Screen → "Need Players" button (manager/moderator only)

**Create Recruiting Post Screen:**
```
┌─────────────────────────────────────┐
│ Recruit Players               [Post]│
├─────────────────────────────────────┤
│ Link to Event (optional):           │
│ [Select Event ▼] None selected      │
│                                     │
│ How many players needed?            │
│ [5  ]                               │
│                                     │
│ Urgency:                            │
│ [✓] Mark as urgent                  │
│                                     │
│ Needed by (optional):               │
│ [📅 Tomorrow, 6:00 PM]              │
│                                     │
│ Message:                            │
│ ┌─────────────────────────────────┐ │
│ │ Need 5 players for tomorrow's  │ │
│ │ game! All skill levels welcome  │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Firestore Write:**
```dart
await _firestore.collection('feedPosts').add({
  'type': 'hub_recruiting',
  'hubId': hubId,
  'eventId': selectedEventId, // nullable
  'authorId': currentUserId,
  'content': message,
  'neededPlayers': neededPlayers,
  'isUrgent': isUrgent,
  'recruitingUntil': recruitingUntil,
  'region': hub.region,
  'createdAt': FieldValue.serverTimestamp(),
  // Denormalized
  'hubName': hub.name,
  'hubLogoUrl': hub.logoUrl,
  'authorName': currentUser.name,
});
```

**Regional Feed Display:**
```
┌─────────────────────────────────────┐
│ 🚨 URGENT                           │
│ Tel Aviv Football Hub               │
│ Need 5 players · Needed by 6:00 PM │
├─────────────────────────────────────┤
│ Need 5 players for tomorrow's game! │
│ All skill levels welcome            │
├─────────────────────────────────────┤
│ [Join Event] [Message Hub]          │
└─────────────────────────────────────┘
```

**User Actions:**
- Click "Join Event" → Navigate to event detail → Register
- Click "Message Hub" → Opens private message to hub manager

---

### 10.5 Likes System

**Like/Unlike Post:**
```dart
final postRef = _firestore.doc('hubs/$hubId/feed/posts/items/$postId');

if (isLiked) {
  // Unlike
  await postRef.update({
    'likes': FieldValue.arrayRemove([currentUserId]),
    'likeCount': FieldValue.increment(-1),
  });
} else {
  // Like
  await postRef.update({
    'likes': FieldValue.arrayUnion([currentUserId]),
    'likeCount': FieldValue.increment(1),
  });
  
  // Send notification to post author (Cloud Function or client)
  final post = await postRef.get();
  if (post.data()!['authorId'] != currentUserId) {
    await _firestore.collection('notifications/${post.data()!['authorId']}/items').add({
      'type': 'like',
      'title': 'לייק חדש',
      'body': '${currentUser.name} אהב את הפוסט שלך',
      'entityId': postId,
      'hubId': hubId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
```

**Likes Display:**
```
❤️ 12 likes
```

Click on likes → Show list of users who liked

---

## 11. CHAT SYSTEM

### 11.1 Chat Types

**Three Chat Contexts:**

1. **Hub Chat:** `/hubs/{hubId}/chat/{messageId}` (hub members only)
2. **Game Chat:** `/games/{gameId}/chat/{messageId}` (game participants)
3. **Private Messages:** `/private_messages/{conversationId}/messages/{messageId}` (1-on-1)

---

### 11.2 Hub Chat

**Entry Point:** Hub Detail Screen → "Chat" tab

**Chat Screen:**
```
┌─────────────────────────────────────┐
│ ← Hub Chat                          │
├─────────────────────────────────────┤
│                                     │
│ [Yesterday]                         │
│                                     │
│ 👤 Yossi · 10:30 AM                 │
│    Who's coming to tonight's game?  │
│                                     │
│                👤 David · 10:35 AM  │
│                   I'm in! 🔥        │
│                                     │
│ [Today]                             │
│                                     │
│ 👤 Sarah · 9:00 AM                  │
│    Running 10 minutes late          │
│                                     │
├─────────────────────────────────────┤
│ [Type a message...] [📷] [Send]     │
└─────────────────────────────────────┘
```

**Send Message:**
```dart
await _firestore.collection('hubs/$hubId/chat').add({
  'messageId': messageId,
  'senderId': currentUserId,
  'message': messageText,
  'timestamp': FieldValue.serverTimestamp(),
  'type': 'text',
  'senderName': currentUser.name,
  'senderPhotoUrl': currentUser.photoUrl,
});
```

**Cloud Function:** `onHubMessageCreated`
```javascript
exports.onHubMessageCreated = functions.firestore
  .document('hubs/{hubId}/chat/{messageId}')
  .onCreate(async (snap, context) => {
    const hubId = context.params.hubId;
    const senderId = snap.data().senderId;
    const senderName = snap.data().senderName;
    const message = snap.data().message;
    
    // Update hub's last chat message timestamp
    await admin.firestore().doc(`hubs/${hubId}`).update({
      lastChatMessageAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Fetch all hub members
    const members = await admin.firestore()
      .collection(`hubs/${hubId}/members`)
      .where('status', '==', 'active')
      .get();
    
    // Send notifications to all members (except sender)
    const batch = admin.firestore().batch();
    members.docs.forEach(memberDoc => {
      const userId = memberDoc.id;
      if (userId === senderId) return; // Skip sender
      
      // Check user's notification preferences
      // (simplified - should fetch user doc and check notificationPreferences.hub_chat)
      
      batch.set(admin.firestore().collection(`notifications/${userId}/items`).doc(), {
        type: 'hub_chat',
        title: `💬 ${senderName}`,
        body: message.substring(0, 100), // Truncate long messages
        entityId: hubId,
        hubId: hubId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    
    await batch.commit();
  });
```

**Real-Time Updates:**
```dart
// Listen to new messages
_firestore
  .collection('hubs/$hubId/chat')
  .orderBy('timestamp', descending: true)
  .limit(50)
  .snapshots()
  .listen((snapshot) {
    // Update UI with new messages
  });
```

---

### 11.3 Private Messages

**Entry Point:** User Profile Screen → "Send Message" button

**Conversation ID:** `{smallerUID}_{largerUID}` (ensures consistent ordering)

**Example:**
- User A: `abc123`
- User B: `xyz789`
- Conversation ID: `abc123_xyz789`

**Send Private Message:**
```dart
final conversationId = _getConversationId(currentUserId, recipientId);

await _firestore.collection('private_messages/$conversationId/messages').add({
  'messageId': messageId,
  'conversationId': conversationId,
  'senderId': currentUserId,
  'recipientId': recipientId,
  'message': messageText,
  'timestamp': FieldValue.serverTimestamp(),
  'read': false,
});

// Also create/update conversation metadata (for list view)
await _firestore.doc('private_messages/$conversationId').set({
  'participantIds': [currentUserId, recipientId],
  'lastMessage': messageText,
  'lastMessageAt': FieldValue.serverTimestamp(),
  'lastSenderId': currentUserId,
}, SetOptions(merge: true));
```

**Mark as Read:**
```dart
// When recipient opens conversation
await _firestore
  .collection('private_messages/$conversationId/messages')
  .where('recipientId', '==', currentUserId)
  .where('read', '==', false)
  .get()
  .then((snapshot) {
    final batch = _firestore.batch();
    snapshot.docs.forEach((doc) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    });
    return batch.commit();
  });
```

**Inbox Screen:**
```
┌─────────────────────────────────────┐
│ Messages                            │
├─────────────────────────────────────┤
│ 👤 David Cohen              [●] 2   │
│    See you at the game! · 10m ago   │
├─────────────────────────────────────┤
│ 👤 Sarah Levi                       │
│    Thanks! · 2h ago                 │
├─────────────────────────────────────┤
│ 👤 Yossi Mizrahi                    │
│    No problem · Yesterday           │
└─────────────────────────────────────┘
```

`[●] 2` = 2 unread messages

---

### 11.4 Image Messages

**Send Image in Chat:**
```
1. User clicks camera icon
2. Select/take photo
3. Compress image (max 1920px width)
4. Upload to Storage: `/uploads/chat/{chatId}/{messageId}.jpg`
5. Create ChatMessage with type='image', imageUrl=downloadUrl
```

```dart
final imageUrl = await _uploadChatImage(image, chatId);

await _firestore.collection('hubs/$hubId/chat').add({
  'messageId': messageId,
  'senderId': currentUserId,
  'message': '', // Empty for image messages
  'timestamp': FieldValue.serverTimestamp(),
  'type': 'image',
  'imageUrl': imageUrl,
  'senderName': currentUser.name,
  'senderPhotoUrl': currentUser.photoUrl,
});
```

**Image Message UI:**
```
┌─────────────────────────────────────┐
│ 👤 Yossi · 2:30 PM                  │
│    ┌───────────────────────────┐   │
│    │                           │   │
│    │    [Image Thumbnail]      │   │
│    │                           │   │
│    └───────────────────────────┘   │
└─────────────────────────────────────┘
```

Click image → Full-screen image viewer with zoom/pan

---

### 11.5 Chat Moderation

**Moderator Actions:**
- Delete message (moderator/manager only)
- Block user from chat (ban from hub)

**Delete Message:**
```dart
// Firestore rules allow moderators to delete
await _firestore.doc('hubs/$hubId/chat/$messageId').delete();
```

**Firestore Rule:**
```javascript
match /hubs/{hubId}/chat/{messageId} {
  allow delete: if isHubModerator(hubId, request.auth.uid);
}
```

---

## 12. NOTIFICATIONS SYSTEM

### 12.1 Notification Types

| Type | Title (Hebrew) | Body Example | Trigger |
|------|----------------|--------------|---------|
| `game_reminder` | ⚽ משחק מתחיל בקרוב | משחק מתחיל בעוד שעתיים | Cloud Function (2h before game) |
| `message` | 💬 הודעה חדשה | David sent you a message | Private message received |
| `like` | ❤️ לייק חדש | Sarah liked your post | Post liked |
| `comment` | 💬 תגובה חדשה | Yossi commented on your post | Comment added |
| `signup` | ✅ אושרת למשחק | Your request to join was approved | Signup approved |
| `new_follower` | 👤 עוקב חדש | David started following you | Follow created |
| `hub_chat` | 💬 Sarah | Great game today! | Hub chat message |
| `new_game` | 🎮 משחק חדש | New game created in Tel Aviv Hub | Game created in hub |

---

### 12.2 Notification Creation Flow

**Example: Comment Notification**

```dart
// In onCommentCreated Cloud Function
await admin.firestore().collection('notifications/${postAuthorId}/items').add({
  'notificationId': notificationId,
  'userId': postAuthorId,
  'type': 'comment',
  'title': 'תגובה חדשה',
  'body': `${commentAuthor} הגיב על הפוסט שלך`,
  'data': {
    'postId': postId,
    'commentId': commentId,
    'hubId': hubId,
  },
  'entityId': postId,
  'hubId': hubId,
  'read': false,
  'createdAt': admin.firestore.FieldValue.serverTimestamp(),
});

// Also send FCM push notification
const userTokens = await fetchFCMTokens(postAuthorId);
if (userTokens.length > 0) {
  await admin.messaging().sendEachForMulticast({
    tokens: userTokens,
    notification: {
      title: 'תגובה חדשה',
      body: `${commentAuthor} הגיב על הפוסט שלך`,
    },
    data: {
      type: 'comment',
      postId: postId,
      hubId: hubId,
    },
  });
}
```

---

### 12.3 FCM Token Management

**Firestore Path:** `/users/{uid}/fcm_tokens/tokens`

**Token Document:**
```json
{
  "tokens": [
    "fcm_token_1_ios_device",
    "fcm_token_2_android_device"
  ]
}
```

**Register Token (on app start):**
```dart
final token = await FirebaseMessaging.instance.getToken();
await _firestore.doc('users/$uid/fcm_tokens/tokens').set({
  'tokens': FieldValue.arrayUnion([token]),
}, SetOptions(merge: true));
```

**Remove Token (on logout):**
```dart
await _firestore.doc('users/$uid/fcm_tokens/tokens').update({
  'tokens': FieldValue.arrayRemove([token]),
});
```

---

### 12.4 Notification Preferences

**User Model Field:** `notificationPreferences` (Map<String, bool>)

**Default Preferences:**
```dart
{
  'game_reminder': true,
  'message': true,
  'like': true,
  'comment': true,
  'signup': true,
  'new_follower': true,
  'hub_chat': true,
  'new_comment': true,
  'new_game': true,
}
```

**Settings Screen:**
```
┌─────────────────────────────────────┐
│ Notification Settings               │
├─────────────────────────────────────┤
│ Game Reminders           [✓]        │
│ Private Messages         [✓]        │
│ Likes                    [✓]        │
│ Comments                 [✓]        │
│ Game Signups             [✓]        │
│ New Followers            [ ]        │
│ Hub Chat                 [✓]        │
│ New Games in Hubs        [✓]        │
└─────────────────────────────────────┘
```

**Check Before Sending:**
```javascript
// In Cloud Function before creating notification
const user = await admin.firestore().doc(`users/${userId}`).get();
const prefs = user.data().notificationPreferences || {};

if (prefs.hub_chat !== false) { // Default to true if not set
  // Create notification
}
```

---

### 12.5 Notification Inbox

**Screen:** Notifications Screen (bell icon in app bar)

**Query:**
```dart
final notifications = _firestore
  .collection('notifications/$uid/items')
  .orderBy('createdAt', descending: true)
  .limit(50)
  .snapshots();
```

**UI:**
```
┌─────────────────────────────────────┐
│ Notifications              [●] 3    │
├─────────────────────────────────────┤
│ [●] ⚽ משחק מתחיל בקרוב             │
│     משחק מתחיל בעוד שעתיים · 1h ago │
├─────────────────────────────────────┤
│ [●] 💬 תגובה חדשה                   │
│     David הגיב על הפוסט שלך · 2h ago│
├─────────────────────────────────────┤
│     ❤️ לייק חדש                     │
│     Sarah אהבה את הפוסט שלך · 5h ago│
└─────────────────────────────────────┘
```

**Mark as Read:**
```dart
// When user opens notification
await _firestore.doc('notifications/$uid/items/$notificationId').update({
  'read': true,
});
```

**Mark All as Read:**
```dart
final batch = _firestore.batch();
final unread = await _firestore
  .collection('notifications/$uid/items')
  .where('read', '==', false)
  .get();

unread.docs.forEach((doc) {
  batch.update(doc.reference, {'read': true});
});

await batch.commit();
```

**Unread Count Badge:**
```dart
final unreadCount = await _firestore
  .collection('notifications/$uid/items')
  .where('read', '==', false)
  .count()
  .get();
```

---

### 12.6 Deep Linking from Notifications

**FCM Message Data:**
```json
{
  "type": "game_reminder",
  "gameId": "game123",
  "hubId": "hub456"
}
```

**Handle Notification Tap:**
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  final type = message.data['type'];
  final gameId = message.data['gameId'];
  final hubId = message.data['hubId'];
  
  switch (type) {
    case 'game_reminder':
      context.go('/games/$gameId');
      break;
    case 'hub_chat':
      context.go('/hubs/$hubId?tab=chat');
      break;
    case 'comment':
      final postId = message.data['postId'];
      context.go('/hubs/$hubId/posts/$postId');
      break;
    // ... other cases
  }
});
```

**URL Scheme:** `kattrick://game/{gameId}` or `kattrick://hub/{hubId}`

---

# (CONTINUED - Section 13: Non-Functional Requirements...)



## 13. NON-FUNCTIONAL REQUIREMENTS

### 13.1 Performance Requirements

**App Launch Time:**
- Cold start: < 3 seconds
- Hot start: < 1 second
- Time to interactive: < 2 seconds

**Screen Transition Time:**
- Screen navigation: < 300ms
- Tab switching: < 200ms
- Modal transitions: < 250ms

**Data Loading:**
- Feed posts: < 2 seconds for initial 20 posts
- Game list: < 1.5 seconds for initial 20 games
- Hub members: < 2 seconds for initial 50 members
- Chat messages: < 1 second for initial 50 messages

**Image Loading:**
- Profile photos (512x512): < 500ms
- Post photos (1920px): < 1.5 seconds
- Thumbnails: < 300ms
- Progressive loading: Show low-res placeholder → high-res image

**Offline Performance:**
- Firestore persistence: Unlimited cache enabled
- Read from cache: < 100ms
- Optimistic UI updates: Immediate feedback, sync when online
- Queue writes when offline: Auto-retry when connection restored

**Real-Time Updates:**
- Chat message latency: < 500ms
- Feed post updates: < 2 seconds
- Game signup updates: < 1 second
- Notification delivery: < 5 seconds (dependent on FCM)

---

### 13.2 Scalability Targets

**Current Scale (Dec 2025):**
- Users: ~500 (beta)
- Hubs: ~50
- Games/Week: ~100
- Firestore Reads: ~50k/day
- Firestore Writes: ~5k/day

**6-Month Target (June 2026):**
- Users: 5,000 MAU (Monthly Active Users)
- Hubs: 250
- Games/Week: 1,000
- Firestore Reads: ~1M/day
- Firestore Writes: ~100k/day

**12-Month Target (Dec 2026):**
- Users: 10,000 MAU
- Hubs: 500
- Games/Week: 2,000
- Firestore Reads: ~2M/day
- Firestore Writes: ~200k/day

**Architecture Scalability:**
- Firestore: Supports 1M+ concurrent connections (well above target)
- Cloud Functions: Auto-scales to demand (no config needed)
- Firebase Storage: Unlimited storage (pay per GB)
- FCM: Supports millions of devices (no limit)

**Performance at Scale:**
- Denormalized fields reduce reads by 90%
- Pagination limits queries to 20-50 items
- Indexes optimize all queries to < 100ms
- Cloud Functions process events asynchronously

---

### 13.3 Security Requirements

**Authentication:**
- All users must be authenticated (Firebase Auth)
- Anonymous access disabled (explicitly signed out on app start)
- Email verification required for password reset
- No custom claims yet (future: sync hub roles to JWT)

**Authorization:**
- Firestore Security Rules enforce all permissions
- Server-side validation via Cloud Functions
- No client-side security bypass possible
- Audit trails for admin actions (Game.auditLog, HubMember.updatedBy)

**Data Protection:**
- User data encrypted at rest (Firestore default)
- User data encrypted in transit (HTTPS only)
- No passwords stored in Firestore (Firebase Auth handles)
- Sensitive fields hidden based on User.privacySettings

**Israeli Privacy Laws (Data Protection Regulation 1981):**
- Age gate: 13+ enforcement (User.birthDate validation)
- Parental consent: Not implemented (assume users are 13+)
- Data export: Not implemented (future: /settings/export-data)
- Data deletion: User can delete account (deletes all personal data)
- Cookie consent: Not applicable (mobile app)

**GDPR Compliance (Future - if expanding beyond Israel):**
- Right to access: Export user data
- Right to rectification: Edit profile
- Right to erasure: Delete account
- Right to portability: Export data as JSON
- Data minimization: Only collect necessary data
- Consent: Explicit opt-in for notifications

**Content Moderation:**
- Moderators can delete posts/comments
- Managers can ban users
- No automated content filtering (future: AI moderation)
- User blocking (User.blockedUserIds)

**Abuse Prevention:**
- Firebase App Check: Prevent bot traffic
- Rate limiting: Not implemented (future: Cloud Functions rate limits)
- Spam detection: Not implemented (future: detect repeated posts)

---

### 13.4 Reliability & Availability

**Target Uptime:** 99.9% (3 nines)
- Downtime: < 8.76 hours/year
- Firestore SLA: 99.95% (Firebase commitment)
- Cloud Functions SLA: 99.5%

**Error Handling:**
- All errors logged to Crashlytics
- Non-fatal errors: Show user-friendly error message, retry
- Fatal errors: Crash report sent, user sees "Something went wrong" screen
- Network errors: Show offline indicator, queue writes

**Backup & Recovery:**
- Daily automated Firestore backups (3 AM UTC)
- Retention: 7 days
- Recovery time: < 1 hour (restore from backup)
- Firebase Storage backup: Daily rsync to secondary bucket

**Monitoring:**
- Crashlytics: Real-time crash reports
- Firebase Analytics: User behavior tracking
- Cloud Function logs: Structured JSON logging
- Performance Monitoring: Not implemented (future: Firebase Performance)

---

### 13.5 Usability Requirements

**Language:**
- Hebrew (RTL) only
- All UI text in Hebrew
- Date/time formatting: Hebrew locale
- Number formatting: Hebrew locale

**Accessibility:**
- Not prioritized (future: VoiceOver/TalkBack support)
- Color contrast: Meets WCAG 2.1 AA (dark theme)
- Text scaling: Supports iOS/Android system text size
- Touch targets: Min 44x44pt (iOS) / 48x48dp (Android)

**Onboarding:**
- Profile setup wizard: 4 steps (name, birthdate, location, photo)
- Progressive disclosure: Show features as needed
- No tutorial (app is intuitive)

**Error Messages:**
- User-friendly Hebrew messages
- No technical jargon
- Actionable guidance (e.g., "בדוק את החיבור לאינטרנט" instead of "Network error")

---

### 13.6 Maintainability

**Code Quality:**
- Dart Analyzer: Strict mode enabled
- Lint rules: 50+ rules enforced
- No warnings allowed in production builds
- Code coverage: Not tracked (future: 70%+ target)

**Documentation:**
- Inline code comments for complex logic
- Model classes: Freezed + JSON serialization
- Firestore schema documented in DATABASE_SCHEMA.md
- This PRD serves as product documentation

**Versioning:**
- Semantic versioning: MAJOR.MINOR.PATCH
- Build numbers: Auto-incremented per build
- App Store version: Manually set in pubspec.yaml

**Testing:**
- Unit tests: Limited (future: expand coverage)
- Widget tests: Limited
- Integration tests: None
- Manual QA: Primary testing method

---

## 14. EDGE CASES & FAILURE MODES

### 14.1 Network Failures

**Scenario 1: User Goes Offline Mid-Action**
- **What Happens:**
  - Firestore write queued locally
  - UI shows optimistic update (e.g., "Joining game...")
  - Snackbar: "אין חיבור לאינטרנט. השינויים יישמרו כשתחזור לאינטרנט"
- **Recovery:**
  - When connection restored, queued writes auto-sync
  - If write fails (e.g., game is full), show error + revert UI
  - User sees success/failure notification

**Scenario 2: Image Upload Fails**
- **What Happens:**
  - User selects photo for post
  - Compress image locally
  - Upload to Storage → Network error
- **Recovery:**
  - Retry upload (exponential backoff: 1s, 2s, 4s)
  - After 3 retries, show error: "העלאת התמונה נכשלה. נסה שוב"
  - User can retry manually or remove photo

**Scenario 3: Cloud Function Fails**
- **Example:** onGameCreated fails to denormalize creator name
- **What Happens:**
  - Game created in Firestore (client write succeeds)
  - Cloud Function throws error → logged to Cloud Functions console
  - Game missing createdByName field
- **Recovery:**
  - Client fallback: Fetch creator name from /users/{createdBy} if denormalized field missing
  - Manual fix: Run migration script to backfill missing data
  - Future prevention: Add retry logic to Cloud Functions

---

### 14.2 Race Conditions

**Scenario 1: Two Users Join Full Game Simultaneously**
- **Setup:** Game has maxPlayers=20, currently 19 confirmed
- **What Happens:**
  - User A clicks "Join" → writes GameSignup (confirmed count becomes 20)
  - User B clicks "Join" 100ms later → writes GameSignup (confirmed count becomes 21)
  - Game is now overbooked!
- **Prevention:**
  - Firestore transaction on game signup:
    ```dart
    await _firestore.runTransaction((transaction) async {
      final gameDoc = await transaction.get(gameRef);
      final confirmedCount = gameDoc.data()!['confirmedPlayerCount'];
      
      if (confirmedCount >= maxPlayers) {
        throw Exception('Game is full');
      }
      
      transaction.set(signupRef, signupData);
      transaction.update(gameRef, {'confirmedPlayerCount': FieldValue.increment(1)});
    });
    ```
  - If transaction fails, show error: "המשחק מלא"

**Scenario 2: Manager Deletes Hub While Member Joins**
- **Setup:** User A is joining hub, Manager deletes hub simultaneously
- **What Happens:**
  - User A creates HubMember doc
  - Manager deletes Hub doc
  - HubMember doc orphaned (no parent hub)
- **Prevention:**
  - Firestore rule: Prevent hub deletion if memberCount > 1
  - Manager must remove all members first before deleting hub
- **Recovery:**
  - Orphan cleanup Cloud Function (weekly cron):
    ```javascript
    const orphanMembers = await admin.firestore()
      .collectionGroup('members')
      .get();
    
    for (const memberDoc of orphanMembers.docs) {
      const hubId = memberDoc.ref.parent.parent.id;
      const hubExists = await admin.firestore().doc(`hubs/${hubId}`).get().exists;
      if (!hubExists) {
        await memberDoc.ref.delete(); // Delete orphan
      }
    }
    ```

---

### 14.3 Data Inconsistencies

**Scenario 1: Denormalized Counter Out of Sync**
- **Example:** hub.memberCount shows 50, but actual members count is 48
- **Cause:** Cloud Function onMembershipChange failed or skipped
- **Detection:**
  - Admin dashboard (future) shows red flag if denormalized count ≠ actual count
- **Recovery:**
  - Run recount Cloud Function (admin-triggered):
    ```javascript
    exports.recountHubMembers = functions.https.onCall(async (data, context) => {
      const hubId = data.hubId;
      const actualCount = await admin.firestore()
        .collection(`hubs/${hubId}/members`)
        .where('status', '==', 'active')
        .count()
        .get();
      
      await admin.firestore().doc(`hubs/${hubId}`).update({
        memberCount: actualCount.data().count,
      });
      
      return { success: true, actualCount: actualCount.data().count };
    });
    ```

**Scenario 2: veteranSince Set by Client (Security Bypass Attempt)**
- **What Happens:**
  - Malicious client attempts to write `veteranSince: now()` to HubMember doc
- **Prevention:**
  - Firestore rule rejects write:
    ```javascript
    match /hubs/{hubId}/members/{userId} {
      allow update: if
        !request.resource.data.diff(resource.data).affectedKeys().hasAny(['veteranSince']);
    }
    ```
  - Write fails with "Permission denied"

**Scenario 3: User Deletes Account Mid-Game**
- **Setup:** User signed up for game tomorrow, then deletes account today
- **What Happens:**
  - User doc deleted
  - GameSignup doc orphaned
  - Game still shows user in confirmedPlayerIds
- **Recovery:**
  - On account deletion:
    - Cancel all future GameSignups
    - Remove from all hub memberships
    - Delete private messages
    - Keep game history (anonymize: replace userId with "DeletedUser")

---

### 14.4 User Mistakes

**Scenario 1: User Accidentally Cancels Game Signup**
- **What Happens:**
  - User clicks "Leave Game" by mistake
  - GameSignup status changed to 'cancelled'
- **Recovery:**
  - Show confirmation dialog: "בטוח שברצונך לבטל את ההרשמה?"
  - If confirmed, allow re-signup:
    - Update existing GameSignup status to 'confirmed' (don't create new doc)
    - Cloud Function increments confirmedPlayerCount again

**Scenario 2: Manager Deletes Hub by Mistake**
- **Prevention:**
  - Delete hub requires TWO confirmations:
    1. "מחיקת האב תמחק את כל הנתונים. האם להמשיך?"
    2. Type hub name to confirm: "הקלד את שם האב כדי לאשר: [hub name]"
- **Recovery:**
  - No automatic recovery (hub is deleted)
  - Contact support (future: restore from daily backup)

**Scenario 3: User Joins Wrong Game**
- **Recovery:**
  - Allow cancellation up to 1 hour before game starts
  - After that, show warning: "המשחק מתחיל בקרוב. צור קשר עם המארגן לביטול"

---

### 14.5 Malicious Behavior

**Scenario 1: Spam Posts**
- **Detection:** User creates 10+ posts in 1 minute
- **Prevention:** Not implemented (future: rate limiting in Cloud Functions)
- **Recovery:** Manager/moderator deletes spam posts + bans user

**Scenario 2: Fake Game Signups**
- **Attack:** User signs up for 20 games they won't attend
- **Prevention:** Reputation system (future: track no-show rate, auto-ban if > 30%)
- **Recovery:** Game creator kicks user + reports abuse

**Scenario 3: Inappropriate Content**
- **Detection:** Manual reports (future: "Report Post" button)
- **Prevention:** Content moderation (manager/moderator review)
- **Recovery:** Delete post + ban user if repeated offenses

---

## 15. ANALYTICS & METRICS

### 15.1 Key Performance Indicators (KPIs)

**Growth Metrics:**
- Daily Active Users (DAU)
- Monthly Active Users (MAU)
- DAU/MAU ratio (engagement)
- New user registrations/week
- User retention (D1, D7, D30)

**Activation Metrics:**
- Profile completion rate
- Hub joins per new user
- First game signup time (time from registration to first signup)
- First game creation time (time to first game organized)

**Engagement Metrics:**
- Games per user per month
- Hub posts per user per month
- Chat messages per user per month
- Average session duration
- Sessions per user per week

**Retention Metrics:**
- D1 retention: % users who return next day
- D7 retention: % users who return within 7 days
- D30 retention: % users who return within 30 days
- Churn rate: % users who don't return after 30 days

**Monetization Metrics (Future):**
- Ad impressions per user per day
- Ad click-through rate (CTR)
- Ad revenue per user (ARPU)
- Fill rate (% of ad requests filled)

---

### 15.2 Firebase Analytics Events

**Currently Tracked (30+ events):**

**User Events:**
- `app_open` (automatic)
- `sign_up` (user creates account)
- `login` (user signs in)
- `profile_complete` (user completes profile setup)
- `profile_edit` (user updates profile)

**Hub Events:**
- `hub_created` (user creates hub)
- `hub_joined` (user joins hub)
- `hub_left` (user leaves hub)
- `hub_viewed` (user views hub detail)

**Game Events:**
- `game_created` (user creates game)
- `game_signup` (user joins game)
- `game_cancel_signup` (user cancels signup)
- `game_completed` (game marked as completed)
- `team_maker_used` (team builder used)

**Event Events:**
- `event_created` (manager creates event)
- `event_registered` (user registers for event)
- `event_converted` (event converted to game)

**Social Events:**
- `post_created` (user creates feed post)
- `post_liked` (user likes post)
- `comment_added` (user comments on post)
- `message_sent` (private message sent)
- `hub_chat_message` (hub chat message sent)

**Discovery Events:**
- `hub_searched` (user searches for hubs)
- `venue_searched` (user searches for venues)
- `regional_feed_viewed` (user views regional feed)

**Revenue Events (Future):**
- `ad_impression` (ad shown to user)
- `ad_click` (user clicks ad)

---

### 15.3 User Properties

**Demographics:**
- `age_group` (teens, young, adults, mature, veteran, legend)
- `region` (צפון, מרכז, דרום, ירושלים)
- `preferred_position` (Goalkeeper, Defender, Midfielder, Attacker)

**Engagement:**
- `hub_count` (number of hubs user is member of)
- `games_played` (lifetime games participated)
- `veteran_status` (boolean - is veteran in any hub)

**Acquisition:**
- `sign_up_date` (date user registered)
- `days_since_signup` (calculated)

---

### 15.4 Conversion Funnels

**Onboarding Funnel:**
```
1. App Install → 100%
2. Account Created → 85%
3. Profile Completed → 70%
4. First Hub Joined → 50%
5. First Game Signup → 35%
6. First Game Attended → 25%
```

**Hub Creation Funnel:**
```
1. Clicks "Create Hub" → 100%
2. Fills Hub Name → 90%
3. Adds Description → 75%
4. Selects Venue → 60%
5. Completes Creation → 50%
```

**Game Organization Funnel:**
```
1. Clicks "Create Game" → 100%
2. Selects Date/Time → 95%
3. Selects Venue → 85%
4. Invites Players → 70%
5. Uses Team Maker → 40%
6. Records Results → 30%
```

---

### 15.5 Alerts & Monitoring

**Critical Alerts (PagerDuty/Email):**
- App crash rate > 1%
- Cloud Function error rate > 5%
- Firestore write errors > 100/hour
- Storage upload failures > 50/hour

**Warning Alerts (Slack):**
- Daily active users drop > 20% week-over-week
- Game creation rate drop > 30% week-over-week
- Notification delivery failures > 10/hour

**Informational Dashboards:**
- Firebase Analytics: Real-time user counts
- Crashlytics: Top crashes by frequency
- Cloud Functions: Invocation count, errors, latency
- Firestore: Read/write operations, index usage

---

## 16. MONETIZATION STRATEGY (AD-BASED MODEL)

**CRITICAL:** This is the core monetization strategy for Kattrick.

### 16.1 Business Model Overview

**Revenue Model:** Ad-Based (NOT Subscriptions/Freemium)

**Value Proposition:**
- **For Users:** 100% free forever, no paywalls, no premium features
- **For Advertisers:** Highly engaged football community, geo-targeted ads, niche audience
- **For Kattrick:** Run ad agency leveraging user base, campaign management

**Target ARPU (Average Revenue Per User):**
- **Conservative:** $0.50/month per MAU
- **Target:** $1.00/month per MAU
- **Optimistic:** $2.00/month per MAU

**Revenue Projections:**

| Timeline | MAU | ARPU/month | Monthly Revenue | Annual Revenue |
|----------|-----|------------|-----------------|----------------|
| 6 months | 5,000 | $0.50 | $2,500 | $30,000 |
| 12 months | 10,000 | $1.00 | $10,000 | $120,000 |
| 18 months | 20,000 | $1.50 | $30,000 | $360,000 |
| 24 months | 40,000 | $2.00 | $80,000 | $960,000 |

---

### 16.2 Ad Placement Locations

**In-App Ad Placements (Native Ads - Preferred):**

1. **Hub Feed Ads (Primary Placement)**
   - **Location:** Between posts in hub feed (every 5th post)
   - **Format:** Native card, looks like a post
   - **Content:** Local sports gear shops, football fields, sports drinks
   - **Example:**
     ```
     ┌─────────────────────────────────────┐
     │ 📢 Sponsored                        │
     │ Mike Sport - ציוד כדורגל במרכז      │
     ├─────────────────────────────────────┤
     │ 🏷️ 20% הנחה על כל הנעליים          │
     │ [Image: Football boots]             │
     │ ┌─────────────────────────────────┐ │
     │ │ [CTA Button: לחנות →]           │ │
     │ └─────────────────────────────────┘ │
     └─────────────────────────────────────┘
     ```
   - **Frequency:** Max 1 ad per 5 posts (20% ad-to-content ratio)
   - **Targeting:** Geo-location, age, gender, interests

2. **Regional Feed Ads**
   - **Location:** Between recruiting posts in regional feed (every 4th post)
   - **Format:** Native card
   - **Content:** Local businesses, sports facilities
   - **Frequency:** 25% ad-to-content ratio

3. **Game Detail Screen Ad**
   - **Location:** Below game info, above participant list
   - **Format:** Banner (320x50) or Card (full width)
   - **Content:** Game-related (e.g., "Book this venue for your next game")
   - **Frequency:** 1 ad per game screen view

4. **Hub Discovery Ads**
   - **Location:** Between hubs in "Discover Hubs" screen (every 3rd hub)
   - **Format:** Hub-like card
   - **Content:** Sponsored hubs (premium hubs pay to be featured)
   - **Example:**
     ```
     ┌─────────────────────────────────────┐
     │ 🌟 Featured Hub                     │
     │ Elite Football Academy              │
     ├─────────────────────────────────────┤
     │ 📍 Tel Aviv · 50 members            │
     │ Professional training for all levels│
     │ ┌─────────────────────────────────┐ │
     │ │ [Join Hub]                      │ │
     │ └─────────────────────────────────┘ │
     └─────────────────────────────────────┘
     ```

5. **Post-Game Results Ad (Interstitial)**
   - **Location:** After game results recorded, before returning to feed
   - **Format:** Full-screen interstitial (dismissible after 3 seconds)
   - **Content:** Sports recovery products, nutrition, injury prevention
   - **Frequency:** Max 1 per game completion (not on every game)

---

### 16.3 Ad Network Integration

**Phase 1 (Months 1-6): Google AdMob**
- **Why:** Easy integration, global reach, auto-fill ads
- **Implementation:**
  - Add `google_mobile_ads` Flutter package
  - Create AdMob account + app units
  - Implement native ads, banner ads, interstitial ads
  - Use AdMob's targeting (auto geo, demographics)

**Code Example (Native Ad in Feed):**
```dart
// In HubFeedScreen
ListView.builder(
  itemCount: posts.length + (posts.length ~/ 5), // Add ad slots
  itemBuilder: (context, index) {
    // Every 5th item is an ad
    if (index % 5 == 4) {
      return NativeAdCard(
        adUnitId: Platform.isIOS 
          ? 'ca-app-pub-xxx/iOS-native-ad-unit'
          : 'ca-app-pub-xxx/android-native-ad-unit',
      );
    }
    
    // Otherwise, show post
    final postIndex = index - (index ~/ 5);
    return PostCard(post: posts[postIndex]);
  },
);
```

**Phase 2 (Months 7-12): Direct Sales (Self-Managed)**
- **Why:** Higher revenue share (70-80% vs AdMob's 55-60%)
- **Implementation:**
  - Build admin dashboard for campaign management
  - Sell ad slots directly to local businesses (sports shops, gyms, etc.)
  - Custom targeting (region, hub, age group)
  - Pricing: CPM (Cost Per Mille - per 1000 impressions) or flat monthly fee

**Phase 3 (Months 13+): Hybrid Model**
- **Primary:** Direct sales (higher revenue)
- **Fallback:** AdMob (fill unsold inventory)
- **Target:** 60% direct, 40% AdMob

---

### 16.4 Ad Campaign Management (Future)

**Admin Dashboard (Web):**

**Campaign Creation:**
```
┌─────────────────────────────────────┐
│ Create Ad Campaign                  │
├─────────────────────────────────────┤
│ Campaign Name:                      │
│ [Mike Sport - Summer Sale]          │
│                                     │
│ Ad Creative:                        │
│ [Upload Image (1200x628)]           │
│ Headline: [20% Off Football Boots]  │
│ Body: [Visit our store in Tel Aviv] │
│ CTA Button: [Shop Now]              │
│ Link URL: [https://mikesport.co.il] │
│                                     │
│ Targeting:                          │
│ Region: [✓] מרכז [ ] צפון [ ] דרום  │
│ Age: [18] - [35]                    │
│ Gender: [All] [Male] [Female]       │
│ Hubs: [All] [Select specific hubs]  │
│                                     │
│ Budget:                             │
│ Total Budget: [₪5,000]              │
│ Pricing Model: [CPM ▼] ₪20 per 1000│
│ Est. Impressions: 250,000           │
│                                     │
│ Schedule:                           │
│ Start: [2026-06-01]                 │
│ End: [2026-06-30]                   │
│                                     │
│ [Preview Ad] [Launch Campaign]      │
└─────────────────────────────────────┘
```

**Campaign Analytics:**
```
┌─────────────────────────────────────┐
│ Mike Sport - Summer Sale            │
│ Status: Active · 15 days remaining  │
├─────────────────────────────────────┤
│ Impressions: 120,000 / 250,000 (48%)│
│ Clicks: 2,400 (2.0% CTR)            │
│ Conversions: 48 (tracked via pixel) │
│ Spend: ₪2,400 / ₪5,000              │
│                                     │
│ Performance by Region:              │
│ מרכז: 80,000 impressions, 1,600 clicks│
│ צפון: 30,000 impressions, 600 clicks│
│ דרום: 10,000 impressions, 200 clicks│
│                                     │
│ [Pause Campaign] [Edit] [Report]    │
└─────────────────────────────────────┘
```

---

### 16.5 Ad Delivery Logic (Client-Side)

**Firestore Collection:** `/adCampaigns/{campaignId}`

**Campaign Model:**
```dart
class AdCampaign {
  final String campaignId;
  final String advertiserId;
  final String adCreativeUrl; // Image URL
  final String headline;
  final String body;
  final String ctaText; // "Shop Now"
  final String linkUrl;
  final TargetingCriteria targeting; // region, age, gender, hubs
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int totalBudget; // in cents
  final int spentBudget; // in cents
  final int impressions; // total served
  final int clicks; // total clicks
}
```

**Ad Fetching Logic:**
```dart
// In HubFeedScreen
Future<AdCampaign?> _fetchRelevantAd() async {
  final user = await _getCurrentUser();
  
  // Query active campaigns matching user's targeting
  final campaigns = await _firestore
    .collection('adCampaigns')
    .where('isActive', isEqualTo: true)
    .where('targeting.region', isEqualTo: user.region) // Assume index on targeting.region
    .where('startDate', isLessThanOrEqualTo: Timestamp.now())
    .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
    .get();
  
  // Client-side filtering (age, gender, etc.)
  final eligibleCampaigns = campaigns.docs
    .where((doc) {
      final campaign = AdCampaign.fromJson(doc.data());
      return _matchesTargeting(campaign.targeting, user);
    })
    .toList();
  
  // Random selection (or weighted by budget remaining)
  if (eligibleCampaigns.isEmpty) return null;
  final randomIndex = Random().nextInt(eligibleCampaigns.length);
  
  return AdCampaign.fromJson(eligibleCampaigns[randomIndex].data());
}

// Track impression (Cloud Function increments campaign.impressions)
await _firestore.collection('adImpressions').add({
  'campaignId': campaign.campaignId,
  'userId': user.uid,
  'timestamp': FieldValue.serverTimestamp(),
  'placement': 'hub_feed', // or 'regional_feed', 'game_detail', etc.
});

// Track click
await _firestore.collection('adClicks').add({
  'campaignId': campaign.campaignId,
  'userId': user.uid,
  'timestamp': FieldValue.serverTimestamp(),
});
```

**Cloud Function:** `onAdImpression`
```javascript
exports.onAdImpression = functions.firestore
  .document('adImpressions/{impressionId}')
  .onCreate(async (snap, context) => {
    const campaignId = snap.data().campaignId;
    
    // Increment campaign impressions
    await admin.firestore().doc(`adCampaigns/${campaignId}`).update({
      impressions: admin.firestore.FieldValue.increment(1),
    });
  });
```

---

### 16.6 Pricing Strategy

**CPM (Cost Per Mille) - Recommended:**
- ₪20-₪50 per 1,000 impressions
- Standard in Israel: ₪25-₪35 CPM for niche audiences
- Kattrick premium: ₪40-₪50 (highly engaged, geo-targeted)

**CPC (Cost Per Click) - Alternative:**
- ₪1-₪3 per click
- Higher revenue potential if CTR is good (2%+)

**Flat Monthly Fee (Sponsorships):**
- Hub sponsorship: ₪500-₪2,000/month (logo in hub, featured placement)
- Category exclusivity: ₪5,000/month (only sports shop in region)

**Revenue Calculator:**
| MAU | Impressions/User/Month | Total Impressions/Month | CPM | Monthly Revenue |
|-----|------------------------|-------------------------|-----|-----------------|
| 10,000 | 50 | 500,000 | ₪30 | ₪15,000 |
| 20,000 | 60 | 1,200,000 | ₪35 | ₪42,000 |
| 40,000 | 70 | 2,800,000 | ₪40 | ₪112,000 |

---

### 16.7 User Experience Considerations

**CRITICAL: Maintain 100% Free Experience**
- No ads blocking content
- Dismissible interstitials (after 3 seconds)
- Native ads blend with feed (clearly marked "Sponsored")
- No auto-play video ads (data consumption)
- No audio ads

**Ad Frequency Limits:**
- Hub feed: Max 1 ad per 5 posts (20%)
- Regional feed: Max 1 ad per 4 posts (25%)
- Interstitials: Max 1 per game completion (not every game)
- Banner ads: Persistent but non-intrusive

**Ad Quality Standards:**
- Only sports-related ads (no dating, gambling, crypto)
- No inappropriate content (validated by admin)
- Geo-relevant (Israeli businesses only)

**Opt-Out (Future - Subscription Model):**
- NOT planned for initial launch
- Possible future: "Kattrick Premium" ₪19.90/month → ad-free
- Would require rethinking "100% free forever" promise

---

### 16.8 Technical Implementation Roadmap

**Phase 1 (Months 1-3): AdMob Integration**
- Add `google_mobile_ads` package
- Implement native ads in hub feed
- Implement banner ads in game detail screen
- Test ad placements with test campaigns
- Measure baseline CTR, fill rate

**Phase 2 (Months 4-6): Analytics & Optimization**
- Track ad impressions, clicks, CTR
- A/B test ad placements (every 5th vs every 3rd post)
- Optimize ad creative (image size, CTA text)
- Analyze user feedback (complaints about ads)

**Phase 3 (Months 7-12): Direct Sales Platform**
- Build web admin dashboard for campaign management
- Implement Firestore-based campaign storage
- Build ad delivery logic (targeting, scheduling)
- Integrate payment processing (Israeli credit cards, PayPal)
- Launch pilot with 3-5 local businesses

**Phase 4 (Months 13+): Scale & Hybrid Model**
- Hire sales team (1-2 people)
- Reach out to Israeli sports brands (Adidas Israel, Nike Israel)
- Negotiate national campaigns (₪10k-₪50k/month)
- Maintain AdMob fallback for unsold inventory
- Target 60% direct sales, 40% AdMob

---

## 17. GAPS & MISSING FEATURES

### 17.1 Core Missing Features (Deferred to Post-Launch)

**1. Tournament System**
- **Description:** Bracket-based tournaments with elimination rounds
- **Use Case:** Hubs want to organize 8-team/16-team tournaments
- **Implementation Complexity:** High (bracket logic, seeding, tiebreakers)
- **Priority:** Medium (3-6 months post-launch)
- **Data Model:**
  ```dart
  class Tournament {
    final String tournamentId;
    final String hubId;
    final String name;
    final List<TournamentRound> rounds; // Quarterfinals, Semifinals, Finals
    final TournamentFormat format; // single_elimination, double_elimination
  }
  ```

**2. League System**
- **Description:** Season-based leagues with standings, promotion/relegation
- **Use Case:** Multiple hubs form a league, play regular season + playoffs
- **Implementation Complexity:** Very High (fixture scheduling, table calculations)
- **Priority:** Low (12+ months post-launch)

**3. Advanced Player Rating System**
- **Current:** Simple 1-7 manager rating per hub
- **Missing:** Global skill rating (Elo, TrueSkill), position-specific ratings
- **Implementation Complexity:** Medium
- **Priority:** Medium (6-12 months post-launch)

**4. Player Analytics Dashboard**
- **Current:** Basic stats (wins, losses, goals, assists)
- **Missing:** Performance trends, heatmaps, position stats, form graph
- **Implementation Complexity:** Medium
- **Priority:** Low (aesthetics, not core functionality)

**5. Automated Content Moderation**
- **Current:** Manual moderation by managers/moderators
- **Missing:** AI-powered spam detection, profanity filter, image moderation
- **Implementation Complexity:** High (requires ML model integration)
- **Priority:** Medium (only if spam becomes a problem)

**6. Web App (PWA)**
- **Current:** Mobile app only (iOS/Android)
- **Missing:** Web version for desktop users
- **Implementation Complexity:** Medium (Flutter Web)
- **Priority:** Low (95% of users are mobile)

**7. Multi-Language Support**
- **Current:** Hebrew only
- **Missing:** English, Arabic (for Israeli market expansion)
- **Implementation Complexity:** Medium (i18n, RTL/LTR switching)
- **Priority:** Low (only if expanding beyond Israeli market)

---

### 17.2 Admin Dashboard (Critical for Ad-Based Model)

**Why Critical:** Cannot manage ad campaigns without web dashboard

**Functionality Needed:**
- User management (view users, ban users, reset passwords)
- Hub management (view hubs, delete inappropriate hubs)
- Ad campaign management (create, edit, pause, delete campaigns)
- Analytics dashboard (MAU, DAU, revenue, top hubs, top games)
- Content moderation (review reported posts, delete spam)

**Implementation Plan:**
- **Framework:** Flutter Web (reuse existing codebase) OR Next.js (separate codebase)
- **Timeline:** 3-6 months post-launch
- **Priority:** **HIGH** (required for Phase 3 monetization)

**Screens:**
1. Dashboard Home (KPIs, graphs)
2. Users List + User Detail
3. Hubs List + Hub Detail
4. Ad Campaigns List + Create/Edit Campaign
5. Analytics (Firestore queries → charts)
6. Content Moderation Queue

---

### 17.3 Incomplete Features (Partially Implemented)

**1. Polls (Fully Implemented BUT Underutilized)**
- **Status:** Models and UI exist (`lib/models/poll.dart`, `lib/widgets/polls/poll_card.dart`)
- **Gap:** Not prominently featured in UI, no onboarding for managers
- **Fix:** Add "Create Poll" button to Hub Feed, show polls in feed

**2. Achievements/Badges (Partially Implemented)**
- **Status:** `Gamification` model exists, basic badges defined
- **Gap:** No UI to display badges on profile, no notification when earned
- **Fix:** Add "Badges" tab to user profile, send notification on badge unlock

**3. Recurring Games (Partially Implemented)**
- **Status:** Model supports `isRecurring`, but no Cloud Function to auto-create instances
- **Gap:** Manager must manually create each instance
- **Fix:** Implement `createRecurringGameInstances` Cloud Function

**4. Venue Discovery (Map View Missing)**
- **Status:** Venues stored with `GeoPoint`, but no map view in app
- **Gap:** Users can't browse venues on a map
- **Fix:** Add map view using `google_maps_flutter` package

---

### 17.4 Technical Debt & Improvements

**1. Image Compression Inconsistency**
- **Issue:** Some screens compress images before upload, others don't
- **Impact:** High storage costs, slow uploads
- **Fix:** Centralize image compression in `StorageService`

**2. Firestore Index Management**
- **Issue:** Indexes created ad-hoc when errors occur
- **Impact:** Production errors when new queries added
- **Fix:** Use `firestore.indexes.json` to define all indexes upfront

**3. Error Handling Inconsistency**
- **Issue:** Some screens show generic "Error occurred", others show specific errors
- **Impact:** Poor UX, hard to debug
- **Fix:** Centralize error handling in `ErrorHandlerService`

**4. Test Coverage**
- **Issue:** Limited unit tests, no integration tests
- **Impact:** Regressions when refactoring
- **Fix:** Add test coverage (target 70%+ for critical flows)

**5. Code Duplication**
- **Issue:** Similar logic repeated across screens (e.g., fetch user data)
- **Impact:** Hard to maintain, inconsistent behavior
- **Fix:** Refactor into shared services, create reusable widgets

---

## 18. ROADMAP & FUTURE OPPORTUNITIES

### 18.1 3-Month Roadmap (Immediate - Dec 2025 to Feb 2026)

**Focus:** Stabilize core features, integrate AdMob

**Milestones:**
- ✅ Month 1 (Dec 2025): Fix critical bugs, polish onboarding, prepare for beta launch
- ⏳ Month 2 (Jan 2026): Launch closed beta (50-100 users), collect feedback
- 📋 Month 3 (Feb 2026): Integrate AdMob, test ad placements, launch public beta

**Deliverables:**
1. **Beta Launch (Jan 2026)**
   - Invite 50 beta testers (Tel Aviv area)
   - Set up Crashlytics alerts
   - Daily monitoring of bugs

2. **AdMob Integration (Feb 2026)**
   - Add native ads to hub feed
   - Add banner ads to game detail screen
   - Measure baseline metrics (impressions, CTR)

3. **Feedback Iteration (Feb 2026)**
   - Fix top 10 user-reported bugs
   - Improve onboarding based on dropout analysis
   - Optimize ad placement based on CTR data

---

### 18.2 6-Month Roadmap (Short-Term - Mar to Aug 2026)

**Focus:** Grow user base, optimize ads, build admin dashboard

**Growth Target:** 5,000 MAU by Aug 2026

**Milestones:**
- Month 4-5 (Mar-Apr 2026): Public launch, marketing push, onboard 50 hubs
- Month 6 (May 2026): Build admin dashboard (Phase 1: Analytics)
- Month 7-8 (Jun-Jul 2026): Admin dashboard (Phase 2: Ad campaign management)
- Month 8 (Aug 2026): Launch first direct ad campaign (pilot with local shop)

**Deliverables:**
1. **Public Launch (Mar 2026)**
   - App Store (iOS) + Google Play (Android)
   - Press release (Israeli tech blogs)
   - Social media campaign (#Kattrick)

2. **Hub Onboarding Campaign**
   - Reach out to 100 existing football groups (Facebook, WhatsApp)
   - Offer free onboarding support (help set up hub, invite members)
   - Target: 50 active hubs by May 2026

3. **Admin Dashboard (May-Jul 2026)**
   - Analytics (MAU, DAU, revenue, top hubs)
   - User management (view, ban, reset password)
   - Ad campaign management (create, edit, pause)

4. **First Direct Ad Campaign (Aug 2026)**
   - Pilot with 1-2 local sports shops
   - Run 1-month campaign (₪2,000 budget)
   - Measure ROI, gather learnings

---

### 18.3 12-Month Roadmap (Medium-Term - Sep 2026 to Dec 2026)

**Focus:** Scale ad revenue, expand features, improve retention

**Growth Target:** 10,000 MAU by Dec 2026

**Milestones:**
- Month 9-10 (Sep-Oct 2026): Optimize ad revenue (CPM optimization, direct sales)
- Month 11-12 (Nov-Dec 2026): Launch tournament system, improve player analytics

**Deliverables:**
1. **Ad Revenue Scale (Sep-Oct 2026)**
   - Onboard 5-10 direct advertisers
   - Increase CPM from ₪25 to ₪35 (better targeting)
   - Target: ₪10,000/month ad revenue by Oct 2026

2. **Tournament System (Nov 2026)**
   - Single-elimination bracket UI
   - 8-team and 16-team support
   - MVP selection, awards

3. **Player Analytics Dashboard (Dec 2026)**
   - Performance trends (wins/losses over time)
   - Position-specific stats
   - Form graph (last 10 games)

---

### 18.4 Future Opportunities (18+ Months)

**1. B2B Offerings**
- **Opportunity:** Sell Kattrick to sports facilities as SaaS
- **Use Case:** Football field owners use Kattrick to manage bookings, leagues
- **Revenue Model:** ₪500-₪2,000/month per facility
- **Timeline:** 18-24 months

**2. Merchandise Integration**
- **Opportunity:** Partner with sports gear shops, allow in-app purchases
- **Use Case:** User buys football boots via Kattrick, shop pays commission
- **Revenue Model:** 10-15% commission on sales
- **Timeline:** 18-24 months

**3. Live Match Streaming**
- **Opportunity:** Stream games live, monetize with ads/subscriptions
- **Use Case:** Fans watch live games from their phone
- **Technical Complexity:** Very High (video streaming infrastructure)
- **Timeline:** 24+ months

**4. AI-Powered Features**
- **Scouting Reports:** AI analyzes player stats, recommends players to recruit
- **Injury Risk Prediction:** ML model predicts injury risk based on activity
- **Optimal Lineup Suggestions:** AI suggests best team composition
- **Timeline:** 24+ months (requires data collection first)

**5. International Expansion**
- **Markets:** Europe (Spain, Italy, France), South America (Brazil, Argentina)
- **Challenges:** Localization, competition, different football culture
- **Timeline:** 36+ months (only if Israeli market saturated)

---

## 19. TECHNICAL SPECIFICATIONS

### 19.1 Tech Stack Summary

**Mobile App:**
- **Framework:** Flutter 3.6+ (Dart)
- **State Management:** Riverpod 2.6.1
- **Navigation:** GoRouter 14.2.7 (declarative routing)
- **Data Modeling:** Freezed (immutable models) + JSON serialization

**Backend:**
- **Database:** Cloud Firestore (NoSQL, real-time)
- **Authentication:** Firebase Authentication (Email/Password, Google, Apple)
- **Storage:** Firebase Storage (images, videos)
- **Functions:** Cloud Functions (Node.js 20, Gen 2)
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Analytics:** Firebase Analytics + Crashlytics

**Dependencies (Key Packages):**
- `firebase_core`: 3.3.0
- `cloud_firestore`: 5.4.4
- `firebase_auth`: 5.3.1
- `firebase_storage`: 12.3.4
- `firebase_messaging`: 15.0.0
- `riverpod`: 2.6.1
- `go_router`: 14.2.7
- `freezed`: 2.5.7
- `google_mobile_ads`: (future - for AdMob integration)
- `google_maps_flutter`: (future - for map views)

**Development Tools:**
- **IDE:** VS Code / Android Studio
- **Version Control:** Git + GitHub
- **CI/CD:** GitHub Actions (future: auto-deploy to TestFlight/Play Console)
- **Monitoring:** Firebase Crashlytics, Firebase Analytics

---

### 19.2 Versioning & Release Process

**Versioning:**
- **Semantic Versioning:** MAJOR.MINOR.PATCH (e.g., 1.2.3)
- **MAJOR:** Breaking changes (rare)
- **MINOR:** New features, non-breaking changes
- **PATCH:** Bug fixes only

**Build Numbers:**
- iOS: Auto-incremented by CI/CD
- Android: `versionCode` in `build.gradle`

**Release Channels:**
- **Production:** App Store + Google Play (public)
- **Beta:** TestFlight (iOS) + Internal Testing (Android)
- **Alpha:** Internal builds (developers only)

**Release Cadence:**
- **Major:** Every 6 months (1.0, 2.0, etc.)
- **Minor:** Every month (1.1, 1.2, 1.3, etc.)
- **Patch:** As needed (critical bugs only)

---

### 19.3 Deployment Architecture

**Mobile App:**
- **iOS:** App Store (review time: 1-3 days)
- **Android:** Google Play (review time: 1-2 days)

**Backend:**
- **Firestore:** Deployed via Firebase Console (no downtime)
- **Cloud Functions:** Deployed via `firebase deploy --only functions`
- **Storage Rules:** Deployed via Firebase Console
- **Security Rules:** Deployed via `firebase deploy --only firestore:rules`

**Environments:**
- **Production:** Firebase project `kickabout-production`
- **Staging:** Firebase project `kickabout-staging` (future)
- **Development:** Firebase Emulator Suite (local)

---

## 20. ADMIN DASHBOARD VISION

**CRITICAL:** Required for ad-based monetization model

### 20.1 Admin Dashboard Goals

**Primary Goals:**
1. **Ad Campaign Management:** Create, edit, pause, analyze campaigns
2. **Analytics:** View MAU, DAU, revenue, top hubs, top games
3. **User Management:** Ban users, reset passwords, view profiles
4. **Content Moderation:** Delete spam posts, review reported content
5. **Hub Management:** Delete inappropriate hubs, feature hubs

---

### 20.2 Dashboard Architecture

**Framework:** Next.js 15 (React) + Tailwind CSS OR Flutter Web (reuse codebase)

**Recommendation:** Next.js (better web experience, separate concerns)

**Authentication:**
- Admin users: Separate collection `/admins/{adminId}`
- Role: `superadmin`, `moderator`, `sales`
- Firebase Auth for login

**Hosting:** Firebase Hosting or Vercel

**URL:** `admin.kattrick.app` or `kattrick.app/admin`

---

### 20.3 Dashboard Screens

**1. Dashboard Home**
```
┌─────────────────────────────────────────────────────────┐
│ Kattrick Admin Dashboard                     [Profile ▼]│
├─────────────────────────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        │
│ │   MAU   │ │   DAU   │ │ Revenue │ │  Hubs   │        │
│ │  8,234  │ │  2,456  │ │ ₪12,450 │ │   213   │        │
│ │  +12%   │ │  +8%    │ │  +25%   │ │  +5%    │        │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘        │
│                                                          │
│ ┌──────────────────────────────────────────────────┐   │
│ │ User Growth (Last 30 Days)                       │   │
│ │ [Line graph: MAU over time]                      │   │
│ └──────────────────────────────────────────────────┘   │
│                                                          │
│ ┌──────────────────────────────────────────────────┐   │
│ │ Revenue Breakdown                                │   │
│ │ [Pie chart: AdMob vs Direct Sales]               │   │
│ └──────────────────────────────────────────────────┘   │
│                                                          │
│ ┌──────────────────────────────────────────────────┐   │
│ │ Top Hubs (by MAU)                                │   │
│ │ 1. Tel Aviv Football - 450 members               │   │
│ │ 2. Jerusalem Runners - 380 members               │   │
│ │ 3. Haifa United - 320 members                    │   │
│ └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

**2. Ad Campaigns Screen**
```
┌─────────────────────────────────────────────────────────┐
│ Ad Campaigns                       [+ Create Campaign]  │
├─────────────────────────────────────────────────────────┤
│ [Filter: All ▼] [Search campaigns...]                   │
│                                                          │
│ ┌────────────────────────────────────────────────────┐ │
│ │ ● Active  Mike Sport - Summer Sale                │ │
│ │           Impressions: 120k / 250k (48%)           │ │
│ │           Clicks: 2.4k (2.0% CTR)                  │ │
│ │           Spend: ₪2,400 / ₪5,000                   │ │
│ │           [View] [Edit] [Pause]                    │ │
│ └────────────────────────────────────────────────────┘ │
│                                                          │
│ ┌────────────────────────────────────────────────────┐ │
│ │ ⏸ Paused  Elite Academy - Winter Training         │ │
│ │           Impressions: 50k / 100k (50%)            │ │
│ │           [View] [Edit] [Resume]                   │ │
│ └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

**3. Users Screen**
```
┌─────────────────────────────────────────────────────────┐
│ Users                              Total: 8,234          │
├─────────────────────────────────────────────────────────┤
│ [Search users...] [Filter: All ▼] [Export CSV]          │
│                                                          │
│ ┌────────────────────────────────────────────────────┐ │
│ │ 👤 Yossi Cohen (yossi@gmail.com)                  │ │
│ │    Joined: 2025-10-15 · Hubs: 3 · Games: 42       │ │
│ │    [View Profile] [Ban User] [Reset Password]     │ │
│ └────────────────────────────────────────────────────┘ │
│                                                          │
│ ┌────────────────────────────────────────────────────┐ │
│ │ 👤 Sarah Levi (sarah@gmail.com)                   │ │
│ │    Joined: 2025-09-20 · Hubs: 2 · Games: 28       │ │
│ │    [View Profile] [Ban User] [Reset Password]     │ │
│ └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

**4. Content Moderation Screen**
```
┌─────────────────────────────────────────────────────────┐
│ Content Moderation                  Pending: 12          │
├─────────────────────────────────────────────────────────┤
│ ┌────────────────────────────────────────────────────┐ │
│ │ 🚩 Reported Post                                   │ │
│ │    Author: David (david@gmail.com)                 │ │
│ │    Hub: Tel Aviv Football                          │ │
│ │    Content: "Check out this amazing deal! [link]" │ │
│ │    Reported by: 3 users (spam)                     │ │
│ │    [View Full Post] [Delete] [Dismiss]             │ │
│ └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

### 20.4 Dashboard Implementation Timeline

**Phase 1 (Months 4-6): Analytics Only**
- Read-only dashboard (view MAU, DAU, revenue)
- Charts using Recharts/Chart.js
- Firestore queries aggregated daily

**Phase 2 (Months 7-9): Ad Campaign Management**
- Create/edit/pause ad campaigns
- View campaign analytics (impressions, clicks, CTR)
- Targeting UI (region, age, gender)

**Phase 3 (Months 10-12): Full Admin Features**
- User management (ban, reset password)
- Content moderation (delete posts, review reports)
- Hub management (delete hubs, feature hubs)

---

# CONCLUSION

This PRD represents the **MASTER BLUEPRINT** for the Kattrick mobile application, documenting:

✅ **Product Vision:** 100% free, ad-supported football community platform for Israel  
✅ **Complete Feature Inventory:** 40+ features across 86 screens  
✅ **Data Models:** 35+ Firestore models with full specifications  
✅ **Backend Architecture:** 34 Cloud Functions, denormalization strategy, security rules  
✅ **Membership System:** 4-tier role hierarchy with server-managed veteran promotion  
✅ **Game & Event Logic:** Complete lifecycle from creation to multi-match session recording  
✅ **Social & Communication:** Hub feed, comments, recruiting, 3 chat types  
✅ **Notifications:** 9 notification types with FCM integration  
✅ **Monetization Strategy:** Ad-based model with CPM pricing, direct sales roadmap  
✅ **NFRs:** Performance, scalability, security, reliability targets  
✅ **Edge Cases:** Network failures, race conditions, malicious behavior handling  
✅ **Analytics:** KPIs, funnels, Firebase events  
✅ **Gaps:** Missing features, technical debt identified  
✅ **Roadmap:** 3-month, 6-month, 12-month milestones  
✅ **Admin Dashboard Vision:** Critical for ad campaign management  

**Document Stats:**
- **Total Lines:** 10,000+ lines  
- **Sections:** 20 comprehensive sections  
- **Screens Documented:** 86 screens  
- **Data Models:** 35+ models  
- **Cloud Functions:** 34 functions  
- **Use Cases:** 100+ flows documented  

**No developer should need to ask questions** - this PRD is the single source of truth for Kattrick's product definition, architecture, and implementation roadmap.

**Last Updated:** December 5, 2025  
**Version:** 1.0 (Master PRD)

---

# APPENDIX A: HEBREW TRANSLATION GUIDE

| English | Hebrew | Notes |
|---------|--------|-------|
| Hub | האב | (community group) |
| Manager | מנהל | |
| Moderator | מנחה | |
| Veteran | שחקן ותיק | (60+ days member) |
| Member | חבר | |
| Guest | אורח | |
| Game | משחק | |
| Event | אירוע | |
| Join | הצטרף | |
| Leave | עזוב | |
| Create | צור | |
| Edit | ערוך | |
| Delete | מחק | |
| Confirm | אשר | |
| Cancel | בטל | |
| Signup | הרשמה | |
| RSVP | אני בא | ("I'm coming") |
| Team | קבוצה | |
| Player | שחקן | |
| Goalkeeper | שוער | |
| Defender | מגן | |
| Midfielder | קשר | |
| Attacker | חלוץ | |
| Feed | פיד | |
| Post | פוסט | |
| Comment | תגובה | |
| Like | לייק | |
| Chat | צ'אט | |
| Message | הודעה | |
| Notification | התראה | |
| Settings | הגדרות | |
| Profile | פרופיל | |
| Venue | מגרש | (football field) |

---

# APPENDIX B: FIRESTORE COLLECTION STRUCTURE

```
/users/{uid}
  - User document

/users/{uid}/fcm_tokens/tokens
  - FCM token array

/hubs/{hubId}
  - Hub document

/hubs/{hubId}/members/{userId}
  - HubMember document (NEW - Dec 2025 refactor)

/hubs/{hubId}/events/{eventId}
  - HubEvent document

/hubs/{hubId}/feed/posts/items/{postId}
  - FeedPost document
  
  /hubs/{hubId}/feed/posts/items/{postId}/comments/{commentId}
    - Comment document

/hubs/{hubId}/chat/{messageId}
  - ChatMessage document

/hubs/{hubId}/polls/{pollId}
  - Poll document
  
  /hubs/{hubId}/polls/{pollId}/votes/{voteId}
    - PollVote document

/games/{gameId}
  - Game document

/games/{gameId}/signups/{userId}
  - GameSignup document

/games/{gameId}/chat/{messageId}
  - ChatMessage document

/venues/{venueId}
  - Venue document

/notifications/{userId}/items/{notificationId}
  - Notification document

/private_messages/{conversationId}/messages/{messageId}
  - PrivateMessage document

/feedPosts/{postId}
  - FeedPost document (regional feed - public)

/adCampaigns/{campaignId}
  - AdCampaign document (future)

/adImpressions/{impressionId}
  - AdImpression document (future)

/adClicks/{clickId}
  - AdClick document (future)
```

---

**END OF PRD**

