# PATCH 3 — Routing + Shell + Nav - Checklist

## 📦 קבצים שנוצרו/עודכנו (14 קבצים)

### Services (1 קובץ)
1. ✅ `lib/services/auth_service.dart` - AuthService עם authStateChanges stream

### Routing (2 קבצים)
2. ✅ `lib/routing/app_router.dart` - GoRouter configuration עם כל ה-routes
3. ✅ `lib/routing/go_router_refresh_stream.dart` - GoRouterRefreshStream ל-auth state changes

### Widgets (1 קובץ)
4. ✅ `lib/widgets/app_scaffold.dart` - AppScaffold עם AppBar + Hebrew titles

### Screens (9 קבצים - placeholders)
5. ✅ `lib/screens/auth/login_screen.dart` - Login screen (placeholder)
6. ✅ `lib/screens/hub/hub_list_screen.dart` - Hub list screen (placeholder)
7. ✅ `lib/screens/hub/create_hub_screen.dart` - Create hub screen (placeholder)
8. ✅ `lib/screens/hub/hub_detail_screen.dart` - Hub detail screen (placeholder)
9. ✅ `lib/screens/game/game_list_screen.dart` - Game list screen (placeholder)
10. ✅ `lib/screens/game/create_game_screen.dart` - Create game screen (placeholder)
11. ✅ `lib/screens/game/game_detail_screen.dart` - Game detail screen (placeholder)
12. ✅ `lib/screens/game/team_maker_screen.dart` - Team maker screen (placeholder)
13. ✅ `lib/screens/game/stats_logger_screen.dart` - Stats logger screen (placeholder)

### Updated Files (1 קובץ)
14. ✅ `lib/main.dart` - עודכן להשתמש ב-go_router + Riverpod
15. ✅ `pubspec.yaml` - נוסף go_router

## 🔧 Shell Commands

### 1. התקנת Dependencies
```bash
flutter pub get
```

### 2. בדיקת קומפילציה
```bash
flutter analyze
```

### 3. הרצת האפליקציה
```bash
flutter run -d chrome
```

## ✅ Manual Test Checklist

### בדיקה 1: Routing Setup
- [ ] האפליקציה עולה בלי crash
- [ ] GoRouter מוגדר נכון
- [ ] כל ה-routes מוגדרים
- [ ] אין שגיאות קומפילציה

### בדיקה 2: Auth Redirect
- [ ] כשמשתמש לא authenticated, redirect ל-`/auth`
- [ ] כשמשתמש authenticated, redirect ל-`/`
- [ ] Auth state changes מעדכנים את ה-router

### בדיקה 3: Routes Navigation
- [ ] `/auth` - מציג LoginScreen
- [ ] `/` - מציג HubListScreen
- [ ] `/hubs` - מציג HubListScreen
- [ ] `/hubs/create` - מציג CreateHubScreen
- [ ] `/hubs/:id` - מציג HubDetailScreen עם hubId
- [ ] `/games` - מציג GameListScreen
- [ ] `/games/create` - מציג CreateGameScreen
- [ ] `/games/:id` - מציג GameDetailScreen עם gameId
- [ ] `/games/:id/team-maker` - מציג TeamMakerScreen
- [ ] `/games/:id/stats` - מציג StatsLoggerScreen

### בדיקה 4: AppScaffold
- [ ] AppScaffold מציג AppBar עם title
- [ ] AppBar עם back button (כשיש)
- [ ] AppBar עם actions (אם יש)
- [ ] FloatingActionButton מוצג (אם יש)
- [ ] הטקסט בעברית (RTL)

### בדיקה 5: RTL Support
- [ ] הטקסט מוצג מימין לשמאל
- [ ] ה-AppBar מיושר לימין
- [ ] ה-navigation מיושר לימין
- [ ] כל ה-screens תומכים ב-RTL

### בדיקה 6: Auth Service
- [ ] AuthService מחזיר currentUser
- [ ] AuthService מחזיר authStateChanges stream
- [ ] signInAnonymously() עובד (אם Firebase מוגדר)
- [ ] signOut() עובד (אם Firebase מוגדר)

### בדיקה 7: Limited Mode
- [ ] כאשר Firebase לא מוגדר, האפליקציה לא קורסת
- [ ] Auth service מחזיר null/empty streams ב-limited mode
- [ ] Router עובד גם ב-limited mode

## 🐛 Expected Issues & Solutions

### Issue 1: Router Not Updating on Auth Change
**Solution**: ודא ש-`GoRouterRefreshStream` מקשיב ל-auth state changes

### Issue 2: Redirect Loop
**Solution**: ודא שה-redirect logic נכון (לא authenticated → /auth, authenticated → /)

### Issue 3: Route Not Found
**Solution**: ודא שכל ה-routes מוגדרים ב-`app_router.dart`

### Issue 4: Screen Not Found
**Solution**: ודא שכל ה-screens נוצרו ומיובאים נכון

## 📝 Notes

1. **GoRouter**: כל ה-routes מוגדרים ב-`app_router.dart`
2. **Auth Redirect**: Router מעדכן אוטומטית לפי auth state
3. **RTL Support**: כל ה-screens תומכים ב-RTL
4. **Placeholder Screens**: כל ה-screens הם placeholders (יושלמו ב-patches הבאים)
5. **Riverpod**: Router משתמש ב-Riverpod ל-state management

## ✅ Success Criteria

- [x] GoRouter מוגדר
- [x] כל ה-routes מוגדרים
- [x] Auth redirect עובד
- [x] AppScaffold נוצר
- [x] כל ה-placeholder screens נוצרו
- [x] אין שגיאות קומפילציה
- [ ] האפליקציה רצה ב-Chrome (לבדוק)
- [ ] כל ה-routes עובדים (לבדוק)
- [ ] Auth redirect עובד (לבדוק)

## 🚀 Next Steps

אחרי ש-PATCH 3 עובד:
- PATCH 4: Auth UI (מימוש LoginScreen)
- PATCH 5: Hubs screens (מימוש HubListScreen, CreateHubScreen, HubDetailScreen)
- PATCH 6: Games screens (מימוש GameListScreen, CreateGameScreen, GameDetailScreen)

## 📚 Routes Structure

```
/auth - LoginScreen
/ - HubListScreen (home)
/hubs - HubListScreen
/hubs/create - CreateHubScreen
/hubs/:id - HubDetailScreen
/games - GameListScreen
/games/create - CreateGameScreen
/games/:id - GameDetailScreen
/games/:id/team-maker - TeamMakerScreen
/games/:id/stats - StatsLoggerScreen
```

## 🔐 Auth Flow

1. User לא authenticated → redirect to `/auth`
2. User authenticated → redirect to `/`
3. Auth state changes → router מתעדכן אוטומטית
4. GoRouterRefreshStream מקשיב ל-auth state changes

