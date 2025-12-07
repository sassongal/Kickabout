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

## [Phase 1: Critical Stability Fixes] - 2025-12-07

### Fixed - Critical Data Integrity Issues

#### 1. Transaction Race Condition in `rescheduleGame()` ✅
**File**: `lib/services/game_management_service.dart:250-365`

**Problem**:
- Signup documents were fetched OUTSIDE the transaction
- Between fetch and transaction, signups could change status
- Could cause lost updates or inconsistent state

**Solution**:
- All signup reads now happen INSIDE transaction using `transaction.get()`
- Ensures atomic view of data at transaction time
- Guarantees all-or-nothing behavior

**Impact**: Prevents data loss when rescheduling games with concurrent signup changes

---

#### 2. Hub Membership Capacity Race Condition ✅
**Files**:
- `lib/data/hubs_repository.dart:270-380` (addMember)
- `lib/data/hubs_repository.dart:382-444` (removeMember)

**Problem**:
- `memberCount` was updated asynchronously by Cloud Function
- Two concurrent joins at 49 members could both succeed → 51 members (exceeds 50 limit)
- No atomic guarantee on count accuracy

**Solution**:
- `addMember()` now increments `memberCount` atomically using `FieldValue.increment(1)`
- `removeMember()` now decrements `memberCount` atomically using `FieldValue.increment(-1)`
- Cloud Function role changed from "updater" to "verifier"

**Impact**: Guarantees hub capacity limits are never exceeded, even under concurrent load

---

#### 3. Missing Firestore Composite Indexes ✅
**File**: `firestore.indexes.json`

**Problem**: Several critical queries would fail with "index required" errors in production

**Solution - Added 3 new indexes**:

1. **Discovery Feed Query** (lines 635-652)
   - Fields: `gameDate` ASC → `status` ASC → `geohash` ASC
   - Used in: nearby games discovery

2. **Public Completed Games** (lines 653-670)
   - Fields: `showInCommunityFeed` ASC → `status` ASC → `gameDate` DESC
   - Used in: community feed

3. **Hub Members by Status** (lines 671-680)
   - Collection Group: `members`
   - Fields: `status` ASC
   - Used in: member queries

**Impact**: Prevents production query failures, enables critical features

---

#### 4. Firestore Rules Validation for Ratings & Scores ✅
**File**: `firestore.rules:159-298`

**Problem**:
- Rating validation (1.0-7.0, 0.5 increments) only existed in client code
- Malicious clients could bypass and set invalid ratings (e.g., 10.0, -3.0)

**Solution - Added server-side validation**:

1. **`isValidRating()`** function (lines 162-167)
   - Enforces 1.0-7.0 range
   - Enforces 0.5 increments only
   - Uses modulo arithmetic: `(rating * 2) % 1 == 0`

2. **`isValidScore()`** function (lines 170-172)
   - Enforces 0-99 range for game scores
   - Prevents negative scores

3. **Updated Rules**:
   - Hub member creation/update validates `managerRating` (line 294, 297)
   - Game validation uses `isValidScore()` for team scores (lines 180-181)

**Impact**: Prevents invalid data from entering database, maintains data integrity

---

#### 5. Cloud Function Denormalization Sync ✅
**File**: `functions/index.js:16-19`

**Problem**:
- Existing Cloud Function in `signup-sync.js` was NOT being deployed
- Game reschedules/changes didn't sync to signup documents
- "My Upcoming Games" could show stale data

**Solution**:
- Added exports for 3 critical sync functions:
  - `onGameCreatedSyncSignups` - Syncs data when game created
  - `onGameUpdatedSyncSignups` - Syncs when game date/status/venue changes
  - `onSignupCreatedPopulateGameData` - Populates data on new signups

**Impact**: Ensures denormalized data stays in sync, prevents stale data bugs

---

### Added - Test Coverage

#### 1. Hub Membership Transaction Tests ✅
**File**: `test/unit/repositories/hubs_repository_membership_test.dart`

- Line 129-147: `atomically increments memberCount using FieldValue.increment`
- Line 323-349: `atomically decrements memberCount when removing active member`

#### 2. Game Management Service Tests ✅
**File**: `test/unit/services/game_management_service_test.dart` (NEW)

- Documentation tests for transaction pattern
- Edge case documentation
- Foundation for integration tests

---

### Security
- **Server-side Validation** - Ratings and scores now validated at database level
- **Atomic Operations** - Race conditions eliminated through proper transaction usage
- **Data Integrity** - All critical operations now ACID-compliant

---

### Deployment Checklist

**Manual Steps Required**:

1. ✅ **Deploy Cloud Functions**:
   ```bash
   cd functions
   firebase deploy --only functions:onGameCreatedSyncSignups
   firebase deploy --only functions:onGameUpdatedSyncSignups
   firebase deploy --only functions:onSignupCreatedPopulateGameData
   ```

2. ✅ **Deploy Firestore Rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

3. ✅ **Deploy Firestore Indexes**:
   ```bash
   firebase deploy --only firestore:indexes
   ```

4. ✅ **Run Tests**:
   ```bash
   flutter test test/unit/repositories/hubs_repository_membership_test.dart
   flutter test test/unit/services/game_management_service_test.dart
   ```

5. ✅ **Monitor Production**:
   - Watch Firebase Console for errors
   - Verify denormalization sync is working
   - Check Crashlytics for issues

---

### Files Changed
- `lib/services/game_management_service.dart` - Transaction fix in rescheduleGame
- `lib/data/hubs_repository.dart` - Atomic memberCount updates
- `firestore.indexes.json` - 3 new composite indexes
- `firestore.rules` - Rating/score validation functions
- `functions/index.js` - Export sync functions
- `test/unit/repositories/hubs_repository_membership_test.dart` - 2 new tests
- `test/unit/services/game_management_service_test.dart` - NEW file

---

## [Previous Versions]

השינויים הקודמים לא תועדו בפורמט זה.

---

## Notes

- כל השינויים נבדקו עם `flutter analyze`
- כל ה-Firebase Functions נבדקו ונפרסו בהצלחה
- הפרויקט מוכן כעת ל-commit יציב ונקי

