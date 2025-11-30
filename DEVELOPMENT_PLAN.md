# 🚀 Kattrick - Development Plan
## תוכנית פיתוח מפורטת לפי Phase 1

> **תאריך:** 2025-01-30  
> **סטטוס:** מוכן לביצוע  
> **משך זמן משוער:** 6-8 שבועות

---

## 📋 סקירה כללית

לפי ה-Roadmap וה-Gap Analysis, אנחנו ב-**Phase 1: Core Refinement** שצריך להשלים 5 תכונות קריטיות לפני Production.

### מה כבר בוצע ✅
- ✅ Priority 1: Security Fixes (Callable Functions)
- ✅ Priority 2: Google Maps API Key Security (עדיין צריך rotation ידני)
- ✅ Priority 3: FCM Token Architecture (unified)
- ✅ Priority 4: Cursor AI Setup (.cursorrules, .cursorignore)

### מה צריך לבנות עכשיו 🎯

---

## Week 1-2: Date of Birth + Age Groups

### מטרה
הוספת תאריך לידה חובה לכל המשתמשים וחישוב קבוצות גיל אוטומטי.

### משימות

#### 1. עדכון User Model
- [ ] הוספת `dateOfBirth` כ-required field (לא optional)
- [ ] יצירת extension `UserAgeExtension` עם:
  - `int get age` - חישוב גיל מדויק
  - `String get ageGroup` - קבוצת גיל (13-15, 16-18, וכו')
  - `bool get isMinimumAge` - בדיקה שגיל >= 13

#### 2. עדכון Onboarding/Signup
- [ ] הוספת DatePicker ל-`register_screen.dart`
- [ ] הוספת DatePicker ל-`auth_screen.dart` (signup flow)
- [ ] הוספת validation: גיל מינימלי 13
- [ ] הוספת הודעת שגיאה בעברית

#### 3. עדכון Profile Screen
- [ ] הצגת גיל וקבוצת גיל בפרופיל
- [ ] אפשרות לערוך תאריך לידה (אם לא הוזן)

#### 4. עדכון Player Scouting
- [ ] הוספת filter לפי קבוצת גיל
- [ ] הצגת קבוצת גיל ב-player cards

#### 5. Firestore Rules
- [ ] הוספת validation rule: `dateOfBirth` required
- [ ] הוספת validation rule: גיל >= 13

#### 6. Migration Script
- [ ] יצירת Cloud Function למיגרציה של משתמשים קיימים
- [ ] הוספת prompt למשתמשים קיימים להזין תאריך לידה

**קבצים לעדכון:**
- `lib/models/user.dart`
- `lib/screens/auth/register_screen.dart`
- `lib/screens/auth/auth_screen.dart`
- `lib/screens/profile/profile_screen.dart`
- `lib/widgets/player_card.dart`
- `firestore.rules`

**זמן משוער:** 2-3 ימים

---

## Week 3-4: Attendance Confirmation

### מטרה
שליחת תזכורת 2 שעות לפני משחק ואישור נוכחות.

### משימות

#### 1. עדכון Game Model
- [ ] הוספת `attendanceConfirmations: Map<String, String>` (userId -> status)
- [ ] הוספת `reminderSent: bool`
- [ ] הוספת `reminderSentAt: DateTime?`

#### 2. Cloud Function: Attendance Reminder
- [ ] יצירת `sendAttendanceReminders` scheduled function
- [ ] רץ כל 10 דקות
- [ ] מוצא משחקים ב-2 שעות הקרובות
- [ ] שולח FCM notification עם deep link
- [ ] מסמן `reminderSent = true`

#### 3. Flutter UI: Confirmation Dialog
- [ ] יצירת `AttendanceConfirmationDialog` widget
- [ ] כפתורים: "אני מגיע" / "לא יכול"
- [ ] עדכון Firestore עם הסטטוס
- [ ] הצגת סטטוס בפרופיל המשחק

#### 4. Game Detail Screen
- [ ] הצגת רשימת אישורי נוכחות
- [ ] אייקונים: ✅ מגיע, ❌ לא מגיע, ⏳ לא אישר
- [ ] סטטיסטיקות: X מתוך Y אישרו

#### 5. Organizer View
- [ ] מסך נפרד למארגן עם רשימה מלאה
- [ ] אפשרות לשלוח תזכורת ידנית
- [ ] רשימת מי לא אישר

**קבצים לעדכון:**
- `lib/models/game.dart`
- `functions/index.js` (Cloud Function)
- `lib/widgets/dialogs/attendance_confirmation_dialog.dart` (חדש)
- `lib/screens/game/game_detail_screen.dart`

**זמן משוער:** 3-4 ימים

---

## Week 5: 3 Hub Tiers (Veteran Role)

### מטרה
הוספת תפקיד Veteran בין Manager ל-Player.

### מצב נוכחי
✅ `HubRole.veteran` כבר קיים ב-`lib/models/hub_role.dart`!

### משימות

#### 1. בדיקה ותיקון Permissions
- [ ] בדיקה ש-`canRecordGame()` כולל veteran
- [ ] בדיקה ש-`canPromoteToVeteran()` עובד נכון
- [ ] עדכון כל בדיקות ההרשאות

#### 2. UI: Promotion to Veteran
- [ ] הוספת כפתור "קידום ל-Veteran" ב-Hub Settings
- [ ] דיאלוג אישור
- [ ] עדכון Firestore role

#### 3. UI: Veteran Badge
- [ ] הוספת badge/icon ל-Veteran בפרופיל
- [ ] הצגה ב-Hub members list
- [ ] הצגה ב-player cards

#### 4. Permissions Logic
- [ ] עדכון `HubPermissionsService` (אם קיים)
- [ ] בדיקה ש-Veteran יכול רק ל-record games
- [ ] בדיקה ש-Veteran לא יכול ל-manage members

**קבצים לבדיקה/עדכון:**
- `lib/models/hub_role.dart` (כבר קיים!)
- `lib/services/hub_permissions_service.dart` (אם קיים)
- `lib/screens/hub/hub_settings_screen.dart`
- `lib/widgets/player_card.dart`

**זמן משוער:** 1-2 ימים (כי כבר יש את ה-enum!)

---

## Week 6-7: Start Event + Auto-Close

### מטרה
אפשרות להתחיל משחק 30 דקות לפני הזמן + סגירה אוטומטית.

### משימות

#### 1. עדכון Game Status
- [ ] הוספת `archived_not_played` ל-`GameStatus` enum
- [ ] עדכון `GameStatusConverter`

#### 2. Start Event Button
- [ ] הוספת כפתור "התחל משחק" ב-Game Detail
- [ ] Validation: רק 30 דקות לפני `scheduledAt`
- [ ] Lock teams (לא ניתן לשנות אחרי start)
- [ ] שינוי status ל-`inProgress`

#### 3. Cloud Function: Auto-Close
- [ ] יצירת `scheduledGameAutoClose` scheduled function
- [ ] רץ כל 10 דקות
- [ ] מוצא משחקים pending שלא התחילו תוך 3 שעות → `archived_not_played`
- [ ] מוצא משחקים active שלא הסתיימו תוך 5 שעות → `completed`
- [ ] שולח FCM notification

#### 4. UI Updates
- [ ] הצגת סטטוס `archived_not_played` בצבע אפור
- [ ] הודעת הסבר למשתמש
- [ ] הסתרת משחקים archived מה-feed (אופציונלי)

**קבצים לעדכון:**
- `lib/models/enums/game_status.dart`
- `lib/models/game.dart`
- `functions/index.js` (Cloud Function)
- `lib/screens/game/game_detail_screen.dart`

**זמן משוער:** 3-4 ימים

---

## Week 8: Team Balancing UI

### מטרה
מסך ייעודי לאיזון קבוצות עם UI משופר.

### משימות

#### 1. Team Balancing Screen
- [ ] יצירת `team_balancing_screen.dart`
- [ ] הצגת שתי קבוצות (A/B) side-by-side
- [ ] Drag & drop בין קבוצות
- [ ] Balance score indicator

#### 2. Auto Balance Button
- [ ] שימוש ב-`TeamMaker` הקיים
- [ ] הצגת preview לפני אישור
- [ ] אפשרות ל-reset

#### 3. Visual Improvements
- [ ] Color coding לקבוצות
- [ ] Player avatars
- [ ] Skill indicators
- [ ] Balance meter (visual)

**קבצים לעדכון:**
- `lib/screens/game/team_balancing_screen.dart` (חדש)
- `lib/logic/team_maker.dart` (כבר קיים - שימוש)

**זמן משוער:** 2-3 ימים

---

## 📊 סיכום Phase 1

| תכונה | זמן משוער | עדיפות | סטטוס |
|------|----------|--------|-------|
| Date of Birth + Age Groups | 2-3 ימים | 🔴 קריטי | ⏳ ממתין |
| Attendance Confirmation | 3-4 ימים | 🔴 קריטי | ⏳ ממתין |
| 3 Hub Tiers (Veteran) | 1-2 ימים | 🟡 גבוה | ⏳ ממתין (חלקית קיים) |
| Start Event + Auto-Close | 3-4 ימים | 🔴 קריטי | ⏳ ממתין |
| Team Balancing UI | 2-3 ימים | 🟡 גבוה | ⏳ ממתין |

**סה"כ:** 11-16 ימי עבודה (2-3 שבועות)

---

## 🎯 המלצה להתחלה

### אפשרות 1: לפי סדר עדיפויות (מומלץ)
1. **Date of Birth + Age Groups** - בסיס לכל התכונות האחרות
2. **Attendance Confirmation** - תכונה קריטית למשתמשים
3. **Start Event + Auto-Close** - שיפור UX משמעותי
4. **3 Hub Tiers** - מהיר (כבר יש enum)
5. **Team Balancing UI** - שיפור UX

### אפשרות 2: לפי קלות ביצוע
1. **3 Hub Tiers** - הכי מהיר (enum כבר קיים)
2. **Date of Birth + Age Groups** - בינוני
3. **Team Balancing UI** - בינוני
4. **Start Event + Auto-Close** - מורכב יותר
5. **Attendance Confirmation** - הכי מורכב (Cloud Function + UI)

---

## 📝 הוראות ביצוע

לכל תכונה:
1. קרא את ה-`10_IMPLEMENTATION_SUPPLEMENT.md` לפרטים
2. בדוק את ה-`11_CURRENT_STATE.md` מה כבר קיים
3. עקוב אחר ה-`.cursorrules` לכללי הקוד
4. עדכן את `Agent steps` אחרי כל תכונה
5. הרץ `flutter pub run build_runner build` אחרי שינויי models

---

## 🚀 התחלה

**אני ממליץ להתחיל עם: Date of Birth + Age Groups**

זו התכונה הבסיסית ביותר וכל השאר נשענים עליה. אחרי שזה יושלם, נוכל להמשיך ל-Attendance Confirmation.

**האם להתחיל עם Date of Birth + Age Groups?**

