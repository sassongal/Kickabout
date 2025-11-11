# 🚀 הוראות Deployment

## GitHub Repository

הפרויקט כבר מחובר ל-GitHub:
- **Repository**: `git@github.com:sassongal/Kickabout.git`
- **Branch**: `main`

### העלאה ל-GitHub

```bash
# ודא שאתה על branch main
git branch -M main

# העלה את השינויים
git push -u origin main
```

## 🔒 בדיקת אבטחה

לפני העלאה, ודא שאין קבצים רגישים:

```bash
# בדוק אם יש קבצים רגישים ב-staging
git status | grep -E "(\.env|google-services|GoogleService|serviceAccount)"

# בדוק מה כבר ב-remote
git ls-remote origin main | head -5
```

## 📦 Firebase Deployment

### Web (Firebase Hosting)

```bash
# Build
flutter build web --release

# Deploy (אם יש Firebase project מוגדר)
firebase deploy --only hosting
```

### Android (Play Store)

```bash
# Build App Bundle
flutter build appbundle --release

# הקובץ יהיה ב: build/app/outputs/bundle/release/app-release.aab
```

### iOS (App Store)

```bash
# Build iOS
flutter build ios --release

# פתח Xcode וסיים את התהליך
open ios/Runner.xcworkspace
```

## 🔐 הגדרת Firebase

### 1. יצירת Firebase Project

1. לך ל-[Firebase Console](https://console.firebase.google.com/)
2. צור project חדש או בחר קיים
3. הפעל את השירותים הבאים:
   - **Authentication** (Email/Password + Anonymous)
   - **Cloud Firestore**
   - **Storage**

### 2. הגדרת FlutterFire CLI

```bash
# התקן FlutterFire CLI
dart pub global activate flutterfire_cli

# הגדר את הפרויקט
flutterfire configure
```

זה ייצור את `lib/config/firebase_options.dart` אוטומטית.

### 3. הגדרת Security Rules

#### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users - כל משתמש יכול לקרוא, רק הוא יכול לערוך
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Hubs - כל משתמש יכול לקרוא, רק חברים יכולים לערוך
    match /hubs/{hubId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (request.resource.data.memberIds.hasAny([request.auth.uid]) ||
         request.resource.data.createdBy == request.auth.uid);
    }
    
    // Games - כל משתמש יכול לקרוא, רק יוצר יכול לערוך
    match /games/{gameId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.createdBy == request.auth.uid;
      
      // Signups - כל משתמש יכול לקרוא/לכתוב את שלו
      match /signups/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Teams - כל משתמש יכול לקרוא, רק יוצר המשחק יכול לכתוב
      match /teams/{teamId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && 
          get(/databases/$(database)/documents/games/$(gameId)).data.createdBy == request.auth.uid;
      }
      
      // Events - כל משתמש יכול לקרוא/לכתוב
      match /events/{eventId} {
        allow read, write: if request.auth != null;
      }
    }
    
    // Ratings - כל משתמש יכול לקרוא, רק הוא יכול לכתוב את שלו
    match /ratings/{userId}/history/{ratingId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile photos - כל משתמש יכול לקרוא, רק הוא יכול לכתוב
    match /profile_photos/{userId}.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Game photos - כל משתמש יכול לקרוא/לכתוב
    match /game_photos/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📝 הערות

- **אל תעלה קבצים רגישים** - `.env`, `google-services.json`, `GoogleService-Info.plist` כבר ב-`.gitignore`
- **בדוק Security Rules** - ודא שהכל מאובטח לפני production
- **Test במוקדם** - בדוק את כל התכונות לפני deployment

