# PATCH 6 — Games Screens - Checklist

## 📦 קבצים שנוצרו/עודכנו (3 קבצים)

### Screens (3 קבצים)
1. ✅ `lib/screens/game/game_list_screen.dart` - GameListScreen עם filter לפי hub
2. ✅ `lib/screens/game/create_game_screen.dart` - CreateGameScreen עם טופס יצירת משחק
3. ✅ `lib/screens/game/game_detail_screen.dart` - GameDetailScreen עם signups + כפתורי פעולה

### Providers (1 קובץ - נוסף ב-PATCH 5)
4. ✅ `lib/data/repositories_providers.dart` - נוסף selectedHubProvider

## 🔧 Shell Commands

### 1. בדיקת קומפילציה
```bash
flutter analyze
```

### 2. הרצת האפליקציה
```bash
flutter run -d chrome
```

## ✅ Manual Test Checklist

### בדיקה 1: GameListScreen
- [ ] GameListScreen מציג dropdown filter לפי hub
- [ ] GameListScreen מציג רשימת משחקים (מסודרים לפי gameDate desc)
- [ ] FAB "צור משחק" → navigate ל-`/games/create`
- [ ] לחיצה על משחק → navigate ל-`/games/:id`
- [ ] כאשר אין משחקים, מציג empty state
- [ ] כאשר אין hubs, מציג הודעה
- [ ] Loading state מוצג בזמן טעינה
- [ ] Error state מוצג במקרה של שגיאה
- [ ] כל הטקסט בעברית (RTL)

### בדיקה 2: CreateGameScreen
- [ ] CreateGameScreen מציג dropdown לבחירת hub
- [ ] CreateGameScreen מציג date picker
- [ ] CreateGameScreen מציג time picker
- [ ] CreateGameScreen מציג dropdown למספר קבוצות (2/3/4)
- [ ] CreateGameScreen מציג location field (אופציונלי)
- [ ] Validation עובד (hub required)
- [ ] כפתור "צור משחק" יוצר משחק
- [ ] אחרי יצירה, navigate חזרה ל-`/games`
- [ ] אחרי יצירה, מציג SnackBar "המשחק נוצר בהצלחה!"
- [ ] Game נוצר עם status=teamSelection
- [ ] Loading state מוצג בזמן יצירה
- [ ] Error handling עובד

### בדיקה 3: GameDetailScreen
- [ ] GameDetailScreen מציג פרטי משחק (date, location, status, teamCount)
- [ ] GameDetailScreen מציג רשימת signups (מקובצים לפי status)
- [ ] כפתור "נרשם" / "מסיר הרשמה" עובד
- [ ] כפתור "בחר קבוצות" מוצג (רק ל-creator, status=teamSelection/teamsFormed)
- [ ] כפתור "התחל משחק" מוצג (רק ל-creator, status=teamsFormed)
- [ ] כפתור "סיים משחק" מוצג (רק ל-creator, status=inProgress)
- [ ] Signups מוצגים עם שם ואימייל
- [ ] Signups מקובצים לפי status (confirmed/pending)
- [ ] Loading state מוצג בזמן טעינה
- [ ] Error handling עובד

### בדיקה 4: Signups
- [ ] setSignup() יוצר signup עם status=confirmed
- [ ] removeSignup() מסיר signup
- [ ] watchSignups() מחזיר stream של signups
- [ ] Signups מתעדכנים בזמן אמת

### בדיקה 5: Game Status Changes
- [ ] updateGameStatus() מעדכן status
- [ ] רק creator יכול לעדכן status
- [ ] "התחל משחק" → status=inProgress
- [ ] "סיים משחק" → status=completed
- [ ] Status changes מתעדכנים בזמן אמת

### בדיקה 6: Navigation
- [ ] GameListScreen → CreateGameScreen (FAB)
- [ ] GameListScreen → GameDetailScreen (tap on game)
- [ ] GameDetailScreen → TeamMakerScreen (כפתור "בחר קבוצות")
- [ ] כל ה-navigation עובד עם go_router

### בדיקה 7: RTL Support
- [ ] כל הטקסט מיושר לימין
- [ ] כל ה-icons מיושרים נכון
- [ ] ה-UI נראה תקין ב-RTL

## 🐛 Expected Issues & Solutions

### Issue 1: Game Not Found
**Solution**: ודא ש-gameId תקין וש-Firestore rules מאפשרים read

### Issue 2: Create Game Fails
**Solution**: ודא ש-Firestore rules מאפשרים write וש-createdBy תקין

### Issue 3: Signup Fails
**Solution**: ודא ש-Firestore rules מאפשרים write ל-signups subcollection

### Issue 4: Status Update Fails
**Solution**: ודא ש-רק creator יכול לעדכן status (בדיקה בקוד)

## 📝 Notes

1. **Game Creation**: Game נוצר עם status=teamSelection
2. **Signups**: Signups מקובצים לפי status (confirmed/pending)
3. **Creator Only**: רק creator יכול לעדכן status ולגשת לכפתורי פעולה
4. **Real-time Updates**: כל ה-screens משתמשים ב-streams לעדכונים בזמן אמת
5. **Error Handling**: כל ה-screens מציגים error states

## ✅ Success Criteria

- [x] GameListScreen נוצר
- [x] CreateGameScreen נוצר
- [x] GameDetailScreen נוצר
- [x] selectedHubProvider נוצר
- [x] כל ה-screens משתמשים ב-games_repository & signups_repository
- [x] Creator-only checks מוגדרים
- [x] אין שגיאות קומפילציה
- [ ] האפליקציה רצה ב-Chrome (לבדוק)
- [ ] יצירת משחק עובדת (לבדוק)
- [ ] הרשמה למשחק עובדת (לבדוק)
- [ ] שינוי status עובד (לבדוק)

## 🚀 Next Steps

אחרי ש-PATCH 6 עובד:
- PATCH 7: Team Maker V1 (algorithm + UI)
- PATCH 8: Gameday Stats Logger + Recap
- PATCH 9: l10n/RTL polish

## 📚 Features

### GameListScreen
- ✅ Filter לפי hub (dropdown)
- ✅ רשימת משחקים (מסודרים לפי gameDate desc)
- ✅ FAB "צור משחק"
- ✅ Empty state (כשאין משחקים)
- ✅ Loading state
- ✅ Error state
- ✅ Navigation ל-game detail

### CreateGameScreen
- ✅ בחירת hub (dropdown)
- ✅ בחירת תאריך (date picker)
- ✅ בחירת שעה (time picker)
- ✅ בחירת מספר קבוצות (2/3/4)
- ✅ location field (optional)
- ✅ Validation
- ✅ יצירת משחק עם createdBy, hubId, gameDate, teamCount
- ✅ Loading state
- ✅ Error handling
- ✅ Navigation חזרה אחרי יצירה

### GameDetailScreen
- ✅ פרטי משחק (date, location, status, teamCount)
- ✅ רשימת signups (מקובצים לפי status)
- ✅ כפתור "נרשם" / "מסיר הרשמה"
- ✅ כפתור "בחר קבוצות" (creator only)
- ✅ כפתור "התחל משחק" (creator only)
- ✅ כפתור "סיים משחק" (creator only)
- ✅ Loading state
- ✅ Error handling
- ✅ Real-time updates

