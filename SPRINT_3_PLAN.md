# Sprint 3: MOTM Voting UI Implementation

## 🎯 Goal
Complete the Man of the Match voting feature by implementing the user interface.

**Estimated Time**: 2-3 hours
**Current Status**: Backend ✅ Complete | UI ❌ Not Started

---

## ✅ What's Already Done (Sprint 2)

### Backend Infrastructure
- ✅ Game model has MOTM fields (`motmVotingEnabled`, `motmVotes`, `motmWinnerId`, `motmVotingClosedAt`)
- ✅ HubMember model has `totalMvps` field
- ✅ `onMotmVoteAdded` Cloud Function (auto-close at 80%)
- ✅ `closeExpiredMotmVoting` Cloud Function (2-hour timeout)
- ✅ Tie-breaking logic using manager ratings
- ✅ Automatic MVP count updates

**Files**:
- [lib/features/games/domain/models/game.dart](lib/features/games/domain/models/game.dart)
- [lib/features/hubs/domain/models/hub_member.dart](lib/features/hubs/domain/models/hub_member.dart)
- [functions/src/games/motm_triggers.js](functions/src/games/motm_triggers.js)

---

## 📝 Tasks Breakdown

### Task 1: Create MOTM Voting Screen (60 min)

#### 1.1 Create Screen File
**File**: `lib/features/games/presentation/screens/vote_motm_screen.dart`

**UI Components**:
- App bar with "הצבע לשחקן המצטיין"
- Voting progress indicator: "8/15 הצביעו"
- List of eligible players (confirmed participants, exclude self)
- Each player card:
  - Player photo
  - Player name
  - Rating badge
  - Vote button
- "Already voted" state showing who you voted for
- Close/back button

**Screen Logic**:
```dart
class VoteMotmScreen extends ConsumerStatefulWidget {
  final String gameId;

  // 1. Load game + signups
  // 2. Check if current user already voted
  // 3. Show player list or "already voted" state
  // 4. Submit vote via GamesRepository
  // 5. Show success message
}
```

**Data Flow**:
1. Read game document
2. Get confirmed signups
3. Fetch user data for players
4. Submit vote: Update `game.motmVotes[currentUserId] = selectedPlayerId`
5. Cloud Function handles the rest (auto-close, winner calculation)

#### 1.2 Add Route
**File**: `lib/routing/app_router.dart`

Add route: `/games/:gameId/vote-motm`

---

### Task 2: Post-Game Voting Popup (30 min)

#### 2.1 Create Popup Widget
**File**: `lib/features/games/presentation/widgets/motm_voting_popup.dart`

**Trigger**: When game status changes to `completed` AND `motmVotingEnabled = true`

**UI**:
- Bottom sheet or dialog
- Trophy icon
- Title: "מי היה שחקן המשחק?"
- Quick vote buttons (top 3-5 players by rating)
- "View All Players" → Navigate to VoteMotmScreen
- "Vote Later" → Dismiss

#### 2.2 Integrate in CompletedGameState
**File**: `lib/features/games/presentation/widgets/strategies/completed_game_state.dart`

**Logic**:
```dart
@override
void initState() {
  super.initState();

  // Show popup once if voting is open
  if (game.motmVotingEnabled &&
      game.motmVotingClosedAt == null &&
      !hasVoted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMotmVotingPopup();
    });
  }
}
```

**Storage**: Use SharedPreferences to track if popup was shown for this game.

---

### Task 3: Display MOTM Results (30 min)

#### 3.1 Create Results Widget
**File**: `lib/features/games/presentation/widgets/motm_results_card.dart`

**UI**:
- Card with gold/trophy theme
- Trophy icon 🏆
- Winner name + photo
- Vote count: "8 שחקנים הצביעו"
- Voting closed timestamp
- "View All Votes" button (optional - shows breakdown)

**Display Logic**:
```dart
class MotmResultsCard extends StatelessWidget {
  final Game game;
  final User? winnerUser;

  // Only show if:
  // - motmVotingEnabled = true
  // - motmVotingClosedAt != null
  // - motmWinnerId != null
}
```

#### 3.2 Integrate in CompletedGameState
**File**: `lib/features/games/presentation/widgets/strategies/completed_game_state.dart`

Add `MotmResultsCard` after game summary, before stats sections.

---

### Task 4: Hub Settings Toggle (20 min)

#### 4.1 Add Field to Hub Model
**File**: `lib/features/hubs/domain/models/hub.dart`

```dart
@Default(false) bool enableMotmVoting, // Default: disabled (opt-in)
```

Run: `dart run build_runner build --delete-conflicting-outputs`

#### 4.2 Add Toggle in Hub Settings
**File**: `lib/features/hubs/presentation/screens/hub_settings_screen.dart`

**UI**:
```dart
SwitchListTile(
  title: const Text('הצבעה לשחקן המצטיין'),
  subtitle: const Text(
    'אפשר הצבעה למצטיין אחרי כל משחק. מגביר מעורבות ותחרותיות',
  ),
  value: hub.enableMotmVoting,
  onChanged: (value) async {
    await hubsRepo.updateHub(
      hubId,
      {'enableMotmVoting': value},
    );
  },
)
```

**Location**: Add in "Gamification" or "Game Settings" section

---

### Task 5: Game Creation Inheritance (20 min)

#### 5.1 Update Create Game Screen
**File**: `lib/features/games/presentation/screens/create_game_screen.dart`

**Add State Variable**:
```dart
bool _motmVotingEnabled = false;
```

**Load Default from Hub**:
```dart
Future<void> _loadDefaultVenue(String hubId) async {
  final hub = await hubsRepo.getHub(hubId);

  if (hub != null && mounted) {
    setState(() {
      _hubCity = hub.city;
      _motmVotingEnabled = hub.enableMotmVoting ?? false; // NEW
    });
  }
}
```

**Add Checkbox UI** (after payment tracking section):
```dart
// MOTM Voting (Sprint 2.3)
if (!_isPublicGame) // Only for hub games
  Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(width: 8),
              const Text(
                'שחקן מצטיין',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('אפשר הצבעה לשחקן המצטיין'),
            subtitle: const Text(
              'שחקנים יוכלו להצביע למצטיין אחרי המשחק',
            ),
            value: _motmVotingEnabled,
            onChanged: (value) {
              setState(() {
                _motmVotingEnabled = value ?? false;
              });
            },
          ),
        ],
      ),
    ),
  ),
```

**Include in Game Creation**:
```dart
final game = Game(
  // ... existing fields
  motmVotingEnabled: _motmVotingEnabled, // NEW
);
```

---

### Task 6: Notifications (Optional - 20 min)

#### 6.1 Voting Opened Notification
**File**: `functions/src/games/motm_triggers.js`

Add to `onMotmVoteAdded` when voting first becomes available:

```javascript
// After game completes and MOTM is enabled
if (afterData.status === "completed" &&
    afterData.motmVotingEnabled &&
    Object.keys(beforeVotes).length === 0) {

  // Send notification to all participants
  const signupsSnapshot = await db
    .collection("games").doc(gameId)
    .collection("signups")
    .where("status", "==", "confirmed")
    .get();

  const playerIds = signupsSnapshot.docs.map(doc => doc.id);

  await sendNotificationToPlayers(playerIds, {
    title: "הצבע לשחקן המצטיין! 🏆",
    body: `המשחק הסתיים. מי היה השחקן המצטיין?`,
    data: {
      type: "motm_voting_opened",
      gameId: gameId,
    },
  });
}
```

#### 6.2 Reminder Notification
Create new Cloud Function: `remindMotmVoting`

**Trigger**: Scheduled (every hour)
**Logic**:
- Find games with voting open for 1+ hour
- < 80% participation
- Send reminder to users who haven't voted

#### 6.3 Winner Announced Notification
**File**: `functions/src/games/motm_triggers.js`

Add after winner is determined:

```javascript
// After closing voting and setting winnerId
await sendNotificationToPlayers(playerIds, {
  title: "שחקן המצטיין נבחר! 🏆",
  body: `${winnerName} נבחר כשחקן המצטיין!`,
  data: {
    type: "motm_winner_announced",
    gameId: gameId,
    winnerId: winnerId,
  },
});
```

---

## 🎨 UI/UX Guidelines

### Design Principles
- **Celebratory**: Use gold/amber colors, trophy icons
- **Simple**: One tap to vote
- **Clear Progress**: Always show X/Y voted
- **Respectful**: Don't allow voting for self
- **Engaging**: Show results immediately after voting closes

### Color Scheme
- Primary: Amber/Gold (#FFC107)
- Success: Green (voting closed)
- Pending: Orange (voting open)
- Icons: Trophy 🏆, Star ⭐

### Typography
- Titles: Bold, 18-20pt
- Player names: Medium, 16pt
- Subtitles: Regular, 14pt

---

## 🧪 Testing Checklist

### Voting Screen
- [ ] Loads eligible players correctly
- [ ] Excludes current user from list
- [ ] Shows voting progress
- [ ] Submits vote successfully
- [ ] Shows "already voted" state
- [ ] Displays error if vote fails

### Post-Game Popup
- [ ] Shows when game completes with MOTM enabled
- [ ] Doesn't show if already voted
- [ ] Doesn't show if voting closed
- [ ] Navigates to voting screen correctly
- [ ] Dismisses properly

### Results Display
- [ ] Shows winner name + photo
- [ ] Displays vote count
- [ ] Only appears when voting closed
- [ ] Trophy icon renders correctly

### Hub Settings
- [ ] Toggle switches correctly
- [ ] Saves to Firestore
- [ ] Loads default value on screen open

### Game Creation
- [ ] Inherits hub default
- [ ] Checkbox toggles correctly
- [ ] Value saved in game document

### Notifications
- [ ] Voting opened notification sent
- [ ] Reminder sent after 1 hour (if enabled)
- [ ] Winner announcement sent

---

## 📂 Files to Create (3)

1. `lib/features/games/presentation/screens/vote_motm_screen.dart` - Main voting screen
2. `lib/features/games/presentation/widgets/motm_voting_popup.dart` - Post-game popup
3. `lib/features/games/presentation/widgets/motm_results_card.dart` - Results display

---

## 📝 Files to Modify (5)

1. `lib/features/hubs/domain/models/hub.dart` - Add `enableMotmVoting` field
2. `lib/features/hubs/presentation/screens/hub_settings_screen.dart` - Add toggle
3. `lib/features/games/presentation/screens/create_game_screen.dart` - Add checkbox
4. `lib/features/games/presentation/widgets/strategies/completed_game_state.dart` - Add popup + results
5. `lib/routing/app_router.dart` - Add route

---

## 🚀 Implementation Order

### Phase 1: Core Voting (90 min)
1. Create `vote_motm_screen.dart` with full voting UI
2. Add route in `app_router.dart`
3. Manual navigation test (direct URL)

### Phase 2: Results Display (30 min)
4. Create `motm_results_card.dart`
5. Integrate in `completed_game_state.dart`
6. Test with manually set winner in Firestore

### Phase 3: Hub Settings (30 min)
7. Add field to Hub model
8. Add toggle in hub settings
9. Test toggle save/load

### Phase 4: Game Creation (30 min)
10. Add checkbox in create game
11. Load default from hub
12. Test game creation with MOTM enabled

### Phase 5: Post-Game Popup (30 min)
13. Create `motm_voting_popup.dart`
14. Trigger in `completed_game_state.dart`
15. Test popup appearance

### Phase 6: Notifications (Optional - 30 min)
16. Add notification triggers to Cloud Functions
17. Test notifications in Firebase Console

---

## 🎯 Success Criteria

### Must Have
- ✅ Users can vote for MOTM after game completes
- ✅ Winner displayed in completed games
- ✅ Hub managers can enable/disable MOTM
- ✅ Game creators can override hub default

### Nice to Have
- ⭐ Post-game popup for quick voting
- ⭐ Notifications (opened, reminder, winner)
- ⭐ Vote breakdown (show who voted for whom)
- ⭐ MVP leaderboard in hub stats

---

## 🎉 When Complete

Sprint 3 will deliver a **fully functional MOTM voting system** that:
- Increases player engagement
- Adds gamification
- Builds player reputation (totalMvps)
- Requires zero manual intervention (auto-closes)

Combined with Sprint 2's payment tracking and chemistry scoring, this completes the **"Best Neighborhood Football App in Israel"** feature set! 🚀

---

Ready to start? Begin with **Phase 1: Core Voting** (create the voting screen first).
