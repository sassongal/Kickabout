# PATCH 5 — Hubs Screens - Checklist

## 📦 קבצים שנוצרו/עודכנו (4 קבצים)

### Providers (1 קובץ)
1. ✅ `lib/data/repositories_providers.dart` - נוסף currentUserIdProvider

### Screens (3 קבצים)
2. ✅ `lib/screens/hub/hub_list_screen.dart` - HubListScreen עם רשימת hubs + FAB
3. ✅ `lib/screens/hub/create_hub_screen.dart` - CreateHubScreen עם טופס יצירת hub
4. ✅ `lib/screens/hub/hub_detail_screen.dart` - HubDetailScreen עם פרטי hub + כפתור הצטרפות/עזיבה

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

### בדיקה 1: HubListScreen
- [ ] HubListScreen מציג רשימת hubs של המשתמש
- [ ] FAB "צור הוב" מוצג
- [ ] לחיצה על FAB → navigate ל-`/hubs/create`
- [ ] לחיצה על hub → navigate ל-`/hubs/:id`
- [ ] כאשר אין hubs, מציג "אין הובס"
- [ ] Loading state מוצג בזמן טעינה
- [ ] Error state מוצג במקרה של שגיאה
- [ ] כל הטקסט בעברית (RTL)

### בדיקה 2: CreateHubScreen
- [ ] CreateHubScreen מציג טופס עם name field
- [ ] CreateHubScreen מציג description field (אופציונלי)
- [ ] Validation עובד (name required)
- [ ] כפתור "צור הוב" יוצר hub
- [ ] אחרי יצירה, navigate חזרה ל-`/hubs`
- [ ] אחרי יצירה, מציג SnackBar "ההוב נוצר בהצלחה!"
- [ ] Creator נוסף אוטומטית ל-memberIds
- [ ] Loading state מוצג בזמן יצירה
- [ ] Error handling עובד

### בדיקה 3: HubDetailScreen
- [ ] HubDetailScreen מציג פרטי hub (name, description)
- [ ] HubDetailScreen מציג מספר חברים
- [ ] HubDetailScreen מציג רשימת חברים
- [ ] כפתור "הצטרף להוב" / "עזוב הוב" מוצג
- [ ] לחיצה על כפתור → toggle membership
- [ ] אחרי הצטרפות, מציג SnackBar "הצטרפת להוב"
- [ ] אחרי עזיבה, מציג SnackBar "עזבת את ההוב"
- [ ] Creator מוצג עם Chip "יוצר"
- [ ] Loading state מוצג בזמן טעינה
- [ ] Error handling עובד

### בדיקה 4: Hub Membership
- [ ] addMember() מוסיף uid ל-memberIds
- [ ] removeMember() מסיר uid מ-memberIds
- [ ] watchHubsByMember() מחזיר רק hubs שהמשתמש חבר בהם
- [ ] Membership changes מתעדכנים בזמן אמת

### בדיקה 5: Navigation
- [ ] HubListScreen → CreateHubScreen (FAB)
- [ ] HubListScreen → HubDetailScreen (tap on hub)
- [ ] CreateHubScreen → HubListScreen (after create)
- [ ] כל ה-navigation עובד עם go_router

### בדיקה 6: RTL Support
- [ ] כל הטקסט מיושר לימין
- [ ] כל ה-icons מיושרים נכון
- [ ] ה-UI נראה תקין ב-RTL

## 🐛 Expected Issues & Solutions

### Issue 1: Hub Not Found
**Solution**: ודא ש-hubId תקין וש-Firestore rules מאפשרים read

### Issue 2: Create Hub Fails
**Solution**: ודא ש-Firestore rules מאפשרים write וש-createdBy תקין

### Issue 3: Membership Toggle Fails
**Solution**: ודא ש-Firestore rules מאפשרים update ל-memberIds

### Issue 4: Users Not Loading
**Solution**: ודא ש-users_repository.getUsers() עובד וש-Firestore rules מאפשרים read

## 📝 Notes

1. **Hub Creation**: Creator נוסף אוטומטית ל-memberIds
2. **Membership**: כפתור toggle membership (הצטרף/עזוב)
3. **Real-time Updates**: כל ה-screens משתמשים ב-streams לעדכונים בזמן אמת
4. **Error Handling**: כל ה-screens מציגים error states
5. **Loading States**: כל ה-screens מציגים loading states

## ✅ Success Criteria

- [x] HubListScreen נוצר
- [x] CreateHubScreen נוצר
- [x] HubDetailScreen נוצר
- [x] currentUserIdProvider נוצר
- [x] כל ה-screens משתמשים ב-hubs_repository
- [x] אין שגיאות קומפילציה
- [ ] האפליקציה רצה ב-Chrome (לבדוק)
- [ ] יצירת hub עובדת (לבדוק)
- [ ] הצטרפות/עזיבה עובדת (לבדוק)

## 🚀 Next Steps

אחרי ש-PATCH 5 עובד:
- PATCH 6: Games screens (מימוש GameListScreen, CreateGameScreen, GameDetailScreen)
- PATCH 7: Team Maker V1 (algorithm + UI)
- PATCH 8: Gameday Stats Logger + Recap

## 📚 Features

### HubListScreen
- ✅ רשימת hubs של המשתמש (watchHubsByMember)
- ✅ FAB "צור הוב"
- ✅ Empty state (כשאין hubs)
- ✅ Loading state
- ✅ Error state
- ✅ Navigation ל-hub detail

### CreateHubScreen
- ✅ טופס עם name (required)
- ✅ טופס עם description (optional)
- ✅ Validation
- ✅ יצירת hub עם createdBy, createdAt, memberIds
- ✅ Loading state
- ✅ Error handling
- ✅ Navigation חזרה אחרי יצירה

### HubDetailScreen
- ✅ פרטי hub (name, description, member count)
- ✅ רשימת חברים
- ✅ כפתור הצטרפות/עזיבה
- ✅ Toggle membership
- ✅ Creator badge
- ✅ Loading state
- ✅ Error handling
- ✅ Real-time updates

