# Kickadoor - Soccer Social Network

A React/TypeScript implementation of Kickadoor, a social network for neighborhood soccer players in Israel.

## 🎨 Design System

### Colors
- **Primary Blue**: `#1976D2` (Main actions, headers)
- **Secondary Green**: `#4CAF50` (Success, field/grass theme)
- **Accent Purple**: `#9C27B0` (Special features, gradients)
- **Background**: `#F5F5F5` (Light gray, Hattrick-inspired)
- **Text Primary**: `#212121`
- **Text Secondary**: `#757575`

### Typography
- **Headings**: Orbitron (Geometric, athletic, uppercase with letter-spacing)
- **Subheadings**: Montserrat (Bold, clean)
- **Body**: Inter (Readable, modern)

## 📱 App Structure

### Authentication
- **LoginScreen**: Email/password + social login options

### Main Navigation (Bottom Bar)
1. **Home** - Dashboard with stats, recommendations, upcoming games
2. **Games** - List of all games, create new games
3. **Map** - Discover nearby hubs and games
4. **Hubs** - Browse all soccer communities
5. **Profile** - Player profile with stats and analytics

### Key Screens

#### Home Dashboard
- User profile card with availability toggle
- Quick action buttons (Create game, Find players, Discover hubs)
- Performance stats with circular progress rings
- My Hubs section
- AI player recommendations
- Upcoming games list

#### Players Board
- Searchable list of all players
- Filter options (position, city, rating, availability)
- Player cards with avatar, name, rating, position, distance
- Status indicators (available/busy/not available)

#### Hubs Board
- List/Map view toggle
- Hub cards with member count, location, activity
- Search and filter capabilities

#### Hub Detail
- Tabbed interface:
  - **Overview**: Members grid, hub info
  - **Games**: List of hub games
  - **Feed**: Social posts and updates
  - **Chat**: Hub chat room

#### Games List
- Upcoming games section
- Past games section
- Game status badges
- Player count indicators
- Quick create game button

#### Player Profile
- Large avatar with status ring
- Rating display with progress bar
- Rating history line chart
- Advanced analytics radar chart (8 skills)
- Follow/Edit profile actions
- Followers/Following counts

#### Map View
- Interactive map placeholder
- Nearby hubs list
- Nearby games list
- Distance indicators

## 🧩 Key Components

### Custom Components
- **FuturisticCard**: White cards with subtle borders and shadows
- **GradientButton**: Buttons with blue/green/purple gradients
- **PlayerAvatar**: Circular avatars with colored status rings
- **StatsRing**: Circular progress indicators for stats
- **StatsDashboard**: Grid of stats rings for performance metrics
- **PlayerRecommendationCard**: AI-powered player suggestions with glow effect
- **BottomNavigation**: Fixed bottom nav bar with 5 main sections

### UI Libraries
- **Shadcn/ui**: Pre-built accessible components
- **Recharts**: Line charts and radar charts for analytics
- **Lucide React**: Clean, modern icons

## 📊 Data Models

### User
- uid, name, email, city
- availabilityStatus (available/busy/notAvailable)
- currentRankScore (1-10)
- preferredPosition (Goalkeeper/Defender/Midfielder/Forward)
- totalParticipations

### Hub (Soccer Community)
- hubId, name, description
- memberIds array
- location (lat/lng)
- city, radius

### Game
- gameId, hubId, gameDate
- location, locationPoint
- teamCount (2, 3, or 4)
- status (teamSelection/inProgress/completed/cancelled)
- signupCount, maxPlayers

### Feed Post
- postId, hubId, authorId
- type (text/game/photo)
- content, photoUrls
- likes, commentCount

## 🌍 RTL Support

All screens support Right-to-Left layout for Hebrew:
- `dir="rtl"` on main containers
- Hebrew labels and text
- Mirrored navigation flow
- Right-aligned text

## 🎯 Key Features

1. **Social Networking**: Follow players, join hubs, post updates
2. **Game Management**: Create games, track signups, manage teams
3. **Player Discovery**: AI-powered recommendations, search/filter
4. **Performance Tracking**: Rating system, stats dashboard, analytics
5. **Location-Based**: Find nearby hubs and games on map
6. **Real-time Updates**: Game status, availability, chat

## 🚀 Navigation Flow

```
Login
  ↓
Home Dashboard
  ├→ Players Board → Player Profile
  ├→ Hubs Board → Hub Detail → (Games/Feed/Chat)
  ├→ Games List → Game Detail
  ├→ Map View → (Hubs/Games)
  └→ Profile (Own) → Edit Profile
```

## 💡 Future Enhancements

- Game detail screen with team maker
- Stats logger for post-game input
- Real-time chat implementation
- Interactive map with Google Maps
- Push notifications
- Advanced filtering and search
- Tournament/league management
- Photo galleries for games

---

**Built with React, TypeScript, Tailwind CSS, and Shadcn/ui**
