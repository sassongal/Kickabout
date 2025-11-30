# 🗳️ Polls System - Architecture

## תוכן עניינים
1. [סקירה כללית](#סקירה-כללית)
2. [Firestore Structure](#firestore-structure)
3. [Data Models](#data-models)
4. [Security Rules](#security-rules)
5. [Cloud Functions](#cloud-functions)
6. [User Flows](#user-flows)

---

## סקירה כללית

מערכת הסקרים מאפשרת ל-Hub Managers ו-Moderators ליצור סקרים לקהילה:
- **יצירת סקרים** - שאלות עם 2-10 אפשרויות
- **3 סוגי סקרים** - Single Choice, Multiple Choice, Rating
- **הצבעה** - חברי Hub יכולים להצביע
- **תוצאות בזמן אמת** - עדכון מיידי של התוצאות
- **סיום אוטומטי** - סקרים נסגרים אוטומטית בתאריך שנקבע
- **התראות** - הודעה על סקרים חדשים

---

## Firestore Structure

### Collection: `polls`

```
polls/
  {pollId}/
    pollId: string
    hubId: string
    createdBy: string (userId)
    question: string
    options: Array<PollOption>
    type: 'singleChoice' | 'multipleChoice' | 'rating'
    status: 'active' | 'closed' | 'archived'
    createdAt: Timestamp
    endsAt: Timestamp | null
    closedAt: Timestamp | null
    totalVotes: number
    voters: Array<string> (userIds)
    allowMultipleVotes: boolean
    showResultsBeforeVote: boolean
    isAnonymous: boolean
    description: string | null
    
    votes/  (subcollection - optional, for detailed tracking)
      {voteId}/
        voteId: string
        pollId: string
        userId: string
        selectedOptionIds: Array<string>
        votedAt: Timestamp
        rating: number | null
```

### PollOption Structure

```typescript
{
  optionId: string,
  text: string,
  voteCount: number,
  voters: Array<string>,  // empty if isAnonymous
  imageUrl: string | null
}
```

---

## Data Models

### Poll Model

```dart
@freezed
class Poll with _$Poll {
  const factory Poll({
    required String pollId,
    required String hubId,
    required String createdBy,
    required String question,
    required List<PollOption> options,
    required PollType type,
    required PollStatus status,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() DateTime? endsAt,
    @TimestampConverter() DateTime? closedAt,
    @Default(0) int totalVotes,
    @Default([]) List<String> voters,
    @Default(false) bool allowMultipleVotes,
    @Default(false) bool showResultsBeforeVote,
    @Default(false) bool isAnonymous,
    String? description,
  }) = _Poll;
}
```

### Poll Types

```dart
enum PollType {
  singleChoice,    // בחירה אחת בלבד
  multipleChoice,  // בחירה של מספר אפשרויות
  rating,          // דירוג 1-5 כוכבים
}
```

### Poll Status

```dart
enum PollStatus {
  active,    // פעיל - ניתן להצביע
  closed,    // סגור - לא ניתן להצביע, אך ניתן לראות
  archived,  // בארכיון - לא מוצג בברירת מחדל
}
```

---

## Security Rules

### Read Permissions
- ✅ כל חבר ב-Hub יכול לקרוא סקרים של ה-Hub
- ❌ לא ניתן לקרוא סקרים של Hubs שאינך חבר בהם

### Write Permissions

#### Create Poll
- ✅ Hub Managers
- ✅ Hub Moderators
- ❌ Regular members
- **Validations:**
  - Must have 2-10 options
  - createdBy must match auth.uid
  - hubId must be valid

#### Update Poll
- ✅ Poll creator
- ✅ Hub Managers
- ❌ Cannot directly modify votes/voters (only via Cloud Function)
- **Allowed Updates:**
  - question
  - description
  - status
  - endsAt

#### Delete Poll
- ✅ Poll creator
- ✅ Hub Managers

#### Vote
- ❌ Cannot write directly to Firestore
- ✅ Must use Cloud Function `votePoll`

---

## Cloud Functions

### 1. `onPollCreated` (Firestore Trigger)

**Trigger:** `onCreate` on `polls/{pollId}`

**Actions:**
1. Send notification to Hub members
2. Create initial analytics document
3. Validate poll structure

```javascript
exports.onPollCreated = onDocumentCreated(
  'polls/{pollId}',
  async (event) => {
    const poll = event.data.data();
    
    // Send notifications to Hub members
    await notifyHubMembers(poll.hubId, {
      title: 'סקר חדש',
      body: poll.question,
      data: { pollId: event.params.pollId },
    });
  }
);
```

### 2. `votePoll` (Callable Function)

**Authentication:** Required  
**Rate Limit:** 10 votes per minute

**Input:**
```javascript
{
  pollId: string,
  selectedOptionIds: string[],
  rating?: number
}
```

**Actions:**
1. Verify user is Hub member
2. Verify poll is active
3. Verify user hasn't voted (unless allowMultipleVotes)
4. Update poll document (atomic transaction)
5. Create vote document in subcollection
6. Return updated poll

**Security:**
- Transaction ensures atomic updates
- Prevents race conditions
- Validates vote against poll type

```javascript
exports.votePoll = onCall(
  { invoker: 'authenticated' },
  async (request) => {
    const { pollId, selectedOptionIds, rating } = request.data;
    const userId = request.auth.uid;
    
    await checkRateLimit(userId, 'votePoll', 10, 1);
    
    return db.runTransaction(async (transaction) => {
      // Get poll
      const pollRef = db.collection('polls').doc(pollId);
      const poll = await transaction.get(pollRef);
      
      // Validations...
      // Update poll
      // Create vote document
      
      return { success: true, poll: updatedPoll };
    });
  }
);
```

### 3. `closePoll` (Callable Function)

**Authentication:** Required (Manager/Creator only)  
**Rate Limit:** 5 per minute

**Input:**
```javascript
{
  pollId: string
}
```

**Actions:**
1. Verify user is creator or manager
2. Close poll (set status to 'closed')
3. Set closedAt timestamp
4. Send notification with results summary

### 4. `scheduledPollAutoClose` (Scheduled Function)

**Schedule:** Every 10 minutes

**Actions:**
1. Find polls where `endsAt <= now()` and `status == 'active'`
2. Close them automatically
3. Send results notifications

```javascript
exports.scheduledPollAutoClose = onSchedule(
  'every 10 minutes',
  async () => {
    const now = admin.firestore.Timestamp.now();
    
    const polls = await db.collection('polls')
      .where('status', '==', 'active')
      .where('endsAt', '<=', now)
      .get();
    
    for (const pollDoc of polls.docs) {
      await closePoll(pollDoc.id);
    }
  }
);
```

---

## User Flows

### Flow 1: Create Poll

```
1. Manager opens "Create Poll" screen
2. Fills in:
   - Question
   - Options (2-10)
   - Poll Type
   - End Date (optional)
   - Settings (anonymous, show results, etc.)
3. Taps "Create"
4. PollsRepository.createPoll()
5. Firestore creates document
6. onPollCreated trigger fires
7. Notifications sent to Hub members
8. User sees success message
9. Poll appears in Hub's polls list
```

### Flow 2: Vote on Poll

```
1. User opens poll from Hub screen
2. Sees question and options
3. Selects option(s)
4. Taps "Vote"
5. votePoll Cloud Function called
6. Validations:
   - User is Hub member ✓
   - Poll is active ✓
   - User hasn't voted ✓
7. Transaction updates:
   - Increment option.voteCount
   - Add user to option.voters (if not anonymous)
   - Add user to poll.voters
   - Increment poll.totalVotes
8. Vote document created in subcollection
9. Real-time listener updates UI
10. User sees updated results
```

### Flow 3: View Results

```
1. User opens poll
2. If hasVoted OR showResultsBeforeVote:
   - Show results with charts
   - Show percentages
   - Show vote counts
   - Highlight winning option
3. If not voted and not showResultsBeforeVote:
   - Show "Vote to see results"
4. Real-time updates via Stream
```

### Flow 4: Auto-Close Poll

```
1. Scheduled function runs every 10 minutes
2. Finds polls with:
   - status == 'active'
   - endsAt <= now()
3. For each poll:
   - Set status = 'closed'
   - Set closedAt = now()
   - Find winning option
   - Send notification:
     "הסקר '{question}' הסתיים! התוצאה: {winningOption}"
```

---

## Performance Considerations

### Indexes Required

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "polls",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "hubId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "polls",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "endsAt", "order": "ASCENDING" }
      ]
    }
  ]
}
```

### Caching Strategy

```dart
// Cache polls for 5 minutes
CacheService().getOrFetch<List<Poll>>(
  'hub_${hubId}_polls',
  () => _fetchPollsFromFirestore(hubId),
  ttl: Duration(minutes: 5),
);
```

### Real-time Updates

```dart
// Use Firestore streams for real-time results
Stream<Poll> watchPoll(String pollId) {
  return _firestore
    .collection('polls')
    .doc(pollId)
    .snapshots()
    .map((doc) => Poll.fromJson(doc.data()!));
}
```

---

## Error Handling

### Common Errors

| Error | Code | Message | Action |
|-------|------|---------|--------|
| Poll not found | `not-found` | הסקר לא נמצא | Show error |
| Already voted | `already-voted` | כבר הצבעת בסקר זה | Show results |
| Poll closed | `poll-closed` | הסקר סגור להצבעות | Show results |
| Not a member | `permission-denied` | אינך חבר ב-Hub | Redirect |
| Rate limit | `resource-exhausted` | יותר מדי הצבעות | Wait message |

---

## Analytics & Metrics

### Track
- Total polls created
- Average votes per poll
- Most popular poll types
- Engagement rate (voters / members)
- Average time to vote
- Poll completion rate

### Dashboard Metrics
- Active polls count
- Total votes today/week/month
- Most active Hub (by poll engagement)
- Popular poll times

---

## Future Enhancements

### Phase 2
- [ ] Poll templates
- [ ] Recurring polls (weekly venue poll)
- [ ] Poll categories
- [ ] Rich media options (images, videos)
- [ ] Poll scheduling (publish at specific time)

### Phase 3
- [ ] Poll analytics dashboard
- [ ] Export results to PDF
- [ ] Poll sharing outside Hub
- [ ] Weighted voting
- [ ] Ranked choice voting

---

**Status:** 🚧 In Development  
**Version:** 1.0.0  
**Last Updated:** Nov 30, 2025

