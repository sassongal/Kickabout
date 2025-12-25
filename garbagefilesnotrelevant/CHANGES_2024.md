# סיכום שינויים - 2024

## תאריך: היום

### 1. שיפורי מסך המשחקים הראשי

#### תכונות חדשות:
- **הצגת משחקים שהושלמו מכל ההובס** - כאשר לא נבחר הוב, מוצגים משחקים שהושלמו מכל ההובס
- **עיצוב לוח מודעות** - כרטיסי משחק מעוצבים כמו לוח מודעות עם תוצאה בולטת במרכז
- **פרטים מלאים בכרטיס**:
  - תוצאת המשחק (בולט במרכז)
  - תאריך המשחק
  - מיקום (מאירוע, venue, או מהאב)
  - שם ההאב
  - מי תיעד את המשחק ("תועד על ידי: שם")
- **לחיצה על כרטיס** - מעבירה למסך פרטי המשחק

#### קבצים שעודכנו:
- `lib/screens/game/game_list_screen.dart` - עיצוב חדש של כרטיסי משחק
- `lib/data/games_repository.dart` - הוספת `watchCompletedGames()` לקבלת משחקים שהושלמו

---

### 2. שיפורי מסך ההאב

#### תכונות חדשות:
- **תצוגת תפקיד המשתמש** - Chip במעלה המסך משמאל המציג את התפקיד (מנהל/מנחה/חבר)
- **תאריך יצירת ההאב** - טקסט במרכז למעלה: "האב נוצר ב- (תאריך)"
- **רשימת חברים משופרת** - תצוגה עם תמונת פרופיל, שם פרטי ושם משפחה
- **חוקי ההאב** - הוסר מהטאבים, נוסף כפתור שמוביל למסך נפרד
- **כפתורי ניהול מעוצבים**:
  - "הגדרות" - כפתור קטן, כל המילה בשורה אחת
  - "ניהול תפקידים" - "ניהול" בשורה אחת, "תפקידים" בשורה מתחת
  - הוסר כפתור "משחק חדש"
  - "גיוס שחקנים (AI)" - כפתור קטן, כל המילה בשורה
  - כל הכפתורים באותו גובה (`minimumSize: Size(0, 40)`)
- **כפתור אנליטיקס** - מציג "בקרוב" במקום לפתוח מסך

#### קבצים שעודכנו:
- `lib/screens/hub/hub_detail_screen.dart` - כל השיפורים הנ"ל
- `lib/screens/hub/hub_rules_screen.dart` - מסך חדש להצגת חוקי ההאב
- `lib/routing/app_router.dart` - הוספת route למסך חוקי ההאב

---

### 3. שיפורי יצירת אירועים

#### תכונות חדשות:
- **מספר קבוצות** - ברירת מחדל: 3 קבוצות
- **סוג משחק** - שדה חדש עם אפשרויות: 3v3, 4v4, 5v5, 6v6, 7v7, 8v8, 9v9, 10v10, 11v11
- **משך דקות המשחק** - גלגלת אנכית שמתחילה מ-12 דקות, עם ערכים למטה ולמעלה
- **מספר משתתפים** - גלגלת אנכית, ברירת מחדל: 15 (שדה חובה)
- **הוסר שדה "תנאי סיום"**
- **התראות אוטומטיות** - אופציה לשלוח התראה לכל חברי ההאב כשנוצר אירוע ("Event opened")
- **הגבלת הרשמה** - הרשמה נסגרת כשמגיעים למספר המקסימלי של משתתפים
- **תצוגת נרשמים** - מוצג מספר הנרשמים ורשימת המשתתפים שנרשמו
- **פוסט בפיד** - כשמישהו נרשם לאירוע, נוצר פוסט בפיד: "המשתמש X נרשם לאירוע בתאריך X.X.XXXX (3/15)"

#### קבצים שעודכנו:
- `lib/models/hub_event.dart` - הוספת שדות: `teamCount`, `gameType`, `durationMinutes`, `maxParticipants`, `notifyMembers`
- `lib/screens/hub/create_hub_event_screen.dart` - מסך חדש ליצירת אירועים
- `lib/data/hub_events_repository.dart` - עדכון `registerToEvent()` לבדיקת מקסימום משתתפים
- `lib/services/push_notification_integration_service.dart` - הוספת `notifyNewEvent()`
- `lib/screens/hub/hub_events_tab.dart` - עדכון להצגת נרשמים ויצירת פוסטים

---

### 4. שיפורי גיוס שחקנים (Scouting)

#### תכונות חדשות:
- **סטטוס פעיל/לא פעיל** - כל שחקן יכול להגדיר אם הוא "פעיל" (פתוח להאבים והזמנות) או "לא פעיל"
- **פילטרים חדשים**:
  - **טווח גילאים** - Slider עם ברירת מחדל 18-45
  - **איזור מגורים** - Dropdown: צפון, מרכז, דרום, ירושלים
- **הוסרו פילטרים**:
  - פילטר עמדה
  - פילטר דירוג
  - פילטר מרחק מקסימלי
- **מיון לפי מרחק** - הקרוב ביותר למעלה
- **כרטיס שחקן מפורט** - לחיצה על שחקן פותחת כרטיס עם:
  - שם ושם משפחה
  - איזור מגורים
  - טלפון (אם לא מוסתר)
  - מייל (אם לא מוסתר)
  - גיל (מחישוב birthDate)
  - תמונת פרופיל
  - רשימת האבים (כצ'יפים)
  - קבוצה אהודה (אם קיים)

#### קבצים שעודכנו:
- `lib/models/user.dart` - הוספת שדה `isActive` (boolean)
- `lib/screens/home_screen_futuristic.dart` - Switch לסטטוס פעיל/לא פעיל
- `lib/screens/hub/scouting_screen.dart` - פילטרים חדשים וכרטיס שחקן
- `lib/services/scouting_service.dart` - עדכון לוגיקת חיפוש ומיון

---

### 5. שיפורי עריכת פרופיל

#### תכונות חדשות:
- **הגדרת מיקום** - כפתור "הגדר מיקום" עם 3 אפשרויות:
  1. **מיקום נוכחי** - שואב את המיקום הנוכחי מהמכשיר
  2. **חיפוש כתובת** - חיפוש כתובת בשורת חיפוש
  3. **בחירה במפה** - פתיחת מפה לבחירת מיקום

#### קבצים שעודכנו:
- `lib/screens/profile/edit_profile_screen.dart` - הוספת כפתור והפונקציונליות

---

### 6. שיפורי משחקים ואירועים

#### תכונות חדשות:
- **קישור משחקים לאירועים** - משחקים יכולים להיות קשורים לאירוע (`eventId`)
- **תיעוד משחק עבר** - אפשרות לקשר משחק לאירוע בעת תיעוד
- **עריכת משחק** - מסך חדש לעריכת/תיעוד פרטי משחק (תוצאה, מבקיעים, מבשלים, MVP)

#### קבצים שעודכנו:
- `lib/models/game.dart` - הוספת שדה `eventId`
- `lib/models/log_past_game_details.dart` - הוספת שדה `eventId`
- `lib/data/games_repository.dart` - עדכון `logPastGame()` לכלול `eventId`
- `lib/screens/game/log_past_game_screen.dart` - הוספת dropdown לבחירת אירוע
- `lib/screens/hub/edit_game_screen.dart` - מסך חדש לעריכת משחק
- `lib/routing/app_router.dart` - הוספת route למסך עריכת משחק

---

### 7. שיפורי Bottom Navigation

#### תכונות חדשות:
- **שינוי תווית** - "קהילות" שונה ל-"HUBS" (עם אותו אייקון)

#### קבצים שעודכנו:
- `lib/widgets/futuristic/bottom_navigation_bar.dart`

---

### 8. תיקוני באגים

#### תיקונים:
- **תיקון onboarding** - בעיית redirection לאחר השלמת onboarding
- **תיקון יצירת האב** - יוצר ההאב מוגדר אוטומטית כמנהל
- **תיקון package name** - יישור package name ב-Android (`com.mycompany.CounterApp`)
- **תיקון imports** - הוספת `HubEvent` ל-`models.dart` exports
- **תיקון conflicts** - פתרון conflict בין `User` מ-firebase_auth ו-`User` מ-models
- **תיקון null safety** - תיקון בעיות null safety בכמה מקומות
- **תיקון שמות** - תיקון `GeoHashUtils` ל-`GeohashUtils`

#### קבצים שעודכנו:
- `lib/screens/onboarding/onboarding_screen.dart`
- `lib/data/hubs_repository.dart`
- `android/app/build.gradle`
- `android/app/src/main/AndroidManifest.xml`
- `lib/models/models.dart`
- `lib/routing/app_router.dart`
- `lib/screens/hub/hub_detail_screen.dart`
- `lib/screens/profile/edit_profile_screen.dart`
- `lib/screens/hub/hub_rules_screen.dart`
- `lib/screens/game/game_list_screen.dart`

---

### 9. שיפורי UI/UX

#### שיפורים:
- **כפתורי ניהול אחידים** - כל הכפתורים באותו גובה ופרופורציות
- **תצוגת תפקידים** - Chip מעוצב עם אייקון
- **כרטיסי משחק** - עיצוב כמו לוח מודעות
- **כרטיס שחקן** - Bottom sheet מעוצב עם כל הפרטים

---

## סיכום קבצים שנוצרו/עודכנו

### קבצים חדשים:
- `lib/screens/hub/create_hub_event_screen.dart`
- `lib/screens/hub/edit_game_screen.dart`
- `lib/screens/hub/hub_rules_screen.dart`

### קבצים שעודכנו משמעותית:
- `lib/models/user.dart` - הוספת `isActive`
- `lib/models/hub_event.dart` - שדות חדשים
- `lib/models/game.dart` - הוספת `eventId`
- `lib/models/models.dart` - הוספת export של `hub_event.dart`
- `lib/screens/game/game_list_screen.dart` - עיצוב חדש
- `lib/screens/hub/scouting_screen.dart` - פילטרים חדשים וכרטיס שחקן
- `lib/screens/hub/hub_detail_screen.dart` - שיפורי UI רבים
- `lib/services/scouting_service.dart` - לוגיקת חיפוש חדשה
- `lib/routing/app_router.dart` - routes חדשים

---

## הערות טכניות

### Dependencies:
- כל התלויות קיימות, לא נוספו חדשות

### Breaking Changes:
- אין breaking changes - כל השינויים backward compatible

### Migration:
- אין צורך ב-migration - כל השינויים תואמים למבנה הקיים

---

## מה הלאה?

### תכונות עתידיות אפשריות:
- טורנירים וליגות
- שיתוף ווידאו מתקדם
- מערכת תגמולים מורחבת
- אינטגרציה עם רשתות חברתיות
- אפליקציית מאמנים
- סטטיסטיקות מתקדמות נוספות

---

**תאריך עדכון:** היום  
**גרסה:** Development

