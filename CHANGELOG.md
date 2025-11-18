# Changelog

כל השינויים המשמעותיים בפרויקט Kickadoor מתועדים בקובץ זה.

הפורמט מבוסס על [Keep a Changelog](https://keepachangelog.com/he/1.0.0/),
והפרויקט עוקב אחר [Semantic Versioning](https://semver.org/lang/he/).

## [Unreleased] - 2024-11-18

### Added
- **Cloud Functions v2 Migration** - שדרוג מלא של כל Firebase Functions ל-v2 API
  - `onGameCreated` - יצירת פוסט אוטומטי בפיד כשנוצר משחק חדש
  - `onHubMessageCreated` - שליחת התראות פוש אוטומטיות להודעות בצ'אט Hub
  - `searchVenues` - חיפוש מגרשים מאובטח דרך Google Places API עם API Key מוגן
- **Firestore Security Rules** - כללי אבטחה מפורסמים ומאובטחים ל-Firestore ו-Storage
- **Firestore Indexes** - אינדקסים מותאמים לשאילתות מורכבות (games, hubs, users)
- **Custom Permissions System** - מערכת הרשאות מותאמות אישית ליצירת אירועים ופוסטים
  - מנהלי Hubs יכולים להגדיר מי יכול ליצור אירועים ופוסטים
  - תמיכה ב-Firestore rules וב-application code
- **Enhanced Event Creation** - שיפורים מקיפים ליצירת אירועים:
  - מספר קבוצות (ברירת מחדל: 3)
  - סוג משחק (3v3 עד 11v11)
  - משך דקות המשחק (גלגלת אנכית)
  - מספר משתתפים מקסימלי (גלגלת אנכית, ברירת מחדל: 15)
  - התראות אוטומטיות לחברי ההאב
  - הגבלת הרשמה למקסימום משתתפים
- **Enhanced Scouting System** - שיפורים למערכת גיוס שחקנים:
  - פילטרים חדשים: טווח גילאים ואיזור מגורים
  - מיון לפי מרחק (הקרוב ביותר למעלה)
  - כרטיס שחקן מפורט עם כל הפרטים
- **Game-Event Linking** - משחקים יכולים להיות קשורים לאירועים
- **Hub Management Improvements** - שיפורי UI/UX למנהלי Hubs:
  - תצוגת תפקיד המשתמש
  - תאריך יצירת ההאב
  - רשימת חברים משופרת
  - כפתורי ניהול מעוצבים

### Changed
- **Firestore Persistence** - עדכון מ-`enablePersistence()` ל-`Settings.persistenceEnabled` (API החדש)
- **Theme Colors** - עדכון מ-`surfaceVariant` ל-`surfaceContainerHighest` (Material 3)
- **Color Opacity** - עדכון חלקי מ-`withOpacity()` ל-`withValues(alpha:)` (API החדש)

### Fixed
- **Critical Errors** - תיקון כל השגיאות הקריטיות:
  - תיקון `RemoteConfig` undefined identifier ב-`remote_config_service.dart`
  - תיקון `isAnonymous` getter ב-test files
  - תיקון package names מ-`kickabout` ל-`kickadoor` בכל קבצי ה-test
  - תיקון `validateRating` function signature ב-test files
- **Code Cleanup** - ניקוי מקיף של הקוד:
  - תיקון מעל 140 אזהרות `unused_import`
  - הסרת קבצי .md מיותרים (25+ קבצים)
  - הסרת ספריות מיותרות (`Kickadoor Mobile App Design/`, `client/`, `client_backup/`)
- **Build Process** - הוספת שלב `build_runner` להוראות ההתקנה

### Removed
- **Artifact Files** - מחיקת כל קבצי ה-.md שנוצרו כתוצרי לוואי של תהליכי פיתוח קודמים:
  - `API_KEY_SECURITY_WARNING.md`
  - `COMPLETED_FEATURES_SUMMARY.md`
  - `COMPREHENSIVE_REVIEW.md`
  - `DEPLOYMENT.md`
  - `DEPLOYMENT_CHECKLIST.md`
  - `FIGMA_MAKE_PROMPT.md`
  - `FINAL_SUMMARY.md`
  - `FIREBASE_GEMINI_RESPONSE.md`
  - `FIREBASE_IMPLEMENTATION_GUIDE.md`
  - `FIREBASE_SETUP_STATUS.md`
  - `FIX_DEPLOYMENT_ERROR.md`
  - `IMPLEMENTATION_COMPLETE.md`
  - `IMPLEMENTATION_SUMMARY.md`
  - `IMPROVEMENTS_ANALYSIS.md`
  - `LOVEART_AI_PROMPT.md`
  - `MISSING_FEATURES_ANALYSIS.md`
  - `NEXT_STEPS_ACTION_PLAN.md`
  - `NEXT_STEPS_ROADMAP.md`
  - `PERFORMANCE_OPTIMIZATIONS.md`
  - `PRIORITY_FEATURES_IMPLEMENTATION_SUMMARY.md`
  - `SECURITY_NOTES.md`
  - `SECURITY_REVIEW.md`
  - `STAGE_1_COMPLETED.md`
  - `STAGE_1_GUIDE.md`
  - `VENUE_SYSTEM_DOCUMENTATION.md`
  - ועוד...
- **Unused Directories** - מחיקת ספריות מיותרות:
  - `Kickadoor Mobile App Design/` - פרויקט React נפרד
  - `client/` - גיבוי ישן
  - `client_backup/` - גיבוי נוסף

### Security
- **API Key Protection** - Google Places API Key מוגדר ב-Environment Variables של Cloud Functions
- **Firestore Rules** - כללי אבטחה מפורסמים ומאובטחים
- **Code Security** - הסרת כל hardcoded secrets וקבצים רגישים

---

## [Previous Versions]

השינויים הקודמים לא תועדו בפורמט זה.

---

## Notes

- כל השינויים נבדקו עם `flutter analyze`
- כל ה-Firebase Functions נבדקו ונפרסו בהצלחה
- הפרויקט מוכן כעת ל-commit יציב ונקי

