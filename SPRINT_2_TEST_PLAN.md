# Sprint 2 Testing Plan 🧪

## Test Environment
- **Flutter**: Run app in debug mode
- **Firebase Console**: Monitor Firestore and Cloud Functions logs
- **Device**: iOS/Android emulator or physical device

---

## 🧪 Test 1: Payment Tracking (Complete Flow)

### Prerequisites
- Logged in as hub manager/creator
- Hub with at least 5 members

### Test Steps

#### 1.1 Create Paid Game
1. Navigate to hub detail screen
2. Click "Create Game" button
3. Fill in basic details (date, time, location)
4. Scroll to **"תשלום (אופציונלי)"** section
5. Enter cost: `30` (₪30 per player)
6. **Expected**: Info box appears: "תוכל לעקוב אחר תשלומים ולשלוח בקשות תשלום למשתתפים בפרטי המשחק"
7. Submit game creation
8. **Expected**: Game created successfully

#### 1.2 View Payment Card
1. Navigate to game detail screen
2. Scroll down past action buttons
3. **Expected**: See **PaymentStatusCard** showing:
   - Header: "תשלום" with green icon
   - Badge: "₪30 לשחקן"
   - Summary box:
     - "סטטוס: 0/X שילמו"
     - "סה"כ נגבה: ₪0 / ₪Y"

#### 1.3 Mark Players as Paid (Manager)
1. As manager, view game detail
2. In PaymentStatusCard, see section "סמן כשולם"
3. **Expected**: List of all confirmed players with checkboxes
4. Each player shows:
   - Player name
   - Checkbox (unchecked)
   - Status: "ממתין לתשלום" (orange)
   - Pending icon (orange)
5. Check off 3 players as paid
6. **Expected**:
   - Checkboxes checked
   - Status changes to "שולם" (green)
   - Icon changes to check_circle (green)
   - Summary updates: "3/X שילמו"
   - Total collected updates: "₪90 / ₪Y"

#### 1.4 Generate Payment Request
1. Click "צור הודעת תשלום" button
2. **Expected**: Dialog appears showing:
   - Title: "הודעת בקשת תשלום"
   - List of unpaid players
   - Generated message:
     ```
     היי!
     המשחק ב-[מיקום] עולה ₪30 לשחקן.

     נא לשלם למארגן המשחק בביט/פייבוקס.

     תודה! ⚽
     ```
3. Click "העתק ללוח"
4. **Expected**:
   - Dialog closes
   - Snackbar: "ההודעה הועתקה ללוח! כעת אפשר לשלוח בוואטסאפ"
5. Open WhatsApp and paste - verify message is copied

#### 1.5 Player View (Non-Manager)
1. Log in as regular player who signed up
2. View game detail
3. **Expected**: See PaymentStatusCard showing:
   - Summary (read-only)
   - Your status box:
     - If unpaid: "ממתין לתשלום של ₪30" (orange)
     - If paid: "סומנת כמי ששילם ✓" (green)
4. **No** checkboxes or "צור הודעת תשלום" button

#### 1.6 All Paid Scenario
1. As manager, mark ALL players as paid
2. **Expected**: Summary shows "X/X שילמו" in green
3. Click "צור הודעת תשלום"
4. **Expected**: Snackbar: "כל השחקנים שילמו! 🎉" (green)

### Expected Results ✅
- ✅ Payment cost field appears in game creation
- ✅ Payment card only shows for games with cost > 0
- ✅ Manager can mark players as paid/unpaid
- ✅ Summary updates in real-time
- ✅ Message generation works correctly
- ✅ Players see their own status
- ✅ All paid scenario handled

---

## 🧪 Test 2: Chemistry Score Data Collection

### Prerequisites
- Hub with at least 8 players
- Firestore access to verify data

### Test Steps

#### 2.1 Complete First Game
1. Create game with 8 players (4v4)
2. Start game
3. Record result (e.g., Team A: 3, Team B: 1)
4. Complete game
5. Open Firebase Console → Firestore
6. Navigate to `/hubs/{hubId}/pairings/`
7. **Expected**: See 12 pairing documents (6 per team)
   - Team A (winners): 6 pairings, each with:
     - `gamesPlayedTogether: 1`
     - `gamesWonTogether: 1`
     - `winRate: 1.0`
   - Team B (losers): 6 pairings, each with:
     - `gamesPlayedTogether: 1`
     - `gamesWonTogether: 0`
     - `winRate: 0.0`

#### 2.2 Complete Second Game (Same Players)
1. Create another game with SAME 8 players
2. Form teams (may differ from first game)
3. Complete game with result
4. Check Firestore `/hubs/{hubId}/pairings/`
5. **Expected**: Pairing documents updated:
   - `gamesPlayedTogether` incremented
   - `gamesWonTogether` incremented if pair won
   - `winRate` recalculated
   - `lastPlayedTogether` updated

#### 2.3 Verify Pairing ID Format
1. Check pairing document IDs
2. **Expected**: Format `{player1Id}_{player2Id}` where IDs are alphabetically sorted
3. Example: If player IDs are "xyz" and "abc", pairing ID is `abc_xyz`

#### 2.4 Check Cloud Function Logs
1. Firebase Console → Functions → Logs
2. Filter for `onGameCompleted`
3. **Expected**: See logs:
   - "✅ Tracking player pairings for game {gameId}"
   - "Created/updated pairing: {pairingId}"
   - No errors

### Expected Results ✅
- ✅ Pairings created when game completes
- ✅ Win rates calculated correctly
- ✅ Pairing IDs are consistent (sorted)
- ✅ Incremental updates work
- ✅ No duplicate pairings

---

## 🧪 Test 3: MOTM Voting (Backend Only - Manual)

### Prerequisites
- Completed game
- Firestore write access
- At least 5 confirmed participants

### Test Steps

#### 3.1 Enable MOTM Voting
1. Open Firebase Console → Firestore
2. Navigate to game document
3. Edit document, add fields:
   - `motmVotingEnabled: true`
   - `motmVotes: {}` (empty map)
4. Save

#### 3.2 Manually Add Votes
1. Edit game document
2. Set `motmVotes` to:
   ```json
   {
     "voter1Id": "player1Id",
     "voter2Id": "player1Id",
     "voter3Id": "player2Id",
     "voter4Id": "player1Id"
   }
   ```
3. Save
4. **If 4/5 participants (80%)**, `onMotmVoteAdded` should trigger
5. Check game document again
6. **Expected**:
   - `motmWinnerId: "player1Id"` (3 votes)
   - `motmVotingClosedAt: <timestamp>`
7. Check winner's HubMember document
8. **Expected**: `totalMvps` incremented by 1

#### 3.3 Test Tie-Breaker
1. Create scenario with tie (2 players with 2 votes each)
2. **Expected**: Winner is player with higher `managerRating`
3. If ratings are equal, first player in iteration wins (non-deterministic)

#### 3.4 Test Timeout (Scheduled Function)
1. Create completed game with `motmVotingEnabled: true`
2. Set `updatedAt` to 3 hours ago (manually in Firestore)
3. Leave `motmVotes` empty or with < 80% votes
4. Wait for next scheduled run (every 30 minutes)
5. **Expected**: `closeExpiredMotmVoting` closes voting
6. Check game document:
   - `motmVotingClosedAt: <timestamp>`
   - `motmWinnerId: <playerId>` (if votes exist) or null

#### 3.5 Check Cloud Function Logs
1. Firebase Console → Functions → Logs
2. Filter for `onMotmVoteAdded` or `closeExpiredMotmVoting`
3. **Expected**: See logs:
   - "MOTM voting threshold reached (80%). Closing voting..."
   - "MOTM voting closed for game {gameId}. Winner: {winnerId} with {count} votes."
   - "Closed MOTM voting for game {gameId} (timeout). Winner: {winnerId}"

### Expected Results ✅
- ✅ Voting auto-closes at 80% participation
- ✅ Winner calculated correctly
- ✅ Tie-breaker uses managerRating
- ✅ MVP count incremented
- ✅ Timeout function closes after 2 hours
- ✅ Works even with 0 votes (closes without winner)

---

## 🧪 Test 4: Team Maker with Chemistry

### Prerequisites
- Hub with chemistry data (from Test 2)
- At least 8 players with pairing history

### Test Steps

#### 4.1 Create Teams Without Chemistry
1. Navigate to game with 8 players
2. Use TeamMaker to create teams
3. Note the team composition
4. Check balance score

#### 4.2 Simulate Chemistry Data
1. In code, modify TeamMaker call to pass `chemistryData`
2. Use PlayerPairing data from Firestore
3. Create teams again
4. **Expected**: If two players have >65% win rate together, algorithm tries to split them

#### 4.3 Verify Balance Score
1. Check debug logs for balance score
2. **Expected**: Score includes chemistry component (15% weight)
3. Teams with high-chemistry pairs separated should have better score

### Expected Results ✅
- ✅ Algorithm accepts chemistry data parameter
- ✅ High win-rate pairs are penalized
- ✅ Balance score reflects chemistry component
- ✅ Teams are more fair with chemistry consideration

---

## 🐛 Known Issues & Limitations

### Payment Tracking
- ⚠️ No actual payment integration (manual only)
- ⚠️ Manager must manually check Bit/PayBox and mark as paid
- ⚠️ No payment history/audit log

### MOTM Voting
- ⚠️ **UI not implemented yet** - all testing is manual via Firestore
- ⚠️ No notifications when voting opens
- ⚠️ No voting screen in app
- ⚠️ Results not displayed in game history

### Chemistry Score
- ⚠️ UI doesn't show chemistry data to users
- ⚠️ No way to view "best partners" or "chemistry stats"
- ⚠️ Data collection is automatic but invisible

---

## 🚀 Next Steps (Sprint 3)

### High Priority
1. **MOTM Voting UI**
   - Create voting screen
   - Post-game popup
   - Results display in completed games
   - Hub settings toggle

2. **Chemistry Stats Display**
   - Show "best partners" in profile
   - Display win rates with teammates
   - Add to hub statistics screen

3. **Payment History**
   - Log when payments marked
   - Show payment timeline
   - Export payment report

### Medium Priority
4. **Enhanced Notifications**
   - MOTM voting opened
   - MOTM voting closing soon (1 hour left)
   - MOTM winner announced
   - Payment request sent

5. **Analytics Dashboard**
   - Payment collection rates
   - MOTM voting participation rates
   - Chemistry-based team balance improvements

---

## 📊 Success Criteria

### Payment Tracking
- ✅ Managers can set game cost
- ✅ Payment status tracked per player
- ✅ WhatsApp message generated correctly
- ✅ Summary shows accurate totals
- ⏳ 80% of managers use feature (after launch)

### Chemistry Score
- ✅ Pairing data collected automatically
- ✅ Win rates calculated correctly
- ✅ Team balancing considers chemistry
- ⏳ Balance scores improve by 10% (measured)

### MOTM Voting
- ✅ Backend auto-closes at 80% or 2 hours
- ✅ Winner calculated with tie-breaker
- ✅ MVP counts updated
- ⏳ UI implemented (Sprint 3)
- ⏳ 60% voting participation (after UI launch)

---

## 🎯 Test Summary

| Feature | Backend | UI | Deployed | Tested |
|---------|---------|----|----|--------|
| Payment Tracking | ✅ | ✅ | ✅ | ⏳ |
| Chemistry Score | ✅ | ⏳ | ✅ | ⏳ |
| MOTM Voting | ✅ | ❌ | ✅ | ⏳ |

**Legend:**
- ✅ Complete
- ⏳ Pending
- ❌ Not started

---

Ready to start testing! 🚀
