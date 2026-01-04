# Compact Audio Player 🎵

נגן אודיו קומפקטי ומודרני עם אפשרות הרחבה.

## תכונות

### מצב קומפקטי
- כפתור עגול קטן ומינימליסטי (64x64 פיקסלים)
- אייקון Play/Pause
- אינדיקטור "משמיע עכשיו" (נקודה ירוקה)
- אנימציה של טבעות מתרחבות בזמן השמעה
- עיצוב גלסמורפי (זכוכית מטושטשת)

### מצב מורחב
- פאנל מלא עם מידע על השיר הנוכחי (320x160 פיקסלים)
- שם השיר והאלבום
- כפתורי בקרה:
  - Play/Pause
  - Skip Next
  - Mute/Unmute
- סליידר עוצמת קול
- כפתור כיווץ
- אנימציות Fade-in חלקות

## שימוש בסיסי

### 1. הוספה לעמוד

```dart
import 'package:kattrick/features/audio/presentation/widgets/compact_audio_player.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // התוכן שלך
          MyMainContent(),

          // נגן האודיו הקומפקטי
          Positioned(
            bottom: 80,
            right: 16,
            child: CompactAudioPlayer(),
          ),
        ],
      ),
    );
  }
}
```

### 2. מיקומים שונים

```dart
// פינה ימנית תחתונה (ברירת מחדל)
Positioned(
  bottom: 80,
  right: 16,
  child: CompactAudioPlayer(),
)

// פינה שמאלית תחתונה
Positioned(
  bottom: 80,
  left: 16,
  child: CompactAudioPlayer(),
)

// מרכז למטה
Positioned(
  bottom: 80,
  left: 0,
  right: 0,
  child: Center(child: CompactAudioPlayer()),
)
```

## תכונות מתקדמות

### אנימציות

הנגן כולל 3 סוגי אנימציות:

1. **Expand/Collapse Animation** - מעבר חלק בין מצבים
   - משך: 300ms
   - Curve: `easeInOutCubic`

2. **Fade Animation** - הופעה הדרגתית של פקדים
   - התחלה: 30% מתוך האנימציה
   - Curve: `easeIn`

3. **Pulse Animation** - טבעות מתרחבות בזמן השמעה
   - משך: 2 שניות
   - חזרתי אוטומטית

### התאמה אישית

```dart
// בעתיד ניתן יהיה להעביר פרמטרים:
CompactAudioPlayer(
  // צבעי נושא
  primaryColor: Colors.purple,
  accentColor: Colors.deepPurple,

  // מיקום אוטומטי
  autoPosition: AudioPlayerPosition.bottomRight,

  // התנהגות
  autoCollapseAfter: Duration(seconds: 10),
)
```

## אינטגרציה עם PlaylistService

הנגן משתמש ב-`PlaylistService` לניהול המוזיקה:

```dart
final playlist = PlaylistService();

// אתחול
await playlist.initialize();

// בקרה
await playlist.play();
await playlist.pause();
await playlist.nextTrack();
await playlist.setVolume(0.5);
await playlist.toggleMute();

// מידע
print(playlist.currentTrackName);  // "Track 1"
print(playlist.isPlaying);          // true
print(playlist.volume);             // 0.7
```

## עיצוב

### צבעים
- **Primary**: `PremiumColors.primary` (גרדיאנט כחול-סגול)
- **Accent**: `PremiumColors.accent`
- **רקע**: Glassmorphism עם טשטוש 10px
- **גבול**: לבן עם שקיפות 30%

### צללים
- **Blur Radius**: 20px
- **Offset**: (0, 8)
- **Color**: Primary עם שקיפות 40%

### פינות מעוגלות
- **מצב קומפקטי**: 32px (עיגול מלא)
- **מצב מורחב**: 24px

## דוגמאות שימוש

### 1. במסך הבית

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // תוכן ראשי
          CustomScrollView(...),

          // נגן אודיו
          Positioned(
            bottom: 80,
            right: 16,
            child: CompactAudioPlayer(),
          ),
        ],
      ),
    );
  }
}
```

### 2. עם Bottom Navigation Bar

```dart
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // הדף הפעיל
          _pages[_currentIndex],

          // נגן אודיו - מעל ה-BottomNavigationBar
          Positioned(
            bottom: 80, // גובה ה-BottomNav + padding
            right: 16,
            child: CompactAudioPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(...),
    );
  }
}
```

### 3. במשחק Live

```dart
class LiveMatchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ממשק המשחק
          MatchInterface(),

          // נגן אודיו - לא מפריע לפעולות
          Positioned(
            bottom: 100,
            left: 16, // שמאל במקרה זה
            child: CompactAudioPlayer(),
          ),
        ],
      ),
    );
  }
}
```

## Best Practices

### 1. ✅ מיקום מומלץ
```dart
// השאר מרווח מספיק מה-BottomNavigationBar
Positioned(
  bottom: 80, // לפחות 80px מהתחתית
  right: 16,
  child: CompactAudioPlayer(),
)
```

### 2. ✅ שכבות נכונות
```dart
Stack(
  children: [
    // 1. תוכן ראשי (רקע)
    MainContent(),

    // 2. נגן אודיו (קדמה)
    Positioned(..., child: CompactAudioPlayer()),

    // 3. אלמנטים נוספים מעל הנגן (אם צריך)
  ],
)
```

### 3. ❌ להימנע
```dart
// ❌ לא לשים בתוך ListView ישירות
ListView(
  children: [
    CompactAudioPlayer(), // זה לא יעבוד טוב
  ],
)

// ✅ במקום זה:
Stack(
  children: [
    ListView(...),
    Positioned(..., child: CompactAudioPlayer()),
  ],
)
```

## טיפול בשגיאות

הנגן מטפל אוטומטית במצבי שגיאה:

```dart
// אם PlaylistService נכשל באתחול
// הנגן ימשיך לעבוד אבל לא ישמיע קול

// בדיקה אם מוכן:
if (_playlist.isInitialized) {
  await _playlist.play();
}
```

## Performance

- **גודל Widget**: קטן מאוד (64px → 320px)
- **אנימציות**: מותאמות ל-60fps
- **זיכרון**: משתמש ב-Singleton של PlaylistService
- **CPU**: אנימציות רק כשהנגן גלוי

## הערות נוספות

1. **Auto-collapse**: כרגע הנגן לא מתכווץ אוטומטית. ניתן להוסיף Timer עבור זה.
2. **Gestures**: ניתן להוסיף swipe-to-dismiss בעתיד.
3. **Themes**: הנגן משתמש ב-`PremiumColors` - ניתן להתאים לנושאים אחרים.
4. **Accessibility**: כולל תמיכה מלאה ב-VoiceOver ו-TalkBack.

## קבצים קשורים

- `compact_audio_player.dart` - הנגן עצמו
- `playlist_service.dart` - ניהול הפלייליסט
- `audio_settings_screen.dart` - מסך הגדרות אודיו
- `floating_music_player.dart` - נגן מלא ישן (legacy)

---

נוצר: 2026-01-04
גרסה: 1.0.0
