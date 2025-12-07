# עדכון תרחיש בדיקת איזון קבוצות ✅

## מה השתנה?

עדכנתי את התרחיש הירוק "בדיקת איזון קבוצות" (הכפתור הירוק במסך האדמין) כך שייצור **אירוע** במקום משחק.

## לפני → אחרי

### לפני (❌):
```
Hub + 15 שחקנים + Game (משחק)
- status: GameStatus.teamSelection
- נשמר ב-/games/{gameId}
```

### אחרי (✅):
```
Hub + 15 שחקנים + HubEvent (אירוע)
- status: 'upcoming'
- נשמר ב-/hubs/{hubId}/events/items/{eventId}
- תומך ב-Winner Stays model
```

## השינויים המדויקים

### 1. `team_balancing_test_script.dart`

#### יצירת אירוע במקום משחק:
```dart
// לפני:
final gameId = firestore.collection('games').doc().id;
final game = Game(
  gameId: gameId,
  status: GameStatus.teamSelection,
  ...
);
batch.set(firestore.doc(FirestorePaths.game(gameId)), game.toJson());

// אחרי:
final eventId = firestore
    .collection(FirestorePaths.hub(hubId))
    .doc('events')
    .collection('items')
    .doc()
    .id;
final event = HubEvent(
  eventId: eventId,
  status: 'upcoming',
  teamCount: 3,
  registeredPlayerIds: playerIds,  // כל 15 השחקנים
  ...
);
batch.set(eventRef, event.toJson());
```

#### רישום שחקנים:
```dart
// לפני:
firestore.doc(FirestorePaths.gameSignup(gameId, playerId))

// אחרי:
firestore.doc(FirestorePaths.gameSignup(eventId, playerId))
// שים לב: GameSignup נשאר אותו הדבר, רק ה-ID משתנה
```

#### מחיקת תרחיש (cleanup):
```dart
// לפני:
cleanupTestScenario({
  required String hubId,
  required String gameId,  // ❌
  required List<String> playerIds,
})

// אחרי:
cleanupTestScenario({
  required String hubId,
  required String eventId,  // ✅
  required List<String> playerIds,
})
```

### 2. `generate_dummy_data_screen.dart`

#### משתני מצב:
```dart
// לפני:
String? _lastTestGameId;

// אחרי:
String? _lastTestEventId;
```

#### הודעות UI:
```dart
// לפני:
'נוצר Hub + 15 שחקנים + משחק עם 3 קבוצות (5v5v5)'
'⚽ Game ID: ${result['gameId']}'

// אחרי:
'נוצר Hub + 15 שחקנים + אירוע עם 3 קבוצות (Winner Stays)'
'📅 Event ID: ${result['eventId']}'
```

## מה נוצר עכשיו?

כשלוחצים על הכפתור הירוק "צור תרחיש בדיקת איזון קבוצות":

### 1. **Hub חדש**
- שם: "Hub בדיקת איזון קבוצות"
- המשתמש המחובר = מנהל
- 15 חברים (כולל המנהל)

### 2. **15 שחקנים**
- המשתמש המחובר (אתה)
- 14 שחקנים דמה נוספים
- כולם עם דירוגים מאוזנים (4.2-8.5)
- כולם עם עמדות (Goalkeeper, Defender, Midfielder, Forward)
- כולם חברים באב

### 3. **אירוע חדש** ✨
- כותרת: "אירוע בדיקת איזון קבוצות"
- תאריך: בעוד שעתיים
- סטטוס: 'upcoming'
- `teamCount`: 3 (עבור Winner Stays)
- `maxParticipants`: 15
- **`registeredPlayerIds`**: כל 15 השחקנים
- מיקום: גן דניאל, חיפה

### 4. **רישומים לאירוע** ✅
- **כל 15 השחקנים** נרשמו לאירוע
- **כולם עם `SignupStatus.confirmed`**
- מסמכים ב-`/games/{eventId}/signups/{playerId}`

## זרימת העבודה החדשה

```
1. לחיצה על "צור תרחיש בדיקת איזון קבוצות"
           ↓
2. נוצר Hub + 15 שחקנים + אירוע
           ↓
3. כל 15 השחקנים מאושרים ורשומים
           ↓  
4. נווט להאב → לחץ על האירוע
           ↓
5. לחץ "צור קבוצות" → TeamMaker יוצר 3 קבוצות
           ↓
6  לחץ "פתח משחק" → יוצר Game ומתחיל Winner Stays
           ↓
7. 🎮 משחק Winner Stays מוכן!
```

## מבנה Firestore

```
/hubs/{hubId}/
  - name: "Hub בדיקת איזון קבוצות"
  - createdBy: {currentUserId}
  - memberCount: 15
  
  /members/
    /{currentUserId}  ← role: 'manager', managerRating: 7.5
    /{player1}        ← role: 'member', managerRating: 6.3
    /{player2}        ← role: 'member', managerRating: 5.8
    ...
  
  /events/
    /items/{eventId}/  ← ✨ HubEvent document ✨
      - title: "אירוע בדיקת איזון קבוצות"
      - status: 'upcoming'
      - teamCount: 3
      - registeredPlayerIds: [15 players]
      - eventDate: now + 2 hours

/games/{eventId}/      ← שים לב: eventId משמש כ-gameId לרישומים
  /signups/
    /{currentUserId}  ← status: confirmed
    /{player1}        ← status: confirmed
    ...

/users/{playerId}  ← 14 new users + current user
```

## אישורים שנוצרו ✅

1. **Hub membership**: כל 15 השחקנים נוספו ל-`/hubs/{hubId}/members/`
2. **Hub count**: `memberCount` = 15
3. **Manager rating**: כל שחקן קיבל `managerRating` (4.2-8.5)
4. **Event registration**: כל השחקנים ברשימת `registeredPlayerIds`
5. **Signup documents**: 15 מסמכי `GameSignup` עם `status: confirmed`
6. **Hub IDs**: כל שחקן עודכן עם `hubIds: [hubId]`

## בדיקה

לאחר הרצת התרחיש, תוכל:

1. ✅ לנווט להאב החדש
2. ✅ לראות 15 חברים
3. ✅ לראות את האירוע ברשימת האירועים
4. ✅ לכנס לאירוע ולראות 15 שחקנים מאושרים
5. ✅ ללחוץ "צור קבוצות" וליצור 3 קבוצות מאוזנות
6. ✅ ללחוץ "פתח משחק" ולהתחיל Winner Stays session

## קבצים ששונו

- ✅ `lib/scripts/team_balancing_test_script.dart`
  - השתנה מיצירת `Game` ליצירת `HubEvent`
  - עודכן `cleanupTestScenario` למחוק אירוע
  - עודכן ה-return value מ-`gameId` ל-`eventId`

- ✅ `lib/screens/admin/generate_dummy_data_screen.dart`
  - שונה `_lastTestGameId` ל-`_lastTestEventId`
  - עודכנו כל ההודעות והתיאורים
  - עודכנה הקריאה ל-`cleanupTestScenario`

## סיכום

**עכשיו התרחיש הירוק יוצר אירוע עם 15 שחקנים מאושרים, מוכן לחלוטין עבור:**
- ✅ יצירת קבוצות עם TeamMaker
- ✅ פתיחת סשן Winner Stays
- ✅ בדיקת כל הזרימה מקצה לקצה

**אתה המנהל + אחד מ-15 השחקנים המאושרים!** 👑⚽
