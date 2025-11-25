# Kickadoor - Project Overview for Dean

<div dir="rtl">

## 📋 תוכן עניינים

1. [סקירה כללית](#סקירה-כללית)
2. [מטרת הפרויקט](#מטרת-הפרויקט)
3. [מי הלקוח האידיאלי?](#מי-הלקוח-האידיאלי)
4. [מבנה הפרויקט - מבט טכני](#מבנה-הפרויקט---מבט-טכני)
5. [מה זה Flutter? (למי שלא מכיר)](#מה-זה-flutter-למי-שלא-מכיר)
6. [מפרט טכני מפורט](#מפרט-טכני-מפורט)
7. [מה חסר? מה נדרש להשלמה?](#מה-חסר-מה-נדרש-להשלמה)
8. [דרישות להמשך פיתוח](#דרישות-להמשך-פיתוח)
9. [סיכום והמלצות](#סיכום-והמלצות)

---

## 📱 סקירה כללית

**Kickadoor** היא אפליקציית מובייל (iOS ו-Android) המהווה רשת חברתית לכדורגל שכונתי בישראל. האפליקציה מחברת בין שחקנים, קבוצות (Hubs), ומגרשים, ומאפשרת ניהול מלא של משחקי כדורגל שכונתיים.

### מה האפליקציה עושה?

האפליקציה מאפשרת:

- **לשחקנים**: למצוא קבוצות (Hubs) פעילות בקרבתם, להצטרף לקהילות, למצוא שחקנים אחרים מהאיזור, ולנהל את הפרופיל והסטטיסטיקות שלהם
- **למנהלי קבוצות (Hubs)**: לנהל את הקבוצה, לארגן משחקים ואירועים, למצוא שחקנים חדשים, ולנהל הרשאות ותפקידים
- **לכולם**: ליצור קשרים חברתיים סביב הכדורגל, לשתף תמונות וחוויות, לתקשר בצ'אט, ולבנות קהילה פעילה

### מצב נוכחי

האפליקציה נמצאת בשלב **פיתוח פעיל** - רוב התכונות הבסיסיות מושלמות ופועלות, אך יש עוד עבודה להשלמת תכונות מתקדמות ותיקון באגים.

---

## 🎯 מטרת הפרויקט

### החזון

ליצור פלטפורמה מרכזית לכדורגל שכונתי בישראל שתאפשר:

1. **חיבור שחקנים וקבוצות** - שחקנים יכולים למצוא קבוצות בקרבתם, וקבוצות יכולות למצוא שחקנים
2. **ניהול משחקים מקצועי** - ארגון משחקים, איזון קבוצות, רישום סטטיסטיקות
3. **קהילה פעילה** - פיד חברתי, צ'אט, הודעות, שיתוף תמונות
4. **מעקב ביצועים** - דירוג שחקנים, סטטיסטיקות, היסטוריית משחקים

### השוק

השוק הישראלי לכדורגל שכונתי הוא גדול ופעיל, עם אלפי שחקנים וקבוצות ברחבי הארץ. כיום, רוב הפעילות מתנהלת דרך WhatsApp וקבוצות פייסבוק, מה שיוצר בעיות של:

- קושי למצוא שחקנים/קבוצות חדשים
- ניהול לא מסודר של משחקים
- חוסר מעקב אחר ביצועים
- חוסר קהילה מרכזית

Kickadoor נועדה לפתור את כל הבעיות האלה.

---

## 👥 מי הלקוח האידיאלי?

### קהלי יעד עיקריים

#### 1. שחקני כדורגל שכונתי (גילאים 18-50)
- **פרופיל**: שחקנים שמשחקים כדורגל באופן קבוע או מזדמן
- **צרכים**: למצוא קבוצות, להצטרף למשחקים, לעקוב אחר ביצועים
- **תכונות רלוונטיות**: חיפוש Hubs, רישום למשחקים, פרופיל שחקן, סטטיסטיקות

#### 2. מנהלי קבוצות/הובס (Hub Managers)
- **פרופיל**: אנשים שמנהלים קבוצות כדורגל שכונתיות
- **צרכים**: לנהל את הקבוצה, לארגן משחקים, למצוא שחקנים חדשים
- **תכונות רלוונטיות**: ניהול Hub, יצירת משחקים/אירועים, גיוס שחקנים, אנליטיקס

#### 3. שחקנים מקצועיים/חצי-מקצועיים
- **פרופיל**: שחקנים שמחפשים לשפר את הביצועים ולעקוב אחר הסטטיסטיקות
- **צרכים**: מעקב מפורט אחר ביצועים, השוואה לשחקנים אחרים
- **תכונות רלוונטיות**: דירוגים מפורטים, גרפים, לוח תוצאות

### שוק פוטנציאלי

- **ישראל**: כ-500,000-1,000,000 שחקני כדורגל פעילים
- **קבוצות שכונתיות**: אלפי קבוצות ברחבי הארץ
- **מגרשים**: מאות מגרשים ציבוריים ופרטיים

---

## 🏗️ מבנה הפרויקט - מבט טכני

### ארכיטקטורה כללית

```
┌─────────────────────────────────────────┐
│         Flutter Mobile App              │
│  (iOS, Android, Web - Single Codebase)  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Firebase Backend                │
│  ┌──────────────────────────────────┐  │
│  │  Firestore (Database)            │  │
│  │  - Users, Hubs, Games, Posts     │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │  Cloud Functions (Backend Logic)  │  │
│  │  - Notifications, Auto-posts      │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │  Firebase Storage (Files)        │  │
│  │  - Images, Photos                │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │  Firebase Auth (Authentication)  │  │
│  └──────────────────────────────────┘  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│      External Services                   │
│  - Google Maps API                      │
│  - Google Places API                    │
│  - FCM (Push Notifications)             │
└─────────────────────────────────────────┘
```

### מבנה תיקיות הפרויקט

```
kickabout/
├── lib/                          # קוד המקור הראשי (Dart/Flutter)
│   ├── config/                   # תצורת Firebase ו-Environment
│   ├── core/                     # קבועים וכלים בסיסיים
│   ├── data/                     # Repositories - גישה ל-Firestore
│   │   ├── repositories.dart     # כל ה-Repositories
│   │   ├── hubs_repository.dart  # ניהול Hubs
│   │   ├── games_repository.dart # ניהול משחקים
│   │   ├── users_repository.dart # ניהול משתמשים
│   │   └── ...
│   ├── models/                   # Data Models (61 קבצים)
│   │   ├── user.dart            # מודל משתמש
│   │   ├── hub.dart             # מודל Hub
│   │   ├── game.dart            # מודל משחק
│   │   ├── hub_event.dart       # מודל אירוע
│   │   └── ...
│   ├── routing/                  # ניהול ניווט (GoRouter)
│   │   └── app_router.dart      # הגדרת כל ה-routes
│   ├── screens/                   # מסכי האפליקציה (54 מסכים)
│   │   ├── auth/                 # מסכי התחברות/רישום
│   │   ├── home/                 # מסך בית
│   │   ├── hub/                  # מסכי Hubs (15 מסכים)
│   │   ├── game/                 # מסכי משחקים (8 מסכים)
│   │   ├── profile/              # מסכי פרופיל
│   │   ├── social/               # מסכי רשת חברתית (9 מסכים)
│   │   ├── location/             # מסכי מפה וחיפוש
│   │   └── ...
│   ├── services/                  # Services (23 קבצים)
│   │   ├── auth_service.dart     # אימות משתמשים
│   │   ├── location_service.dart  # מיקום GPS
│   │   ├── push_notification_service.dart
│   │   └── ...
│   ├── widgets/                   # רכיבי UI לשימוש חוזר (33 קבצים)
│   ├── theme/                     # עיצוב וטיפוגרפיה
│   └── utils/                     # כלי עזר
├── assets/                        # קבצי מדיה
│   ├── icons/                     # אייקונים (29 קבצים)
│   ├── images/                    # תמונות
│   └── logo/                      # לוגו
├── functions/                     # Firebase Cloud Functions (Node.js)
│   └── index.js                   # כל ה-Functions
├── firestore.rules                # כללי אבטחה ל-Firestore
├── firestore.indexes.json         # אינדקסים ל-Firestore
├── android/                       # קוד Android native
├── ios/                           # קוד iOS native
└── pubspec.yaml                   # תלויות הפרויקט
```

### סטטיסטיקות קוד

- **54 מסכים** - כל מסך הוא קובץ נפרד
- **61 מודלים** - מבני נתונים (User, Hub, Game, וכו')
- **23 Services** - שירותים (Auth, Location, Notifications, וכו')
- **33 Widgets** - רכיבי UI לשימוש חוזר
- **20 Repositories** - גישה לנתונים ב-Firestore
- **כ-15,000+ שורות קוד** (הערכה)

---

## 📱 מה זה Flutter? (למי שלא מכיר)

### מבוא ל-Flutter

**Flutter** הוא framework של Google לפיתוח אפליקציות מובייל cross-platform. זה אומר שאתה כותב קוד **פעם אחת** ומקבל אפליקציות ל-**iOS, Android, ו-Web**.

### למה Flutter?

#### יתרונות:

1. **Cross-Platform** - קוד אחד לכל הפלטפורמות
   - חוסך זמן פיתוח משמעותי
   - קל לתחזוקה (תיקון באג אחד מתקן בכל הפלטפורמות)

2. **ביצועים מעולים** - Flutter לא משתמש ב-WebView או JavaScript bridge
   - האפליקציה מהירה כמו אפליקציה native
   - UI חלק ו-fluid

3. **Hot Reload** - שינויים בקוד נראים מיד באפליקציה
   - מקצר מאוד את זמן הפיתוח
   - מאפשר לראות שינויים תוך שניות

4. **קהילה גדולה** - הרבה חבילות (packages) זמינות
   - Firebase, Maps, ועוד הרבה

5. **Material Design & Cupertino** - עיצוב מודרני מובנה

#### חסרונות:

1. **גודל אפליקציה** - אפליקציות Flutter נוטות להיות גדולות יותר מאפליקציות native
2. **תלות ב-Google** - Flutter הוא של Google (אבל open-source)
3. **עקומת למידה** - צריך ללמוד Dart (שפה חדשה)

### מה זה Dart?

**Dart** היא שפת התכנות שבה כותבים Flutter. היא דומה ל-JavaScript/TypeScript, אבל עם:

- **Type Safety** - בדיקת טיפוסים בזמן קומפילציה (כמו TypeScript)
- **Null Safety** - הגנה מפני שגיאות null
- **Async/Await** - תמיכה טובה ב-asynchronous programming

### דוגמה לקוד Flutter:

```dart
// דוגמה פשוטה - מסך עם כפתור
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hello')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            print('Button clicked!');
          },
          child: Text('Click me'),
        ),
      ),
    );
  }
}
```

### איך Flutter עובד?

1. **כותבים קוד ב-Dart** (בתיקיית `lib/`)
2. **Flutter קומפיל** את הקוד ל-native code
3. **התוצאה**: אפליקציה native לכל פלטפורמה

---

## 🔧 מפרט טכני מפורט

### Frontend (Mobile App)

#### טכנולוגיות עיקריות:

1. **Flutter SDK 3.6.0+**
   - Framework לפיתוח cross-platform
   - תמיכה ב-iOS, Android, Web

2. **Riverpod 2.6.1** - State Management
   - ניהול מצב האפליקציה
   - דומה ל-Redux או MobX
   - **למה Riverpod?** - פתרון מודרני, type-safe, קל לבדיקות

3. **GoRouter 14.2.7** - Navigation/Routing
   - ניהול ניווט בין מסכים
   - תמיכה ב-deep linking
   - **למה GoRouter?** - declarative, type-safe, תמיכה ב-complex navigation

4. **Freezed 2.5.7** - Immutable Data Classes
   - יצירת מודלים (Models) immutable
   - code generation אוטומטי
   - **למה Freezed?** - בטיחות, קל לתחזוקה, תמיכה ב-JSON serialization

#### חבילות עיקריות (Dependencies):

**Firebase:**
- `firebase_core` - ליבת Firebase
- `firebase_auth` - אימות משתמשים (Email, Google, Apple)
- `cloud_firestore` - מסד נתונים NoSQL עם real-time updates
- `firebase_storage` - אחסון קבצים (תמונות)
- `firebase_messaging` - Push notifications
- `firebase_analytics` - אנליטיקס
- `cloud_functions` - קריאה ל-Firebase Functions

**UI & Design:**
- `google_fonts` - פונטים מ-Google Fonts
- `fl_chart` - גרפים לסטטיסטיקות
- `cached_network_image` - תמונות עם cache
- `shimmer` - אפקט loading

**Location & Maps:**
- `geolocator` - GPS location
- `geocoding` - המרת כתובת ↔ קואורדינטות
- `google_maps_flutter` - מפות Google

**State & Data:**
- `shared_preferences` - אחסון מקומי
- `flutter_riverpod` - State management

**Other:**
- `image_picker` - בחירת תמונות
- `intl` - בינלאומיות (i18n)
- `http` - HTTP requests

### Backend (Firebase)

#### Firebase Services בשימוש:

1. **Firestore** - מסד נתונים NoSQL
   - **Collections**: users, hubs, games, events, feed, messages
   - **Real-time updates** - שינויים בנתונים מתעדכנים מיד באפליקציה
   - **Offline persistence** - האפליקציה עובדת גם ללא אינטרנט
   - **Security Rules** - כללי אבטחה מפורסמים

2. **Firebase Authentication**
   - Email/Password
   - Google Sign-In
   - Apple Sign-In
   - Anonymous (זמני)

3. **Firebase Storage**
   - אחסון תמונות פרופיל
   - אחסון תמונות משחקים
   - Security Rules מוגדרות

4. **Firebase Cloud Functions v2** (Node.js)
   - `onGameCreated` - יוצר פוסט אוטומטי כשנוצר משחק
   - `onHubMessageCreated` - שולח push notifications להודעות בצ'אט
   - `searchVenues` - חיפוש מגרשים דרך Google Places API (מאובטח)

5. **Firebase Cloud Messaging (FCM)**
   - Push notifications
   - התראות על משחקים, הודעות, תגובות

6. **Firebase Analytics**
   - מעקב אחר שימוש באפליקציה
   - אירועים מותאמים אישית

### External Services

1. **Google Maps Platform**
   - Google Maps API - תצוגת מפות
   - Google Places API - חיפוש מגרשים (דרך Cloud Functions)

2. **FCM (Firebase Cloud Messaging)**
   - Push notifications

### מבנה מסד הנתונים (Firestore)

#### Collections עיקריות:

1. **`/users/{userId}`** - משתמשים
   - פרטי פרופיל, מיקום, דירוגים, hubIds

2. **`/hubs/{hubId}`** - קבוצות
   - פרטי Hub, חברים, תפקידים, הרשאות
   - **Subcollections**:hubs/{hubId}/events/{eventId}` - אירועים
     - `/hubs/{hubId}/feed/posts/items/{postId}` - פוסטים בפיד
     - `/hubs/{hubId}/chat/messages/{messageId}` - הודעות צ'אט

3. **`/games/{gameId}`** - משחקים
   - פרטי משחק, תוצאות, שחקנים, סטטיסטיקות

4. **`/notifications/{userId}/items/{notificationId}`** - התראות

5. **`/venues/{venueId}`** - מגרשים

### Security & Rules

- **Firestore Security Rules** - כללי אבטחה מפורסמים ב-`firestore.rules`
- **Storage Security Rules** - כללי אבטחה ל-Storage ב-`storage.rules`
- **API Keys** - מוגנים ב-Environment Variables של Cloud Functions

---

## ❌ מה חסר? מה נדרש להשלמה?

### תכונות שצריך להשלים/לתקן

#### 1. תכונות חסרות עיקריות

**א. מערכת הרשאות מותאמות אישית - UI**
- ✅ **Backend מוכן** - יש תמיכה ב-`hub.permissions`
- ❌ **UI חסר** - אין מסך למנהל להגדיר הרשאות מותאמות
- **מה נדרש**: מסך ניהול הרשאות שבו מנהל יכול לבחור מי יכול ליצור אירועים/פוסטים

**ב. מסך אנליטיקס מלא**
- ✅ **Backend מוכן** - יש `HubAnalyticsScreen` אבל מציג "בקרוב"
- ❌ **לוגיקה חסרה** - צריך לחשב ולציג סטטיסטיקות אמיתיות
- **מה נדרש**: חישוב סטטיסטיקות Hub (מספר משחקים, שחקנים פעילים, וכו')

**ג. מערכת הזמנות (Invitations)**
- ✅ **Backend חלקי** - יש `hub_invitations_screen.dart`
- ❌ **לוגיקה חסרה** - צריך לשלוח הזמנות ולטפל בהן
- **מה נדרש**: שליחת הזמנות, קבלת הזמנות ב-inbox, אישור/דחייה

**ד. מערכת תגובות לפוסטים**
- ✅ **Backend מוכן** - יש תמיכה ב-Firestore
- ❌ **UI חסר** - אין מסך/UI לתגובות
- **מה נדרש**: UI לתגובות על פוסטים, יצירת תגובה, מחיקת תגובה

#### 2. באגים שצריך לתקן

**א. רשימת חברים לא מוצגת**
- **בעיה**: כשלוחצים על "חברים" בהאב, לא רואים רשימה
- **סיבה אפשרית**: `hub.memberIds` ריק או בעיה בטעינת משתמשים
- **סטטוס**: הוספתי debug logs, צריך לבדוק

**ב. המפה לא נטענת**
- **בעיה**: המפה תקועה ב-"טוען מפה..."
- **סיבה אפשרית**: בעיה בטעינת אייקונים או location service
- **סטטוס**: הוספתי timeout, צריך לבדוק

**ג. בעיות הרשאות**
- **בעיה**: משתמשים לא יכולים ליצור אירועים/פוסטים למרות שהם מנהלים
- **סיבה אפשרית**: בעיה ב-Firestore rules או ב-application code
- **סטטוס**: תיקנתי את ה-rules, צריך לבדוק

#### 3. שיפורים נדרשים

**א. ביצועים (Performance)**
- אופטימיזציה של טעינת תמונות
- Lazy loading למסכים גדולים
- Caching מתקדם יותר

**ב. UX/UI**
- שיפורי עיצוב במסכים מסוימים
- אנימציות חלקות יותר
- טיפול טוב יותר בשגיאות

**ג. בדיקות (Testing)**
- הוספת בדיקות אוטומטיות (Unit tests, Widget tests)
- בדיקות אינטגרציה
- בדיקות E2E

**ד. תיעוד**
- תיעוד API
- תיעוד קוד
- מדריכי משתמש

### תכונות עתידיות (Nice to Have)

1. **טורנירים וליגות** - ארגון טורנירים וליגות
2. **שיתוף ווידאו** - העלאת ושיתוף סרטונים
3. **מערכת תגמולים מורחבת** - נקודות, תגים, הישגים
4. **אינטגרציה עם רשתות חברתיות** - שיתוף ל-Facebook/Instagram
5. **אפליקציית מאמנים** - כלים מיוחדים למאמנים
6. **סטטיסטיקות מתקדמות** - ניתוחים עמוקים יותר

---

## 🛠️ דרישות להמשך פיתוח

### דרישות טכניות

#### 1. סביבת פיתוח

**חובה:**
- **Flutter SDK 3.6.0+** - Framework הראשי
- **Dart 3.0.0+** - שפת התכנות
- **Android Studio / VS Code** - IDE
- **Xcode** (לפיתוח iOS) - רק ב-Mac
- **Android SDK** - לפיתוח Android

**מומלץ:**
- **Git** - ניהול גרסאות
- **Firebase CLI** - לניהול Firebase
- **FlutterFire CLI** - להגדרת Firebase

#### 2. חשבונות ושירותים

**חובה:**
- **Firebase Project** - כבר קיים (`kickabout-ddc06`)
- **Google Cloud Platform Account** - לניהול Firebase
- **Google Maps API Key** - למפות (מוגדר ב-Cloud Functions)

**מומלץ:**
- **Apple Developer Account** - לפרסום ב-App Store (99$/שנה)
- **Google Play Console** - לפרסום ב-Play Store (25$ חד-פעמי)

#### 3. ידע טכני נדרש

**חובה:**
- **Flutter/Dart** - הבנה בסיסית לפחות
- **Firebase** - הבנה ב-Firestore, Auth, Storage
- **Git** - עבודה עם Git

**מומלץ:**
- **State Management** - הבנה ב-Riverpod
- **NoSQL Databases** - הבנה ב-Firestore
- **REST APIs** - הבנה ב-APIs

### תהליך פיתוח

#### 1. Setup סביבת פיתוח

```bash
# 1. התקנת Flutter
# (הורדה מ-flutter.dev)

# 2. Clone הפרויקט
git clone [repository-url]
cd kickabout

# 3. התקנת תלויות
flutter pub get

# 4. יצירת קוד (Code Generation)
flutter pub run build_runner build --delete-conflicting-outputs

# 5. הרצת האפליקציה
flutter run
```

#### 2. תהליך עבודה יומיומי

```bash
# 1. עדכון קוד מה-Git
git pull

# 2. עדכון תלויות (אם נוספו)
flutter pub get

# 3. יצירת קוד (אם שונו מודלים)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. בדיקת שגיאות
flutter analyze

# 5. הרצת האפליקציה
flutter run

# 6. Hot Reload - אחרי שינויים בקוד, לחץ 'r' בטרמינל
# או Hot Restart - לחץ 'R' בטרמינל
```

#### 3. פרסום שינויים

```bash
# 1. בדיקת שגיאות
flutter analyze

# 2. בדיקות (אם יש)
flutter test

# 3. Commit ל-Git
git add .
git commit -m "Description of changes"
git push

# 4. פרסום Firebase Functions (אם שונו)
firebase deploy --only functions

# 5. פרסום Firestore Rules (אם שונו)
firebase deploy --only firestore:rules
```

### מה זה דורש בפועל?

#### זמן פיתוח משוער להשלמת תכונות חסרות:

1. **מסך ניהול הרשאות** - 2-3 ימים
2. **מסך אנליטיקס מלא** - 3-5 ימים
3. **מערכת הזמנות** - 3-4 ימים
4. **מערכת תגובות** - 2-3 ימים
5. **תיקון באגים** - 2-3 ימים
6. **שיפורי UX/UI** - 3-5 ימים
7. **בדיקות ותיעוד** - 3-5 ימים

**סה"כ משוער: 18-28 ימי עבודה** (תלוי במורכבות)

#### מיומנויות נדרשות:

- **Flutter/Dart** - רמה בינונית-מתקדמת
- **Firebase** - רמה בינונית
- **UI/UX Design** - רמה בסיסית-בינונית
- **Problem Solving** - חשוב מאוד

---

## 📊 סיכום והמלצות

### מצב נוכחי

האפליקציה נמצאת ב-**שלב מתקדם של פיתוח**:

✅ **מה מוכן:**
- רוב התכונות הבסיסיות פועלות
- Backend (Firebase) מוגדר ומאובטח
- 54 מסכים מוכנים
- מערכת הרשאות בסיסית
- Push notifications
- מפות וחיפוש

❌ **מה חסר:**
- תכונות מתקדמות (אנליטיקס, הרשאות מותאמות UI)
- תיקון באגים מסוימים
- שיפורי UX/UI
- בדיקות אוטומטיות

### המלצות להמשך

#### למי שלא מכיר Flutter:

1. **למד Flutter בסיסי** - קורסים מקוונים, tutorials
2. **התנסה בפרויקט קטן** - לפני עבודה על הפרויקט הגדול
3. **קרא את הקוד הקיים** - הבן את המבנה והסגנון
4. **עבוד עם מפתח מנוסה** - לשאלות ותמיכה

#### למי שמכיר Flutter:

1. **התחיל עם תיקון באגים** - דרך טובה להכיר את הקוד
2. **הוסף תכונות קטנות** - לפני תכונות גדולות
3. **עקוב אחר ה-Conventions** - הקוד הקיים מגדיר את הסגנון
4. **תעד שינויים** - עדכן את CHANGELOG.md

### סיכום טכני

**טכנולוגיות:**
- Frontend: Flutter (Dart)
- Backend: Firebase (Firestore, Functions, Auth, Storage)
- External: Google Maps, Google Places

**גודל הפרויקט:**
- ~15,000+ שורות קוד
- 54 מסכים
- 61 מודלים
- 23 services

**רמת מורכבות:**
- **בינונית-מתקדמת** - לא פרויקט פשוט, אבל גם לא מסובך מדי

**זמן להשלמה:**
- **3-4 שבועות** עבודה ממוקדת להשלמת התכונות החסרות

---

## 📞 יצירת קשר ושאלות

אם יש שאלות או צריך עזרה:

- **Gal** - you@joya-tech.net
- **Repository**: [GitHub URL]
- **Documentation**: קרא את README.md ו-DATABASE_SCHEMA.md

---

**תאריך עדכון:** 18 בנובמבר 2024  
**גרסה:** Development  
**סטטוס:** פעיל בפיתוח

---

**Kickadoor** - פתח את הדלת לכדורגל שכונתי! 🚪⚽

</div>

