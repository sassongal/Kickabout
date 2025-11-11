# Kickabout - Israeli Pickup Soccer App

## 📱 תקציר MVP

Kickabout היא אפליקציה לניהול משחקי כדורגל מזדמנים (pickup soccer) בישראל. האפליקציה מאפשרת לשחקנים ליצור הובים (hubs), לארגן משחקים, לבנות קבוצות מאוזנות באופן דטרמיניסטי, ולעקוב אחר סטטיסטיקות ודירוגים.

## ✨ תכונות עיקריות

### 🔐 אימות
- **כניסה אנונימית** - התחברות מהירה ללא יצירת חשבון
- **כניסה עם מייל/סיסמה** - חשבון מלא עם הרשמה
- **איפוס סיסמה** - שחזור סיסמה דרך אימייל

### 👥 הובים (Hubs)
- יצירת הובים לניהול קבוצות שחקנים
- הצטרפות/עזיבה מהובים
- רשימת חברים בהוב

### ⚽ משחקים
- יצירת משחקים עם תאריך, שעה, מיקום
- בחירת מספר קבוצות (2/3/4)
- ניהול נרשמים (מאושר/ממתין)
- מעקב אחר סטטוס משחק (teamSelection → teamsFormed → inProgress → completed)

### 🎯 יצירת קבוצות (Team Maker)
- **אלגוריתם דטרמיניסטי** - snake draft + local swap
- איזון אוטומטי לפי דירוג שחקנים
- גרירה ושחרור (drag & drop) לשדרוג ידני
- תצוגת מטריקות איזון

### 📊 רישום סטטיסטיקות
- טיימר מקומי למעקב זמן משחק
- רישום אירועים בזמן אמת: שערים, בישולים, הצלות, כרטיסים, MVP
- שמירה אוטומטית ל-Firestore עם serverTimestamp
- סיכום משחק בעברית עם אפשרות שיתוף ב-WhatsApp

### ⭐ מערכת דירוגים
- דירוג שחקנים ב-8 קטגוריות: defense, passing, shooting, dribbling, physical, leadership, teamPlay, consistency
- חישוב דירוג נוכחי (ממוצע של N משחקים אחרונים או time-based decay)
- גרף היסטוריית דירוגים
- פרופיל שחקן עם דירוג נוכחי והיסטוריה

### 📸 תמונות פרופיל
- העלאת תמונות פרופיל ל-Firebase Storage
- עריכת פרופיל (שם, אימייל, טלפון, עמדה מועדפת)

### 🌐 תמיכה ב-RTL ועברית
- ממשק בעברית (RTL)
- תמיכה ב-localization (עברית/אנגלית)

## 🛠 טכנולוגיות

### Frontend
- **Flutter** - Framework cross-platform (Web, iOS, Android)
- **Riverpod** - State management
- **GoRouter** - Declarative routing
- **Freezed** - Immutable data classes
- **JSON Serializable** - JSON serialization

### Backend & Services
- **Firebase Auth** - Authentication (Anonymous + Email/Password)
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - File storage (תמונות פרופיל)
- **Firebase Hosting** - Web hosting (לעתיד)

### Libraries
- `fl_chart` - Charts for rating history
- `image_picker` - Image selection
- `share_plus` - Sharing functionality
- `url_launcher` - URL/WhatsApp links

## 📋 דרישות

- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Firebase project (עם Auth, Firestore, Storage מופעלים)

## 🚀 הוראות הרצה מקומית

### 1. התקנת תלויות

```bash
flutter pub get
```

### 2. הגדרת Firebase

#### אופציה א': FlutterFire CLI (מומלץ)

```bash
# התקנת FlutterFire CLI
dart pub global activate flutterfire_cli

# הגדרת Firebase
flutterfire configure
```

#### אופציה ב': הגדרה ידנית

1. הוסף את `google-services.json` ל-`android/app/`
2. הוסף את `GoogleService-Info.plist` ל-`ios/Runner/`
3. עדכן את `lib/config/firebase_options.dart` (או הפעל `flutterfire configure`)

### 3. הרצת האפליקציה

```bash
# Web
flutter run -d chrome

# iOS
flutter run -d ios

# Android
flutter run -d android
```

### 4. מצב מוגבל (Limited Mode)

אם Firebase לא מוגדר, האפליקציה תרוץ ב-"Limited Mode" - ללא גישה ל-Firebase, אך עם UI מלא לבדיקות.

## 📁 מבנה הפרויקט

```
lib/
├── config/          # תצורת Firebase ו-Environment
├── core/            # קבועים ומסרים
├── data/            # Repositories ל-Firestore
├── l10n/            # קבצי localization
├── logic/           # לוגיקה עסקית (Team Maker)
├── models/          # Data models (Freezed)
├── routing/         # GoRouter configuration
├── screens/         # מסכי האפליקציה
│   ├── auth/        # מסכי אימות
│   ├── game/        # מסכי משחקים
│   ├── hub/         # מסכי הובים
│   └── profile/     # מסכי פרופיל
├── services/        # Services (Auth, Storage)
├── ui/              # UI components (Team Builder)
├── utils/           # Utilities (Recap Generator, Snackbar Helper)
└── widgets/         # Reusable widgets
```

## 🔒 אבטחה

- כל הקבצים הרגישים (`.env`, `google-services.json`, `GoogleService-Info.plist`) מוחרגים ב-`.gitignore`
- אין hardcoded secrets בקוד
- Firebase Security Rules נדרשות ל-Firestore ו-Storage

## 📦 Deployment

### Firebase Hosting (Web)

```bash
# Build
flutter build web

# Deploy
firebase deploy --only hosting
```

### App Store / Play Store

```bash
# iOS
flutter build ios --release

# Android
flutter build appbundle --release
```

## 🧪 בדיקות

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📝 הערות

- האפליקציה תומכת ב-**Hebrew-first** עם RTL
- ה-Team Maker משתמש ב-**אלגוריתם דטרמיניסטי** (ללא AI בזמן ריצה)
- כל הנתונים נשמרים ב-**Firestore** עם מבנה מוגדר
- ה-Stats Logger משתמש ב-**טיימר מקומי** (לא מסונכרן בין מכשירים)

## 🤝 תרומה

זהו פרויקט MVP. תרומות יתקבלו בברכה!

## 📄 רישיון

[ציין רישיון כאן]

## 👤 יצירת קשר

Gal - you@joya-tech.net

