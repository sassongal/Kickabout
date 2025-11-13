# ✅ Deployment Checklist - Firebase Implementation

## 📋 לפני Deployment

### 1. הגדרת API Keys

```bash
# Google Places API Key
firebase functions:config:set googleplaces.apikey="YOUR_GOOGLE_PLACES_API_KEY"

# Custom API (אופציונלי)
firebase functions:config:set customapi.baseurl="https://your-api.com"
firebase functions:config:set customapi.apikey="YOUR_CUSTOM_API_KEY"

# בדוק את ההגדרות
firebase functions:config:get
```

### 2. התקנת Dependencies

```bash
cd functions
npm install
cd ..
```

### 3. בדיקת קבצים

- ✅ `firestore.indexes.json` - קיים
- ✅ `remoteconfig.template.json` - קיים
- ✅ `functions/index.js` - מעודכן עם functions חדשות
- ✅ `functions/package.json` - כולל dependencies חדשות

---

## 🚀 Deployment Steps

### שלב 1: Firestore Indexes

```bash
firebase deploy --only firestore:indexes
```

**⏱️ זמן**: 5-10 דקות (יצירת indexes)

**✅ בדיקה**: לך ל-Firebase Console → Firestore → Indexes
- ודא שה-indexes נוצרו בהצלחה
- המתן עד שכל ה-indexes במצב "Enabled"

### שלב 2: Remote Config

```bash
firebase deploy --only remoteconfig
```

**✅ בדיקה**: לך ל-Firebase Console → Remote Config
- ודא שה-template הועלה
- בדוק את הערכים

### שלב 3: Cloud Functions

```bash
firebase deploy --only functions
```

**⏱️ זמן**: 2-5 דקות

**✅ בדיקה**: לך ל-Firebase Console → Functions
- ודא שכל ה-functions מופיעות:
  - `searchVenues`
  - `getPlaceDetails`
  - `syncVenueToCustomAPI`
  - `onVenueChanged`
  - `onGameCreated`
  - `onHubMessageCreated`
  - `onCommentCreated`
  - `onFollowCreated`
  - `sendGameReminder`

### שלב 4: Flutter App

```bash
# Install new dependencies
flutter pub get

# Test on device
flutter run
```

---

## 🧪 Testing

### Test Cloud Functions

```bash
# Test searchVenues
firebase functions:shell
> searchVenues({latitude: 31.7683, longitude: 35.2137, radius: 5000})
```

### Test Remote Config

```dart
final remoteConfig = RemoteConfigService();
await remoteConfig.initialize();
print('Radius: ${remoteConfig.venueSearchRadiusDefault}');
```

### Test Firestore Indexes

1. נסה query מורכב ב-Firestore Console
2. ודא שאין שגיאות "index required"

---

## ⚠️ Troubleshooting

### שגיאת Index Required

**בעיה**: `The query requires an index`

**פתרון**:
1. לך ל-Firestore Console → Indexes
2. לחץ על הקישור ב-error message
3. לחץ "Create Index"
4. המתן ליצירת ה-index

### שגיאת API Key

**בעיה**: `Google Places API key not configured`

**פתרון**:
```bash
firebase functions:config:set googleplaces.apikey="YOUR_KEY"
firebase deploy --only functions
```

### שגיאת Rate Limit

**בעיה**: `Rate limit exceeded`

**פתרון**:
- זה תקין! ה-function מגביל קריאות
- המתן 2 שניות בין קריאות

---

## 📊 Monitoring

### Cloud Functions Logs

```bash
firebase functions:log
```

### Performance

1. Firebase Console → Functions → Metrics
2. בדוק:
   - Invocation count
   - Error rate
   - Execution time

### Costs

1. Firebase Console → Usage and Billing
2. Google Cloud Console → Billing
3. בדוק:
   - Cloud Functions invocations
   - Firestore reads/writes
   - Google Places API calls

---

## ✅ Post-Deployment Checklist

- [ ] כל ה-indexes נוצרו בהצלחה
- [ ] כל ה-functions עובדות
- [ ] Remote Config נטען באפליקציה
- [ ] חיפוש מגרשים עובד (דרך Cloud Functions)
- [ ] אין שגיאות ב-logs
- [ ] Performance תקין
- [ ] Costs סבירים

---

## 🔄 Updates

כשמעדכנים:

```bash
# Update functions only
firebase deploy --only functions

# Update indexes only
firebase deploy --only firestore:indexes

# Update Remote Config only
firebase deploy --only remoteconfig

# Update everything
firebase deploy
```

---

**תאריך יצירה**: $(date)

