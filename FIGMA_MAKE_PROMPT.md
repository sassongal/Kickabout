# 🎨 Kickadoor - Complete Design System & App Structure for Figma Make

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

### Reusable Widgets

1. **FuturisticScaffold**: App bar with logo, title, actions
2. **FuturisticCard**: Card with border, rounded corners
3. **GradientButton**: Button with blue→light blue gradient
4. **PlayerAvatar**: Circular avatar with navigation to profile
5. **OptimizedImage**: Cached network image with loading/error states
6. **StatsDashboard**: Progress rings, charts, metrics
7. **PlayerRecommendationCard**: Card with avatar, name, rating, match reasons
8. **GamePhotosGallery**: Grid of game photos with full-screen viewer
9. **AvailabilityToggle**: Dropdown to set availability status
10. **KickaBallLogo**: App logo component

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
- **Border Radius**: 8px, 12px, 16px, 24px
- **Shadows**: Minimal (0-2px elevation)
- **Icons**: Material Icons, 24px default
- **Images**: Avatar (circular), Photos (rounded corners)

---

## 📝 Additional Notes

### RTL (Right-to-Left) Support
- All layouts must support Hebrew RTL
- Text alignment: Right for Hebrew
- Icons and buttons: Mirrored for RTL
- Navigation: Right-to-left flow

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

### Phase 1 (Core)
1. Design system (colors, typography, components)
2. Authentication screens
3. Home dashboard
4. Player/Hub lists

### Phase 2 (Features)
5. Hub detail with tabs
6. Game screens
7. Profile with charts
8. Social feed

### Phase 3 (Advanced)
9. Maps integration
10. Chat interfaces
11. Gamification elements
12. Admin screens

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

