# Music Player Integration 🎵

אינטגרציה מלאה של נגן המוזיקה באפליקציה.

## סקירה

הנגן מורכב משני חלקים עיקריים:

1. **כפתור בהיידר** - אייקון נוט מוזיקלית עם אינדיקטור "משמיע עכשיו"
2. **Dialog מלא** - נגן מלא עם כל הפקדים

## מבנה הקבצים

```
lib/
├── features/audio/
│   ├── infrastructure/
│   │   └── services/
│   │       └── playlist_service.dart          # ניהול הפלייליסט
│   └── presentation/
│       └── widgets/
│           ├── compact_audio_player.dart      # נגן קומפקטי (FAB-style)
│           ├── music_player_dialog.dart       # Dialog נגן מלא
│           └── audio_player_example.dart      # דוגמאות שימוש
└── widgets/
    └── premium/
        └── app_bar_with_logo.dart             # AppBar עם כפתור מוזיקה
```

## 1. כפתור בהיידר

### מיקום
הכפתור נמצא ב-`AppBarWithLogo` בין `OfflineIndicatorIcon` לבין `NotificationsBadgeButton`.

### תכונות
- **אייקון דינמי**:
  - `Icons.music_note_rounded` כשמשמיע
  - `Icons.music_note_outlined` כשעצור
- **אינדיקטור חי**: נקודה ירוקה מנצנצת בפינה כשמשמיע
- **Tooltip**: "נגן מוזיקה"
- **פעולה**: פותח את ה-Dialog המלא

### קוד

```dart
class _MusicPlayerButton extends StatefulWidget {
  const _MusicPlayerButton();

  @override
  State<_MusicPlayerButton> createState() => _MusicPlayerButtonState();
}

class _MusicPlayerButtonState extends State<_MusicPlayerButton> {
  final PlaylistService _playlist = PlaylistService();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initPlaylist();
  }

  Future<void> _initPlaylist() async {
    await _playlist.initialize();
    if (mounted) {
      setState(() {
        _isPlaying = _playlist.isPlaying;
      });
    }

    // Listen to playlist changes
    _startListening();
  }

  void _startListening() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _isPlaying = _playlist.isPlaying;
        });
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.music_note_rounded : Icons.music_note_outlined,
            color: PremiumColors.textPrimary,
          ),
          onPressed: () => showMusicPlayerDialog(context),
          tooltip: 'נגן מוזיקה',
        ),
        if (_isPlaying)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
```

## 2. Music Player Dialog

### תכונות

#### עיצוב
- **Glassmorphic design** עם טשטוש רקע
- **גרדיאנט צבעוני** (Primary → Accent)
- **אנימציית כניסה**: Slide מלמטה למעלה (300ms)
- **מקסימום 400x600** פיקסלים

#### פקדים
1. **Album Art** - דיסק מסתובב בזמן השמעה
2. **Track Info** - שם השיר והאלבום
3. **Play/Pause** - כפתור ראשי גדול
4. **Next Track** - דילוג לשיר הבא
5. **Mute/Unmute** - השתקה מהירה
6. **Volume Slider** - בקרת עוצמה
7. **Track Progress** - מספר שיר ואנימציית waveform

### שימוש

```dart
// פתיחת הנגן
showMusicPlayerDialog(context);

// בתוך כפתור
IconButton(
  icon: Icon(Icons.music_note),
  onPressed: () => showMusicPlayerDialog(context),
)
```

### אנימציות

1. **Vinyl Rotation** - הדיסק מסתובב בזמן השמעה
   - משך: 3 שניות לסיבוב מלא
   - חוזר אינסוף כשמשמיע
   - עוצר כשעוצר

2. **Waveform** - ברים מזדקרים בזמן השמעה
   - משך: 800ms
   - 4 ברים עם עיכוב בין כל אחד
   - נעלם כשעוצר

3. **Slide In** - כניסה מלמטה
   - Curve: `easeOutCubic`
   - משך: 300ms

## 3. PlaylistService

### Singleton Service
```dart
final playlist = PlaylistService();
```

### API מרכזי

```dart
// אתחול
await playlist.initialize();

// בקרה
await playlist.play();
await playlist.pause();
await playlist.nextTrack();
await playlist.setVolume(0.5);
await playlist.toggleMute();
await playlist.mute();
await playlist.unmute();

// מידע
print(playlist.currentTrackName);     // "Track 1"
print(playlist.currentTrackNumber);   // 1
print(playlist.totalTracks);          // 5
print(playlist.isPlaying);            // true
print(playlist.isMuted);              // false
print(playlist.volume);               // 0.7
```

## אינטגרציה באפליקציה

### מסך הבית

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithLogo(
        title: 'Home',
        // הכפתור כבר משולב אוטומטית!
      ),
      body: YourContent(),
    );
  }
}
```

### מסכים אחרים

כל מסך שמשתמש ב-`AppBarWithLogo` מקבל אוטומטית את כפתור המוזיקה:

```dart
Scaffold(
  appBar: AppBarWithLogo(
    title: 'Settings',
  ),
  body: SettingsContent(),
)
```

### התאמה אישית

אם אתה רוצה להסתיר את כפתור המוזיקה במסך מסוים:

```dart
// לא ניתן כרגע - הכפתור תמיד מוצג
// TODO: הוסף פרמטר showMusicButton אם נדרש
```

## Flow המשתמש

```
1. משתמש נכנס לאפליקציה
   ↓
2. רואה אייקון מוזיקה בהיידר
   ↓
3. לוחץ על האייקון
   ↓
4. Dialog נפתח עם אנימציה
   ↓
5. משתמש לוחץ Play
   ↓
6. המוזיקה מתחילה
   ↓
7. האייקון בהיידר משתנה + נקודה ירוקה
   ↓
8. הדיסק מתחיל להסתובב
   ↓
9. Waveform מתחיל לזוז
   ↓
10. משתמש סוגר את ה-Dialog
    ↓
11. המוזיקה ממשיכה ברקע
    ↓
12. האינדיקטור בהיידר נשאר
```

## State Management

### Player State
- **מקומי**: כל widget שומר `_isPlaying` משלו
- **Singleton**: `PlaylistService` הוא המקור האמת
- **Polling**: בדיקה כל שנייה אם המצב השתנה

### שיפורים עתידיים
- [ ] StreamController לעדכוני state
- [ ] Provider/Riverpod לניהול state גלובלי
- [ ] Event bus למצבי player

## עיצוב

### צבעים
```dart
// גרדיאנט ראשי
colors: [
  PremiumColors.primary.withValues(alpha: 0.95),
  PremiumColors.accent.withValues(alpha: 0.95),
]

// אינדיקטור "משמיע"
Colors.greenAccent

// פקדים
Colors.white (עם שקיפויות שונות)
```

### טיפוגרפיה
```dart
// כותרת
fontSize: 14
fontWeight: w600
letterSpacing: 1.5

// שם שיר
fontSize: 24
fontWeight: bold

// אלבום
fontSize: 14
alpha: 0.7
```

## Best Practices

### 1. ✅ הכפתור תמיד זמין
הכפתור מופיע בכל מסך שמשתמש ב-`AppBarWithLogo`.

### 2. ✅ המוזיקה ממשיכה ברקע
סגירת ה-Dialog לא עוצרת את המוזיקה.

### 3. ✅ אינדיקטור חזותי
המשתמש תמיד יודע אם מוזיקה מתנגנת.

### 4. ✅ גישה מהירה למשתקת
כפתור Mute בולט בנגן.

### 5. ⚠️ Polling במקום Streams
כרגע משתמשים ב-polling כל שנייה. שקול שדרוג ל-Streams.

## Troubleshooting

### הכפתור לא מופיע
```dart
// ודא שאתה משתמש ב-AppBarWithLogo
Scaffold(
  appBar: AppBarWithLogo(...), // ✅
  // NOT: AppBar(...),          // ❌
)
```

### המוזיקה לא מתנגנת
```dart
// ודא שקבצי האודיו קיימים
assets/sound/
├── k1.mp3
├── k2.mp3
├── k3.mp3
├── k4.mp3
└── k5.mp3

// ב-pubspec.yaml:
flutter:
  assets:
    - assets/sound/
```

### האינדיקטור לא מתעדכן
הבעיה: ה-polling לא עובד.
פתרון: הפעל מחדש את האפליקציה.

## עדכונים עתידיים

### גרסה 1.1
- [ ] StreamController במקום polling
- [ ] הגדרת `showMusicButton` ב-AppBarWithLogo
- [ ] Playlist selector (בחירה בין פלייליסטים)
- [ ] Auto-pause כשיוצאים מהאפליקציה

### גרסה 1.2
- [ ] Mini-player בתחתית המסך
- [ ] Swipe gestures ב-Dialog
- [ ] Equalizer visualization
- [ ] Background playback עם notification

### גרסה 2.0
- [ ] Spotify/Apple Music integration
- [ ] Upload custom playlists
- [ ] Share current track
- [ ] Lyrics display

---

נוצר: 2026-01-04
גרסה: 1.0.0
מחבר: Kattrick Dev Team
