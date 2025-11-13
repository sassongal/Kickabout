# 🎨 Kickadoor - Complete Design System & App Structure for Figma Make

> **Note**: This prompt references the existing Figma design output located in `/Kickadoor Mobile App Design/` folder, which contains React/TypeScript implementations of all components. Use these as reference for exact styling, component structure, and implementation details.

## 📱 App Overview

**Kickadoor** is a social network for neighborhood soccer players in Israel. It connects players, Hubs (soccer communities), and fields, enabling users to find local games, organize matches, build communities, and track performance.

### Key Characteristics
- **Target Audience**: Soccer players in Israel, ages 16-45
- **Language**: Hebrew (RTL - Right-to-Left)
- **Platform**: Flutter (Cross-platform: Web, iOS, Android)
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Messaging)
- **Design Style**: Modern, clean, inspired by Hattrick.org with blue, green, and purple accents

---

## 🛠️ Tech Stack

### Frontend Framework
- **Flutter** (Dart) - Cross-platform mobile/web framework
- **Riverpod** - State management
- **GoRouter** - Declarative routing
- **Material 3** - UI design system

### Backend & Services
- **Firebase Authentication** - Email/Password + Anonymous auth
- **Cloud Firestore** - NoSQL real-time database
- **Firebase Storage** - Image/file storage
- **Firebase Cloud Messaging** - Push notifications
- **Google Maps Platform** - Maps, geocoding, location services

### Key Libraries
- `fl_chart` - Charts and data visualization
- `cached_network_image` - Optimized image loading
- `image_picker` - Image selection
- `geolocator` - GPS location services
- `google_maps_flutter` - Maps integration
- `google_fonts` - Typography (Orbitron, Inter, Montserrat)

---

## 🎨 Design System

### Color Palette (Hattrick.org inspired + Blue/Purple)

#### Primary Colors
- **Primary Blue**: `#1976D2` (RGB: 25, 118, 210)
- **Primary Light**: `#42A5F5` (RGB: 66, 165, 245)
- **Primary Dark**: `#1565C0` (RGB: 21, 101, 192)

#### Secondary Colors
- **Secondary Green**: `#4CAF50` (RGB: 76, 175, 80) - Grass green like Hattrick
- **Secondary Light**: `#81C784` (RGB: 129, 199, 132)
- **Secondary Dark**: `#388E3C` (RGB: 56, 142, 60)

#### Accent Colors
- **Accent Purple**: `#9C27B0` (RGB: 156, 39, 176)
- **Accent Light**: `#BA68C8` (RGB: 186, 104, 200)
- **Accent Dark**: `#7B1FA2` (RGB: 123, 31, 162)

#### Background & Surface
- **Background**: `#F5F5F5` (Light gray/white - Hattrick style)
- **Surface**: `#FFFFFF` (White)
- **Surface Variant**: `#E0E0E0` (Light gray)

#### Text Colors
- **Text Primary**: `#212121` (Dark gray/black)
- **Text Secondary**: `#757575` (Medium gray)
- **Text Tertiary**: `#9E9E9E` (Light gray)

#### Status Colors
- **Success**: `#4CAF50` (Green)
- **Warning**: `#FF9800` (Orange)
- **Error**: `#E53935` (Red)
- **Info**: `#1976D2` (Blue)

### Typography

#### Headings (Orbitron - Geometric, Athletic)
- **Heading 1**: Orbitron, 32px, Bold, Letter-spacing: 1.2
- **Heading 2**: Orbitron, 24px, Semi-bold (600), Letter-spacing: 0.8
- **Heading 3**: Orbitron, 20px, Semi-bold (600), Letter-spacing: 0.5
- **Tech Headline**: Orbitron, 18px, Bold, Letter-spacing: 2.0, Color: Secondary Green

#### Body Text (Inter - Clean, Modern)
- **Body Large**: Inter, 16px, Normal, Line-height: 1.5
- **Body Medium**: Inter, 14px, Normal, Line-height: 1.5
- **Body Small**: Inter, 12px, Normal, Line-height: 1.4

#### Labels (Montserrat - Bold, Geometric)
- **Label Large**: Montserrat, 14px, Semi-bold (600), Letter-spacing: 0.5
- **Label Medium**: Montserrat, 12px, Medium (500), Letter-spacing: 0.3
- **Label Small**: Montserrat, 10px, Medium (500), Letter-spacing: 0.5

### UI Elements

#### Buttons
- **Elevated Button**: 
  - Background: Primary Blue
  - Border-radius: 12px
  - Padding: 24px horizontal, 16px vertical
  - Elevation: 0 (flat design)
  - Text: Label Large (Montserrat)

- **Outlined Button**:
  - Border: 2px Secondary Green
  - Border-radius: 12px
  - Padding: 24px horizontal, 16px vertical
  - Text: Label Large

- **Gradient Button**:
  - Gradient: Primary Blue → Primary Light (top-left to bottom-right)
  - Border-radius: 12px
  - Shadow: Minimal

#### Cards
- **Card Style**:
  - Background: White (#FFFFFF)
  - Border-radius: 16px
  - Border: 1px Surface Variant (#E0E0E0)
  - Elevation: 0
  - Padding: 16px

#### Input Fields
- **Text Field**:
  - Background: Surface Variant (#E0E0E0)
  - Border-radius: 12px
  - Border: 1px Surface Variant (default)
  - Focus Border: 2px Secondary Green
  - Label: Label Medium (Montserrat)

#### Icons
- **Icon Style**: Material Icons
- **Size**: 24px default
- **Color**: Text Secondary (#757575)

### Design Principles
- **Clean Geometry**: Rounded rectangles, minimal shadows
- **Data-Visual Cues**: Progress rings, radar charts
- **Kinetic UI**: Subtle animations, micro-interactions
- **Grid-Based Layout**: Consistent spacing (16px default)
- **RTL Support**: All layouts support Right-to-Left (Hebrew)

---

## 📊 Data Models

### User Model
```dart
{
  uid: String (required),
  name: String (required),
  email: String (required),
  photoUrl: String? (optional),
  phoneNumber: String? (optional),
  city: String? (optional),
  availabilityStatus: String (default: 'available'), // 'available', 'busy', 'notAvailable'
  createdAt: DateTime (required),
  hubIds: List<String> (default: []),
  currentRankScore: double (default: 5.0), // 1.0-10.0
  preferredPosition: String (default: 'Midfielder'), // 'Goalkeeper', 'Defender', 'Midfielder', 'Forward'
  totalParticipations: int (default: 0),
  location: GeoPoint? (optional),
  geohash: String? (optional)
}
```

### Hub Model (Soccer Community)
```dart
{
  hubId: String (required),
  name: String (required),
  description: String? (optional),
  createdBy: String (required), // userId
  createdAt: DateTime (required),
  memberIds: List<String> (default: []),
  settings: Map<String, dynamic> (default: {'ratingMode': 'basic'}),
  roles: Map<String, String> (default: {}), // userId -> 'manager' | 'moderator' | 'member'
  location: GeoPoint? (optional),
  geohash: String? (optional),
  radius: double? (optional) // km
}
```

### Game Model
```dart
{
  gameId: String (required),
  createdBy: String (required), // userId
  hubId: String (required),
  gameDate: DateTime (required),
  location: String? (optional), // Legacy text
  locationPoint: GeoPoint? (optional), // Geographic location
  geohash: String? (optional),
  venueId: String? (optional),
  teamCount: int (default: 2), // 2, 3, or 4 teams
  status: GameStatus (default: 'teamSelection'), // 'teamSelection', 'inProgress', 'completed', 'cancelled'
  photoUrls: List<String> (default: []),
  createdAt: DateTime (required),
  updatedAt: DateTime (required),
  // Recurring games
  isRecurring: bool (default: false),
  parentGameId: String? (optional),
  recurrencePattern: String? (optional), // 'weekly', 'biweekly', 'monthly'
  recurrenceEndDate: DateTime? (optional)
}
```

### Feed Post Model
```dart
{
  postId: String (required),
  hubId: String (required),
  authorId: String (required), // userId
  type: String (required), // 'text', 'game', 'photo'
  content: String? (optional),
  photoUrls: List<String> (default: []),
  gameId: String? (optional),
  createdAt: DateTime (required),
  likes: List<String> (default: []), // userIds
  commentCount: int (default: 0)
}
```

---

## 📱 Screens & Features

### 1. Authentication Screens
- **Splash Screen**: Animated logo, loading screen image
- **Login Screen**: Email/Password, Anonymous login option
- **Register Screen**: Email, password, name, phone number

### 2. Home Dashboard (`HomeScreenFuturistic`)
**Main Features**:
- User profile card with avatar, name, availability toggle
- Stats dashboard (current rank, participations, recent performance)
- Upcoming games list
- My Hubs section (Hubs user created + Hubs user is member of)
- AI player recommendations
- Quick actions (Create game, Find players, Discover hubs)

**UI Elements**:
- Gradient buttons
- Futuristic cards
- Progress rings for stats
- Player recommendation cards with avatars

### 3. Players Board (`PlayersListScreen`)
**Features**:
- List of all players with filters
- Search by name
- Filter by: City, Position, Rating range, Availability, Distance
- Sort by: Rating, Distance, Name
- Player cards showing: Avatar, Name, Rating, Position, Distance, Availability status

### 4. Hubs Board (`HubsBoardScreen`)
**Features**:
- List of all Hubs
- Map view showing Hub locations
- Filter by: City, Distance, Activity level
- Hub cards showing: Name, Member count, Distance, Activity indicators
- Toggle between list and map view

### 5. Hub Detail Screen (`HubDetailScreen`)
**Tabs**:
- **Overview**: Hub info, member list, quick actions
- **Games**: List of Hub games
- **Feed**: Social feed posts
- **Chat**: Real-time chat
- **Events**: Hub events (tournaments, training sessions)

**Manager Actions** (if user is manager):
- Create game
- Add manual player (for players without app)
- Manage roles (assign manager/moderator)
- Hub settings
- Scouting (AI player discovery)
- Create Hub event

### 6. Game Screens
- **Game List**: All games user is part of
- **Game Calendar**: Monthly calendar view of games
- **Create Game**: Form with date, time, location (map picker), team count, recurring options
- **Game Detail**: Game info, teams, signups, stats, photos, chat
- **Team Maker**: AI-powered balanced team formation
- **Stats Logger**: Input game statistics (goals, assists, saves, cards, MVP votes)

### 7. Profile Screens
- **Player Profile**: 
  - Avatar, name, city, position, availability
  - Current rating and rating history (Line chart)
  - Advanced analytics (Radar chart for skills, trend indicators)
  - Game history
  - Followers/Following count
  - Edit profile button

- **Edit Profile**: Update name, photo, city, position, phone

### 8. Social Features
- **Feed Screen**: Social feed with posts, photos, game recaps
- **Post Detail**: View post, comments, likes
- **Create Post**: Text + photo upload
- **Hub Chat**: Real-time chat for Hub members
- **Private Messages**: One-on-one conversations
- **Notifications**: In-app notifications list
- **Followers/Following**: Lists of user connections

### 9. Location Screens
- **Discover Hubs**: Find Hubs near user location
- **Map Screen**: Interactive map with Hubs and games
- **Map Picker**: Select location for game/Hub creation

### 10. Gamification
- **Leaderboard**: Top players by rating, points, participations
- **Badges & Achievements**: Visual badges for milestones
- **Points System**: Points for games, ratings, social activity

### 11. Admin
- **Generate Dummy Data**: Create test users, Hubs, games with realistic data

### 12. Scouting (AI Player Discovery)
- **Scouting Screen**: For Hub managers
- Filters: Position, Rating range, Distance, Availability
- AI match score (0-100) with reasons
- Quick invite to game or Hub

---

## 🧩 Key UI Components

### Reusable Widgets (Figma Output Reference)

> **Reference**: All components are implemented in `/Kickadoor Mobile App Design/src/components/`

1. **FuturisticCard** (`FuturisticCard.tsx`)
   - White background (#FFFFFF)
   - Border: 1.5px #E0E0E0
   - Border-radius: 16px (rounded-lg)
   - Shadow: shadow-md (or glow effect for special cards)
   - Padding: 16px (p-4)
   - Optional `glow` prop for special highlighting

2. **GradientButton** (`GradientButton.tsx`)
   - Variants: `primary` (blue), `secondary` (green), `accent` (purple)
   - Gradient: `bg-gradient-to-r from-[#1976D2] to-[#1565C0]` (primary)
   - Text: Uppercase, Montserrat bold, tracking-wide
   - Border-radius: 12px (rounded-lg)
   - Padding: 24px horizontal, 12px vertical (px-6 py-3)
   - Supports icon prop

3. **PlayerAvatar** (`PlayerAvatar.tsx`)
   - Circular avatar with colored status ring
   - Sizes: `sm`, `md`, `lg`, `xl`
   - Status colors: Green (available), Orange (busy), Red (notAvailable)
   - Ring thickness varies by size

4. **StatsDashboard** (`StatsDashboard.tsx`)
   - Grid layout: 2 columns
   - Uses `StatsRing` components
   - Heading: Orbitron, uppercase, tracking-widest
   - Stats: Games Played (blue), Wins (green), Goals (purple), Avg Rating (orange)

5. **StatsRing** (`StatsRing.tsx`)
   - Circular progress indicator
   - Customizable color
   - Shows value/maxValue as percentage
   - Label below ring

6. **PlayerRecommendationCard** (`PlayerRecommendationCard.tsx`)
   - Special card with glow effect
   - Shows player avatar, name, rating, position
   - Match score percentage
   - Match reasons as chips
   - Clickable with hover effect

7. **HomeDashboard** (`HomeDashboard.tsx`)
   - Main dashboard layout
   - User profile card with availability toggle
   - Quick action buttons (3-column grid)
   - Stats dashboard section
   - My Hubs section
   - AI recommendations section
   - Upcoming games list

8. **BottomNavigation** (`BottomNavigation.tsx`)
   - Fixed bottom navigation bar
   - 5 main sections: Home, Games, Map, Hubs, Profile
   - Active state highlighting
   - Icons from Lucide React

9. **PlayerProfile** (`PlayerProfile.tsx`)
   - Large avatar with status ring
   - Rating display with progress bar
   - Line chart for rating history (Recharts)
   - Radar chart for skills (8 skills)
   - Follow/Edit profile button

10. **HubDetail** (`HubDetail.tsx`)
    - Tabbed interface (Overview, Games, Feed, Chat)
    - Member grid
    - Hub info card
    - Manager actions section

11. **PlayersBoard** (`PlayersBoard.tsx`)
    - Searchable list
    - Filter chips
    - Player cards with avatar, rating, position, distance
    - Status indicators

12. **HubsBoard** (`HubsBoard.tsx`)
    - List/Map view toggle
    - Hub cards with member count, location
    - Activity indicators

### UI Component Library (Shadcn/ui)

> **Reference**: All base UI components in `/Kickadoor Mobile App Design/src/components/ui/`

The design uses Shadcn/ui components built on Radix UI:
- **Button** (`button.tsx`): Base button with variants
- **Card** (`card.tsx`): Base card component
- **Input** (`input.tsx`): Text input fields
- **Switch** (`switch.tsx`): Toggle switches
- **Tabs** (`tabs.tsx`): Tabbed interfaces
- **Progress** (`progress.tsx`): Progress bars
- **Avatar** (`avatar.tsx`): Avatar component
- **Badge** (`badge.tsx`): Status badges
- **Dialog** (`dialog.tsx`): Modal dialogs
- **Select** (`select.tsx`): Dropdown selects
- **Chart** (`chart.tsx`): Chart wrapper for Recharts
- And 40+ more components...

### Data Visualization

- **Recharts** library for charts:
  - `LineChart` - Rating history over time
  - `RadarChart` - Skills visualization (8 skills)
  - `ResponsiveContainer` - Responsive chart wrapper

### Charts & Data Visualization
- **Line Chart** (fl_chart): Rating history over time
- **Radar Chart** (fl_chart): Player skills visualization
- **Progress Ring**: Circular progress indicators
- **Data Ring**: Stats visualization with rings

---

## 🗺️ Navigation Flow

### Main Navigation (Bottom Bar)
1. **Home** - Dashboard
2. **Games** - Game list/calendar
3. **Map** - Location discovery
4. **Hubs** - Hubs board
5. **Profile** - User profile

### Route Structure
```
/ (Home)
├── /auth (Login)
├── /register (Register)
├── /players (Players Board)
├── /hubs-board (Hubs Board)
├── /hubs
│   ├── /create (Create Hub)
│   └── /:id (Hub Detail)
│       ├── /settings (Hub Settings)
│       ├── /manage-roles (Manage Roles)
│       ├── /scouting (AI Scouting)
│       ├── /feed/:postId (Post Detail)
│       └── /create-post (Create Post)
├── /games
│   ├── /create (Create Game)
│   └── /:id (Game Detail)
│       ├── /team-maker (Team Maker)
│       ├── /stats (Stats Logger)
│       ├── /basic-rating (Basic Rating)
│       └── /chat (Game Chat)
├── /profile/:uid (Player Profile)
│   └── /edit (Edit Profile)
├── /notifications (Notifications)
├── /messages (Messages List)
│   └── /:conversationId (Private Chat)
├── /calendar (Game Calendar)
└── /admin/generate-dummy-data (Admin)
```

---

## 🔥 Firebase Integration

### Collections Structure
```
/users/{uid}
  - User data

/hubs/{hubId}
  - Hub data
  /hubs/{hubId}/feed/{postId}
    - Feed posts
  /hubs/{hubId}/chat/{messageId}
    - Chat messages

/games/{gameId}
  - Game data
  /games/{gameId}/signups/{signupId}
    - Game signups
  /games/{gameId}/teams/{teamId}
    - Teams
  /games/{gameId}/events/{eventId}
    - Game events

/notifications/{userId}/items/{notificationId}
  - User notifications

/ratings/{userId}/snapshots/{snapshotId}
  - Rating history
```

### Storage Paths
```
profile_photos/{userId}/{timestamp}.jpg
game_photos/{gameId}/{timestamp}.jpg
hubs/{hubId}/feed/photos/{timestamp}.jpg
```

---

## 🎯 Design Requirements for Figma

### Components to Create

1. **Buttons**
   - Primary (Elevated) - Blue gradient
   - Secondary (Outlined) - Green border
   - Text button
   - Icon button

2. **Cards**
   - Player card
   - Hub card
   - Game card
   - Post card
   - Stats card

3. **Navigation**
   - Bottom navigation bar (5 items)
   - App bar with logo
   - Tab bar

4. **Forms**
   - Text input
   - Date picker
   - Dropdown/Select
   - Checkbox
   - Radio button

5. **Data Visualization**
   - Progress ring
   - Line chart
   - Radar chart
   - Stats dashboard

6. **Lists**
   - Player list item
   - Game list item
   - Notification item
   - Message item

7. **Modals & Dialogs**
   - Alert dialog
   - Bottom sheet
   - Full-screen modal

### Screen Templates Needed

1. **Splash Screen** - Logo animation
2. **Login/Register** - Auth forms
3. **Home Dashboard** - Main screen layout
4. **Players Board** - List with filters
5. **Hubs Board** - List + Map view
6. **Hub Detail** - Tabbed interface
7. **Game Detail** - Game info + teams
8. **Player Profile** - Profile with charts
9. **Feed Screen** - Social feed
10. **Chat Screen** - Message interface

### Design Tokens

- **Spacing**: 4px, 8px, 12px, 16px, 24px, 32px
- **Border Radius**: 8px (rounded), 12px (rounded-lg), 16px (rounded-xl), 24px (rounded-2xl)
- **Shadows**: 
  - `shadow-md` - Default card shadow
  - `shadow-[0_0_20px_rgba(76,175,80,0.15)]` - Glow effect for special cards
- **Icons**: Lucide React, 24px default (w-6 h-6)
- **Images**: Avatar (circular), Photos (rounded corners 8px)
- **Gradients**: 
  - Primary: `from-[#1976D2] to-[#1565C0]`
  - Secondary: `from-[#4CAF50] to-[#388E3C]`
  - Accent: `from-[#9C27B0] to-[#7B1FA2]`

### CSS Variables (from globals.css)

The design uses CSS custom properties defined in `globals.css`:
```css
--primary-blue: #1976D2;
--primary-light: #42A5F5;
--primary-dark: #1565C0;
--secondary-green: #4CAF50;
--secondary-light: #81C784;
--secondary-dark: #388E3C;
--accent-purple: #9C27B0;
--accent-light: #BA68C8;
--accent-dark: #7B1FA2;
--bg-main: #F5F5F5;
--surface: #FFFFFF;
--surface-variant: #E0E0E0;
--text-primary: #212121;
--text-secondary: #757575;
--text-tertiary: #9E9E9E;
```

### Tailwind CSS Classes

The Figma output uses Tailwind CSS with custom configuration:
- Background: `bg-[#F5F5F5]` for main background
- Text colors: `text-[#212121]`, `text-[#757575]`, `text-[#9E9E9E]`
- Borders: `border-[#E0E0E0]` for card borders
- Gradients: `bg-gradient-to-r` or `bg-gradient-to-br`
- RTL Support: `dir="rtl"` on main containers

---

## 📝 Additional Notes

### RTL (Right-to-Left) Support
- All layouts must support Hebrew RTL
- Implementation: `dir="rtl"` on main containers
- Text alignment: Right for Hebrew (automatic with RTL)
- Icons and buttons: Mirrored for RTL (Lucide React handles this)
- Navigation: Right-to-left flow
- Example from code: `<div className="min-h-screen bg-[#F5F5F5] pb-20" dir="rtl">`

### Figma Output Reference

The `/Kickadoor Mobile App Design/` folder contains:
- **React/TypeScript** implementations of all screens
- **Component library** with exact styling
- **Type definitions** in `src/types/index.ts`
- **Mock data** in `src/data/mockData.ts`
- **Global styles** in `src/styles/globals.css`
- **Shadcn/ui components** in `src/components/ui/`

**Key Files to Reference**:
- `src/App.tsx` - Main app structure and navigation
- `src/components/HomeDashboard.tsx` - Dashboard implementation
- `src/components/PlayerProfile.tsx` - Profile with charts
- `src/components/HubDetail.tsx` - Hub detail with tabs
- `src/components/GradientButton.tsx` - Button component
- `src/components/FuturisticCard.tsx` - Card component
- `src/components/StatsDashboard.tsx` - Stats visualization
- `src/components/StatsRing.tsx` - Circular progress
- `src/components/PlayerRecommendationCard.tsx` - AI recommendations
- `src/components/BottomNavigation.tsx` - Bottom nav bar

**Figma Design File**: https://www.figma.com/design/w4idy9zy89LHZrtIGQuc1B/Kickadoor-Mobile-App-Design

### Responsive Design
- Mobile-first approach
- Breakpoints: 360px (small), 414px (medium), 768px (tablet)
- Optimized for Samsung S23 Ultra and similar devices

### Accessibility
- High contrast text
- Touch targets: Minimum 44x44px
- Screen reader support
- Color-blind friendly (don't rely only on color)

### Performance Considerations
- Lazy loading for images
- Optimized asset sizes
- Minimal animations (smooth 60fps)
- Efficient list rendering

---

## 🚀 Implementation Priority

### Phase 1 (Core) - ✅ Already Implemented in Figma
1. ✅ Design system (colors, typography, components)
2. ✅ Authentication screens (`LoginScreen.tsx`)
3. ✅ Home dashboard (`HomeDashboard.tsx`)
4. ✅ Player/Hub lists (`PlayersBoard.tsx`, `HubsBoard.tsx`)

### Phase 2 (Features) - ✅ Already Implemented in Figma
5. ✅ Hub detail with tabs (`HubDetail.tsx`)
6. ⚠️ Game screens (`GamesList.tsx` - basic implementation)
7. ✅ Profile with charts (`PlayerProfile.tsx`)
8. ⚠️ Social feed (partially in `HubDetail.tsx`)

### Phase 3 (Advanced) - ⚠️ Partially Implemented
9. ⚠️ Maps integration (`MapView.tsx` - placeholder)
10. ⚠️ Chat interfaces (in `HubDetail.tsx` - basic)
11. ⚠️ Gamification elements (StatsDashboard implemented)
12. ❌ Admin screens (not in Figma output)

### What's Already Built (Figma Output)
- ✅ Complete component library
- ✅ All main screens with layouts
- ✅ Navigation structure
- ✅ RTL support
- ✅ Responsive design
- ✅ Data visualization (charts)
- ✅ Mock data structure

### What Needs Enhancement
- ⚠️ Interactive map (currently placeholder)
- ⚠️ Real-time chat UI (basic structure exists)
- ⚠️ Game detail screen (not in Figma output)
- ⚠️ Stats logger screen (not in Figma output)
- ⚠️ Team maker screen (not in Figma output)
- ❌ Admin screens
- ❌ Scouting screen

---

## 📞 Contact & Resources

- **App Name**: Kickadoor (קיקאדור)
- **Package Name**: kickadoor
- **Version**: 1.0.0
- **Contact**: Gal - you@joya-tech.net

### Key Files Reference
- Theme: `lib/theme/futuristic_theme.dart`
- Constants: `lib/core/constants.dart`
- Models: `lib/models/`
- Screens: `lib/screens/`
- Widgets: `lib/widgets/`

---

**This document provides everything needed to rebuild the Kickadoor design in Figma. All colors, typography, components, and screen structures are detailed above.**

