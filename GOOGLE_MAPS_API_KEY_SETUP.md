# הגדרת מפתח Google Maps API

## 📍 מיקומי המפתח

המפתח `AIzaSyAtGhXyexqP8bYiH2nqaTxeECtvENWqPPU` מוגדר בכל המקומות הבאים:

### 1. Client-Side (Flutter)
- **`lib/config/env.dart`** - מפתח לשימוש בקוד Flutter
  ```dart
  static const String googleMapsApiKey = 'AIzaSyAtGhXyexqP8bYiH2nqaTxeECtvENWqPPU';
  ```

### 2. Android
- **`android/app/src/main/AndroidManifest.xml`** - מפתח ל-Android Maps SDK
  ```xml
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="AIzaSyAtGhXyexqP8bYiH2nqaTxeECtvENWqPPU" />
  ```

### 3. iOS
- **`ios/Runner/AppDelegate.swift`** - מפתח ל-iOS Maps SDK
  ```swift
  GMSServices.provideAPIKey("AIzaSyAtGhXyexqP8bYiH2nqaTxeECtvENWqPPU")
  ```

### 4. Web
- **`web/index.html`** - מפתח ל-Maps JavaScript API
  ```html
  <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyAtGhXyexqP8bYiH2nqaTxeECtvENWqPPU"></script>
  ```

### 5. Server-Side (Firebase Cloud Functions)
- **Firebase Secret** - מפתח מאובטח ב-Firebase Secrets
  ```bash
  echo "AIzaSyAtGhXyexqP8bYiH2nqaTxeECtvENWqPPU" | firebase functions:secrets:set GOOGLE_APIS_KEY
  ```

## 🔒 אבטחה

### הגבלות ב-Google Cloud Console

**Application Restrictions:**
- **Android:** Package name: `com.mycompany.CounterApp`
- **iOS:** Bundle ID: `com.mycompany.CounterApp`
- **Web:** Domain restrictions (אם נדרש)

**API Restrictions:**
- ✅ Maps SDK for Android
- ✅ Maps SDK for iOS
- ✅ Maps JavaScript API
- ✅ Places API
- ✅ Geocoding API (אם נדרש)

### הגנה מפני חשיפה

1. **`.gitignore`** - הקבצים הבאים מוגנים:
   - `lib/config/env.dart` - לא ב-gitignore (נדרש בקוד)
   - `android/app/src/main/AndroidManifest.xml` - לא ב-gitignore (נדרש לבנייה)
   - `ios/Runner/AppDelegate.swift` - לא ב-gitignore (נדרש לבנייה)
   - `web/index.html` - לא ב-gitignore (נדרש לבנייה)

2. **המלצה:** אם המפתח רגיש, שקול:
   - שימוש ב-Environment Variables
   - שימוש ב-Flutter Flavors
   - הגבלות חזקות ב-Google Cloud Console

## 🔄 עדכון המפתח

אם צריך לעדכן את המפתח, עדכן אותו בכל 5 המקומות לעיל.

## ✅ אימות

לאחר עדכון, ודא:
1. המפה נטענת ב-Android ✅
2. המפה נטענת ב-iOS ✅
3. המפה נטענת ב-Web ✅
4. Cloud Functions עובדות (searchVenues, getPlaceDetails) ✅
