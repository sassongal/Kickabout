# ⏱️ Kattrick - Stopwatch Feature Documentation
## Game Stopwatch & Utility Stopwatch

> **Created:** November 30, 2025  
> **Version:** 1.0  
> **Status:** ✅ Implemented

---

## 🎯 Overview

The Stopwatch feature provides two main utilities:

1. **StopwatchUtility** - General-purpose stopwatch for any use case
2. **GameStopwatch** - Specialized stopwatch for recording game events in real-time

---

## 📦 Components

### 1. StopwatchUtility (`lib/utils/stopwatch_utility.dart`)

**Purpose:** General-purpose stopwatch utility

**Features:**
- ✅ Start/Stop/Pause/Resume
- ✅ Reset
- ✅ Elapsed time tracking
- ✅ Formatting helpers (MM:SS, HH:MM:SS, human-readable)
- ✅ ChangeNotifier for UI updates

**Usage:**
```dart
final stopwatch = StopwatchUtility();

// Start
stopwatch.start();

// Pause
stopwatch.pause();

// Resume
stopwatch.resume();

// Stop
stopwatch.stop();

// Reset
stopwatch.reset();

// Get elapsed time
final elapsed = stopwatch.elapsed;

// Format time
final formatted = StopwatchUtility.formatMMSS(elapsed); // "05:30"
```

---

### 2. GameStopwatch (`lib/utils/game_stopwatch.dart`)

**Purpose:** Game-specific stopwatch for recording events during active games

**Features:**
- ✅ Stopwatch for game duration
- ✅ Record goals with timestamps
- ✅ Record assists with timestamps
- ✅ Record cards (yellow/red)
- ✅ Record saves (for goalkeepers)
- ✅ Export events as GameEvent list
- ✅ Score tracking per team
- ✅ Event filtering (by team, by player)

**Usage:**
```dart
final gameStopwatch = GameStopwatch(
  gameId: 'game123',
  hubId: 'hub456',
);

// Start game
gameStopwatch.start();

// Record a goal
gameStopwatch.recordGoal(
  playerId: 'player123',
  playerName: 'דוד כהן',
  team: 'A',
  assistPlayerId: 'player456', // Optional
  assistPlayerName: 'יוסי לוי', // Optional
);

// Record an assist
gameStopwatch.recordAssist(
  playerId: 'player456',
  playerName: 'יוסי לוי',
  team: 'A',
  goalPlayerId: 'player123',
  goalPlayerName: 'דוד כהן',
);

// Get score
final teamAScore = gameStopwatch.getScoreForTeam('A');
final teamBScore = gameStopwatch.getScoreForTeam('B');

// Export events for saving
final events = gameStopwatch.exportAsGameEvents();
```

---

### 3. GameStopwatchWidget (`lib/widgets/game/game_stopwatch_widget.dart`)

**Purpose:** UI widget for displaying and controlling game stopwatch

**Features:**
- ✅ Large stopwatch display (MM:SS format)
- ✅ Score display (Team A vs Team B)
- ✅ Start/Pause/Resume/Reset controls
- ✅ Quick goal recording buttons (tap player to record goal)
- ✅ Event list with timestamps
- ✅ Delete events
- ✅ Real-time updates

**Usage:**
```dart
GameStopwatchWidget(
  stopwatch: gameStopwatch,
  teamAPlayers: teamA,
  teamBPlayers: teamB,
  onEventsRecorded: (events) {
    // Called when events are recorded
    // Can save to Firestore here
  },
)
```

---

## 🎮 Integration with GameRecordingScreen

The Game Stopwatch is integrated into `GameRecordingScreen`:

### Flow:

1. **Team Setup Phase:**
   - User assigns players to Team A and Team B
   - Click "התחל משחק" (Start Game)

2. **Game Active Phase:**
   - Stopwatch starts automatically
   - User can record goals by tapping players
   - Events are tracked in real-time
   - Score updates automatically

3. **Finish Game:**
   - Click "סיום משחק" (Finish Game)
   - Events are exported and saved to Firestore
   - Game is created with final score and events

---

## 📊 Data Model

### GameEventRecord

```dart
class GameEventRecord {
  final String eventId;
  final EventType type; // goal, assist, card, save
  final String playerId;
  final String playerName;
  final String team; // 'A' or 'B'
  final Duration timestamp; // Time in game when event occurred
  final DateTime recordedAt; // When event was recorded
  final Map<String, dynamic> metadata;
}
```

### Event Types

- `EventType.goal` - Goal scored
- `EventType.assist` - Assist provided
- `EventType.card` - Yellow/Red card
- `EventType.save` - Goalkeeper save
- `EventType.mvpVote` - MVP vote (future)

---

## 🔄 Event Flow

```
User taps player → recordGoal() → GameEventRecord created
  ↓
Event added to _events list
  ↓
notifyListeners() → UI updates
  ↓
Score recalculated
  ↓
Event list updated
```

---

## 💾 Saving to Firestore

When game finishes:

```dart
// Export events
final gameEvents = gameStopwatch.exportAsGameEvents();

// Save to Firestore
for (final event in gameEvents) {
  await eventsRepo.addEvent(gameId, event);
}
```

Events are saved to: `/games/{gameId}/events/{eventId}`

---

## 🎨 UI Features

### Stopwatch Display
- Large time display (64px font)
- MM:SS format
- Updates every 100ms

### Score Display
- Team A vs Team B
- Color-coded (Orange vs Blue)
- Updates in real-time

### Quick Goal Recording
- Horizontal scrollable list of players
- Tap player to record goal
- Visual feedback on tap

### Event List
- Reverse chronological order (newest first)
- Shows: Time, Event Type, Player Name
- Delete button for each event
- Color-coded by team

---

## 🚀 Future Enhancements

### Planned Features:
- [ ] Assist recording (link to last goal)
- [ ] Card recording (yellow/red)
- [ ] Save recording (for goalkeepers)
- [ ] MVP selection
- [ ] Half-time pause
- [ ] Overtime support
- [ ] Event editing (change time, player)
- [ ] Export to PDF/Share

---

## 📝 Related Files

- `lib/utils/stopwatch_utility.dart` - General stopwatch
- `lib/utils/game_stopwatch.dart` - Game stopwatch
- `lib/widgets/game/game_stopwatch_widget.dart` - UI widget
- `lib/screens/game/game_recording_screen.dart` - Integration
- `lib/models/game_event.dart` - Event model
- `lib/models/enums/event_type.dart` - Event types

---

## ✅ Testing Checklist

- [x] Stopwatch starts correctly
- [x] Time updates in real-time
- [x] Goals recorded correctly
- [x] Score updates correctly
- [x] Events displayed correctly
- [x] Events can be deleted
- [x] Game can be finished
- [x] Events saved to Firestore
- [ ] Assist recording (future)
- [ ] Card recording (future)
- [ ] Save recording (future)

---

**Status:** ✅ **Fully Implemented and Integrated!**

**Ready for:** Production use

---

*Last Updated: November 30, 2025*

