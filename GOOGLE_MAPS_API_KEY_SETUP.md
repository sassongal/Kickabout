# 🔐 Google Maps API Key Security Setup

## ⚠️ CRITICAL: Your API Key is Currently Exposed!

**Current Key:** `AIzaSyAtGhXyexqP8bYiH2nqaTxeECtvENWqPPU`

**Exposed in:**
- `lib/config/env.dart` ✅ **FIXED** - Now uses environment variables
- `android/app/src/main/AndroidManifest.xml` ⚠️ Still hardcoded (needs manual update)
- `ios/Runner/AppDelegate.swift` ⚠️ Still hardcoded (needs manual update)
- `web/index.html` ⚠️ Still hardcoded (needs manual update)

---

## 🚨 Immediate Actions Required

### Step 1: Rotate the API Key (URGENT!)

1. **Go to Google Cloud Console:**
   - https://console.cloud.google.com/apis/credentials

2. **Create a NEW API key:**
   - Click "Create Credentials" → "API Key"
   - Copy the new key

3. **Disable/Restrict the OLD key:**
   - Find the old key: `AIzaSyAtGhXyexqP8bYiH2nqaTxeECtvENWqPPU`
   - Click "Restrict key" or "Delete"

---

### Step 2: Set Up the NEW Key Properly

#### For Flutter App (Frontend)

**Option A: Using Environment Variables (Recommended)**

1. Create `.env` file in project root:
```bash
echo "GOOGLE_MAPS_API_KEY=YOUR_NEW_KEY_HERE" > .env
```

2. Run app with environment variable:
```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_NEW_KEY_HERE
```

**Option B: Update Hardcoded Values (Temporary)**

Update these files manually:
- `android/app/src/main/AndroidManifest.xml` - Replace old key
- `ios/Runner/AppDelegate.swift` - Replace old key  
- `web/index.html` - Replace old key

#### For Firebase Functions (Backend)

```bash
# Set as Firebase Secret
echo "YOUR_NEW_KEY" | firebase functions:secrets:set GOOGLE_APIS_KEY
```

---

### Step 3: Restrict the NEW Key in Google Cloud Console

**Application Restrictions:**
- ✅ Android: Add package name `com.mycompany.CounterApp`
- ✅ iOS: Add bundle ID (check `ios/Runner.xcodeproj`)
- ✅ Web: Add your domain (e.g., `kattrick.app`)

**API Restrictions:**
- ✅ Maps SDK for Android
- ✅ Maps SDK for iOS
- ✅ Maps JavaScript API
- ✅ Places API
- ✅ Geocoding API (if used)

**DO NOT enable:**
- ❌ All APIs (too permissive!)

---

## 📝 Code Changes Made

### ✅ Fixed: `lib/config/env.dart`

Now uses environment variables:
```dart
static const String googleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: '', // Empty in production - must be set!
);
```

### ⚠️ Still Needs Manual Update:

1. **AndroidManifest.xml** - Add security comments
2. **AppDelegate.swift** - Add security comments
3. **web/index.html** - Add security comments

---

## 🔒 Security Best Practices

1. **Never commit API keys to Git**
   - ✅ `.env` is already in `.gitignore`
   - ✅ `google-services.json` is already in `.gitignore`

2. **Use different keys for different environments:**
   - Development key (unrestricted, for local testing)
   - Production key (fully restricted)

3. **Monitor API usage:**
   - Set up billing alerts in Google Cloud Console
   - Review API usage regularly

4. **Rotate keys periodically:**
   - Every 6-12 months
   - Immediately if exposed

---

## 🧪 Testing

After updating the key:

1. **Test Android:**
```bash
flutter run -d android
```

2. **Test iOS:**
```bash
flutter run -d ios
```

3. **Test Web:**
```bash
flutter run -d chrome
```

---

## 📚 Additional Resources

- [Google Maps Platform Security Best Practices](https://developers.google.com/maps/api-security-best-practices)
- [Firebase Secrets Documentation](https://firebase.google.com/docs/functions/config-env)

---

**Last Updated:** 2025-01-30  
**Status:** ⚠️ Requires manual key rotation and updates

