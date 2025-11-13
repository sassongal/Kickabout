# 🏟️ מערכת המגרשים - תיעוד מלא

## 📋 סקירה כללית

מערכת המגרשים מאפשרת:
- **חיפוש מגרשים** - שחקנים יכולים לחפש מגרשים ציבוריים ולהשכרה באיזור שלהם
- **ניהול מגרשים ל-Hub** - כל Hub יכול לנהל כמה מגרשים
- **התאמה חכמה** - שחקנים מוצאים Hubs רלוונטים לפי המגרשים הקרובים אליהם

---

## 🏗️ ארכיטקטורה

### 1. **מודלים**

#### `Venue` Model
```dart
class Venue {
  String venueId;
  String hubId; // Hub owner
  String name;
  GeoPoint location; // From Google Maps
  String? googlePlaceId; // Google Places API ID
  String? address;
  List<String> amenities;
  String surfaceType; // grass, artificial, concrete
  int maxPlayers;
  bool isActive;
}
```

#### `PlaceResult` (Google Places)
```dart
class PlaceResult {
  String placeId;
  String name;
  double latitude;
  double longitude;
  bool isPublic; // Public vs rental
  // ... more fields
}
```

### 2. **Services**

#### `GooglePlacesService`
- **חיפוש מגרשים** - Text search + Nearby search
- **חיפוש להשכרה** - Rental venues search
- **פרטי מגרש** - Get place details by ID
- **מרחק** - Calculate distance between points

#### `CustomApiService`
- **אינטגרציה עם API מותאם אישית**
- **Sync venues** - סנכרון מגרשים
- **Custom search** - חיפוש מותאם

#### `HubVenueMatcherService`
- **התאמה חכמה** - מציאת Hubs רלוונטים לשחקן
- **Relevance scoring** - ציון רלוונטיות (מרחק + גודל Hub)
- **חיפוש לפי מיקום** - Hubs לפי מגרשים קרובים

### 3. **Repositories**

#### `VenuesRepository`
- CRUD operations למגרשים
- `getVenuesByHub()` - כל המגרשים של Hub
- `findVenuesNearby()` - חיפוש מגרשים קרובים
- Geohash queries לאופטימיזציה

### 4. **Screens**

#### `VenueSearchScreen`
- חיפוש מגרשים עם Google Places API
- סינון: הכל / ציבורי / להשכרה
- בחירת מגרש להוספה ל-Hub
- תצוגה עם מרחק, דירוג, פרטים

#### `MapScreen` (שופר)
- הצגת מגרשים עם markers כתומים
- הצגת Hubs עם markers כחולים
- Filter: הכל / הובים / משחקים / מגרשים
- קליק על מגרש → נווט ל-Hub

---

## 🔄 Flow - איך זה עובד?

### 1. **חיפוש מגרשים (שחקן)**
```
שחקן → VenueSearchScreen
  ↓
GooglePlacesService.searchVenues()
  ↓
Text Search + Nearby Search + Rental Search
  ↓
תוצאות עם מרחק, דירוג, סוג (ציבורי/להשכרה)
  ↓
שחקן בוחר מגרש → רואה איזה Hub משחק שם
```

### 2. **הוספת מגרש ל-Hub (מנהל)**
```
מנהל Hub → Hub Settings → ניהול מגרשים
  ↓
VenueSearchScreen (selectMode=true)
  ↓
חיפוש מגרשים → בחירת מגרש
  ↓
PlaceResult.toVenue() → יצירת Venue
  ↓
VenuesRepository.createVenue()
  ↓
עדכון Hub.venueIds
```

### 3. **מציאת Hubs רלוונטים (שחקן)**
```
שחקן → DiscoverHubsScreen
  ↓
HubVenueMatcherService.findRelevantHubs()
  ↓
1. מציאת מגרשים קרובים
2. קבלת Hubs של המגרשים
3. חישוב relevance score (מרחק + גודל)
4. מיון לפי רלוונטיות
  ↓
רשימת Hubs מומלצים
```

### 4. **הצגה במפה**
```
MapScreen → _loadMarkers()
  ↓
אם filter = 'hubs' או 'all':
  - טעינת Hubs
  - טעינת מגרשים של כל Hub
  - הוספת markers (כחול = Hub, כתום = מגרש)
  ↓
אם filter = 'venues':
  - טעינת כל המגרשים הקרובים
  - הצגה עם שם Hub
```

---

## 🔌 אינטגרציה עם Google Places API

### Endpoints בשימוש:
1. **Text Search** - `https://maps.googleapis.com/maps/api/place/textsearch/json`
2. **Nearby Search** - `https://maps.googleapis.com/maps/api/place/nearbysearch/json`
3. **Place Details** - `https://maps.googleapis.com/maps/api/place/details/json`

### Parameters:
- `query` - חיפוש טקסטואלי
- `location` - lat,lng
- `radius` - רדיוס חיפוש במטרים
- `type` - stadium|gym|park|establishment
- `keyword` - מילות מפתח (מגרש כדורגל, השכרת מגרש)
- `language=he` - עברית

### Rate Limiting:
- מומלץ ליישם caching ב-Cloud Functions
- שימוש ב-geohash queries ב-Firestore

---

## 🔌 אינטגרציה עם Custom API

### `CustomApiService` Methods:
- `searchVenues()` - חיפוש מגרשים
- `getVenueDetails()` - פרטי מגרש
- `syncVenue()` - סנכרון מגרש

### Configuration:
```dart
Env.customApiBaseUrl = 'https://your-api.com';
Env.customApiKey = 'your-api-key';
```

---

## 📊 Relevance Scoring Algorithm

```dart
distanceScore = 1.0 / (1.0 + distanceKm)  // Inverse distance
sizeScore = (memberCount / 100.0).clamp(0.0, 1.0)  // Normalized
relevanceScore = (distanceScore * 0.7) + (sizeScore * 0.3)
```

**גורמים:**
- **מרחק** (70%) - מגרש קרוב יותר = רלוונטי יותר
- **גודל Hub** (30%) - Hub גדול יותר = רלוונטי יותר

---

## 🗺️ Map Markers

- **כחול** (`hueBlue`) - Hubs
- **כתום** (`hueOrange`) - מגרשים
- **ירוק** (`hueGreen`) - משחקים
- **אדום** (`hueRed`) - מיקום נוכחי

---

## 🔐 Security & Privacy

- **Firestore Rules** - רק חברי Hub יכולים לראות מגרשים של Hub
- **API Keys** - Google Maps API key ב-Env (לא בקוד)
- **Rate Limiting** - מומלץ ב-Cloud Functions

---

## 🚀 שיפורים עתידיים

1. **Caching** - Cloud Functions cache ל-Google Places results
2. **AI Recommendations** - Gemini AI להמלצות חכמות
3. **Venue Reviews** - ביקורות על מגרשים
4. **Availability** - זמינות מגרשים להשכרה
5. **Booking** - הזמנת מגרשים דרך האפליקציה

---

**תאריך יצירה**: $(date)

