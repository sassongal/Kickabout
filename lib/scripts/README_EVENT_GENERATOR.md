# Dummy Event Generator for Winner Stays

## Overview
The `generateEventWithPlayers` method creates a Hub Event with 15 confirmed players, all ready for the TeamMaker to create 3 balanced teams for the Winner Stays session model.

## Usage

### From Flutter App
```dart
import 'package:kattrick/scripts/generate_dummy_data.dart';

// In an async context (e.g., onPressed callback):
final generator = DummyDataGenerator();
final eventId = await generator.generateEventWithPlayers(
  hubId: 'your-hub-id-here',
  playerCount: 15,  // Optional, defaults to 15
  eventTitle: 'Custom Event Title',  // Optional
  eventDate: DateTime.now().add(Duration(hours: 2)),  // Optional
);

print('Event created with ID: $eventId');
```

### What it Creates

1. **15 New Players** (or custom count):
   - At least 2 Goalkeepers (13% of total)
   - ~40% Defenders
   - ~30% Midfielders  
   - ~30% Forwards
   - Ratings: 3.0-7.0 (randomized for balanced teams)
   - All with realistic Israeli names and photos
   - All marked as `SignupStatus.confirmed`

2. **Hub Event**:
   - Status: `upcoming`
   - Team Count: `3` (for Winner Stays)
   - Max Participants: matches player count
   - All players registered and confirmed
   - Ready for team creation immediately

3. **Side Effects**:
   - Players are added to hub members subcollection
   - Hub `memberCount` is incremented
   - GameSignup documents created for each player

## Generated Data Structure

### Players
- **Name**: Random Israeli first + last name
- **Email**: `firstname.lastname.###@kickabout.local` 
- **Position**: Goalkeeper, Defender, Midfielder, or Forward
- **Rating (`currentRankScore`)**: 3.0-7.0 (used by TeamMaker)
- **Photo**: Random realistic photo from randomuser.me
- **Location**: Near Haifa area
- **Availability**: 'available'
- **Hub Membership**: Added to specified hub

### Event
- **Title**: "Winner Stays Session DD/MM" (or custom)
- **Date**: 2 hours from now (or custom)
- **Status**: "upcoming"
- **Team Count**: 3
- **Registered Players**: All 15 players confirmed

## Workflow

```
1. Run generateEventWithPlayers(hubId: 'xyz')
   ↓
2. Event created with 15 confirmed players
   ↓
3. Navigate to Event → view-event.dart
   ↓
4. Click "Generate Teams" button
   ↓
5. TeamMaker creates 3 balanced teams
   ↓
6. Click "Open Game" button
   ↓
7. Winner Stays game session starts!
```

## Notes

- Players are unique each time (new UIDs generated)
- All players have realistic data compatible with TeamMaker requirements
- Position distribution ensures balanced team creation
- At least 2 GKs guarantees each team can have a goalkeeper
- Ratings are spread across 3-7 range for variety
- All players are immediately confirmed (no approval needed)

## Example Output

```
🎯 Generating event with 15 confirmed players for Hub: abc123...
👥 Creating 15 players:
   - 2 Goalkeepers
   - 4 Defenders
   - 4 Midfielders
   - 5 Forwards
✅ Successfully created event xyz456 with 15 confirmed players
📋 Event: Winner Stays Session 5/12
📅 Date: 5/12/2025 18:30
✨ Ready for Team Creation!
```

## Firestore Structure

```
/hubs/{hubId}/
  /events/
    /items/{eventId}  ← HubEvent document
      - registeredPlayerIds: [userId1, userId2, ...]
      - status: 'upcoming'
      - teamCount: 3
      
  /members/
    /{userId}  ← Hub member docs
    
/games/{eventId}/
  /signups/
    /{userId}  ← GameSignup docs (status: confirmed)
    
/users/{userId}  ← User documents
```
