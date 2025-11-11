# PATCH 2 — Firestore Paths + Repositories - Checklist

## 📦 קבצים שנוצרו (9 קבצים)

### Services (1 קובץ)
1. ✅ `lib/services/firestore_paths.dart` - כל ה-Firestore paths כ-constants

### Repositories (6 קבצים)
2. ✅ `lib/data/users_repository.dart` - UsersRepository עם CRUD + Streams
3. ✅ `lib/data/hubs_repository.dart` - HubsRepository עם addMember/removeMember
4. ✅ `lib/data/games_repository.dart` - GamesRepository עם listByHub, status changes
5. ✅ `lib/data/signups_repository.dart` - SignupsRepository עם setSignup
6. ✅ `lib/data/teams_repository.dart` - TeamsRepository עם setTeams
7. ✅ `lib/data/events_repository.dart` - EventsRepository עם addEvent

### Providers (2 קבצים)
8. ✅ `lib/data/repositories.dart` - Barrel file ל-export כל ה-repositories
9. ✅ `lib/data/repositories_providers.dart` - Riverpod providers לכל ה-repositories

### Updated Files (1 קובץ)
10. ✅ `pubspec.yaml` - נוספו flutter_riverpod, riverpod_annotation, riverpod_generator

## 🔧 Shell Commands

### 1. התקנת Dependencies
```bash
flutter pub get
```

### 2. בדיקת קומפילציה
```bash
flutter analyze
```

### 3. הרצת Tests (אם יש)
```bash
flutter test
```

## ✅ Manual Test Checklist

### בדיקה 1: Firestore Paths
- [ ] `FirestorePaths.user(uid)` מחזיר path נכון
- [ ] `FirestorePaths.hub(hubId)` מחזיר path נכון
- [ ] `FirestorePaths.game(gameId)` מחזיר path נכון
- [ ] `FirestorePaths.gameSignup(gameId, uid)` מחזיר path נכון
- [ ] `FirestorePaths.gameTeam(gameId, teamId)` מחזיר path נכון
- [ ] `FirestorePaths.gameEvent(gameId, eventId)` מחזיר path נכון
- [ ] `FirestorePaths.ratingHistory(uid, ratingId)` מחזיר path נכון

### בדיקה 2: UsersRepository
- [ ] `getUser(uid)` עובד
- [ ] `watchUser(uid)` מחזיר stream
- [ ] `setUser(user)` יוצר/מעדכן user
- [ ] `updateUser(uid, data)` מעדכן user
- [ ] `deleteUser(uid)` מוחק user
- [ ] `getUsers(uids)` מחזיר רשימת users
- [ ] `watchUsersByHub(hubId)` מחזיר stream של users

### בדיקה 3: HubsRepository
- [ ] `getHub(hubId)` עובד
- [ ] `watchHub(hubId)` מחזיר stream
- [ ] `createHub(hub)` יוצר hub
- [ ] `updateHub(hubId, data)` מעדכן hub
- [ ] `deleteHub(hubId)` מוחק hub
- [ ] `watchHubsByMember(uid)` מחזיר stream של hubs
- [ ] `addMember(hubId, uid)` מוסיף member
- [ ] `removeMember(hubId, uid)` מסיר member
- [ ] `isMember(hubId, uid)` בודק membership

### בדיקה 4: GamesRepository
- [ ] `getGame(gameId)` עובד
- [ ] `watchGame(gameId)` מחזיר stream
- [ ] `createGame(game)` יוצר game
- [ ] `updateGame(gameId, data)` מעדכן game
- [ ] `updateGameStatus(gameId, status)` מעדכן status
- [ ] `deleteGame(gameId)` מוחק game
- [ ] `watchGamesByHub(hubId)` מחזיר stream של games
- [ ] `watchGamesByCreator(uid)` מחזיר stream של games
- [ ] `listGamesByHub(hubId)` מחזיר רשימת games

### בדיקה 5: SignupsRepository
- [ ] `getSignup(gameId, uid)` עובד
- [ ] `watchSignup(gameId, uid)` מחזיר stream
- [ ] `setSignup(gameId, uid, status)` יוצר/מעדכן signup
- [ ] `removeSignup(gameId, uid)` מסיר signup
- [ ] `watchSignups(gameId)` מחזיר stream של signups
- [ ] `getSignups(gameId)` מחזיר רשימת signups
- [ ] `watchSignupsByStatus(gameId, status)` מחזיר stream
- [ ] `isSignedUp(gameId, uid)` בודק signup

### בדיקה 6: TeamsRepository
- [ ] `getTeam(gameId, teamId)` עובד
- [ ] `watchTeam(gameId, teamId)` מחזיר stream
- [ ] `setTeams(gameId, teams)` מגדיר teams (מחליף את כל ה-teams)
- [ ] `watchTeams(gameId)` מחזיר stream של teams
- [ ] `getTeams(gameId)` מחזיר רשימת teams
- [ ] `updateTeam(gameId, teamId, data)` מעדכן team
- [ ] `deleteTeam(gameId, teamId)` מוחק team

### בדיקה 7: EventsRepository
- [ ] `getEvent(gameId, eventId)` עובד
- [ ] `watchEvent(gameId, eventId)` מחזיר stream
- [ ] `addEvent(gameId, event)` מוסיף event
- [ ] `watchEvents(gameId)` מחזיר stream של events
- [ ] `getEvents(gameId)` מחזיר רשימת events
- [ ] `watchEventsByType(gameId, type)` מחזיר stream
- [ ] `watchEventsByPlayer(gameId, playerId)` מחזיר stream
- [ ] `deleteEvent(gameId, eventId)` מוחק event

### בדיקה 8: Riverpod Providers
- [ ] `firestoreProvider` מחזיר FirebaseFirestore instance
- [ ] `usersRepositoryProvider` מחזיר UsersRepository
- [ ] `hubsRepositoryProvider` מחזיר HubsRepository
- [ ] `gamesRepositoryProvider` מחזיר GamesRepository
- [ ] `signupsRepositoryProvider` מחזיר SignupsRepository
- [ ] `teamsRepositoryProvider` מחזיר TeamsRepository
- [ ] `eventsRepositoryProvider` מחזיר EventsRepository

### בדיקה 9: Limited Mode Handling
- [ ] כל ה-repositories מחזירים null/empty כאשר `Env.limitedMode == true`
- [ ] כל ה-streams מחזירים empty streams כאשר `Env.limitedMode == true`
- [ ] כל ה-operations זורקים exception כאשר `Env.limitedMode == true`

## 🐛 Expected Issues & Solutions

### Issue 1: Firestore Not Available
**Solution**: ודא ש-`Env.limitedMode == false` או ש-Firebase מוגדר

### Issue 2: Stream Not Working
**Solution**: ודא ש-Firestore rules מאפשרים read operations

### Issue 3: Update Fails
**Solution**: ודא ש-Firestore rules מאפשרים write operations

### Issue 4: Riverpod Provider Not Found
**Solution**: ודא ש-`flutter_riverpod` מותקן ו-imported נכון

## 📝 Notes

1. **Limited Mode**: כל ה-repositories תומכים ב-limited mode (מחזירים null/empty)
2. **Streams**: כל ה-repositories תומכים ב-streams ל-real-time updates
3. **Error Handling**: כל ה-repositories זורקים exceptions עם הודעות ברורות
4. **Firestore Paths**: כל ה-paths מוגדרים ב-`FirestorePaths` class
5. **Riverpod**: כל ה-repositories זמינים דרך Riverpod providers

## ✅ Success Criteria

- [x] כל ה-repositories נוצרו
- [x] כל ה-Firestore paths מוגדרים
- [x] Riverpod providers נוצרו
- [x] Dependencies נוספו ל-pubspec.yaml
- [x] אין שגיאות קומפילציה
- [ ] כל ה-repositories עובדים (לבדוק עם Firestore)
- [ ] כל ה-streams עובדים (לבדוק עם Firestore)
- [ ] Limited mode עובד (לבדוק)

## 🚀 Next Steps

אחרי ש-PATCH 2 עובד:
- PATCH 3: Routing + shell + nav
- PATCH 4: Auth UI
- PATCH 5: Hubs screens
- PATCH 6: Games screens

## 📚 Repository Features

### UsersRepository
- ✅ CRUD operations
- ✅ Stream user by ID
- ✅ Get multiple users
- ✅ Stream users by hub

### HubsRepository
- ✅ CRUD operations
- ✅ Stream hub by ID
- ✅ Stream hubs by member
- ✅ Add/remove member
- ✅ Check membership

### GamesRepository
- ✅ CRUD operations
- ✅ Stream game by ID
- ✅ Stream games by hub
- ✅ Stream games by creator
- ✅ Update game status
- ✅ List games by hub

### SignupsRepository
- ✅ Get/set signup
- ✅ Stream signup
- ✅ Stream all signups
- ✅ Stream signups by status
- ✅ Check if signed up

### TeamsRepository
- ✅ Get/set teams
- ✅ Stream teams
- ✅ Update team
- ✅ Delete team
- ✅ Set teams (replaces all)

### EventsRepository
- ✅ Add event
- ✅ Stream events
- ✅ Stream events by type
- ✅ Stream events by player
- ✅ Delete event

