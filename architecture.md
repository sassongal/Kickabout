# Kickabout - Neighborhood Soccer App Architecture

## Overview
A comprehensive neighborhood soccer application focusing on fair team formation, performance tracking, and community engagement.

## Core Features (MVP)
1. **Player Management**: Add/remove players with basic profiles
2. **Team Formation**: Snake draft algorithm for balanced teams
3. **Statistics Tracking**: 6-parameter rating system (Defense, Passing, Shooting, Leadership, Team Play, Lack of Errors)
4. **Ranking System**: Weighted scoring with decay factor for recent games
5. **Game History**: Track past games and player performance

## Technical Stack
- **Frontend**: Flutter with Material 3 design
- **Data Storage**: Local storage using shared_preferences (MVP phase)
- **State Management**: Built-in StatefulWidget and Provider pattern
- **Charts**: fl_chart for ranking visualization

## Data Models

### Player
```dart
class Player {
  String id;
  String name;
  String? photoUrl;
  double currentRankScore;
  List<RankingEntry> rankingHistory;
  PlayerAttributes attributes;
  DateTime createdAt;
}
```

### Game
```dart
class Game {
  String id;
  DateTime gameDate;
  List<String> playerIds;
  Map<String, Team> teams;
  GameStatus status;
  List<PlayerStats> gameStats;
}
```

### PlayerStats
```dart
class PlayerStats {
  String playerId;
  String gameId;
  double defense;
  double passing;
  double shooting;
  double leadership;
  double teamPlay;
  double lackOfErrors;
  bool isVerified;
}
```

## App Structure
```
lib/
├── main.dart
├── theme.dart
├── models/
│   ├── player.dart
│   ├── game.dart
│   └── player_stats.dart
├── services/
│   ├── player_service.dart
│   ├── game_service.dart
│   └── ranking_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── player_management_screen.dart
│   ├── team_formation_screen.dart
│   ├── stats_input_screen.dart
│   └── player_profile_screen.dart
├── widgets/
│   ├── player_card.dart
│   ├── team_display.dart
│   └── rating_input.dart
└── utils/
    └── team_algorithm.dart
```

## Algorithm Implementation

### Snake Draft Team Formation
1. Sort players by currentRankScore (descending)
2. Allocate using snake pattern: A→B→A→B then B→A→B→A
3. Calculate team balance (difference < 10% threshold)
4. Provide shuffle option if imbalanced

### Ranking Calculation
```
ComplexScore = (w_defense * Defense) + (w_passing * Passing) + 
               (w_shooting * Shooting) + (w_leadership * Leadership) + 
               (w_teamPlay * TeamPlay) + (w_lackOfErrors * LackOfErrors)

Final Rank = Weighted average of last N games with decay factor
```

## Development Phases
1. **Phase 1**: Core player management and team formation
2. **Phase 2**: Statistics tracking and ranking system
3. **Phase 3**: Enhanced UI, charts, and game history

## File Count Target
Target: 10-12 files total for maintainability and simplicity.