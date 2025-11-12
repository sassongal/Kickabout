# 🔄 איפוס מצב Authentication

## בעיה
האפליקציה זוכרת את מצב ההתחברות הקודם (Anonymous Login) ולא מחזירה למסך ההתחברות.

## פתרונות

### פתרון 1: ניקוי נתונים מקומיים ב-Chrome

#### דרך 1: Developer Console
1. פתח את האפליקציה ב-Chrome
2. לחץ `F12` או `Cmd+Option+I` (Mac) / `Ctrl+Shift+I` (Windows)
3. לך ללשונית **Application** (או **אפליקציה**)
4. בתפריט השמאלי, תחת **Storage**:
   - לחץ על **Local Storage** → `http://localhost:XXXXX`
   - לחץ ימני → **Clear** (או Delete)
   - חזור על זה גם עבור **Session Storage**
5. רענן את הדף (`F5` או `Cmd+R`)

#### דרך 2: Clear Site Data
1. פתח את האפליקציה ב-Chrome
2. לחץ על האייקון של המנעול/מידע בצד שמאל של ה-URL bar
3. בחר **Site settings** (הגדרות אתר)
4. לחץ על **Clear data** (נקה נתונים)
5. רענן את הדף

#### דרך 3: Incognito Mode
1. פתח חלון Incognito (`Cmd+Shift+N` / `Ctrl+Shift+N`)
2. נווט ל-`http://localhost:XXXXX`
3. זה יתחיל ממצב נקי

### פתרון 2: ניווט ידני למסך ההתחברות

אם ניקוי הנתונים לא עבד, נסה:

1. נווט ישירות ל:
   ```
   http://localhost:65073/#/auth
   ```
   (החלף את המספר בפורט שלך)

2. זה אמור להציג את מסך ההתחברות

### פתרון 3: Logout Programmatic (אם יש כפתור)

אם יש כפתור Logout באפליקציה:
1. לחץ עליו
2. זה יאפס את ה-auth state
3. תועבר אוטומטית ל-`/auth`

### פתרון 4: איפוס Firebase Auth (אם צריך)

אם כלום לא עובד, אפשר לאפס את Firebase Auth:

```dart
// בקונסול של Flutter DevTools או ב-Debug Console
await FirebaseAuth.instance.signOut();
```

## בדיקת מצב נוכחי

### בדיקה 1: Auth State
פתח את ה-Console ב-Chrome ובדוק:
```javascript
// בדוק אם יש auth state
localStorage.getItem('firebase:authUser:...')
```

### בדיקה 2: Router State
בדוק את ה-URL:
- אם אתה ב-`/` או `/hubs` → אתה מחובר
- אם אתה ב-`/auth` → אתה לא מחובר

## פתרון קבוע: כפתור Logout

✅ **הוסף כפתור Logout ב-HubListScreen**

כפתור Logout נוסף ב-AppBar של מסך ההובס:
- לחץ על האייקון `logout` בפינה הימנית העליונה
- זה יקרא ל-`authService.signOut()`
- ה-Router יאפס אוטומטית ל-`/auth`

**מיקום:** `lib/screens/hub/hub_list_screen.dart` - כפתור ב-AppBar actions

## הערות

- **Anonymous Login** נשמר ב-Local Storage של הדפדפן
- **Email/Password Login** גם נשמר ב-Local Storage
- Firebase Auth שומר את ה-state ב-IndexedDB/LocalStorage
- ה-Router (`app_router.dart`) בודק את ה-auth state ומעביר ל-`/auth` אם לא מחובר

## אם עדיין לא עובד

1. בדוק את ה-Console ל-errors
2. בדוק את ה-Network tab ל-Firebase requests
3. בדוק את ה-Router logs (אם `debugLogDiagnostics: true`)

