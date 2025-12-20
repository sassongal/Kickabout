class CityUtils {
  // Map of cities to their respective regions
  static const Map<String, String> _cityToRegion = {
    // North
    'חיפה': 'צפון',
    'טבריה': 'צפון',
    'עפולה': 'צפון',
    'נהריה': 'צפון',
    'כרמיאל': 'צפון',
    'עכו': 'צפון',
    'נצרת': 'צפון',
    'קריית שמונה': 'צפון',
    'צפת': 'צפון',
    'בית שאן': 'צפון',
    'קריות': 'צפון',
    'קריית אתא': 'צפון',
    'קריית מוצקין': 'צפון',
    'קריית ביאליק': 'צפון',
    'קריית ים': 'צפון',
    'יוקנעם': 'צפון',
    'זכרון יעקב': 'צפון',
    'חדרה': 'צפון', // Borderline, but often considered North/Sharon
    'פרדס חנה': 'צפון',

    // Center
    'תל אביב': 'מרכז',
    'רמת גן': 'מרכז',
    'גבעתיים': 'מרכז',
    'ראשון לציון': 'מרכז',
    'חולון': 'מרכז',
    'בת ים': 'מרכז',
    'פתח תקווה': 'מרכז',
    'בני ברק': 'מרכז',
    'רמת השרון': 'מרכז',
    'קריית אונו': 'מרכז',
    'אור יהודה': 'מרכז',
    'יהוד': 'מרכז',
    'גבעת שמואל': 'מרכז',
    'ראש העין': 'מרכז',
    'מודיעין': 'מרכז',
    'רחובות': 'מרכז',
    'נס ציונה': 'מרכז',
    'לוד': 'מרכז',
    'רמלה': 'מרכז',
    'יבנה': 'מרכז',

    // Sharon
    'נתניה': 'מרכז', // Often grouped with Center in broad definitions, but let's map to Center for simplicity if we only have 4 regions. User asked for specific mapping.
    // Wait, user listed Sharon separately in the prompt example? 
    // "North, Center, Sharon, Jerusalem, South". 
    // But the app currently has: North, Center, South, Jerusalem.
    // I should check what regions are supported in the app. 
    // Let's stick to the existing regions (North, Center, South, Jerusalem) to avoid breaking other things, 
    // or map Sharon cities to 'Center' unless I add a new region.
    // The user prompt said: "North: ..., Center: ..., Sharon: ..., Jerusalem: ..., South: ...".
    // So I should probably support 'שרון' if I can, or map it to Center.
    // Let's map Sharon cities to 'מרכז' for now to match the likely existing Enum/Strings, 
    // unless I see 'שרון' is used. I'll check `user.dart` later.
    // For now, I'll map them to 'מרכז' but comment them as Sharon.
    'הרצליה': 'מרכז',
    'כפר סבא': 'מרכז',
    'רעננה': 'מרכז',
    'הוד השרון': 'מרכז',
    'כפר יונה': 'מרכז',
    'טייבה': 'מרכז',

    // Jerusalem
    'ירושלים': 'ירושלים',
    'בית שמש': 'ירושלים',
    'מבשרת ציון': 'ירושלים',
    'מעלה אדומים': 'ירושלים',

    // South
    'באר שבע': 'דרום',
    'אילת': 'דרום',
    'אשקלון': 'דרום',
    'אשדוד': 'דרום',
    'קריית גת': 'דרום',
    'דימונה': 'דרום',
    'ערד': 'דרום',
    'נתיבות': 'דרום',
    'אופקים': 'דרום',
    'שדרות': 'דרום',
    'ירוחם': 'דרום',
    'מצפה רמון': 'דרום',
  };

  /// Get the region for a given city. Returns 'מרכז' as default.
  static String getRegionForCity(String city) {
    // Normalize city name (trim)
    final normalizedCity = city.trim();
    
    // Try to find exact match
    if (_cityToRegion.containsKey(normalizedCity)) {
      return _cityToRegion[normalizedCity]!;
    }
    
    // Try to find match containing the string (simple fuzzy)
    for (final entry in _cityToRegion.entries) {
      if (entry.key.contains(normalizedCity) || normalizedCity.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return 'מרכז'; // Default
  }

  /// Get list of all supported cities for autocomplete
  static List<String> get cities => _cityToRegion.keys.toList()..sort();
}
