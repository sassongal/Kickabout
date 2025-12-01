# שיפורים לחיפוש מגרשים

## סקירה כללית

מסמך זה מתאר שיפורים מוצעים לחיפוש מגרשים בכל המקומות הרלוונטיים באפליקציה:
- יצירת משחק מחוץ להאב (`create_game_screen.dart`)
- יצירת אירוע בהאב (`create_hub_event_screen.dart`)
- יצירת האב (`create_hub_screen.dart`)
- ניהול מגרשים בהאב (`hub_venues_manager.dart`)
- חיפוש מגרשים כללי (`smart_venue_search_field.dart`)

## שיפורים מוצעים

### 1. שיפור UI של תוצאות חיפוש (🔥 עדיפות גבוהה)

**בעיה נוכחית:**
- תוצאות החיפוש לא מציגות מרחק מהמשתמש
- אין אינדיקציה ויזואלית למגרשים מומלצים/פופולריים
- אין תמונות או דירוגים

**פתרון:**
```dart
// הוספת מרחק בתוצאות
- חישוב מרחק בזמן אמת מהמיקום הנוכחי
- הצגת מרחק בפורמט קריא (1.2 ק"מ, 500 מ')
- מיון תוצאות לפי מרחק (קרוב → רחוק)

// אינדיקציות ויזואליות
- Badge למגרשים פופולריים (מספר האבים)
- Badge למגרשים מאומתים (verified)
- אייקונים שונים לסוגי מגרשים (ציבורי/פרטי/קהילתי)
```

**קבצים לעדכון:**
- `lib/widgets/input/smart_venue_search_field.dart`
- `lib/screens/game/create_game_screen.dart`

### 2. סינון לפי סוג מגרש (🔥 עדיפות גבוהה)

**בעיה נוכחית:**
- אין אפשרות לסנן בין מגרשים ציבוריים/פרטיים/קהילתיים
- כל התוצאות מוצגות יחד ללא הבחנה

**פתרון:**
```dart
// הוספת Chip Filters
- "כל המגרשים" (ברירת מחדל)
- "מגרשים ציבוריים"
- "מגרשים פרטיים"
- "מגרשים קהילתיים"

// סינון דינמי
- עדכון תוצאות בזמן אמת לפי הסינון
- שמירת העדפות המשתמש
```

**קבצים לעדכון:**
- `lib/widgets/input/smart_venue_search_field.dart`
- `lib/data/venues_repository.dart` (הוספת פילטר ל-`searchVenuesCombined`)

### 3. הצגת מגרשים קרובים (🔥 עדיפות בינונית)

**בעיה נוכחית:**
- אין הצגה אוטומטית של מגרשים קרובים כשהחיפוש ריק
- המשתמש צריך להקליד כדי לראות תוצאות

**פתרון:**
```dart
// "מגרשים קרובים" כשהחיפוש ריק
- טעינה אוטומטית של 5-10 מגרשים קרובים ביותר
- הצגת מרחק מכל מגרש
- אפשרות לבחור ישירות מהרשימה

// מיקום אוטומטי
- שימוש ב-Geolocator לקבלת מיקום נוכחי
- Fallback למיקום ברירת מחדל (תל אביב) אם אין הרשאה
```

**קבצים לעדכון:**
- `lib/widgets/input/smart_venue_search_field.dart`
- `lib/data/venues_repository.dart` (שימוש ב-`findVenuesNearby`)

### 4. שיפור ביצועים (🔥 עדיפות בינונית)

**בעיה נוכחית:**
- חיפוש מתבצע בכל הקלדה (לא debounced)
- אין caching של תוצאות חיפוש
- קריאות כפולות ל-Google Places API

**פתרון:**
```dart
// Debouncing
- המתנה של 300-500ms לפני ביצוע חיפוש
- ביטול חיפושים קודמים אם המשתמש ממשיך להקליד

// Caching
- שמירת תוצאות חיפוש ב-CacheService
- TTL של 5-10 דקות לתוצאות חיפוש
- Invalidation כשמגרש חדש נוצר

// Batch Requests
- איחוד קריאות ל-API כשיש אפשרות
```

**קבצים לעדכון:**
- `lib/widgets/input/smart_venue_search_field.dart`
- `lib/data/venues_repository.dart`
- `lib/services/cache_service.dart`

### 5. בחירה מהמפה ישירות (✅ כבר קיים)

**סטטוס:**
- כבר מיושם ב-`discover_venues_screen.dart`
- צריך לוודא שכל המקומות שמשתמשים בחיפוש מגרשים יכולים לפתוח את המסך הזה

**שיפור מוצע:**
- הוספת כפתור "בחר מהמפה" ב-`SmartVenueSearchField`
- ניווט ל-`discover_venues_screen` עם אפשרות להחזיר תוצאה

### 6. היסטוריית חיפושים (🔥 עדיפות נמוכה)

**בעיה נוכחית:**
- אין שמירה של חיפושים קודמים
- המשתמש צריך להקליד מחדש מגרשים שהוא חיפש בעבר

**פתרון:**
```dart
// שמירה ב-SharedPreferences
- שמירת 5-10 חיפושים אחרונים
- הצגה כשהחיפוש ריק או מתחיל להקליד
- אפשרות למחוק היסטוריה

// הצגה ב-Autocomplete
- הצגת היסטוריה לפני תוצאות חיפוש
- אייקון מיוחד להיסטוריה
```

**קבצים לעדכון:**
- `lib/widgets/input/smart_venue_search_field.dart`
- `lib/services/cache_service.dart` (הוספת פונקציונליות להיסטוריה)

## יישום מומלץ

### שלב 1: שיפורים בסיסיים (2-3 שעות)
1. ✅ תיקון `_HomeVenueSelector` (הושלם)
2. הוספת מרחק בתוצאות חיפוש
3. הוספת סינון לפי סוג מגרש
4. Debouncing לחיפוש

### שלב 2: שיפורים מתקדמים (3-4 שעות)
1. הצגת מגרשים קרובים
2. שיפור UI של תוצאות (badges, icons)
3. Caching של תוצאות חיפוש

### שלב 3: שיפורים נוספים (2-3 שעות)
1. היסטוריית חיפושים
2. שיפורי UX נוספים

## הערות טכניות

### חישוב מרחק
```dart
// כבר קיים ב-Geolocator
final distance = Geolocator.distanceBetween(
  userLat,
  userLng,
  venue.location.latitude,
  venue.location.longitude,
) / 1000; // ק"מ

// פורמט קריא
String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} מ\'';
  return '${km.toStringAsFixed(1)} ק"מ';
}
```

### Debouncing
```dart
Timer? _searchTimer;

void _onSearchChanged(String query) {
  _searchTimer?.cancel();
  _searchTimer = Timer(const Duration(milliseconds: 400), () {
    _performSearch(query);
  });
}
```

### Caching
```dart
// ב-venues_repository.dart
Future<List<Venue>> searchVenuesCombined(String query) async {
  final cacheKey = 'venue_search_${query.toLowerCase()}';
  return CacheService().getOrFetch(
    cacheKey,
    () => _performSearch(query),
    ttl: Duration(minutes: 5),
  );
}
```

## קבצים לעדכון

1. `lib/widgets/input/smart_venue_search_field.dart` - ווידג'ט חיפוש משופר
2. `lib/data/venues_repository.dart` - לוגיקת חיפוש משופרת
3. `lib/screens/game/create_game_screen.dart` - שימוש בווידג'ט משופר
4. `lib/screens/hub/create_hub_event_screen.dart` - שימוש בווידג'ט משופר
5. `lib/services/cache_service.dart` - הוספת caching לחיפושים

## בדיקות

- [ ] חיפוש מגרשים מציג מרחק
- [ ] סינון לפי סוג מגרש עובד
- [ ] מגרשים קרובים מוצגים כשהחיפוש ריק
- [ ] Debouncing מונע חיפושים מיותרים
- [ ] Caching משפר ביצועים
- [ ] UI משופר עם badges ואייקונים

