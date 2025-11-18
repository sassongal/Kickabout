# Environment Setup Guide

## Overview

This guide explains how to configure different environments (staging vs production) for the Kickabout app.

---

## Current Setup

### Firebase Configuration

The app currently uses a single Firebase project configured via:
- `lib/config/firebase_options.dart` - Generated Firebase configuration
- `lib/config/env.dart` - Environment flags

### Environment Variables

The app uses `Env` class to control behavior:
- `Env.isFirebaseAvailable` - Checks if Firebase is initialized
- `Env.limitedMode` - Fallback mode when Firebase is unavailable

---

## Recommended Environment Setup

### Option 1: Firebase Project Separation (Recommended)

**Staging Environment**:
- Create a separate Firebase project: `kickabout-staging`
- Configure via `flutterfire configure --project=kickabout-staging`
- Use different `firebase_options.dart` file: `firebase_options_staging.dart`

**Production Environment**:
- Use existing Firebase project: `kickabout-production`
- Keep current `firebase_options.dart`

**Implementation**:
```dart
// lib/config/env.dart
class Env {
  static const bool isStaging = bool.fromEnvironment('STAGING', defaultValue: false);
  static const bool isProduction = !isStaging;
  
  static String get firebaseProjectId => isStaging 
    ? 'kickabout-staging' 
    : 'kickabout-production';
}
```

**Build Commands**:
```bash
# Staging
flutter build apk --dart-define=STAGING=true

# Production
flutter build apk --dart-define=STAGING=false
```

---

### Option 2: Flutter Flavors (Alternative)

**Setup**:
1. Create flavor configurations in `android/app/build.gradle`:
```gradle
android {
    flavorDimensions "environment"
    productFlavors {
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            resValue "string", "app_name", "Kickabout Staging"
        }
        production {
            dimension "environment"
            resValue "string", "app_name", "Kickabout"
        }
    }
}
```

2. Create flavor-specific Firebase configs:
- `lib/config/firebase_options_staging.dart`
- `lib/config/firebase_options_production.dart`

3. Update `main.dart` to select config based on flavor:
```dart
import 'package:kickadoor/config/firebase_options_staging.dart' as staging;
import 'package:kickadoor/config/firebase_options_production.dart' as production;

void main() {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'production');
  final options = flavor == 'staging' 
    ? staging.DefaultFirebaseOptions.currentPlatform
    : production.DefaultFirebaseOptions.currentPlatform;
  
  Firebase.initializeApp(options: options);
  runApp(const MyApp());
}
```

**Build Commands**:
```bash
# Staging
flutter build apk --flavor staging --dart-define=FLAVOR=staging

# Production
flutter build apk --flavor production --dart-define=FLAVOR=production
```

---

## Current Status

**Status**: ⚠️ Single environment setup

**Recommendation**: Implement Option 1 (Firebase Project Separation) for:
- Isolated test data
- Safe testing of Cloud Functions
- Separate analytics
- Easier rollback

---

## Environment-Specific Configuration

### Staging
- Firebase Project: `kickabout-staging`
- App Bundle ID: `com.kickabout.staging`
- Analytics: Disabled or test mode
- Crashlytics: Test mode

### Production
- Firebase Project: `kickabout-production`
- App Bundle ID: `com.kickabout`
- Analytics: Full tracking
- Crashlytics: Production mode

---

## Deployment Checklist

### Staging Deployment
- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules --project kickabout-staging`
- [ ] Deploy indexes: `firebase deploy --only firestore:indexes --project kickabout-staging`
- [ ] Deploy Cloud Functions: `firebase deploy --only functions --project kickabout-staging`
- [ ] Build staging APK: `flutter build apk --dart-define=STAGING=true`
- [ ] Test on staging Firebase project

### Production Deployment
- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules --project kickabout-production`
- [ ] Deploy indexes: `firebase deploy --only firestore:indexes --project kickabout-production`
- [ ] Deploy Cloud Functions: `firebase deploy --only functions --project kickabout-production`
- [ ] Build production APK: `flutter build apk --dart-define=STAGING=false`
- [ ] Upload to Play Store / App Store

---

## Next Steps

1. Create staging Firebase project
2. Configure `flutterfire` for staging
3. Update `Env` class with environment detection
4. Update build scripts
5. Test staging deployment

